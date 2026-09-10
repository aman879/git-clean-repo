# Git Clean CLI

A simple and interactive command-line tool to quickly find and delete local Git repositories or delete repositories from your GitHub account.

## Prerequisites

Ensure you have the following dependencies installed:

- [`fzf`](https://github.com/junegunn/fzf) (Required for interactive selection)
- [`gh`](https://cli.github.com/) (Required for cleaning GitHub repositories)
- `git` (Required for cleaning local repositories)

## Installation

You can install `git-clean` using the provided installation script. It copies the script to `~/.local/bin/git-clean` and ensures the path is in your `~/.zshrc`.

```bash
./install.sh
source ~/.zshrc
```

## Usage

### Local Repositories

Search and delete local Git repositories. If no paths are provided, it searches in common development directories like `~/Projects`, `~/Code`, `~/Work`, `~/Desktop`, and `~/Documents`.

```bash
git-clean local
```

You can also specify specific directories to search:

```bash
git-clean local ~/my-projects ~/other-code
```

### GitHub Repositories

Search and delete repositories from your GitHub account. You must be authenticated via the GitHub CLI (`gh auth login`).

```bash
git-clean github
```

To search and delete only **private** repositories:

```bash
git-clean github --private
```

### Options

- `-h`, `--help`: Show the help message.
- `-v`, `--version`: Show the version.

## How it works

- **Interactive Selection**: Uses `fzf` to let you search and select multiple repositories. You can use `<TAB>` to select multiple repositories and `<ENTER>` to confirm.
- **Safety**: Deletions require an explicit `DELETE` confirmation before any destructive actions are performed.
