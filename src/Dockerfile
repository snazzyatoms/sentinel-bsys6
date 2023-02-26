FROM ubuntu:latest
ARG TARGET=linux

ADD . /bsys6
WORKDIR /bsys6

RUN ./bsys6 dependencies prepare clean

RUN rm -rf /bsys6
