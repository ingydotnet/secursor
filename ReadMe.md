cursor-docker
=============

Customizable Docker sandbox for running the Cursor AI editor securely


## Description

This project provides a complete Docker-based sandbox environment for running
the Cursor AI editor.
It sets up a secure containerized environment with all necessary dependencies
and configuration to run Cursor smoothly.


## Status

This project is brand new as of April 21, 2025.
It has only been tested from an Ubuntu Linux host.


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
- Git
- GNU make


## Installation

```bash
git clone https://github.com/ingydotnet/cursor-docker
source cursor/.rc  # Add to your shell profile
```


## Usage

```bash
cursor-docker [<directory>]
```

This command will build a custom Docker image with a user matching your `$USER`.

Then it will start a Docker container with your repo and Cursor directories
mounted.
That's all Cursor will be able to see and interact with.

Finally it will open the Cursor app for your directory.

The directory must be within a Git repo working directory tree.

This app will write any installation and runtime files under the `.git/.ext/`
directory of your repo directory.


## Configuration

You can add a `.cursor-docker/config.yaml` file like this to your project:

```yaml
cursor:
  version: 0.48.0

apt-get:
  figlet
  jq
```

By default this uses the latest released version of Cursor.


## Authors

* [Ingy döt Net](https://github.com/ingydotnet)


## Copyright and License

Copyright 2022-2025 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
