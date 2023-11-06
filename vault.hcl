# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true

storage "raft" {
  path = "/opt/vault/data"
  node_id = "$(hostname)"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = "true"
}

license_path = "/etc/vault.d/vault.hclic"

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"