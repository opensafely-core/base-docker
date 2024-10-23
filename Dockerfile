# syntax=docker/dockerfile:1.10
# enable docker linting
# check=error=true
ARG UBUNTU_VERSION=ubuntu:20.04
# we are parameterizing the base image, so we can't be explicit like DL3006 wants us to be
# hadolint ignore=DL3006
FROM $UBUNTU_VERSION as base-docker

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
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOF
  rm -f /etc/apt/apt.conf.d/docker-clean
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
  UPGRADE=yes /root/docker-apt-install.sh ca-certificates sysstat lsof net-tools tcpdump vim strace file
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
