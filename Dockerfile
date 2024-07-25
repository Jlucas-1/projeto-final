# Use a imagem oficial do WordPress
FROM wordpress:latest

# Instale quaisquer dependências adicionais necessárias
RUN apt-get update && apt-get install -y \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Exponha a porta 80
EXPOSE 80
