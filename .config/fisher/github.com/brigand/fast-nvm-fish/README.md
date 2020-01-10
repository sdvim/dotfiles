## What is nvm?

[nvm] is a tool for managing multiple versions of node and npm.

[nvm]: https://github.com/creationix/nvm/blob/master/README.markdown

## What is fast-nvm-fish?

It's a utility that manipulates your PATH to include the desired version of node. Other solutions require parsing `env`'s output and do other slow things. Before this, there was an extra second or two added to my shell startup time. With about 10 versions of node installed this script takes 50ms to run.

## Usage

```sh
nvm install 5
nvm use 5 # or e.g. 5.8 or 5.8.1
```

## Install:

**Requirements:** you must have Fish 2.6.0 or newer.

First install nvm if you haven't already. You can check the [nvm readme] for a more up to data install command.

[nvm readme]: https://github.com/creationix/nvm/blob/master/README.md#install-script

```sh
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
```

Then install `fast-nvm-fish`:

```sh
curl -sSL https://raw.githubusercontent.com/brigand/fast-nvm-fish/master/nvm.fish > ~/.config/fish/functions/nvm.fish
```

Or using [fisher](https://github.com/jorgebucaran/fisher):

```sh
fisher add brigand/fast-nvm-fish
```

The `fish_user_paths` [universal variable](https://fishshell.com/docs/current/tutorial.html#tut_universal) must exist before running `nvm` commands. Run this once in your fish shell:

```sh
set -U fish_user_paths
```

To make it work on new shells you'll need to set a version in `config.fish`.

```sh
echo 'nvm use 7.2.1' >> ~/.config/fish/config.fish
```

If you have nvm installed anywhere other than ~/.nvm, set a global
variable in your `config.fish` file *before* first invoking `nvm use`.

```sh
set -gx NVM_DIR ~/custom_path/nvm
nvm use 7.2.1
```
