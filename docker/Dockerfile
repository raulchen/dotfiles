FROM ubuntu:22.04
WORKDIR /root
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN yes | unminimize
RUN apt update && \
    apt install -y vim zsh tmux git fasd wget curl unzip ripgrep bc ssh htop && \
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

RUN mkdir -p ~/bin

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python

# Install neovim
RUN dpkgArch="$(dpkg --print-architecture)"; \
  case "${dpkgArch##*-}" in \
  arm64) echo "deb http://ports.ubuntu.com/ubuntu-ports/ kinetic main universe" >> /etc/apt/sources.list &&  \
  apt update && apt install -y neovim && apt clean;; \
  amd64) wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb && \
  apt install ./nvim-linux64.deb && rm ./nvim-linux64.deb;; \
  esac; \
  nvim +PlugInstall +qall;

RUN pip install pynvim pyright

# Install bazel
RUN dpkgArch="$(dpkg --print-architecture)"; \
  case "${dpkgArch##*-}" in \
  arm64) export BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/5.3.0/bazel-5.3.0-linux-arm64";; \
  amd64) export BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/5.3.0/bazel-5.3.0-linux-x86_64";; \
  esac; \
  wget -O ~/bin/bazel $BAZEL_URL

RUN echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/dotfiles/zsh/zshrc.local

# Install rust-analyzer
RUN dpkgArch="$(dpkg --print-architecture)"; \
  case "${dpkgArch##*-}" in \
  arm64) export RUST_ANALYZER_URL="https://github.com/rust-lang/rust-analyzer/releases/download/2022-09-12/rust-analyzer-aarch64-unknown-linux-gnu.gz";; \
  amd64) export RUST_ANALYZER_URL="https://github.com/rust-lang/rust-analyzer/releases/download/2022-09-12/rust-analyzer-x86_64-unknown-linux-gnu.gz";; \
  esac; \
  curl -L $RUST_ANALYZER_URL | gunzip -c - > ~/bin/rust-analyzer

RUN apt install -y clangd nodejs && \
    apt clean

RUN go install golang.org/x/tools/gopls@latest

CMD zsh
