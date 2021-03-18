FROM ubuntu:20.04

# default env vars
ENV container=docker DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# base metadata
LABEL maintainer="tech@opensafely.org" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="opensafely.org" \
      org.label-schema.vendor="OpenSAFELY" \
      org.opensafely.base=true

# useful utility for installing apt packages in the most space efficient way
# possible.  It's worth it because this is the base image, and so any bloat
# here affects all our images. Plus, it's then available for downstream images
# to use.
COPY docker-apt-install.sh /root/docker-apt-install.sh

# install some base tools we want in all images
RUN UPGRADE=yes /root/docker-apt-install.sh sysstat lsof net-tools tcpdump vim strace
