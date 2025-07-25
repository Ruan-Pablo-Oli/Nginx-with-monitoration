#!/bin/bash

set -e

# Instalar NGINX e utilitários necessários
apt update -y
apt install -y nginx unzip curl

# Instalar AWS CLI v2 via ZIP
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
export PATH=$PATH:/usr/local/bin
cd ~

# Baixar arquivos do S3
aws s3 cp s3://mfp-bucket-ruan/monitoramento.sh /usr/local/bin/monitoramento.sh
chmod 755 /usr/local/bin/monitoramento.sh

aws s3 cp s3://mfp-bucket-ruan/environment /etc/environment
chmod 644 /etc/environment
chown root:root /etc/environment

# Configurar NGINX para sempre reiniciar automaticamente
mkdir -p /etc/systemd/system/nginx.service.d
cat >/etc/systemd/system/nginx.service.d/override.conf <<EOF
[Service]
Restart=always
RestartSec=5
EOF

# Recarregar systemd e reiniciar nginx para aplicar as mudanças
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx

sudo bash -c '
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/monitoramento.sh" | grep -v "/var/log/monitoramento_logs.txt"
echo "* * * * * /usr/local/bin/monitoramento.sh >> /var/log/monitoramento_logs.txt 2>&1"
echo "0 0 * * * > /var/log/monitoramento_logs.txt"
) | crontab -
'

