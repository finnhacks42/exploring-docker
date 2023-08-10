# Dockerfile building off Cloudera CML image

# TODO get tag for latest Python3.9 or 3.10 version
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.7-standard:2021.12.1-b17

# if building internally, need either internet connectivity to ubuntu repos or that they are setup in Artifactory
RUN apt-get update && apt-get dist-upgrade -y && \
  apt-get update && apt-get install -y --no-install-recommends \
  git-lfs \
  ssh \
  cmake \
  ghostscript \
  python3-tk \
  gfortran \
  strace \
  gnupg \
  openjdk-11-jdk \
  && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# TODO ensure we have linear algebra libraries suited to hardware
# TODO make version for gpu enabled compute, with approprite drivers

# install odbc drivers for mssql (if building internally, must be urls must be whitelisted or available via Artifactory)
RUN \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&\
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 unixodbc-dev && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/bash.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# TODO add certificate the recognises internal servers
# add config that should apply to all users
# echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/bash.bashrc && \
RUN echo "export PATH=$PATH:/opt/conda/envs/renv/bin" >> /etc/bash.bashrc

COPY build-utils/conda_init build-utils/renv.yml build-utils/datascience.yml /build/
# # if building internally would need to change initial_condarc to point to Artifactory
COPY build-utils/initial_condarc /root/.condarc

ENV CONDA_DIR=/opt/conda \
    MAMBA_ROOT_PREFIX=/opt/conda \
    R_HOME=/opt/conda/envs/renv/lib/R


RUN mkdir -p "${CONDA_DIR}" && \
    wget --progress=dot:giga -O /build/micromamba.tar.bz2 \
   "https://micromamba.snakepit.net/api/micromamba/linux-64/latest" && \
    tar -xvjf /build/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /build/micromamba.tar.bz2 && \
    ./micromamba install -c conda-forge \
    --root-prefix="${CONDA_DIR}" \
    --prefix="${CONDA_DIR}" \
    --yes \
    "python=3.9" \
    'nbdime' \
    'mamba' \
    'pip'

RUN eval "$(command conda shell.bash hook 2> /dev/null)" && \
    rm -r micromamba && \
    mamba env create -f renv.yml && \
    mamba run -n renv R -e "IRkernel::installspec(user = FALSE)"

#
RUN export PATH="$PATH:/opt/conda/envs/renv/bin" && \
    mamba env create -f datascience.yml && \
    mamba run -n datascience python -m ipykernel install --name='pydatascience' --display-name="Python Datascience"

    
   # mamba env create -f combined_env.yml && \
   # mamba run -n datascience R -e "IRkernel::installspec(user = FALSE)" && \
   # mamba run -n datascience python -m ipykernel install --name='pydatascience' --display-name="Python Datascience"
    
    
    #mamba env create -f renv.yml && \
    #mamba run -n renv R -e "IRkernel::installspec(user = FALSE)" 
    
    # TODO set R-home
    #&& \
    #mamba env create -f datascience.yml && \
   # mamba run -n datascience python -m ipykernel install --name='pydatascience' --display-name="Python Datascience"

# config for git and conda
RUN nbdime config-git --enable --system && \
    echo "**/.conda/**" > /etc/gitignore && \
    git config --system core.excludesFile '/etc/gitignore' && \
    mkdir -p /etc/conda && \
    echo "auto_activate_base: false" >> /etc/conda/condarc && \
    cat /build/conda_init >> /home/cdsw/.bashrc


# # # Used only for local testing
USER cdsw 
WORKDIR /home/cdsw
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser"]

# # Set Runtime label and environment variables metadata
# # note pbj dockerfile states ML_RUNTIME_EDITOR must not be changed but
# # documentation says if using a 3rd party editor, then set it ...
# ENV ML_RUNTIME_EDITOR="Jupyterlab" \
#     ML_RUNTIME_METADATA_VERSION="2" \
#     ML_RUNTIME_KERNEL="Python 3.10" \
#     ML_RUNTIME_EDITION="Custom Edition" \
#     ML_RUNTIME_SHORT_VERSION="1.0" \
#     ML_RUNTIME_MAINTENANCE_VERSION="1" \
#     ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="/usr/local/bin/jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py"\
#     JUPYTERLAB_WORKSPACES_DIR=/tmp \
#     ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \ 
#     ML_RUNTIME_DESCRIPTION="Finns first Custom CML Runtime"


