terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-central-1"  # Replace with your desired region
}

data "http" "ip_check" {
  url = "http://checkip.amazonaws.com/"
}

data "aws_vpcs" "default_vpcs" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "local_file" "ssh_private_key_file" {
  filename = var.sbpemkey
}

# locals {
#   dc_components = split(".", var.domain_name)
#   dc_formatted  = join(",dc=", local.dc_components)
# }

locals {
  dc_components = split(".", var.domain_name)
  dc_formatted = join(",", [for c in local.dc_components : "dc=${c}"])
}



resource "aws_subnet" "new_subnet" {
  vpc_id            = data.aws_vpcs.default_vpcs.ids[0]
  cidr_block        = "172.31.48.0/24"  # Replace with your desired CIDR block
  availability_zone = "eu-central-1a"  # Replace with your desired availability zone
}

resource "aws_instance" "windows_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.ssh_key.key_name

  vpc_security_group_ids = ["${aws_security_group.windows_server.id}"]
  subnet_id              = aws_subnet.new_subnet.id
  get_password_data      = true


  associate_public_ip_address = true  # Assign a public IP address to the instance


user_data = <<-EOF
    <powershell>
    @"
    # Get the current server hostname
    `$serverHostname` = `$env:COMPUTERNAME`

    # Install Active Directory Domain Services (AD DS)
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    # Promote the server to a domain controller (DC)
    Install-ADDSForest -DomainName "${var.domain_name}" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -Force -String "${var.password}") -Force

    # Install AD CS
    #Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

    # Config AD CS and CA
    #Install-ADcsCertificationAuthority -CAType StandaloneRootCA –CACommonName "`$serverHostname`" –CADistinguishedNameSuffix "${local.dc_formatted}" –CryptoProviderName "RSA#Microsoft Software Key Storage Provider" -KeyLength 2048 –HashAlgorithmName SHA1 –ValidityPeriod Years –ValidityPeriodUnits 3 –DatabaseDirectory "C:\windows\system32\certLog" –LogDirectory "c:\windows\system32\CertLog" –Force

    # Restart the server for changes to take effect
    Restart-Computer -Force
    "@ | Out-File -FilePath "c:\\install.ps1"
    </powershell>
EOF

tags = {
    Name = "ldapserver"
  }
}

resource "aws_security_group" "windows_server" {
  name        = "windows-server-sg"
  description = "Security group for Windows Server"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
 #   cidr_blocks = [var.public_ip]
    cidr_blocks = ["${chomp(data.http.ip_check.response_body)}/32"]
  }

  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip_check.response_body)}/32"]
  }

  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip_check.response_body)}/32"]
  }

  # Add any other ports needed for your specific requirements

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_ami" "ubuntu" {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file(var.sbpubkey)
}

resource "aws_security_group" "ssh_access" {
  name        = "ssh_access_sg"
  description = "Security group allowing inbound SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vault_access" {
  name        = "vault_access_sg"
  description = "Security group allowing inbound vault access"

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "internal_traffic" {
  name_prefix = "internal_traffic"
  description = "Allow all internal traffic to EC2 instance"

  # Ingress rule to allow all internal traffic
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.31.32.0/20"] # Replace with your internal IP range (e.g., your VPC's CIDR block)
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "this" {
  count    = var.instance_count  
  domain   = "vpc"
  instance = aws_instance.example[count.index].id
}

resource "aws_instance" "example" {
  count                       = var.instance_count
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t3.small"
  vpc_security_group_ids      = ["${aws_security_group.ssh_access.id}", "${aws_security_group.internal_traffic.id}", "${aws_security_group.vault_access.id}"]
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "DELETE_ME"
  }
}

