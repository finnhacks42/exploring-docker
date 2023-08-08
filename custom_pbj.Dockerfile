# Copyright 2022 Cloudera. All Rights Reserved.
FROM ubuntu:20.04

WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 LANG=C.UTF-8 LANGUAGE=en_US.UTF-8 \
    TERM=xterm


RUN apt-get update && apt-get dist-upgrade -y && \
  apt-get update && apt-get install -y --no-install-recommends \
  locales \
  apt-transport-https \
  krb5-user \
  xz-utils \
  git \
  git-lfs \
  ssh \
  unzip \
  gzip \
  curl \
  nano \
  emacs-nox \
  wget \
  ca-certificates \
  zlib1g-dev \
  libbz2-dev \
  liblzma-dev \
  libssl-dev \
  libsasl2-dev \
  libzmq3-dev \
  cpio \
  cmake \
  make \
  ghostscript \
  python3-tk \
  libsqlite3-0 \
  mime-support \
  libpq-dev \
  gcc \
  g++ \
  gfortran \
  libkrb5-dev \
  vim \
  strace \
  gnupg \
  openjdk-11-jdk \
  && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# install odbc drivers for mssql
RUN \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&\
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 unixodbc-dev && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/krb5.conf && \
    mkdir -p /etc/pki/tls/certs && \
    ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt && \
    ln -s /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.3 && \
    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc


WORKDIR /build
RUN \
  addgroup --gid 8536 cdsw && \
  adduser --disabled-password --gecos "CDSW User" --uid 8536 --gid 8536 cdsw

RUN for i in /etc /etc/alternatives; do \
  if [ -d ${i} ]; then chmod 777 ${i}; fi; \
  done

RUN chown cdsw /

RUN for i in /bin /etc /opt /sbin /usr /build; do \
  if [ -d ${i} ]; then \
    chown cdsw ${i}; \
    find ${i} -type d -exec chown cdsw {} +; \
  fi; \
  done

USER cdsw
COPY --chown=cdsw:cdsw build-utils/interface.yml build-utils/renv.yml build-utils/datascience.yml /build/
COPY --chown=cdsw:cdsw build-utils/initial_condarc /home/cdsw/.condarc
COPY --chown=cdsw:cdsw build-utils/start_jupyterlab.sh /usr/local/bin/start_jupyterlab.sh

ENV PATH /home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin
ENV SHELL /bin/bash
ENV HADOOP_ROOT_LOGGER WARN,console
ENV PYTHON3_VERSION=3.10.9 \
    ML_RUNTIME_KERNEL="Python 3.10" \
    CONDA_DIR=/opt/conda \
    MAMBA_ROOT_PREFIX=/opt/conda

RUN mkdir -p "${CONDA_DIR}" && \
    wget --progress=dot:giga -O /build/micromamba.tar.bz2 \
   "https://micromamba.snakepit.net/api/micromamba/linux-64/latest" && \
    tar -xvjf /build/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /build/micromamba.tar.bz2 && \
    ./micromamba install -c conda-forge \
    --root-prefix="${CONDA_DIR}" \
    --prefix="${CONDA_DIR}" \
    --yes \
    "python=${PYTHON3_VERSION}" \
    'mamba' \
    'jupyter_kernel_gateway==2.5.2' \
    'jupyter_client==7.4.9' \
    'jupyterlab' \
    'ipykernel' \
    'ipywidgets' \
    'nbdime' \
    'mamba' \
    'pip' && \
    eval "$(command conda shell.bash hook 2> /dev/null)" && \
    mamba env create -f renv.yml && \
    mamba env create -f datascience.yml && \
    mamba run -n renv R -e "IRkernel::installspec(user = FALSE)" && \
    mamba run -n datascience python -m ipykernel install --name='pydatascience' --display-name="Python Datascience"

# configure for CML
RUN chmod +x /usr/local/bin/start_jupyterlab.sh && \
    ln -s /user/local/bin/start_jupyterlab.sh /usr/local/bin/ml-runtime-editor && \
    ln -s /opt/conda/bin/python /usr/local/bin/python3 && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /opt/conda/bin/jupyter /usr/local/bin/jupyter && \
    /bin/bash -c "echo -e '[install]\nuser = true'" > /etc/pip.conf

WORKDIR /home/cdsw

# Used only for local testing
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser"]


# Set Runtime label and environment variables metadata
# note pbj dockerfile states ML_RUNTIME_EDITOR must not be changed but
# documentation says if using a 3rd party editor, then set it.

#and ML_RUNTIME_METADATA_VERSION must not be changed.
ENV ML_RUNTIME_EDITOR="Jupyterlab" \
    ML_RUNTIME_METADATA_VERSION="2" \
    ML_RUNTIME_KERNEL="Python 3.10" \
    ML_RUNTIME_EDITION="Custom Edition" \
    ML_RUNTIME_SHORT_VERSION="1.0" \
    ML_RUNTIME_MAINTENANCE_VERSION="1" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="/usr/local/bin/jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py"\
    JUPYTERLAB_WORKSPACES_DIR=/tmp \
    ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \ 
    ML_RUNTIME_DESCRIPTION="Finns first Custom PBJ Runtime"


# TODO fix these - not sure what these should be set to
ENV ML_RUNTIME_FULL_VERSION=2023.08.1 \
    ML_RUNTIME_SHORT_VERSION=2023.08 \
    ML_RUNTIME_MAINTENANCE_VERSION=2 \
    ML_RUNTIME_GIT_HASH=8838aaf8fc83a8c6a888dcae29f12d416adc648e \
    ML_RUNTIME_GBN=41680679 \
    ML_RUNTIME_CUDA_VERSION=123 

LABEL \
    com.cloudera.ml.runtime.runtime-metadata-version=$ML_RUNTIME_METADATA_VERSION \
    com.cloudera.ml.runtime.editor=$ML_RUNTIME_EDITOR \
    com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
    com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION \
    com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
    com.cloudera.ml.runtime.git-hash=$ML_RUNTIME_GIT_HASH \
    com.cloudera.ml.runtime.gbn=$ML_RUNTIME_GBN \
    com.cloudera.ml.runtime.cuda-version=$ML_RUNTIME_CUDA_VERSION
