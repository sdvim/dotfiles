#!/bin/zsh
read -r -d '' report <<'SCRIPT'
t3=$HOME/.local/bin/t3
[[ -x $t3 ]] || exit 0
threads=$(for project in $HOME $HOME/.t3/scratch $HOME/Git/*(/N); do
    $t3 thread list --project $project --json 2>/dev/null
done | jq -s 'add // [] | unique_by(.threadId) | map(select(.relationshipToParent != "subagent" and (.settled | not) and (.snoozed | not)))')
for id in $(jq -r '.[] | select(.status == "running" or .status == "waiting") | .threadId' <<<$threads); do
    (( $($t3 thread show $id --json --messages 0 | jq '.thread.pendingRequestCount // 0') > 0 )) && jq -r --arg id $id '.[] | select(.threadId == $id) | "input\t\(.title)"' <<<$threads
done
jq -r '.[] | select(.status == "failed") | "failed\t\(.title)"' <<<$threads
SCRIPT
data=$(chezmoi data --format json)
self=$(jq -r .host <<<$data)
hosts=($self ${(f)"$(jq -r '.machines | to_entries[] | select(.value.roles // [] | index("t3-server")) | .key' <<<$data)"})
lines=(${(f)"$(for host in ${(u)hosts}; do
    { if [[ $host == $self ]]; then zsh -c $report; else ssh -o BatchMode=yes -o ConnectTimeout=5 $host $report; fi 2>/dev/null } |
        sed "s/^/$host"$'\t'"/" &
done)"})
(( $#lines )) || exit 0
print "$#lines | sfimage=bubble.left.and.exclamationmark.bubble.right"
print -- ---
for state in input failed; do
    for line in ${(M)lines:#*$'\t'$state$'\t'*}; do
        fields=("${(@ps:\t:)line}")
        print -r -- "${fields[3]} · ${fields[2]} on ${fields[1]}"
    done
done
