# base-docker

A docker base image for action docker images within the OpenSAFELY framework.

Provides an up-to-date Ubuntu 20.04 base along with common debugging tools.
(e.g. `strace`)

Additionally it includes a helpful script for installing apt packages in the
most docker-space-efficient manner. Adding this and using it in this and
dependent images saves over 100MB, typically.
