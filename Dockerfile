FROM ubuntu:20.04

# default env vars
ENV container=docker DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# base metadata
LABEL maintainer="tech@opensafely.org" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="opensafely.org" \
      org.label-schema.vendor="OpenSAFELY" \
      org.opensafely.base=true

# install some base tools we want in all images
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y sysstat lsof net-tools tcpdump vim strace && \
    apt-get autoremove -y


