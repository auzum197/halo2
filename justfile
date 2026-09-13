# Tracking branches for the zakura halo2 fork.
#
#   just sync                     fetch all remotes and rebuild the tracking branches
#                                 (zakura-patches, zakura-rebased, zsa-upstream, commit map); never touches main
#   just sync v1.2.0 79213cbe     same, pinned to explicit zakura / zcash revs instead of the tips
#   just -f .git/regen.just -d . continue
#                                 resume after resolving a source conflict by hand
#   just integrate                rebuild main from zakura-rebased: workspace pins, fixtures, signing
#   just map / check              regenerate / verify the commit map
#   just rerere-push / rerere-pull share recorded conflict resolutions via the rr-cache branch
#
#   Committed: justfile, zakura-patches.classes. Ignored scratch: zakura-patches.map, .regen-state.

source  := "zakura/main"
patches := "zakura-patches"
rebased := "zakura-rebased"
base    := "zcash-upstream/main"
zsa_url := "https://github.com/QED-it/halo2.git"   # the only ZSA source of truth
zsa_src := "zsa/zsa1"
zsa_mirror := "zsa-upstream"
map     := "zakura-patches.map"
classes := "zakura-patches.classes"
state   := ".regen-state"
trunk   := "main"
rootsrc := "main"   # branch to take the workspace root files from
crates  := "halo2_proofs halo2_gadgets halo2_poseidon"
pin_msg := "build: adapt workspace root to zakura manifests and pin shared crates"
fix_msg := "test: regenerate stored circuit fixtures"
rr_branch := "rr-cache"
rr_msg  := "chore: record rerere resolutions"
filter_repo := env("GIT_FILTER_REPO", "git filter-repo")
nosign  := "-c commit.gpgsign=false"

default: sync

# Fetch and rebuild every tracking branch. main is not touched.
sync zakura_rev=source upstream_rev=base: fetch rerere-pull (extract zakura_rev) (rebase upstream_rev) zsa map

# Rebuild main on top of {{rebased}}: pins at the synced zakura rev, fixtures, signatures.
integrate: && fixtures sign map
    #!/usr/bin/env bash
    set -euo pipefail
    . ./{{state}}
    just rebased={{rebased}} trunk={{trunk}} rootsrc={{rootsrc}} pins "$zakura"

# Mirror zsa1 verbatim into {{zsa_mirror}} and report which of its commits zcash main lacks (by patch id).
zsa:
    #!/usr/bin/env bash
    set -euo pipefail
    git branch -f --no-track {{zsa_mirror}} {{zsa_src}}
    echo "{{zsa_mirror}} = {{zsa_src}} @ $(git rev-parse --short {{zsa_src}})"
    echo "{{zsa_src}} commits missing from {{base}}:"
    git cherry -v {{base}} {{zsa_src}} | grep '^+' | sed 's/^+ /  /' || echo "  none"

# Fetch the three upstream remotes. Refuse to fetch ZSA from anywhere but {{zsa_url}}.
fetch:
    #!/usr/bin/env bash
    set -euo pipefail
    [ "$(git remote get-url zsa)" = "{{zsa_url}}" ] || { echo "remote zsa must be {{zsa_url}}; run: git remote set-url zsa {{zsa_url}}" >&2; exit 1; }
    git fetch --multiple zakura zsa zcash-upstream

# Filter the zakura monorepo down to the halo2 crates -> {{patches}}.
extract zakura_rev:
    #!/usr/bin/env bash
    set -euo pipefail
    {{filter_repo}} --version >/dev/null 2>&1 || { echo "git-filter-repo not found; brew install git-filter-repo, or set GIT_FILTER_REPO" >&2; exit 1; }
    zakura=$(git rev-parse --verify "{{zakura_rev}}^{commit}")
    tmp="${TMPDIR:-/tmp}/zakura-extract.$$"; rm -rf "$tmp"
    git clone -q --no-hardlinks "file://$PWD" "$tmp"
    git -C "$tmp" fetch -q "file://$PWD" "$zakura:refs/heads/extract"
    paths=(); for c in {{crates}}; do paths+=(--path "$c" --path "crates/$c"); done
    (cd "$tmp" && {{filter_repo}} --force --refs extract "${paths[@]}" --path-rename crates/: >/dev/null)
    git fetch -q "$tmp" "+refs/heads/extract:refs/heads/{{patches}}"
    for c in {{crates}}; do
        git diff --quiet "$zakura:crates/$c" "{{patches}}:$c" || { echo "{{patches}}:$c differs from $zakura" >&2; exit 1; }
    done
    echo "zakura=$zakura" > {{state}}
    echo "{{patches}}: $(git rev-list --count {{patches}}) commits, tree matches $zakura"

