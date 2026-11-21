#!/bin/zsh
behind=(${(f)"$(swarm status 2>/dev/null | awk '/ behind/ { print $1 "\t" $2 }')"})
(( $#behind )) || exit 0
print "$#behind | sfimage=arrow.down.circle"
print -- ---
for line in $behind; do
    print -r -- "${line%%$'\t'*}: ${line#*$'\t'} commits behind"
done
hosts=(${behind%%$'\t'*})
action="Update | bash=$HOME/.local/bin/swarm"
for param in update $hosts; do
    action+=" param$((++i))=$param"
done
print -r -- "$action terminal=false refresh=true"
