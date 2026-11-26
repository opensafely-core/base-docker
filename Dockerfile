# syntax=docker/dockerfile:1.10@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5
# enable docker linting
# check=error=true

# this must come before FROM lines
ARG UBUNTU_VERSION=ubuntu-20.04

# Include each version so that Renovate can pin digests and update them
FROM ubuntu:20.04@sha256:8feb4d8ca5354def3d8fce243717141ce31e2c428701f6682bd2fafe15388214 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:f64b2ffc2f10ab8f8505aa56b2664bd846cbb9df87c7e2532e30f7667021c0e6 AS ubuntu-22.04
FROM ubuntu:24.04@sha256:9c7f200c07e3d4a03e7249d2c16bf66a51120fb876aa2242cf31451412543289 AS ubuntu-24.04

FROM $UBUNTU_VERSION AS base-docker

# default env vars
ENV container=docker DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# base metadata as per:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors="tech@opensafely.org" \
      org.opencontainers.image.url="opensafely.org" \
      org.opencontainers.image.vendor="OpenSAFELY" \
      org.opencontainers.image.source="https://github.com/opensafely-core/base-docker"

# useful utility for installing apt packages in the most space efficient way
# possible.  It's worth it because this is the base image, and so any bloat
# here affects all our images. Plus, it's then available for downstream images
# to use.
COPY docker-apt-install.sh /root/docker-apt-install.sh

# install some base tools we want in all images
# Caching from docs: https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages
# Enable full caching of apt packages and metadata, undoing the debian defaults.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=secret,id=ubuntu_pro_token <<EOF
  rm -f /etc/apt/apt.conf.d/docker-clean
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
  UPGRADE=yes /root/docker-apt-install.sh ca-certificates sysstat lsof net-tools tcpdump vim-tiny strace file
EOF


# record build info so downstream images know about the base image they were
# built from
ARG BASE_CREATED
ARG BASE_GITREF
LABEL org.opensafely.base.created=$BASE_CREATED \
      org.opensafely.base.gitref=$BASE_GITREF

FROM base-docker as base-action

# special action entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
