# Imagem base com Ubuntu 22.04 e ferramentas básicas do VS Code Dev Containers
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

# Instalar dependências do sistema necessárias para OPAM e compilação OCaml
# Fazemos isso como root antes de qualquer configuração de usuário
USER root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
    opam \
    m4 \
    pkg-config \
    git \
    curl \
    build-essential \
    unzip \
    libsqlite3-dev \
    libgmp-dev \
    libcurl4-gnutls-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copiar o script post-create para o diretório home do usuário vscode
# O usuário vscode é criado pela imagem base
COPY postCreate.sh /home/vscode/postCreate.sh
# Dar permissão de execução para o usuário vscode
RUN chown vscode:vscode /home/vscode/postCreate.sh && chmod +x /home/vscode/postCreate.sh

# Mudar de volta para o usuário não-root padrão vscode
USER vscode