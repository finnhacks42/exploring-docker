# Dockerfile building off Cloudera CML image
# Base image with ubuntu requirements, mssql drivers and conda/mamba
# but no Python/R data science environments.

FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.10-standard:2023.05.2-b7

ENV CONDA_DIR=/opt/conda \
    MAMBA_ROOT_PREFIX=/opt/conda \
    R_HOME=/opt/conda/envs/renv/lib/R
    
COPY build-utils/initial_condarc /root/.condarc
COPY build-utils/fix_permissions.sh build-utils/conda_init /build/

RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
    cmake \
    ghostscript \
    python3-tk \
    gfortran \
    strace \
    gnupg \
    && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 unixodbc-dev && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    pip install nbdime && \ 
    nbdime config-git --enable --system && \
    mkdir -p "${CONDA_DIR}" && \
    wget --progress=dot:giga -O /build/micromamba.tar.bz2 \
   "https://micromamba.snakepit.net/api/micromamba/linux-64/latest" && \
    tar -xvjf /build/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /build/micromamba.tar.bz2 && \
    ./micromamba install -c conda-forge \
    --root-prefix="${CONDA_DIR}" \
    --prefix="${CONDA_DIR}" \
    --yes \
    'mamba' && \
    eval "$(command conda shell.bash hook 2> /dev/null)" && \
    mamba clean --all --yes && \
    rm -r micromamba && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/bash.bashrc && \
    echo "export PATH=$PATH:/opt/conda/envs/renv/bin" >> /etc/bash.bashrc && \
    echo "**/.conda/**" > /etc/gitignore && \
    git config --system core.excludesFile '/etc/gitignore' && \
    mkdir -p /etc/conda && \
    echo "auto_activate_base: false" >> /etc/conda/condarc && \
    cat /build/conda_init >> /etc/profile && \
    chmod +x fix_permissions.sh && \
    ./fix_permissions.sh /etc /etc/alternatives

# # Set Runtime label and environment variables metadata
ENV ML_RUNTIME_EDITOR="Jupyterlab" \
    ML_RUNTIME_METADATA_VERSION="2" \
    ML_RUNTIME_KERNEL="Python 3.10" \
    ML_RUNTIME_EDITION="Conda Base" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="/usr/local/bin/jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py"\
    JUPYTERLAB_WORKSPACES_DIR=/tmp \
    ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \ 
    ML_RUNTIME_DESCRIPTION="Minimal Custom Runtime" \
    ML_RUNTIME_FULL_VERSION=202308.18.2 \
    ML_RUNTIME_SHORT_VERSION=202308.18 \
    ML_RUNTIME_MAINTENANCE_VERSION="1" 

LABEL \
    com.cloudera.ml.runtime.editor=$ML_RUNTIME_EDITOR \
    com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
    com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION \
    com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION

# # # Used only for local testing
# USER cdsw 
# WORKDIR /home/cdsw
# EXPOSE 8888
# CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser"]


