---
title: Rift Drive
author: [ Matthew T. C. Boyea ]
lang: en
keywords: [ ]
default_: report
---
## An open-source encrypted replacement for Google Drive and One Drive

Google Drive and OneDrive are expensive.
It is difficult to create local backups of your storage.
Your data is readable by the organizations that store it.
Plaintext editors are not provided.
There is no way to self-host your data.
They have poor (slow, often incomplete) mobile interfaces.

The Rift Drive allows you to use a cross-platform web interface to access encrypted documents, hosted in the cloud or local servers.
Web editors support simultaneous editing with realtime sync between devices.

### Installation

First, copy this repository.

- [Clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) from GitHub to your computer.

Then, install Nix (the package manager).

- [Install Nix](https://nixos.org/download).
- [Enable Flakes](https://nixos.wiki/wiki/Flakes).

Optionally install direnv (to automatically run `nix develop` when your terminal enters into the project directory).

- [Install direnv](https://direnv.net/docs/installation.html).
- [Install nix-direnv](https://github.com/nix-community/nix-direnv#installation) for better caching (optional).
- Open a terminal in this project's root directory.
- Run command `direnv allow`

### Usage

Be sure to [read the license](./LICENSE.md).

#### Scripts

Commands can be run from within any of the project directories.

| Command | Description |
|:--- |:--- |
| `nix run` | Alias for `nix run .#help` |
| `nix run .#[SCRIPT] [ARGUMENTS]` | Run a script |
| `nix develop` | Start a subshell with the project dependencies installed |

| Script | Description |
|:--- |:--- |
| `help` | Print usage information for the Rift Drive CLI |

Scripts are declared in [flake.nix](./flake.nix) and defined in [scripts/](./scripts).

