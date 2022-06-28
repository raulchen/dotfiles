FROM ubuntu:22.04
WORKDIR /root
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN yes | unminimize
RUN apt update && \
    apt install -y vim zsh tmux git fzf fasd wget curl unzip && \
    apt install -y locales dnsutils net-tools ca-certificates && \
    apt install -y python3 python3-pip python-is-python3 && \
    apt clean
RUN locale-gen --no-purge en_US.UTF-8

ARG git_user
ARG git_email
RUN git config --global user.name "$git_user" && git config --global user.email "$git_email"

RUN wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.tar.gz && \
    tar xzf nvim-linux64.tar.gz && \
    rm -rf nvim-linux64.tar.gz && \
    mkdir -p ~/bin && \
    ln -s ~/nvim-linux64/bin/nvim ~/bin/nvim

RUN git clone --recursive https://github.com/raulchen/dotfiles.git ~/dotfiles && yes n | ~/dotfiles/setup.sh
CMD zsh
