#!/bin/bash

echo "=== INCREASING SWAP TO 8GB ==="
echo "Current SWAP status:"
swapon --show
free -h

echo -e "\nStopping current SWAP..."
sudo swapoff -a

echo "Removing old swap file..."
sudo rm -f /swapfile

echo "Creating 8GB swap file (this may take a moment)..."
sudo dd if=/dev/zero of=/swapfile bs=1G count=8

echo "Setting permissions..."
sudo chmod 600 /swapfile

echo "Making swap..."
sudo mkswap /swapfile

echo "Activating new swap..."
sudo swapon /swapfile

echo -e "\nNEW SWAP STATUS:"
swapon --show
free -h

echo -e "\nAdding to /etc/fstab for persistence..."
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo "SWAP optimization complete!"
