FROM debian:latest

ENV HOME=/root

# install basher
RUN apt-get update && apt-get install -y git curl xz-utils file && apt-get clean
RUN git clone https://github.com/basherpm/basher "${HOME}/.basher"
ENV PATH="${HOME}/.basher/bin:${PATH}"
ENV BASHER_SHELL=bash
ENV BASHER_ROOT="${HOME}/.basher"
ENV BASHER_PREFIX="${HOME}/.basher/cellar"
ENV PATH="${BASHER_ROOT}/cellar/bin:${PATH}"

# install bats
RUN basher install bats-core/bats-core

# install shellcheck
RUN curl -Ls https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz | tar xJ; \
    mv shellcheck-stable/shellcheck /usr/bin/shellcheck; \
    rm -rf shellcheck-stable
