# Auto-rename Zellij tabs based on running command
# Shows command while running, directory name at prompt

function __zellij_tab_preexec --on-event fish_preexec
    if set -q ZELLIJ
        # Get first word of command (the actual program)
        set -l cmd (string split ' ' $argv[1])[1]
        zellij action rename-tab "$cmd" 2>/dev/null
    end
end

function __zellij_tab_postexec --on-event fish_postexec
    if set -q ZELLIJ
        # Reset to directory name after command finishes
        zellij action rename-tab (basename $PWD) 2>/dev/null
    end
end

# Set initial tab name when shell starts
if set -q ZELLIJ
    zellij action rename-tab (basename $PWD) 2>/dev/null
end
