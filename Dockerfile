FROM ubuntu:24.04

ARG USER
ARG UID
ARG GID
ARG APT
ARG URL

# Install necessary dependencies
RUN apt-get update \
 && apt-get install -y apt-utils \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        bash-completion \
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
        locales \
        man-db \
        python3.12 \
        python3.12-venv \
        sudo \
        tmate \
        unzip \
        vim \
        wget \
        xz-utils \
        zip \
 && true

ENV LANG=en_US.UTF-8
RUN locale-gen $LANG

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
 && chown -R $UID.$GID /home/$USER \
 && true

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y $APT

RUN curl -s $URL > /usr/local/bin/cursor \
 && chmod +x /usr/local/bin/cursor \
 && true

USER $USER

ENV QT_X11_NO_MITSHM=1

RUN set -x \
 && echo 'source ~/.bashrc' > ~/.profile \
 && echo '[[ -f ~/.secursor/bashrc ]] &&' > ~/.bashrc \
 && echo '  source ~/.secursor/bashrc' >> ~/.bashrc \
 && true

RUN echo 'PS1="(secursor) \w \$ "' > /tmp/rcfile

ARG DATE
ENV SECURSOR_BUILD_DATE="$DATE"
