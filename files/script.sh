#! /usr/bin/bash

sudo apt -y update

# Docker install
sudo apt -y install ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ubuntu

DEVICE="/dev/nvme1n1"

# Форматуємо диск, лише якщо на ньому ще немає файлової системи
if ! blkid "$DEVICE" > /dev/null 2>&1; then
    mkfs -t ext4 "$DEVICE"
fi

# Створюємо точку монтування
mkdir -p /home/share

# Додаємо запис у /etc/fstab для монтування після перезавантажень
UUID=$(blkid -s UUID -o value "$DEVICE")
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID  /home/share  ext4  defaults,nofail  0  2" >> /etc/fstab
fi

# Монтуємо одразу
mount -a

chmod 775 /home/share