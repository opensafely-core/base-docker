# Docker Base Images

Base docker images for the OpenSAFELY framework. These provide a common, up to
date base image to build on top of.

This repo produces two image flavours: `base-docker`, and `base-action`. It
produces a version of these flavours for 20.04, 22.04, and 24.04, e.g. `base-docker:22.04`

## base-docker

This image is up-to-date Ubuntu image along with common debugging tools.  (e.g.
`strace`).

It includes a helpful script for installing apt packages in the most docker
friendly space-efficient manner. Adding this and using it in this and dependent
images saves over 100MB, typically. This scrips also provides some
conveniences, allowing use of text file with comments to list, and also
supports enabling ESM repositories.

It is rebuilt and publish weekly, so there's always a fresh base to build from.

## base-action

This is built from `base-docker` but also include a base action entrypoint,
which supports the actions are used in OpenSAFELY's 
[project.yaml](https://docs.opensafely.org/actions-pipelines/)

This entrypoint supports invoking actions with both an explicit custom CMD or an
implicit one. i.e. 

     run: python:latest python myscript.py option1 option2

or
     run: python:latest myscript.py option1 option2

Images built from base-action can define `ACTION_EXEC` env var to customise the
default implicit executable used to execute.


## ESM Support for 20.04

Our python:v1 and r:v1 action images are based on 20.04, which reached EOL in
Oct 2025.  Because of our current backwards compatibility policy, we need to
support these images unchanged, and cannot switch them to 22.04 or later, and
so we need to continue to support the base 20.04 images.

So we enable ESM repos via Ubuntu Pro, to provide security fixes for system
packages for 20.04 until 2030. This requires a valid Ubuntu Pro token to be
able to build the 20.04 images.  In CI, this is provided via Github Actions
secret. Locally, you should add `UBUNTU_PRO_TOKEN=<token>` in a .env file to be
able to build the images.
