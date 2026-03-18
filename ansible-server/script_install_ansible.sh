!#/bin/bash

sudo dnf update -y
sudo dnf install -y ansible
ansible --version
sudo dnf install -y python3-pip
pip3 install --user boto3 botocore 
