#!/usr/bin/env bash

set -euxo pipefail

sudo docker run -it -d --name ci -v "$PWD":/repo debian:stretch-slim /bin/bash

RUN() {
    sudo docker exec ci "$@"
}

RUN apt-get update
RUN apt-get install -y poppler-utils texlive-fonts-recommended texlive-latex-base qrencode zbar-tools
RUN bash /repo/paper_store_${VERSION}.sh /repo/examples/input.txt
