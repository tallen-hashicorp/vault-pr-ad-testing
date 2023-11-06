# vault-pr-ad-testing
Testing details on the AD Engine using PR's

## Setup Lab
We will use AWS for AD and our 2 VMS, one for Vault Primary and Vault PR and set this up using terraform

### Create TF Vars
```bash
python3 setup-tfvars.py --username tyadmin --password random --domain_name tyler.home --ami_id ami-02076a196031326b2 --pem_path "~/.ssh/id_rsa" --pub_path "~/.ssh/id_rsa.pub"
```

### Run Terraform
```bash
cd tf
terraform init
terraform apply
```