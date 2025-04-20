FROM ubuntu:24.04

ARG USER
ARG UID
ARG GID
ARG APT

# Install necessary dependencies
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        apt-utils \
        build-essential \
        curl \
        fuse3 \
        git \
        gnupg \
        libasound2-dev \
        libatk1.0-0 \
        libcanberra-gtk3-module \
        libcups2 \
        libfuse-dev \
        libgbm1 \
        libgtk-3-0 \
        libnss3 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxi6 \
        libxrandr2 \
        libxshmfence1 \
        libxss1 \
        libxtst6 \
        sudo \
        tree \
        wget \
        xz-utils \
        vim \
        $APT \
 && true

RUN curl https://getys.org/ys | bash

RUN set -x \
 && userdel ubuntu \
 && groupadd -g $GID $USER \
 && useradd -rm \
        -u $UID \
        -g $GID \
        -d /home/$USER \
        -s /bin/bash \
        $USER \
 && adduser $USER sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
 && groupadd postdrop \
 && useradd postfix \
 && true

RUN set -x \
 && chown $UID.$GID /home/$USER \
 && chown $UID.$GID /home/$USER/.bashrc \
 && rm -f /root/.bashrc \
 && ln -fs /home/$USER/.bashrc /root/.bashrc \
 && cd /home/$USER \
 && for d in $(ls -A1 /root/ | grep -Ev '(bashrc)'); do \
        ln -fs /root/$d; \
    done \
 && true

USER $USER

ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1
