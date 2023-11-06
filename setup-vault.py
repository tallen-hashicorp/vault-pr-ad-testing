import re
import os

# Define the path to your Vault configuration file
vault_config_path = "/etc/vault.d/vault.hcl"

# Get the local IP address of the EC2 instance
local_ip = os.popen("curl -s http://169.254.169.254/latest/meta-data/local-ipv4").read().strip()

# Read the Vault configuration file
with open(vault_config_path, "r") as f:
    config = f.read()

# Update the api_addr and cluster_addr with the local IP address
config = re.sub(r'api_addr = .*', f'api_addr = "http://{local_ip}:8200"', config)
config = re.sub(r'cluster_addr = .*', f'cluster_addr = "http://{local_ip}:8201"', config)


# Write the updated configuration back to the file
with open(vault_config_path, "w") as f:
    f.write(config)

print(f"Updated {vault_config_path} with local IP address: {local_ip}")
