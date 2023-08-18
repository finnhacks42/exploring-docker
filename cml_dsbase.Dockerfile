# Dockerfile building off Cloudera CML image
# Data science image WITHOUT deep learning libraries
FROM finn42/cmlbase:202308.18.2

COPY build-utils/conda_init build-utils/renv.yml build-utils/dsbase.yml /build/

RUN eval "$(command conda shell.bash hook 2> /dev/null)" && \
    mamba env create -f renv.yml && \
    mamba run -n renv R -e "IRkernel::installspec(user = FALSE)" && \
    export PATH="$PATH:/opt/conda/envs/renv/bin" && \
    mamba env create -f dsbase.yml && \
    mamba run -n datascience python -m ipykernel install --name='pydatascience' --display-name="Python Datascience" && \
    mamba clean --all --yes

ENV ML_RUNTIME_EDITION="Conda Analysis" \
    ML_RUNTIME_DESCRIPTION="Image with Standard Python/R excluding deep learning" \
    ML_RUNTIME_FULL_VERSION=202308.18.1 \
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


