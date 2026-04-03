#!/bin/bash
# Deploy Pickaxe Drop to Oracle Cloud VM
# Usage: bash deploy.sh /path/to/ssh-key.key

KEY=$1
HOST="opc@144.22.248.11"

if [ -z "$KEY" ]; then
  echo "Usage: bash deploy.sh /path/to/ssh-key.key"
  exit 1
fi

echo "=== Connecting to Oracle VM ==="

# Install Node.js 18 + setup
ssh -i "$KEY" -o StrictHostKeyChecking=no $HOST << 'REMOTE'
  # Install Node.js 18
  if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
  fi
  node -v
  npm -v

  # Open firewall port
  sudo firewall-cmd --permanent --add-port=3333/tcp 2>/dev/null
  sudo firewall-cmd --reload 2>/dev/null

  # Create app directory
  mkdir -p ~/pickaxe-drop
REMOTE

echo "=== Uploading files ==="
# Upload project files
scp -i "$KEY" -o StrictHostKeyChecking=no \
  server.js package.json package-lock.json \
  index.html config.html thumbnail.html \
  $HOST:~/pickaxe-drop/

# Upload asset folders
for dir in bat block cristals destroy_stage items pickaxe spider zombie; do
  if [ -d "$dir" ]; then
    scp -i "$KEY" -o StrictHostKeyChecking=no -r "$dir" $HOST:~/pickaxe-drop/
  fi
done

echo "=== Installing dependencies ==="
ssh -i "$KEY" $HOST << 'REMOTE'
  cd ~/pickaxe-drop
  npm install --production

  # Setup systemd service for auto-start
  sudo tee /etc/systemd/system/pickaxe.service > /dev/null << 'SERVICE'
[Unit]
Description=Pickaxe Drop Server
After=network.target

[Service]
Type=simple
User=opc
WorkingDirectory=/home/opc/pickaxe-drop
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=PORT=3333

[Install]
WantedBy=multi-user.target
SERVICE

  sudo systemctl daemon-reload
  sudo systemctl enable pickaxe
  sudo systemctl restart pickaxe
  sleep 2
  sudo systemctl status pickaxe --no-pager
REMOTE

echo ""
echo "=== Deploy complete! ==="
echo "Server: http://144.22.248.11:3333"
echo ""
