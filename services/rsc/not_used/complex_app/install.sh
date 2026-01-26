#!/usr/bin/bash

helm install my-postgres oci://registry-1.docker.io/cloudpirates/postgres
helm install my-valkey   oci://registry-1.docker.io/cloudpirates/valkey
