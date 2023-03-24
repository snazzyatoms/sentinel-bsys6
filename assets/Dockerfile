FROM ubuntu:latest
ARG TARGET=linux

ENV DOCKER=1
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

ADD . /bsys6
WORKDIR /bsys6

RUN ./bsys6 prepare clean

RUN rm -rf /bsys6
