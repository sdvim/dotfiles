#!/bin/zsh
state=$HOME/Library/Caches/swarm-cpu
mkdir -p $state
zmodload zsh/datetime
now=$EPOCHSECONDS

sample() {
    local host=$1 out
    if [[ $host == $(chezmoi data --format json | jq -r .host) ]]; then
        out=$(top -l 2 -s 1 -n 3 -o cpu -stats cpu,command)
    else
        out=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $host top -l 2 -s 1 -n 3 -o cpu -stats cpu,command 2>/dev/null)
    fi
    [[ -n $out ]] || return
    print -r -- "$out" | awk -v host=$host '
        /^CPU usage/ { idle = $7 + 0 }
        { last[NR] = $0 }
        END { printf "%s\t%d", host, 100 - idle; for (i = NR - 2; i <= NR; i++) printf "\t%s", last[i]; print "" }'
}

hot=(${(f)"$(for host in $(swarm list); do sample $host & done | while IFS=$'\t' read -r host busy procs; do
    if (( busy >= 95 )); then
        [[ -f $state/$host ]] || print $now >$state/$host
        (( now - $(<$state/$host) >= 600 )) && print -r -- "$host"$'\t'"$busy"$'\t'"$procs"
    else
        rm -f $state/$host
    fi
done)"})
(( $#hot )) || exit 0
print "${(j:, :)${hot%%$'\t'*}} | sfimage=flame"
print -- ---
for line in $hot; do
    fields=("${(@ps:\t:)line}")
    print -r -- "${fields[1]}: ${fields[2]}% CPU for $(( (now - $(<$state/${fields[1]})) / 60 )) min"
    for proc in ${fields[3,-1]}; do print -r -- "--${proc//  ##/ }"; done
    print -r -- "--Shut down simulators | bash=$HOME/.local/bin/swarm param1=run param2=${fields[1]} param3=-- param4=xcrun param5=simctl param6=shutdown param7=all terminal=false refresh=true"
done
