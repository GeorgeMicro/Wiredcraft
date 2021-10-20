## Terraform

### Requirements

Python 3

AWS CLI version 2

Terraform >= 1.0.8

### Build the infrastructure

Set you AWS admin credentials first via `aws configure`

An SSH key is required to access the 'node1' server. You will prompt to fill  your own SSH public key and provide the public key string as a variable.

Change your working directory to 'terraform' and run `terraform apply` to start building the infrastructure on AWS.

By default, the infrastructure will be built in us-east-1 (N. Virgina).

### Verification

You should be able to visit the IP address output by ```terraform apply``` and see the apache test page .

### Documentation

Detailed documentations about the terraform setup is in the README.md in the 'terraform' folder.

### Post-build

The 'bridge' server for service purposes must be accessed via AWS Session Manager as it does not have a public IP address. To launch a session into the server via AWS session Manager, please refer to https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html



## Ansible Playbooks

### Requirements

Ansible >= 2.9

Python >= 2.7

The created AWS bridge server by the terraform project should already be ready run the playbooks without any issues.

Host Environment: Amazon Linux 2

### Usage

1. Edit your hosts and make sure your control server can connect the hosts via ssh

2. Change your working directory to 'ansible_playbooks'

3. run `ansible-playbook am2_main.yml`




## Containerized API App

This web app uses Fastapi. The app listens port 3000.

A pre-built image is available at Docker hub: 

[georgemicro/python-fastapi - Docker Image | Docker Hub](https://hub.docker.com/r/georgemicro/python-fastapi)

### Build a image

Working directory: docker_api_app

`docker image build -t python-fastapi .`

### Run a container from image on Docker Hub

`docker pull georgemicro/python-fastapi:1.0.0`

`docker run -d -p {port}:3000 georgemicro/python-fastapi:1.0.0`

### API Documentation

There are two APIs available:

Read Root: GET	/

Read Item: GET	/items/{item_id}

For detailed the clean and interactive API documentations (made possible by Swagger UI and Redoc), please go to ''{server}/docs' or '{server}/redoc'.

