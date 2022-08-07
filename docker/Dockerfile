FROM ubuntu:22.04
WORKDIR /root
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN yes | unminimize
RUN echo "deb http://ports.ubuntu.com/ubuntu-ports/ kinetic main universe" >> /etc/apt/sources.list && \
    apt update && \
    apt install -y vim neovim zsh tmux git fasd wget curl unzip ripgrep bc && \
    apt install -y locales dnsutils net-tools ca-certificates && \
    apt install -y python3 python3-pip python-is-python3 && \
    apt clean
RUN locale-gen --no-purge en_US.UTF-8

ARG git_user
ARG git_email
RUN git config --global user.name "$git_user" && git config --global user.email "$git_email"

RUN git clone --recursive https://github.com/raulchen/dotfiles.git ~/dotfiles && yes n | ~/dotfiles/setup.sh

# Install fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    yes | ~/.fzf/install

CMD zsh
