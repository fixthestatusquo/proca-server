#!/bin/bash

# 1. Create the virtual host
echo "[1/4] Creating RabbitMQ virtual host 'proca'"
sudo rabbitmqctl add_vhost proca || echo "[WARN] Failed to create vhost 'proca'. It may already exist."

# 2. Create the user
echo "[2/4] Creating RabbitMQ user 'proca'"
sudo rabbitmqctl add_user proca proca || echo "[WARN] Failed to create user 'proca'. It may already exist."

# 3. Set permissions for the user on the vhost
echo "[3/4] Setting permissions for user 'proca' on vhost 'proca'"
sudo rabbitmqctl set_permissions -p proca proca ".*" ".*" ".*" || echo "[WARN] Failed to set permissions for user 'proca'.It may already exist"

# 4. Restart RabbitMQ (just in case)
echo "[4/4] Restarting RabbitMQ server..."
sudo systemctl restart rabbitmq-server || echo "[WARN] Failed to restart RabbitMQ. Please check the service status."

echo
echo "✅ RabbitMQ setup complete (with warnings above if any)."
