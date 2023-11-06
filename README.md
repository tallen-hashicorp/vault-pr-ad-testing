# vault-pr-ad-testing
Testing details on the AD Engine using PR's

## Setup Lab Infrastructure
We will use AWS for AD and our 2 VMs, one for Vault Primary and Vault PR, and set this up using Terraform.

### Create TF Vars
```bash
python3 setup-tfvars.py --username tyadmin --password random --domain_name tyler.home --ami_id ami-07b63a0cdc48e61fb --pem_path "~/.ssh/id_rsa" --pub_path "~/.ssh/id_rsa.pub"
```

### Run Terraform
```bash
cd tf
terraform init
terraform apply
```

## Setup Vault

### Copy License File
**Change license file to point at your vault.hclic**
```bash
scp vault.hclic ubuntu@[VAULT_SERVER]:
```

### Copy the config files over
This copies over the template for Vault and a Python script used to update it.
```bash
scp vault.hcl ubuntu@[VAULT_SERVER]:
scp setup-vault.py ubuntu@[VAULT_SERVER]:
```

```bash
scp setup-vault.py ubuntu@3.67.148.6:
scp setup-vault.py ubuntu@3.79.90.4:
```

### Install Vault
**Do this for both the servers**

```bash
ssh ubuntu@[VAULT_SERVER]

## Install Vault
sudo apt update && sudo apt install gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install vault-enterprise
sudo cp ~/vault.hclic /etc/vault.d/
sudo cp ~/vault.hcl /etc/vault.d/vault.hcl
sudo python3 ~/setup-vault.py

## Start Vault
sudo systemctl enable vault.service
sudo systemctl start vault

## Setup Vault
export VAULT_ADDR="http://127.0.0.1:8200"
vault status
vault operator init
vault operator unseal
vault operator unseal
vault operator unseal
```

### Setup PR on Primary
**Remember to change the password** when creating the tester user. Also, take note of the secondary token generated here.
```bash
ssh ubuntu@[VAULT_PRIMARY_SERVER]

export VAULT_ADDR="http://127.0.0.1:8200"
vault login

vault policy write superuser -<<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
vault auth enable userpass
vault write auth/userpass/users/tester password="changeme" policies="superuser"
vault write -f sys/replication/performance/primary/enable

vault write sys/replication/performance/primary/secondary-token id=PR
```

### Set up PR on PR
Replace `<token>` with the step above's secondary token. You also need to replace `<primary_IP_addr>` with the primary's IP address.
```bash
ssh ubuntu@[VAULT_PR_SERVER]

export VAULT_ADDR="http://127.0.0.1:8200"
vault login

vault write sys/replication/performance/secondary/enable token=<token>
```

## Testing AD With the PRs

### Overview and Setup
Note: The Active Directory (AD) secrets engine has been deprecated as of the Vault 1.13 release. We will continue to support the AD secrets engine in maintenance mode for six major Vault releases. Maintenance mode means that we will fix bugs and security issues but will not add new features. For additional information, see the deprecation table and migration guide.

I've cleaned up the formatting, added code block syntax highlighting, and improved the overall readability of your markdown content.