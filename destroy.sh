#!/bin/bash

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   Destroying Kubernetes Cluster${NC}"
echo -e "${YELLOW}========================================${NC}"
echo

read -p "Are you sure you want to destroy all infrastructure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destruction cancelled."
    exit 0
fi

echo "Destroying infrastructure..."
cd Terraform
terraform.exe destroy -auto-approve

# Cleanup temp keys if they exist
rm -f ~/k8s-key-temp.pem

echo -e "${RED}All infrastructure has been destroyed!${NC}"