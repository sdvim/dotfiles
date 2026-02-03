function c --description "Claude yolo mode in tmux"
    set -l session_name (basename $PWD)

    if set -q TMUX
        claude --dangerously-skip-permissions --fork-session $argv
    else
        if tmux has-session -t "=$session_name" 2>/dev/null
            tmux attach -d -t "=$session_name" \; set status off
        else
            tmux new-session -s "$session_name" "claude --dangerously-skip-permissions --fork-session $argv" \; set status off
        end
    end
end
