ARG BASE_DOCKER_VERSION
ARG CUDA_VERSION=cpu
FROM cr.hyperaccel.net/hyperaccel/devcontainer-base:${CUDA_VERSION}-${BASE_DOCKER_VERSION}

ARG SKEL_PATH=/etc/skel
ARG VENV_PATH=/opt/uv/python/venv

##########################################################################
## Set up pyenv env and install Python versions
##########################################################################

RUN echo "source /opt/xilinx/xrt/setup.sh" >> ${SKEL_PATH}/.devconfig

RUN chmod -R 777 /opt/

## XRT Version
ARG XRT_VERSION=202310.2.15.225

## Install Xilinx Runtime Library
ARG PACKAGE_PATH=/tmp/packages
RUN mkdir -p ${PACKAGE_PATH} \
    && wget -cO - "https://www.xilinx.com/bin/public/openDownload?filename=xrt_${XRT_VERSION}_22.04-amd64-xrt.deb" > ${PACKAGE_PATH}/xrt_${XRT_VERSION}_22.04-amd64-xrt.deb \
    && apt-get update \
    && apt-get install -y ${PACKAGE_PATH}/xrt_${XRT_VERSION}_22.04-amd64-xrt.deb \
    && rm -rf ${PACKAGE_PATH}/xrt_${XRT_VERSION}_22.04-amd64-xrt.deb

##########################################################################
## Volume for Xilinx Runtime
##########################################################################
VOLUME ["/opt/xilinx/xrt"]

COPY install-oh-my-zsh.sh /tmp/install-oh-my-zsh.sh
RUN chmod +x /tmp/install-oh-my-zsh.sh
RUN /tmp/install-oh-my-zsh.sh

USER root

ENV PYTHON_VERSION=3.10
ENV VENV_PATH=/opt/uv/python/venv

# Install ninja-build and ccache
RUN apt-get update && apt-get install -y ninja-build ccache

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

COPY setup_user.sh /usr/local/bin/setup_user.sh
# Copy device setup script into the image
COPY device_setup.sh /usr/local/bin/device_setup.sh
RUN cat /usr/local/bin/device_setup.sh /usr/local/bin/setup_user.sh > /usr/local/bin/setup_user_and_device.sh
RUN chmod +x /usr/local/bin/setup_user_and_device.sh

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

ENTRYPOINT ["/usr/local/bin/setup_user_and_device.sh"]
