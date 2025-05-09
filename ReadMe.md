SECursor
========

Sandboxed Environment Cursor AI Editor


## Status

This project is brand new as of April 21, 2025.
It has only been tested from an Ubuntu Linux host.


## Synopsis

```bash
Usage: secursor [options] [repo]

Options:
      --start         Start the editor (default)
  -r, --restart       Run --kill and --start

  -K, --kill          Kill the editor container
  -R, --rebuild       Rebuild the image and restart

  -h, --help          Show this help message
  -v, --version       Show the version

$ cd my-project-git-repo
$ secursor   # Starts the Cursor VSCode application
```


## Description

This project provides a complete Docker-based sandbox environment for running
the Cursor AI editor.
It sets up a secure containerized environment with all necessary dependencies
and configuration to run Cursor smoothly.


### Rationale

The Cursor AI editor is a powerful tool that integrates AI capabilities directly
into your development workflow.
However, running any application that makes external API calls and has access to
your code raises security concerns.

Cursor has a "YOLO mode" that turns off prompting before taking an action.
While this is mode is off by default, once you've tried it you'll never want to
turn it off.
Even if you did turn it off you'd certainly get tired of thinking through each
prompt and likely you'd eventually approve something you didn't actually want.

Cursor has sandboxing built in, but there's at least a couple issues there:

* It often doesn't work out of the box on Linux, and the most common "fix" you
  see on the net is to start Cursor with the `--no-sandbox` option.
* You need to trust that Cursor (not open source) sandboxing is doing what you
  expect.

Is cursor able to read anything on my disk including my private SSH keys?

Can Cursor be [exploited by other MCPs](
https://invariantlabs.ai/blog/whatsapp-mcp-exploited)?

If Cursor is an agentic AI tool that acts on my behalf with access to my machine
and thus everything my machine can access, what could go wrong?

What if we launched Cursor from an already sandboxed environment?
A machine that had exactly what we needed for successful dev and nothing more?

That's SECursor!

The SECursor project aims to mitigate risks by:

- Running Cursor in an isolated container with limited filesystem access
- Preventing access to sensitive host files and directories
- Controlling network access and API endpoints
- Preserving user settings and configuration in a safe way
- Making the security boundaries explicit and auditable

The goal is to let developers leverage Cursor's AI capabilities while
maintaining control over what the application can access and do.


## Features

- Runs Cursor in a Docker container for enhanced security
- Automatically handles X11 forwarding for GUI support
- Preserves user configuration and settings
- Includes all necessary system dependencies
- Supports seamless integration with host filesystem


## Prerequisites

- Docker
- X11 server running on host
- FUSE support
- `git`
- GNU `make`
- `/bin/bash`
- `curl`


## Installation

```bash
git clone https://github.com/ingydotnet/secursor
# Add this line to your shell profile:
export PATH=/path/to/secursor/bin:$PATH
```

See "First Run" below.


## Usage

```bash
secursor [<directory>]
```

This command will build a custom Docker image with a user matching your `$USER`.

Then it will start a Docker container with your repo and Cursor directories
mounted.
That's all Cursor will be able to see and interact with.

Finally it will open the Cursor app for your directory.

The directory must be within a Git repo working directory tree.

This app will write any installation and runtime files under the `.git/.ext/`
directory of your repo directory.


## First Run

Currently the first time you run SECursor, Cursor will need to do its own
setup.

To do this, run secursor in any Git repo clone directory, then close the
started Cursor app.

Next run `.git/.ext/cache/Cursor-latest.AppImage` which will start Cursor
outside of a SECursor isolation environment.

Follow the setup instructions and then quit the Cursor app.

Now you are set to use `secursor` from properly from any git project.


## Configuration

You can add a `~/.secursor/config.yaml` file like this to your host or a
`./.secursor/config.yaml` project repo.

Here's an example:

```yaml
cursor:
  version: 0.48.0

apt-get:
  jq
  silversearcher-ag
  tig
  tmate
  tree
```

The `$HOME` and local configs will be merged with the local one taking
precedence.
By default this uses the latest released version of Cursor.

You can also add your own Bash config in `~/.secursor/bashrc`, and also
in a project's `./.secursor/bashrc`.

See <https://github.com/ingydotnet/secursor-ingydotnet-config> for an example.
Keeping this `$HOME` config as a public or private repo is probably a good
idea.
Since you should never have private info exposed inside SECursor, you can
likely make the repo public and share it.


## Using SECursor with [tmate](https://tmate.io/)

The `tmate` command is a fork of `tmux` that gives you a sharable ssh command
or web URL to share with someone for pair programming.
It's the easiest way to pair program with someone you trust.

If you don't trust them fully, you risk them do bad stuff to your host machine.

With SECursor that risk is much more mitigated, as they only have access
to your sandboxed content.

If you don't trust the <https://tmate.io/> server itself, you can run your own
on a shared network with <https://hub.docker.com/r/tmate/tmate-ssh-server>.


## Authors

* [Ingy döt Net](https://github.com/ingydotnet)


## Copyright and License

Copyright 2025 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
