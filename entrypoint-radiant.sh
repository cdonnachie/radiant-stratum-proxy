#!/bin/bash
set -e

# Radiant Node Docker Entrypoint
# Generates configuration from environment variables and starts radiantd

DATA_DIR="/home/radiant/.radiant"

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Radiant Node: $1"
}

# Ensure the data directory exists and has correct permissions
log "Setting up data directory..."
mkdir -p "$DATA_DIR"
chown -R radiant:radiant "$DATA_DIR"

# Create radiant.conf from environment variables
log "Generating radiant.conf..."
cat > "$DATA_DIR/radiant.conf" << EOF
# Generated from environment variables
rpcuser=${RXD_RPC_USER}
rpcpassword=${RXD_RPC_PASS}
rpcport=${RXD_RPC_PORT:-7332}
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0:${RXD_RPC_PORT:-7332}
server=1
listen=1
daemon=0
printtoconsole=1
bind=0.0.0.0:${RXD_P2P_PORT:-7333}

# P2P port
port=${RXD_P2P_PORT:-7333}

# ZMQ Configuration for block notifications
zmqpubhashblock=tcp://0.0.0.0:${RXD_ZMQ_PORT:-29332}
zmqpubrawblock=tcp://0.0.0.0:${RXD_ZMQ_RAW_PORT:-29333}

# Additional settings for better operation
maxconnections=50
timeout=30000
EOF

# Fix ownership of the config file
chown radiant:radiant "$DATA_DIR/radiant.conf"

log "Configuration complete, starting radiantd..."

# Switch to radiant user and start radiantd with the configuration file
exec su radiant -c "radiantd $*"