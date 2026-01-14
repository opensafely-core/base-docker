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
images saves over 100MB, typically.

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
