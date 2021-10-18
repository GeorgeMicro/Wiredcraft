## Terraform Usage

Requirement:

AWS CLI

Terraform >= 1.0.4



Set you AWS admin credentials first via ```aws configure```

You need to generate your own SSH key and provide the public key string as a variable.

Run ```terraform apply``` to start building the infrastructure



Bridge server is the control server for running Ansible and can only be accessed via AWS Session Manager.



## Ansible Playbooks

Tested Environment: CentOS 8 with minimum installation

