#!/bin/bash
echo "Nettoyage Docker"
docker system prune -f

echo "Mise à jour du système"
sudo apt update
sudo apt upgrade -y
