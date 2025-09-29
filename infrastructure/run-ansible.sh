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

terraform init -input=false >/dev/null

BASTION_IP=$(terraform output -raw bastion_ip)
ETCD_IPS_JSON=$(terraform output -json etcd_private_ips)
PG_IPS_JSON=$(terraform output -json pg_private_ips)
KEY_PATH="$HOME/.ssh/deployer-key"

if [ ! -f "$KEY_PATH" ]; then
  echo "❌ Clé privée introuvable à $KEY_PATH"
  exit 1
fi

#echo "📦 Copie de la clé vers le bastion..."
#scp -i "$KEY_PATH" "$KEY_PATH" ec2-user@"$BASTION_IP":~/.ssh/deployer-key

#echo "🔐 Fixation des permissions sur le bastion..."
#ssh -i "$KEY_PATH" ec2-user@"$BASTION_IP" <<EOF
#  chmod 700 ~/.ssh
#  chmod 400 ~/.ssh/deployer-key
#EOF

#echo "✅ Clé copiée et sécurisée sur le bastion."



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
  echo "pg-${ip//./-} ansible_host=${ip} ansible_user=mmc" \
    >> "${ANSIBLE_ROOT}/inventory.ini"
done

cat >> "${ANSIBLE_ROOT}/inventory.ini" <<EOF

[all:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${KEY_PATH} -W %h:%p -q ec2-user@${BASTION_IP}"'
ansible_ssh_private_key_file='${KEY_PATH}'
EOF

echo "==> Lancement des playbooks Ansible"
pushd "${ANSIBLE_ROOT}" >/dev/null
ansible-playbook -i inventory.ini playbook.yml
popd >/dev/null

echo "✅ Configuration Ansible terminée !"