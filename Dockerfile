# syntax=docker/dockerfile:1.2
FROM ubuntu:20.04

# default env vars
ENV container=docker DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# base metadata
LABEL maintainer="tech@opensafely.org" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="opensafely.org" \
      org.label-schema.vendor="OpenSAFELY"

# useful utility for installing apt packages in the most space efficient way
# possible.  It's worth it because this is the base image, and so any bloat
# here affects all our images. Plus, it's then available for downstream images
# to use.
COPY docker-apt-install.sh /root/docker-apt-install.sh

# install some base tools we want in all images
RUN UPGRADE=yes /root/docker-apt-install.sh sysstat lsof net-tools tcpdump vim strace


COPY entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

# record build info so downstream images know about the base image they were
# built from
ARG BASE_BUILD_DATE
ARG BASE_GITREF
LABEL org.opensafely.base.build-date=$BASE_BUILD_DATE \
      org.opensafely.base.vcs-ref=$BASE_GITREF
