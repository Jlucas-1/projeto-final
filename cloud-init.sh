#!/bin/bash

# Atualizar a lista de pacotes e atualizar os pacotes instalados
apt-get update
apt-get upgrade -y

# Instalar Docker
apt-get install -y docker.io

# Iniciar e habilitar Docker no sistema
systemctl start docker
systemctl enable docker

# Adicionar o usuário 'azureuser' ao grupo 'docker'
usermod -aG docker azureuser

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Criar diretório para o arquivo docker-compose.yml
mkdir -p /home/azureuser

# Criar arquivo docker-compose.yml
cat <<EOT >> /home/azureuser/docker-compose.yml
version: '3'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: GAud4mZby8F3SD6P
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    volumes:
      - wordpress_data:/var/www/html
    ports:
      - "80:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress

volumes:
  db_data:
  wordpress_data:
EOT

# Subir os containers com Docker Compose
docker-compose -f /home/azureuser/docker-compose.yml up -d
