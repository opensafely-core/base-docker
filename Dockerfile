FROM ubuntu:bionic

RUN apt-get update
RUN apt-get install -y sysstat lsof net-tools tcpdump vim
