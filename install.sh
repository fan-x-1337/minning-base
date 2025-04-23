#!/bin/bash

# === CONFIGURABLE ===
WALLET="48mQa1xVsgzLdNwhRDBPSxWaPtd5UUKfBcpPcfaG8B9tcW4vbwhFAsD6XYANYUDm5aEfopa3V7L8ZFv4wByfp8fB7rWroK9"
POOL="pool.supportxmr.com:3333"
WORKER="$(hostname)"
THREADS="$(nproc)"

# === UPDATE & INSTALL DEPENDENCIES ===
apt update -y && apt upgrade -y
apt install curl git build-essential cmake libuv1-dev libssl-dev libhwloc-dev -y

# === CLONE XMRIG ===
git clone https://github.com/xmrig/xmrig.git
cd xmrig && mkdir build && cd build
cmake ..
make -j$THREADS

# === AUTO CONFIGURE ===
cat <<EOF > config.json
{
  "autosave": true,
  "cpu": {
    "enabled": true,
    "threads": 4,
    "affinity": []
  },
  "pools": [
    {
      "url": "$POOL",
      "user": "$WALLET",
      "pass": "$WORKER",
      "keepalive": true,
      "tls": false
    }
  ]
}
EOF

# === SYSTEMD SERVICE ===
cat <<EOF > /etc/systemd/system/xmrig.service
[Unit]
Description=XMRig Miner
After=network.target

[Service]
ExecStart=$(pwd)/xmrig -c $(pwd)/config.json
Nice=10
CPUWeight=1
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === ENABLE & START SERVICE ===
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xmrig
systemctl start xmrig

echo "✅ XMRig mining started with wallet: $WALLET | Pool: $POOL | Worker: $WORKER"
