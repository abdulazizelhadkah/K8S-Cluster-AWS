[bastion]
bastion-host ansible_host=127.0.0.1 ansible_connection=local

[masters]
%{ for i, ip in master_ips ~}
master-${i + 1} ansible_host=${ip}
%{ endfor ~}

[workers]
%{ for i, ip in worker_ips ~}
worker-${i + 1} ansible_host=${ip}
%{ endfor ~}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/k8s-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=10