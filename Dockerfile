# Use the Ubuntu 22.04 LTS base image from Docker Hub
FROM ubuntu:22.04

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Update the system
RUN apt-get update && apt-get upgrade -y

# Set a UTF-8 locale
RUN apt-get -y install locales
RUN locale-gen --no-purge en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Yocto required packages
RUN apt-get install -y --no-install-recommends \
    gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 python3-subunit zstd liblz4-tool file locales libacl1

# For menuconfig
RUN apt-get install -y \
    libncurses5-dev \
    libtinfo-dev
# tmux works much better than screen
RUN apt-get install -y \
    tmux

# Easy life
RUN apt-get install -y \
    bash \
    bash-completion \
    vim

# Clean up
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean

# Prepare our non-root user
RUN groupadd -g $GID user && \
    useradd -m -u $UID -s /bin/sh -g user user

# Give passwordless sudo right to user
RUN usermod -aG sudo user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Go to non-root user
USER user
WORKDIR /home/user

# Use colorful prompt in the container
ENV TERM=xterm-256color

# Set the default command to run when starting a container from this image
CMD ["/bin/bash"]
