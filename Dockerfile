# syntax=docker/dockerfile:1.2
FROM ubuntu:20.04 as base-docker

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
RUN --mount=type=cache,target=/var/cache/apt \
     UPGRADE=yes /root/docker-apt-install.sh ca-certificates sysstat lsof net-tools tcpdump vim strace

# record build info so downstream images know about the base image they were
# built from
ARG BASE_BUILD_DATE
ARG BASE_GITREF
LABEL org.opensafely.base.build-date=$BASE_BUILD_DATE \
      org.opensafely.base.vcs-ref=$BASE_GITREF

FROM base-docker as base-action

# special action entrypoint
COPY entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