# Rebase {{patches}} (minus the vendored root) onto upstream_rev -> {{rebased}}.
rebase upstream_rev:
    #!/usr/bin/env bash
    set -euo pipefail
    upstream=$(git rev-parse --verify "{{upstream_rev}}^{commit}")
    root=$(git rev-list --max-parents=0 {{patches}})
    echo "upstream=$upstream" >> {{state}}
    echo "prev=$(git branch --show-current)" >> {{state}}
    cp "{{justfile()}}" .git/regen.just   # {{rebased}} has no justfile; keep a copy for the nested call
    git checkout -q -B {{rebased}} {{patches}}
    git {{nosign}} rebase --empty=drop --onto "$upstream" "$root" >/dev/null 2>&1 || true
    just --justfile .git/regen.just --working-directory "$PWD" patches={{patches}} rebased={{rebased}} state={{state}} continue

# Auto-resolve manifest conflicts and resume.
continue:
    #!/usr/bin/env bash
    set -euo pipefail
    while [ -d .git/rebase-merge ]; do
        conflicts="${TMPDIR:-/tmp}/regen-conflicts.$$"; git diff --name-only --diff-filter=U > "$conflicts"
        while IFS= read -r f; do
            case "$f" in
                Cargo.toml|*/Cargo.toml|*/Cargo.lock|*/CHANGELOG.md|*/README.md|*/LICENSE-*)
                    if git cat-file -e "REBASE_HEAD:$f" 2>/dev/null; then git checkout -q REBASE_HEAD -- "$f"; else git rm -q --cached "$f"; rm -f "$f"; fi ;;
                Cargo.lock)
                    git checkout -q HEAD -- "$f" ;;   # never let a crate lockfile deletion take the root lockfile
                *)
                    echo "conflict needs manual resolution at $(git rev-parse --short REBASE_HEAD) $(git log -1 --format=%s REBASE_HEAD):" >&2
                    git diff --name-only --diff-filter=U >&2
                    echo "resolve, git add, then: just -f .git/regen.just -d . continue && just map" >&2; exit 1 ;;
            esac
        done < "$conflicts"; rm -f "$conflicts"
        # --continue/--skip exit non-zero when the next pick conflicts; the loop handles that
        if git diff --cached --quiet; then GIT_EDITOR=true git {{nosign}} rebase --skip >/dev/null 2>&1 || true
        else GIT_EDITOR=true git {{nosign}} rebase --continue >/dev/null 2>&1 || true; fi
    done
    . ./{{state}}
    git ls-files --error-unmatch Cargo.lock >/dev/null || { echo "root Cargo.lock was deleted during rebase" >&2; exit 1; }
    for c in {{crates}}; do
        n=$(git diff --stat "$zakura:crates/$c" "{{rebased}}:$c" | tail -1); echo "$c vs zakura: ${n:-identical}"
    done
    echo "{{rebased}}: $(git rev-list --count "$upstream..{{rebased}}") commits on $upstream"
    [ -n "${prev:-}" ] && git checkout -q "$prev" || true

# Reapply the workspace root and move the git pins to zakura_rev; commits on {{rebased}}.
pins zakura_rev:
    #!/usr/bin/env bash
    set -euo pipefail
    zakura=$(git rev-parse --verify "{{zakura_rev}}^{commit}")
    git checkout -q {{rebased}}
    git checkout {{rootsrc}} -- Cargo.toml Cargo.lock rust-toolchain.toml halo2/Cargo.toml justfile .gitignore README.md {{classes}}
    sed -i '' -E "s/(git = \"https:\/\/github.com\/zakura-core\/common.git\", rev = \")[0-9a-f]+\"/\1$zakura\"/" Cargo.toml
    ver=$(git show "$zakura:Cargo.toml" | sed -n '/^\[workspace.package\]/,/^\[/p' | sed -n 's/^version = "\(.*\)"/\1/p')
    sed -i '' -E "s/^version = \"[^\"]+\"/version = \"$ver\"/; s/(package = \"zakura-halo2-[a-z]+\", version = \")[^\"]+\"/\1$ver\"/" Cargo.toml
    cargo fetch >/dev/null
    cargo build --workspace --all-targets --offline 2>&1 | tail -1
    git add Cargo.toml Cargo.lock rust-toolchain.toml halo2/Cargo.toml
    git {{nosign}} commit -q -m "{{pin_msg}}"
    git checkout -q -B {{trunk}} {{rebased}}
    git branch -f {{rebased}} HEAD~1
    echo "{{trunk}} = {{rebased}} + pins @ $zakura (version $ver)"

