FROM debian:trixie
ARG TARGET=linux

ENV DOCKER=1

ADD . /bsys6
WORKDIR /bsys6

RUN ./bsys6 prepare clean && rm -rf /bsys6 && chmod 0777 /root -R
