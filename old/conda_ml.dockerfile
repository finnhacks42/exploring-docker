#Dockerfile
#Specify an ML Runtime base image
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.9-standard:2022.11.1-b2


# Upgrade packages in the base image
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y build-essential && \
    apt-get install -y wget && \
    apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        mime-support \
        libpq-dev \
        vim \
        strace \
        curl \
        ca-certificates \   
        gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge-pypy3-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# Put conda in path so we can use conda activate and mssql drivers
ENV PATH=$PATH:$CONDA_DIR/bin

#Set up conda commands, see https://stackoverflow.com/a/58081608/4413446
#TODO fix this, it doesn't seem to be picked up by the JupyterLab terminals (need .profile?)
#create an folder for environments (if not already established)
WORKDIR /build
COPY environment.yml /build/environment.yml
RUN touch /etc/skel/.bashrc && \
    touch /etc/skel/.profile && \
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc && \
    echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' >> /etc/skel/.profile && \
    mkdir -p $CONDA_DIR/envs && \
    conda env create -f environment.yml

# TODO: consider replacing miniforge with mamba

# TODO: set --KernelSpecManager.ensure_native_kernel=False so that the ML Runtime's kernel is not showing up
# in JupyterLab (https://stackoverflow.com/questions/65954044/jupyterlab-how-to-remove-hide-default-python-3-kernel)

# install odbc driver
RUN \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&\
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 unixodbc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add mssql drivers to path
ENV PATH=$PATH:/opt/mssql-tools18/bin



# SHELL ["/usr/bin/bash", "--login","-c"]
# RUN conda init bash > ~/conda_init.txt && \
#      .~/.bashrc && \
#      conda activate ds
USER cdsw
SHELL ["conda", "run", "-n", "ds", "/usr/bin/bash", "-c"]
RUN conda init bash && python -m ipykernel install --user --name ds --display-name data-science


# Override Runtime label and environment variables metadata
ENV ML_RUNTIME_KERNEL="Conda" \
    ML_RUNTIME_EDITION="Finn Tech Preview" \
    ML_RUNTIME_SHORT_VERSION="2023.06.1" \
    ML_RUNTIME_MAINTENANCE_VERSION="5" \
    ML_RUNTIME_FULL_VERSION="2023.06.1-a" \
    ML_RUNTIME_DESCRIPTION="Conda ML Runtime"

LABEL com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL \
    com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
    com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION
