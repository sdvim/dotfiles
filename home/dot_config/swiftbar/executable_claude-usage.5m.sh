#!/bin/zsh
report='jq -c "{account: .oauthAccount.emailAddress, at: .cachedUsageUtilization.fetchedAtMs, limits: [.cachedUsageUtilization.utilization.limits[]? | {kind, percent, resets_at}]}" ~/.claude.json'
self=$(chezmoi data --format json | jq -r .host)
for host in $(swarm list); do
    if [[ $host == $self ]]; then zsh -c $report; else ssh -o BatchMode=yes -o ConnectTimeout=5 $host $report; fi 2>/dev/null &
done | jq -rs '
    map(select(.at)) | group_by(.account) | map(max_by(.at))
    | map(select(any(.limits[]; .percent >= 90))) as $hot
    | if ($hot | length) == 0 then empty else
        "\([$hot[].limits[].percent] | max)% | sfimage=gauge.with.dots.needle.100percent",
        "---",
        ($hot[] | .account, (.limits[] | "--\(.kind): \(.percent)% · resets \(.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdate | strflocaltime("%a %H:%M"))"))
      end'
wait
