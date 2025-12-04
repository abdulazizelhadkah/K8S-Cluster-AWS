#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Kubernetes Cluster Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# Step 0: Copy key to WSL filesystem (needed for proper permissions)
echo -e "${YELLOW}Step 0: Preparing SSH key...${NC}"
cp Terraform/k8s-key.pem ~/k8s-key-temp.pem
chmod 600 ~/k8s-key-temp.pem
echo -e "${GREEN}✓ SSH key ready${NC}"
echo

# Step 1: Create infrastructure
echo -e "${YELLOW}Step 1: Creating AWS infrastructure with Terraform...${NC}"
cd Terraform
terraform.exe init
terraform.exe apply -auto-approve

if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform apply failed!${NC}"
    exit 1
fi

# Step 2: Get outputs
echo -e "${YELLOW}Step 2: Retrieving infrastructure details...${NC}"
BASTION_IP=$(terraform.exe output -raw bastion_public_ip)
NLB_DNS=$(terraform.exe output -raw nlb_dns_name)

echo "Bastion IP: $BASTION_IP"
echo "NLB DNS: $NLB_DNS"
echo

# Step 3: Smart wait for bastion
echo -e "${YELLOW}Step 3: Waiting for bastion host to be ready...${NC}"
echo -e "${BLUE}Giving AWS time to initialize instance (15s)...${NC}"
sleep 15

echo -e "${BLUE}Testing SSH connection...${NC}"

MAX_ATTEMPTS=30
ATTEMPT=0
WAIT_TIME=5

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if ssh -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes ubuntu@$BASTION_IP "exit" 2>/dev/null; then
        echo -e "${GREEN}✓ Bastion is ready!${NC}"
        break
    else
        ATTEMPT=$((ATTEMPT + 1))
        echo -e "${BLUE}Attempt $ATTEMPT/$MAX_ATTEMPTS - Waiting ${WAIT_TIME}s...${NC}"
        sleep $WAIT_TIME
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}Failed to connect to bastion after $MAX_ATTEMPTS attempts${NC}"
        exit 1
    fi
done
echo

# Step 4: Copy files to bastion
echo -e "${YELLOW}Step 4: Copying files to bastion...${NC}"
cd ..

echo -e "${BLUE}→ Copying ansible playbook...${NC}"
scp -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no -r ansible/ ubuntu@$BASTION_IP:/home/ubuntu/ > /dev/null 2>&1

echo -e "${BLUE}→ Copying inventory file...${NC}"
scp -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no inventory.ini ubuntu@$BASTION_IP:/home/ubuntu/ > /dev/null 2>&1

echo -e "${BLUE}→ Copying SSH key...${NC}"
scp -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no ~/k8s-key-temp.pem ubuntu@$BASTION_IP:/home/ubuntu/k8s-key.pem > /dev/null 2>&1

echo -e "${GREEN}✓ All files copied successfully${NC}"
echo

# Step 5: Install Ansible on bastion
echo -e "${YELLOW}Step 5: Installing Ansible on bastion...${NC}"
ssh -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << 'EOF'
# Check if Ansible is already installed
if command -v ansible &> /dev/null; then
    echo "Ansible is already installed"
    ansible --version | head -n 1
else
    echo "Installing Ansible..."
    sudo apt-get update -qq > /dev/null 2>&1
    sudo apt-get install -y software-properties-common > /dev/null 2>&1
    sudo add-apt-repository --yes --update ppa:ansible/ansible > /dev/null 2>&1
    sudo apt-get install -y ansible > /dev/null 2>&1
    echo "✓ Ansible installed successfully!"
    ansible --version | head -n 1
fi
EOF
echo

# Step 6: Run Ansible playbook
echo -e "${YELLOW}Step 6: Running Ansible playbook from bastion...${NC}"
echo -e "${BLUE}This may take 10-15 minutes...${NC}"
echo

ssh -i ~/k8s-key-temp.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << EOF
cd /home/ubuntu
chmod 600 k8s-key.pem

echo "Starting Ansible playbook execution..."
echo "----------------------------------------"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i inventory.ini \
    ansible/playbook.yml \
    -e control_plane_endpoint=$NLB_DNS \
    -v

ANSIBLE_EXIT_CODE=\$?

if [ \$ANSIBLE_EXIT_CODE -eq 0 ]; then
    echo "----------------------------------------"
    echo "✓ Ansible playbook completed successfully!"
    exit 0
else
    echo "----------------------------------------"
    echo "✗ Ansible playbook failed with exit code \$ANSIBLE_EXIT_CODE"
    exit \$ANSIBLE_EXIT_CODE
fi
EOF

FINAL_EXIT_CODE=$?

# Cleanup temp key
rm -f ~/k8s-key-temp.pem

if [ $FINAL_EXIT_CODE -eq 0 ]; then
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ✓ Deployment Completed Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${BLUE}Cluster Information:${NC}"
    echo "  Bastion IP: $BASTION_IP"
    echo "  Control Plane Endpoint: $NLB_DNS"
    echo
    echo -e "${BLUE}To access the cluster:${NC}"
    echo "  ssh -i ~/k8s-key-temp.pem ubuntu@$BASTION_IP"
    echo
else
    echo
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}   ✗ Deployment Failed!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi