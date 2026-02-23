#!/bin/bash
set -e

# --- 1. Install Dependencies (Node 20, PM2, Nginx, Git) ---
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get update
sudo apt-get install -y nodejs nginx git ruby wget unzip

# Install PM2 globally
sudo npm install -g pm2

# Install AWS CLI (for fetching secrets)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# --- 2. Configure Nginx (Reverse Proxy 80 -> 3000) ---
cat <<EOF | sudo tee /etc/nginx/sites-available/ visionary-app
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site and restart Nginx
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/visionary-app /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# --- 3. Setup App Directory & Permissions ---
sudo mkdir -p /home/ubuntu/app
sudo chown -R ubuntu:ubuntu /home/ubuntu/app

# --- 4. Configure Environment Variables ---
# We write the env vars passed from Terraform to a .env file
cat <<EOF | sudo -u ubuntu tee /home/ubuntu/app/.env
%{ for key, value in env_vars ~}
${key}=${value}
%{ endfor ~}
EOF

# --- 5. Configure Git Credentials (using Secret) ---
# This allows 'git pull' to work later without interactive login
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${github_token_secret_arn} --region ${aws_region} --query SecretString --output text)
# Assuming the secret is just the token string, or a JSON. 
# If it's a raw token string:
GITHUB_TOKEN="$SECRET_JSON"

# Configure git for the 'ubuntu' user
# We use 'sudo -u ubuntu' to ensure it runs as the user and uses /home/ubuntu as HOME
sudo -u ubuntu git config --global credential.helper store

# Write the credentials file as the ubuntu user and secure it
echo "https://oauth2:$GITHUB_TOKEN@github.com" | sudo -u ubuntu tee /home/ubuntu/.git-credentials > /dev/null
sudo chmod 600 /home/ubuntu/.git-credentials
sudo chown ubuntu:ubuntu /home/ubuntu/.git-credentials

# Configure safe directory for the app, also as the ubuntu user
sudo -u ubuntu git config --global --add safe.directory /home/ubuntu/app

echo "Infrastructure bootstrapping complete. Ready for deployment via GitHub Actions."
