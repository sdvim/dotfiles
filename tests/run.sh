#!/bin/sh
set -u

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

fail() {
    printf 'FAIL %s\n' "$*" >&2
    failures=$((failures + 1))
}
have() { command -v "$1" >/dev/null 2>&1; }

hosts=$(chezmoi --source "$repo" execute-template \
    '{{ range $name, $machine := .machines }}{{ if $machine }}{{ $name }} {{ end }}{{ end }}') || fail "read machines"

for host in $hosts; do
    mkdir -p "$tmp/$host/home"
    printf '[data]\n    host = "%s"\n    tailnet = "example.ts.net"\n' "$host" >"$tmp/$host/chezmoi.toml"
    dest=$tmp/$host/home
    cm() { chezmoi --no-tty --config "$tmp/$host/chezmoi.toml" --source "$repo" --destination "$dest" \
        --cache "$tmp/$host/cache" --persistent-state "$tmp/$host/state.boltdb" "$@"; }

    if cm apply --exclude=scripts --force >/dev/null; then
        git config -f "$dest/.config/git/config" --list >/dev/null || fail "$host: git config does not parse"
        [ "$(ssh -F "$dest/.ssh/config" -G mini </dev/null 2>/dev/null | awk '$1 == "hostname" { print $2 }')" = mini.example.ts.net ] ||
            fail "$host: ssh config does not resolve mini to its tailnet name"
        for zshfile in .zshenv .zprofile .zshrc; do
            zsh -n "$dest/$zshfile" || fail "$host: $zshfile has a syntax error"
        done
        jq -e '.hooks.PostToolUse[0].hooks[0].command | test("atuin hook claude-code")' "$dest/.claude/settings.json" >/dev/null 2>&1 ||
            fail "$host: Claude Code settings lack the Atuin hooks"
        if [ "$(cm execute-template '{{ has "remote-login" (dig "machines" .host "roles" (list) .) }}')" = true ]; then
            grep -qF "$(cm execute-template '{{ .ssh.key }}')" "$dest/.ssh/authorized_keys" 2>/dev/null ||
                fail "$host: authorized_keys lacks the SSH key"
        elif [ -e "$dest/.ssh/authorized_keys" ]; then
            fail "$host: authorized_keys installed without the remote-login role"
        fi
        obsidian="$dest/Library/Application Support/obsidian/obsidian.json"
        if [ "$(cm execute-template '{{ has "personal" (dig "machines" .host "roles" (list) .) }}')" = true ]; then
            jq -e '.cli == true' "$obsidian" >/dev/null 2>&1 || fail "$host: obsidian.json does not enable the CLI"
        elif [ -e "$obsidian" ]; then
            fail "$host: obsidian.json installed without the personal role"
        fi
    else
        fail "$host: chezmoi apply"
    fi

    cm execute-template '{{ includeTemplate "Brewfile" . }}' | ruby -c >/dev/null || fail "$host: Brewfile"

    for script in "$repo"/home/.chezmoiscripts/*; do
        rendered=$tmp/$host/$(basename "$script" .tmpl)
        cm execute-template <"$script" >"$rendered" || fail "$host: render $(basename "$rendered")"
        grep -q . "$rendered" || rm "$rendered"
    done
    if have shellcheck; then
        shellcheck -S warning "$tmp/$host"/run_*.sh || fail "$host: shellcheck"
    fi
    echo "ok  $host"
done

if have shellcheck; then
    shellcheck -S warning "$repo/install.sh" "$repo/tests/run.sh" || fail shellcheck
else
    echo "skip shellcheck (not installed)"
fi

if git -C "$repo" grep --untracked -nIE '[a-z0-9]+-[a-z0-9]+\.ts\.net|BEGIN [A-Z ]*PRIVATE KEY' -- ':!tests/run.sh'; then
    fail "private strings in the repository"
fi
if git -C "$repo" ls-files -co --exclude-standard | grep -iE '\.(ttf|otf|woff2?|pem|key)$'; then
    fail "font or key files in the repository"
fi

[ "$failures" -eq 0 ] || {
    echo "$failures check(s) failed" >&2
    exit 1
}
echo "all checks passed"
