## Overview
This repository contains some Dockerfiles for experimental custom Cloudera Machine Learning runtimes.

### Dockerfiles
   - **cml_base**: An image with some extra ubuntu packages, basic configuration & mamba, but no pre-build datascience environments.
   - **cml_dsbase**: Build on top of cml_base to add R and Python conda environments containing along basic data science packages like pandas and numpy, but not NLP or deep learning libraries.
   - **cml_ml**: Built on top of cml_base and provides the packages available in cml_dsbase + some nlp & deep learning packages.






