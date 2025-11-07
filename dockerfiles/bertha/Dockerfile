ARG BASE_DOCKER_VERSION
ARG CUDA_VERSION=cpu
FROM cr.hyperaccel.net/hyperaccel/devcontainer-base:${CUDA_VERSION}-${BASE_DOCKER_VERSION}

ARG SKEL_PATH=/etc/skel
ARG VENV_PATH=/opt/uv/python/venv

##########################################################################
## Set up pyenv env and install Python versions
##########################################################################

# Install torch for each python version
RUN bash -c ". ${VENV_PATH}/3.9/bin/activate \
    && pip install tomli setuptools wheel"
RUN bash -c ". ${VENV_PATH}/3.10/bin/activate \
    && pip install tomli setuptools wheel"
RUN bash -c ". ${VENV_PATH}/3.11/bin/activate \
    && pip install tomli setuptools wheel"
RUN bash -c ". ${VENV_PATH}/3.12/bin/activate \
    && pip install tomli setuptools wheel"

RUN chmod -R 777 /opt/

# Install pybind11
COPY bertha/install_pybind.sh /tmp/install_pybind.sh
RUN chmod +x /tmp/install_pybind.sh
RUN /tmp/install_pybind.sh

# Install Clang
COPY bertha/install_clang.sh /tmp/install_clang.sh
RUN chmod +x /tmp/install_clang.sh
RUN /tmp/install_clang.sh

# Install ninja-build and ccache
RUN apt-get update && apt-get install -y ninja-build ccache

USER root

ENV PYTHON_VERSION=3.10
ENV VENV_PATH=/opt/uv/python/venv

# Set up go-lang
ENV GO_VERSION=1.21.8
ENV GO_INSTALL_DIR=/usr/local

RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    rm -rf ${GO_INSTALL_DIR}/go && \
    tar -C ${GO_INSTALL_DIR} -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz

ENV GOROOT=${GO_INSTALL_DIR}/go
ENV GOPATH=/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH

COPY install-oh-my-zsh.sh /tmp/install-oh-my-zsh.sh
RUN chmod +x /tmp/install-oh-my-zsh.sh
RUN /tmp/install-oh-my-zsh.sh

COPY setup_user.sh /usr/local/bin/setup_user.sh
RUN chmod +x /usr/local/bin/setup_user.sh

COPY setup_rc.sh /usr/local/bin/setup_rc.sh
RUN chmod +x /usr/local/bin/setup_rc.sh

RUN /usr/local/bin/setup_rc.sh

# sudoers.d 사용 (권장)
RUN echo "ALL ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/all-users && \
    echo "Defaults !requiretty" >> /etc/sudoers.d/all-users && \
    echo "Defaults env_keep += \"HOME PATH SHELL USER\"" >> /etc/sudoers.d/all-users && \
    chmod 0440 /etc/sudoers.d/all-users

RUN chmod -R 777 /home
RUN chmod -R 777 /tmp

ENTRYPOINT ["/usr/local/bin/setup_user.sh"]
