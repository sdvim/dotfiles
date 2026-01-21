#!/usr/bin/env zsh

# SSH tmux session picker for Claude sessions
# Homerow keys for selection, auto-selects on keypress
#
# Set VIP_DIRS to a colon-separated list of directories:
#   export VIP_DIRS="$HOME/dotfiles:$HOME/Git:$HOME/projects/myapp"

if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
  session_keys=(a s d f g h j k l)
  vip_keys=(e w r t)

  # Parse VIP_DIRS into array
  vip_dirs=()
  if [[ -n "$VIP_DIRS" ]]; then
    vip_dirs=("${(@s/:/)VIP_DIRS}")
  fi

  while true; do
    clear
    sessions=("${(@f)$(tmux list-sessions -F '#{session_name}' 2>/dev/null)}")

    echo "Claude sessions:"
    echo ""

    if [[ ${#sessions[@]} -gt 0 && -n "${sessions[1]}" ]]; then
      for i in {1..${#sessions[@]}}; do
        [[ $i -gt 9 ]] && break
        echo "  ${session_keys[$i]}) ${sessions[$i]}"
      done
      echo ""
    fi

    # Show VIP directories
    for i in {1..${#vip_dirs[@]}}; do
      [[ $i -gt ${#vip_keys[@]} ]] && break
      dir="${vip_dirs[$i]}"
      # Collapse $HOME to ~
      display_dir="${dir/#$HOME/~}"
      echo "  ${vip_keys[$i]}) $display_dir"
    done

    echo "  q) quit"
    echo ""
    echo -n "› "

    read -k 1 choice
    echo ""

    case "$choice" in
      q) break ;;
      [ewrt])
        for i in {1..${#vip_keys[@]}}; do
          if [[ "${vip_keys[$i]}" == "$choice" && $i -le ${#vip_dirs[@]} ]]; then
            dir="${vip_dirs[$i]}"
            cd "$dir" && exec tmux new-session -s "${PWD##*/}" "claude --dangerously-skip-permissions"
            break
          fi
        done
        ;;
      [asdfghjkl])
        for i in {1..${#session_keys[@]}}; do
          if [[ "${session_keys[$i]}" == "$choice" && $i -le ${#sessions[@]} ]]; then
            tmux attach -t "${sessions[$i]}"
            break
          fi
        done
        ;;
    esac
  done
fi
