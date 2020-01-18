# Defined in - @ line 1
function config	 --description 'alias config=/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
	/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv;
end

# https://gist.github.com/tomblcode/86b2dd8f4802ff7abe6a14d4f2b514c3#step-4-optional-but-recommended-calling-nvm-use-automatically-in-a-directory-with-a-nvmrc-file

function find_up
    set path (pwd)
    while test $path != "/"
        and not test -e "$path/$argv[1]"
        set path (dirname $path)
    end
    if test -e "$path/$argv[1]"
        echo $path
    else
        echo ""
    end
end

function __check_nvm --on-variable PWD
    if status --is-command-substitution
        return
    end

    set nvm_path (find_up ".nvmrc" | tr -d '[:space:]')

    if test "$nvm_path" != ""

        set nvmrc_node_version (nvm version (cat "$nvm_path/.nvmrc") '; 2>1')

        if test "$nvmrc_node_version" = "N/A"
            echo "Installing node version "(cat "$nvm_path/.nvmrc")
            nvm install
            set nvm_node_version (nvm version)
        else if test "$nvmrc_node_version" != (nvm version)
            echo "Changing node version to $nvmrc_node_version"
            nvm use
            set nvm_node_version (nvm version)
        end
        echo "$nvm_path/.nvmrc"
    else if test (nvm version) = "none"
        nvm use default --silent
    else if test (nvm version) != (nvm version default)
        echo "Reverting node version to default"
        nvm use default
    end
end

__check_nvm