# Regenerate only the stored-circuit fixtures whose tests fail; commits on {{trunk}}.
fixtures:
    #!/usr/bin/env bash
    set -euo pipefail
    git checkout -q {{trunk}}
    failing=$(cargo test --offline --release -p zakura-halo2-gadgets 2>&1 | sed -n 's/^test \(.*stored.*\) \.\.\. FAILED$/\1/p' || true)
    if [ -z "$failing" ]; then echo "no stored-circuit test fails; nothing to regenerate"; exit 0; fi
    echo "regenerating for:"; echo "$failing"
    CIRCUIT_TEST_GENERATE_NEW_DATA=1 cargo test --offline --release -p zakura-halo2-gadgets -- $(echo "$failing" | tr '\n' ' ') >/dev/null
    cargo test --offline --release --workspace 2>&1 | grep -E '^test result' | grep -v ' 0 failed' && { echo "tests still fail" >&2; exit 1; } || true
    git add halo2_gadgets/src/test_circuits/circuit_data
    git {{nosign}} commit -q -m "{{fix_msg}}"
    echo "fixtures committed on {{trunk}}"

# Sign every commit above the upstream base (rewrites {{trunk}} and {{rebased}}).
sign:
    #!/usr/bin/env bash
    set -euo pipefail
    . ./{{state}}
    git checkout -q {{trunk}}
    tip=$(git rev-parse {{rebased}}); n=$(git rev-list --count "$upstream..$tip")
    git rebase -q "$upstream" --exec 'git commit --amend --no-edit -S' >/dev/null
    git branch -f {{rebased}} "$(git rev-list --reverse "$upstream..{{trunk}}" | sed -n "${n}p")"
    echo "unsigned commits left: $(git log --format=%G? "$upstream..{{trunk}}" | grep -vc '^G' || true)"

# Store .git/rr-cache on the orphan {{rr_branch}} branch and push it.
rerere-push:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -d .git/rr-cache ] || { echo "no .git/rr-cache to push"; exit 0; }
    export GIT_DIR="$PWD/.git" GIT_WORK_TREE="$PWD/.git/rr-cache" GIT_INDEX_FILE="${TMPDIR:-/tmp}/rr-index.$$"
    git add -A
    tree=$(git write-tree); rm -f "$GIT_INDEX_FILE"
    parent=$(git rev-parse -q --verify "refs/heads/{{rr_branch}}" || true)
    if [ -n "$parent" ] && [ "$(git rev-parse "$parent^{tree}")" = "$tree" ]; then echo "{{rr_branch}} already up to date"; exit 0; fi
    sign=""; [ "$(git config --get commit.gpgsign || true)" = true ] && sign="-S"
    commit=$(git commit-tree $sign "$tree" ${parent:+-p "$parent"} -m "{{rr_msg}}")
    git update-ref "refs/heads/{{rr_branch}}" "$commit"
    unset GIT_WORK_TREE GIT_INDEX_FILE
    git push -q origin "{{rr_branch}}"
    echo "{{rr_branch}} -> $(git rev-parse --short "$commit") ($(git ls-tree -d "$commit" | wc -l | tr -d ' ') resolutions)"

# Fetch the {{rr_branch}} branch and unpack it into .git/rr-cache (no-op if it does not exist).
rerere-pull:
    #!/usr/bin/env bash
    set -euo pipefail
    git fetch -q origin "+refs/heads/{{rr_branch}}:refs/remotes/origin/{{rr_branch}}" 2>/dev/null || { echo "no {{rr_branch}} branch on origin yet"; exit 0; }
    mkdir -p .git/rr-cache
    git archive "origin/{{rr_branch}}" | tar -x -C .git/rr-cache
    git config rerere.enabled true
    git config rerere.autoupdate true
    echo "rr-cache: $(ls .git/rr-cache | wc -l | tr -d ' ') resolutions"

