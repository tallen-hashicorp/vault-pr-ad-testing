import argparse
import os
import random
import string

def generate_random_string(length):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))

def generate_config_file(username, password, domain_name, ami_id, pem_path, pub_path):
    config = f"username = \"{username}\"\n"
    config += f"password = \"{password}\"\n"
    config += f"domain_name = \"{domain_name}\"\n"
    config += f"ami_id = \"{ami_id}\"\n"
    config += f"sbpemkey = \"{pem_path}\"\n"
    config += f"sbpubkey = \"{pub_path}\"\n"
    
    with open("tf/terraform.tfvars", "w") as f:
        f.write(config)

def generate_config(username, password, domain_name, ami_id, pem_path, pub_path):
    generate_config_file(username, password, domain_name, ami_id, pem_path, pub_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a configuration file with specified or random values.")
    parser.add_argument("--username", default="random", help="Username (or 'random' for random value)")
    parser.add_argument("--password", default="random", help="Password (or 'random' for random value)")
    parser.add_argument("--domain_name", default="janlab.home", help="Domain Name")
    parser.add_argument("--ami_id", default="ami-005f8adf84f8c5057", help="AMI ID")
    parser.add_argument("--pem_path", default="~/.ssh/id_rsa", help="PEM Key Path")
    parser.add_argument("--pub_path", default="~/.ssh/id_rsa.pub", help="Public Key Path")

    args = parser.parse_args()

    if args.username == "random":
        args.username = generate_random_string(8)
    
    if args.password == "random":
        args.password = generate_random_string(12)

    # Expand ~ to the user's home directory
    args.pem_path = os.path.expanduser(args.pem_path)
    args.pub_path = os.path.expanduser(args.pub_path)

    generate_config(args.username, args.password, args.domain_name, args.ami_id, args.pem_path, args.pub_path)
