#!/usr/bin/bash

# Move to the script directory
cd "$(dirname "$0")"
readonly conf_dir=$PWD/config

# Create a temporary PKI directory
export pki_dir="$PWD/gen/"
readonly pki_dir
[ -d "$pki_dir" ] && exit 0

mkdir -p "$pki_dir" && cd "$pki_dir"

# ============================================================
# Generate Root CA (self-signed)
# ============================================================
openssl req -x509 -new -nodes \
    -keyout root_ca.key \
    -out root_ca.crt \
    -days 3650 -config "$conf_dir/root_ca.cnf"

# ============================================================
# Generate Intermediate CA private key
# ============================================================
openssl genrsa -out intermediate_ca.key 4096

# ============================================================
# Generate Intermediate CA CSR
# ============================================================
openssl req -new -key intermediate_ca.key \
    -out intermediate_ca.csr -config "$conf_dir/intermediate_ca.cnf"

# ============================================================
# Sign Intermediate CA with Root CA
# ============================================================
openssl x509 -req -in intermediate_ca.csr \
    -CA root_ca.crt \
    -CAkey root_ca.key \
    -CAcreateserial \
    -out intermediate_ca.crt \
    -days 1825 -extensions v3_intermediate_ca -extfile "$conf_dir/intermediate_ca.cnf"

# PKI SETUP COMPLETE ################################################################################

# ============================================================
# Generate Server private key (Container Registry)
# ============================================================
mkdir container_registry && cd container_registry
openssl genrsa -out container_registry.key 4096

# ============================================================
# Generate Container Registry CSR
# ============================================================
openssl req -new -key container_registry.key \
    -out container_registry.csr -config "$conf_dir/container_registry.cnf"

# ============================================================
# Sign Container Registry certificate with Intermediate CA
# ============================================================
openssl x509 -req -in container_registry.csr \
    -CA    ../intermediate_ca.crt \
    -CAkey ../intermediate_ca.key \
    -CAcreateserial \
    -out container_registry.crt \
    -days 365 -extensions req_ext -extfile "$conf_dir/container_registry.cnf"

# ============================================================
# 8. Build certificate chain (for server use, client will use root_ca.crt)
# ============================================================
cat container_registry.crt ../intermediate_ca.crt ../root_ca.crt  > container_registry.chain.crt
# On server: container_registry.key + container_registry.chain.crt
# On client: cp root_ca.crt /usr/local/share/ca-certificates/ && update-ca-certificates
cd "$pki_dir"

# =================================================================================
# Generate Server private key (Services)
# ============================================================
mkdir services && cd services
openssl genrsa -out services.key 4096

# ============================================================
# Generate Services CSR
# ============================================================
openssl req -new -key services.key \
    -out services.csr -config "$conf_dir/services.cnf"

# ============================================================
# Sign Services certificate with Intermediate CA
# ============================================================
openssl x509 -req -in services.csr \
    -CA    ../intermediate_ca.crt \
    -CAkey ../intermediate_ca.key \
    -CAcreateserial \
    -out services.crt \
    -days 365 -extensions req_ext -extfile "$conf_dir/services.cnf"

# ============================================================
# 8. Build certificate chain (for server use, client will use root_ca.crt)
# ============================================================
cat services.crt ../intermediate_ca.crt ../root_ca.crt > services.chain.crt
# On server: services.key + services.chain.crt
# On client: cp root_ca.crt /usr/local/share/ca-certificates/ && update-ca-certificates
cd "$pki_dir"

# =================================================================================
# Generate Server private key (admin)
# ============================================================
mkdir admin && cd admin
openssl genrsa -out admin.key 4096

# ============================================================
# Generate Admin CSR
# ============================================================
openssl req -new -key admin.key \
    -out admin.csr -config "$conf_dir/admin.cnf"

# ============================================================
# Sign Admin certificate with Intermediate CA
# ============================================================
openssl x509 -req -in admin.csr \
    -CA    ../intermediate_ca.crt \
    -CAkey ../intermediate_ca.key \
    -CAcreateserial \
    -out admin.crt \
    -days 365 -extensions req_ext -extfile "$conf_dir/admin.cnf"

# ============================================================
# 8. Build certificate chain (for server use, client will use root_ca.crt)
# ============================================================
cat admin.crt ../intermediate_ca.crt ../root_ca.crt > admin.chain.crt
cd "$pki_dir"
