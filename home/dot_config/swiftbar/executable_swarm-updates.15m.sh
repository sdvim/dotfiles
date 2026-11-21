#!/bin/zsh
behind=(${(f)"$(swarm status 2>/dev/null | awk -F'\t' '$2 ~ /^[0-9]+$/ && $2 > 0 { print $1 "\t" $2 }')"})
(( $#behind )) || exit 0
print "$#behind | sfimage=arrow.down.circle"
print -- ---
for line in $behind; do
    print -r -- "${line%%$'\t'*}: ${line#*$'\t'} commits behind"
done
hosts=(${behind%%$'\t'*})
action="Update | bash=/usr/bin/open"
for param in -na Ghostty --args --wait-after-command=true -e $HOME/.local/bin/swarm update $hosts; do
    action+=" param$((++i))=$param"
done
print -r -- "$action terminal=false refresh=true"
