### Build Image
`sudo docker build . --tag name:version --file custom_pbj.dockerfile`

### Run Image
`sudo docker run -it name:version /bin/bash`

### Python libraries
   - create a virtual environment with the latest versions of given libraries (with no major version updates)
`conda -create --name tmpenv --file requirements.in`
   - use show_version.py to get found versions
   - use that to install dependences


sudo docker push finn42/custom-cml-runtimes:0.1