# Regenerate the SHA classification map.
map:
    #!/usr/bin/env python3
    import re, subprocess, datetime
    SOURCE, PATCHES, REBASED, BASE = "{{source}}", "{{patches}}", "{{rebased}}", "{{base}}"
    MAP, CLASSES = "{{map}}", "{{classes}}"
    SEP = "\x1f"
    def git(*a): return subprocess.check_output(["git", *a], text=True)
    def log(rng):
        out = git("log", "--reverse", f"--format=%H{SEP}%P{SEP}%aI{SEP}%s", rng)
        return [l.split(SEP) for l in out.splitlines() if l]
    def short(h): return h[:9] if h and h != "-" else "-"
    PERF = re.compile(r"^(Optimi[sz]e|Speed up|Batch|Parallel|Cache|Fuse|Avoid|Prune|Reduce|Precompute|Defer|Reuse|Prepare|Accelerate|Interleave|Eliminate|Fold|Stream|Pin|Overlap|Share|Track|Peel|Use|Compile|Borrow|Keep|Store|Index|Handle cyclic|Merge sorted|Reconstruct|Retain|Factor|Plan|Evaluate|Size|Initialize|Cap|Preserve|Two-lane|Add a self-tuning|Add deferred|Compare|Enable AArch64|halo2: (thread-aware|prepared))", re.I)
    DEP = re.compile(r"(rename|version|changelog|manifest|license|readme|katex|edition|msrv|rust version|crates|packag|tarball|repository|authorship|homepage|bump|release|update to|rand 0\.10|retarget|reframe|provenance|debris|^feat: (create|fork)|workspace|lineage|1\.0\.0|dual-license|dependency|clippy|formatting|prune 17)", re.I)
    def classify(s):
        if PERF.search(s): return "perf"
        if DEP.search(s): return "dep-migration"
        return "chore"
    overrides, notes = {}, {}
    try:
        for l in open(CLASSES):
            if l.startswith("#") or not l.strip(): continue
            c = l.rstrip("\n").split("\t")
            overrides[c[0]] = c[1]
            if len(c) > 2: notes[c[0]] = c[2]
    except FileNotFoundError:
        pass
    def override(o):
        hits = [k for k in overrides if o.startswith(k) or k.startswith(o)]
        return overrides[hits[0]] if hits else None
    def note(o):
        hits = [k for k in notes if o.startswith(k) or k.startswith(o)]
        return notes[hits[0]] if hits else None
    orig = {(d, s): h for h, p, d, s in log(SOURCE)}
    reb = {(d, s): h for h, p, d, s in log(f"{BASE}..{REBASED}")}
    rows, merges, skipped = [], 0, []
    for h, p, d, s in log(PATCHES):
        o = short(orig.get((d, s), "?"))
        if len(p.split()) > 1:
            merges += 1; rows.append((o, short(h), "-", "merge", s)); continue
        r = reb.get((d, s))
        if r is None:
            skipped.append((o, s)); rows.append((o, short(h), "-", "skipped", s)); continue
        rows.append((o, short(h), short(r), override(o) or classify(s), s))
    root = short(git("rev-list", "--max-parents=0", PATCHES).strip())
    hdr = [
        f"# {MAP} — untracked commit map. Generated {datetime.date.today()} by `just map`.",
        f"# Source: {SOURCE} @ {git('rev-parse', SOURCE).strip()}; series tip {rows[-1][0]} \"{rows[-1][4]}\".",
        f"# Series root: {root} ({PATCHES}). {REBASED} root: {short(git('rev-parse', BASE).strip())} ({BASE}).",
        f"# Skipped in {REBASED}: " + "; ".join(f"{o} \"{s}\"" + (f" — {note(o)}" if note(o) else "") for o, s in skipped) + f"; {merges} merge commits (series linearized).",
        f"# Columns: orig_sha\t{PATCHES}_sha\t{REBASED}_sha\tclass\tsubject",
    ]
    with open(MAP, "w") as f:
        f.write("\n".join(hdr) + "\n")
        for r in rows: f.write("\t".join(r) + "\n")
    unresolved = sum(1 for r in rows if r[0] == "?")
    print(f"{MAP}: {len(rows)} rows, {merges} merges, {len(skipped)} skipped, {unresolved} unresolved orig SHAs")

# Fail if the committed history no longer matches the map (ignores the header).
check:
    #!/usr/bin/env bash
    set -euo pipefail
    before="${TMPDIR:-/tmp}/map.before.$$"; after="${TMPDIR:-/tmp}/map.after.$$"
    grep -v '^#' {{map}} > "$before"
    just map >/dev/null
    grep -v '^#' {{map}} > "$after"
    if ! diff "$before" "$after"; then
        echo "{{map}} was stale; regenerated" >&2; exit 1
    fi
    echo "{{map}} is current"
