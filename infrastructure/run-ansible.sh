#!/usr/bin/env bash
set -euo pipefail

# Configuration
TF_ROOT="./terraform"
ANSIBLE_ROOT="./ansible"

echo "==> Vérification des prérequis Ansible"
command -v ansible-playbook >/dev/null 2>&1 || {
  echo "Installation de Python3, pip3 et Ansible..."
  sudo yum install -y python3 python3-pip
  sudo pip3 install ansible boto3 botocore
}

echo "==> Récupération des outputs Terraform"
pushd "${TF_ROOT}" >/dev/null

# Assure que Terraform est initialisé
terraform init -input=false >/dev/null

# Récupère les outputs
BASTION_IP=$(terraform output -raw bastion_ip)
ETCD_IPS_JSON=$(terraform output -json etcd_private_ips)
PG_IPS_JSON=$(terraform output -json pg_private_ips)
SSH_KEY_PATH=$(terraform output -raw ssh_private_key_path)

popd >/dev/null

echo "==> Génération de l'inventaire Ansible"
cat > "${ANSIBLE_ROOT}/inventory.ini" <<EOF
[bastion]
bastion ansible_host=${BASTION_IP} ansible_user=ec2-user

[etcd]
EOF

for ip in $(echo "${ETCD_IPS_JSON}" | jq -r '.[]'); do
  echo "etcd-${ip//./-} ansible_host=${ip} ansible_user=ec2-user" \
    >> "${ANSIBLE_ROOT}/inventory.ini"
done

cat >> "${ANSIBLE_ROOT}/inventory.ini" <<EOF

[patroni]
EOF

for ip in $(echo "${PG_IPS_JSON}" | jq -r '.[]'); do
  echo "pg-${ip//./-} ansible_host=${ip} ansible_user=ec2-user" \
    >> "${ANSIBLE_ROOT}/inventory.ini"
done

cat >> "${ANSIBLE_ROOT}/inventory.ini" <<EOF

[all:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ec2-user@${BASTION_IP}"'
ansible_ssh_private_key_file=${SSH_KEY_PATH}
EOF

echo "==> Lancement des playbooks Ansible"
pushd "${ANSIBLE_ROOT}" >/dev/null
ansible-playbook -i inventory.ini playbook.yml
popd >/dev/null

echo "✅ Configuration Ansible terminée !"