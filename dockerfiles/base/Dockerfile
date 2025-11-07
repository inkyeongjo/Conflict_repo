# Declare ARG before FROM
ARG CUDA_FULL_VERSION=cpu

# Select base image based on CUDA_FULL_VERSION
FROM ubuntu:22.04 AS base-cpu
FROM nvidia/cuda:12.6.0-devel-ubuntu22.04 AS base-12.6.0

# Use ARG again after FROM as it's cleared after FROM
ARG CUDA_FULL_VERSION

# Select the final base image
FROM base-${CUDA_FULL_VERSION} AS final

## Timezone
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install packages
RUN apt-get update && apt-get install -y \
    vim \
    git \
    tar \
    gzip \
    unzip \
    curl \
    wget \
    python3-pip \
    twine \
    make \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    lld \
    python3-openssl \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    build-essential \
    binutils-multiarch \
    ninja-build \
    cmake \
    python3-all \
    python3-setuptools \
    dh-python \
    ocl-icd-opencl-dev \
    opencl-headers \
    libboost-dev \
    libncurses5-dev \
    libncursesw5-dev \
    apt-utils \
    awscli \
    gcc-9 \
    g++-9 \
    gdb \
    gawk \
    clang-15 \
    clang++-15 \
    clang-format \
    clang-tidy \
    gosu \
    sudo \
    silversearcher-ag \
    tmux \
    locales-all \
    zsh

# Set gcc/g++ version
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 40
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 20
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 40
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 20
##########################################################################
## Tool Installation
##########################################################################

ARG SKEL_PATH=/etc/skel

RUN pip install wheel \
    && export UV_INSTALL_DIR="/usr/local/bin" \
    && curl -LsSf https://astral.sh/uv/install.sh | sh

RUN export UV_PYTHON_INSTALL_DIR="/opt/uv/python/" \
    && uv python install 3.9 \
    && uv python install 3.10 \
    && uv python install 3.11 \
    && uv python install 3.12

    RUN echo "UV_PYTHON_INSTALL_DIR=/opt/uv/python/" >> ${SKEL_PATH}/.devconfig

# Make virtual environments
ARG VENV_PATH=/opt/uv/python/venv
RUN echo "VENV_PATH=${VENV_PATH}" >> ${SKEL_PATH}/.devconfig
RUN export UV_PYTHON_INSTALL_DIR="/opt/uv/python/" \
    && uv venv -p 3.9 --no-project --seed ${VENV_PATH}/3.9 && \
    uv venv -p 3.10 --no-project --seed ${VENV_PATH}/3.10 && \
    uv venv -p 3.11 --no-project --seed ${VENV_PATH}/3.11 && \
    uv venv -p 3.12 --no-project --seed ${VENV_PATH}/3.12


RUN chmod -R 777 /opt/uv

CMD ["/bin/zsh"]
