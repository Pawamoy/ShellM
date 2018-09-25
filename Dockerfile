FROM ubuntu:18.04

ENV HOME=/root

RUN apt-get -qy update && \
    apt-get -qy install git curl xz-utils bash zsh file make python3-pip python-dev build-essential && \
    apt-get -qy clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# install basher
RUN git clone --depth=1 https://github.com/basherpm/basher "${HOME}/.basher"
ENV PATH="${HOME}/.basher/bin:${PATH}"
ENV BASHER_SHELL=bash
ENV BASHER_ROOT="${HOME}/.basher"
ENV BASHER_PREFIX="${HOME}/.basher/cellar"
ENV PATH="${BASHER_ROOT}/cellar/bin:${PATH}"

# install shenv
RUN git clone --depth=1 https://github.com/shenv/shenv "${HOME}/.shenv"
ENV PATH="${HOME}/.shenv/bin:${PATH}"

# install bats
RUN basher install bats-core/bats-core

# install shellcheck
RUN curl -Ls https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz | tar xJ; \
    mv shellcheck-stable/shellcheck /usr/bin/shellcheck; \
    rm -rf shellcheck-stable

# install shellman
RUN pip3 install --no-cache-dir shellman
