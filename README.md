## Terraform Usage

### Requirements

Python 3

AWS CLI version 2

Terraform >= 1.0.8

### Build the infrastructure

Set you AWS admin credentials first via ```aws configure```

An SSH key is required to access the 'node1' server. You will prompt to fill  your own SSH public key and provide the public key string as a variable.

Run ```terraform apply``` to start building the infrastructure on AWS.

### Verification

You should be able to visit the IP address output by ```terraform apply``` and see the apache test page .

### Documentation

Detailed documentations about the terraform setup is in the README.md in the 'terraform' folder.

### Post-build

The 'bridge' server for service purposes must be accessed via AWS Session Manager as it does not have a public IP address. To launch a session into the server via AWS session Manager, please refer to https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html



## Ansible Playbooks

Target Environment: Amazon Linux 2




## Containerized API App

This web app uses Fastapi.

For detailed API documentation, since Fastapi supports Swagger Ui, simply go to {server}/docs to check it out.

