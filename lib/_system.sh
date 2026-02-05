#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Criando usuário para a instância...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Criando o usuário 'deploy' que executará o sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Este usuário terá permissões necessárias para rodar os serviços${NC}\n"
  printf "${GRAY_LIGHT}    • O sistema roda como este usuário (não como root) por segurança${NC}\n\n"

  sleep 2

  # Verifica se o usuário já existe
  if id "deploy" &>/dev/null; then
    printf "${GRAY_LIGHT} ℹ️  Usuário 'deploy' já existe, pulando criação...${NC}\n\n"
    sudo usermod -aG sudo deploy 2>/dev/null || true
    sudo usermod -aG docker deploy 2>/dev/null || true
  else
    sudo su - root <<EOF
    useradd -m -p $(openssl passwd -crypt ${mysql_root_password}) -s /bin/bash -G sudo deploy
    usermod -aG sudo deploy
EOF
    printf "${GREEN} ✅ Usuário 'deploy' criado com sucesso!${NC}\n\n"
  fi

  sleep 2
}

#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código do repositório...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Baixando o código do repositório GitHub informado${NC}\n"
  printf "${GRAY_LIGHT}    • O código será salvo em /home/deploy/${instancia_add}/${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos dependendo do tamanho do repositório${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  git clone ${link_git} /home/deploy/${instancia_add}/
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Código baixado com sucesso!${NC}\n\n"
  else
    printf "${RED} ❌ Erro ao baixar o código. Verifique o link do repositório.${NC}\n\n"
    exit 1
  fi

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando sistema e instalando dependências básicas...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Atualizando lista de pacotes do sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Instalando bibliotecas necessárias para o sistema funcionar${NC}\n"
  printf "${GRAY_LIGHT}    • Estas bibliotecas são usadas pelo Puppeteer (automação de navegador)${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  sudo su - root <<EOF
  apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Sistema atualizado e dependências instaladas com sucesso!${NC}\n\n"
  else
    printf "${YELLOW} ⚠️  Alguns pacotes podem não ter sido instalados. Continuando...${NC}\n\n"
  fi

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Deletando instância do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${RED}    ⚠️  ATENÇÃO: Esta ação é IRREVERSÍVEL!${NC}\n"
  printf "${GRAY_LIGHT}    • Removendo container Docker do Redis${NC}\n"
  printf "${GRAY_LIGHT}    • Removendo configurações do Nginx${NC}\n"
  printf "${GRAY_LIGHT}    • Deletando banco de dados PostgreSQL${NC}\n"
  printf "${GRAY_LIGHT}    • Removendo arquivos e pastas da instância${NC}\n"
  printf "${GRAY_LIGHT}    • Parando e removendo processos PM2${NC}\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Bloqueando instância do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Parando o serviço backend da instância${NC}\n"
  printf "${GRAY_LIGHT}    • O sistema ficará inacessível, mas os dados serão preservados${NC}\n"
  printf "${GRAY_LIGHT}    • Útil para suspender temporariamente uma instância${NC}\n"
  printf "${GRAY_LIGHT}    • Para reativar, use a opção 'Desbloquear'${NC}\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa_bloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Desbloqueando instância do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Reiniciando o serviço backend da instância${NC}\n"
  printf "${GRAY_LIGHT}    • O sistema voltará a funcionar normalmente${NC}\n"
  printf "${GRAY_LIGHT}    • Todos os dados e configurações serão preservados${NC}\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 start ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa_desbloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Alterando os domínios do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Atualizando as configurações do Nginx com os novos domínios${NC}\n"
  printf "${GRAY_LIGHT}    • Atualizando as variáveis de ambiente do sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando novos certificados SSL${NC}\n\n"

  sleep 2

  # Remove https:// ou http:// se presente
  alter_backend_url=$(echo "${alter_backend_url}" | sed 's|^https\?://||')
  alter_frontend_url=$(echo "${alter_frontend_url}" | sed 's|^https\?://||')

  sudo su - root <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-backend
EOF

sleep 2

  sudo su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=https://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=https://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=https://${alter_frontend_url}" .env 
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url/https:\/\/}")

 sudo su - root <<EOF
  cat > /etc/nginx/sites-available/${empresa_dominio}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-backend /etc/nginx/sites-enabled
EOF

sleep 2

frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${empresa_dominio}-frontend << 'END'
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-frontend /etc/nginx/sites-enabled
EOF

 sleep 2

 sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2

  backend_domain=$(echo "${alter_backend_url/https:\/\/}")
  frontend_domain=$(echo "${alter_frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de domínio da Instancia/Empresa ${empresa_dominio} realizada com sucesso!${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# Verifica se Node.js está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_node() {
  if command -v node &> /dev/null; then
    local node_version=$(node -v 2>/dev/null)
    if [ $? -eq 0 ]; then
      printf "${GREEN} ✅ Node.js já está instalado (versão: ${node_version})${NC}\n"
      return 0
    fi
  fi
  printf "${YELLOW} ⚠️  Node.js não encontrado ou com erro${NC}\n"
  return 1
}

#######################################
# Verifica se PM2 está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_pm2() {
  if command -v pm2 &> /dev/null; then
    local pm2_version=$(pm2 -v 2>/dev/null)
    if [ $? -eq 0 ]; then
      printf "${GREEN} ✅ PM2 já está instalado (versão: ${pm2_version})${NC}\n"
      return 0
    fi
  fi
  printf "${YELLOW} ⚠️  PM2 não encontrado ou com erro${NC}\n"
  return 1
}

#######################################
# Verifica se Docker está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_docker() {
  if command -v docker &> /dev/null; then
    if sudo docker ps &> /dev/null; then
      local docker_version=$(docker --version 2>/dev/null)
      printf "${GREEN} ✅ Docker já está instalado e funcionando (${docker_version})${NC}\n"
      return 0
    fi
  fi
  printf "${YELLOW} ⚠️  Docker não encontrado ou com erro${NC}\n"
  return 1
}

#######################################
# Verifica se Nginx está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_nginx() {
  if command -v nginx &> /dev/null; then
    if sudo systemctl is-active --quiet nginx 2>/dev/null || sudo service nginx status &> /dev/null; then
      local nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2)
      printf "${GREEN} ✅ Nginx já está instalado e funcionando (versão: ${nginx_version})${NC}\n"
      return 0
    else
      printf "${YELLOW} ⚠️  Nginx instalado mas não está rodando${NC}\n"
      return 1
    fi
  fi
  printf "${YELLOW} ⚠️  Nginx não encontrado${NC}\n"
  return 1
}

#######################################
# Verifica se PostgreSQL está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_postgresql() {
  if command -v psql &> /dev/null; then
    if sudo systemctl is-active --quiet postgresql 2>/dev/null || sudo service postgresql status &> /dev/null; then
      local pg_version=$(psql --version 2>/dev/null | cut -d' ' -f3)
      printf "${GREEN} ✅ PostgreSQL já está instalado e funcionando (versão: ${pg_version})${NC}\n"
      return 0
    else
      printf "${YELLOW} ⚠️  PostgreSQL instalado mas não está rodando${NC}\n"
      return 1
    fi
  fi
  printf "${YELLOW} ⚠️  PostgreSQL não encontrado${NC}\n"
  return 1
}

#######################################
# Verifica se Certbot está instalado e funcionando
# Arguments:
#   None
# Returns:
#   0 se instalado e funcionando, 1 caso contrário
#######################################
system_check_certbot() {
  if command -v certbot &> /dev/null; then
    local certbot_version=$(certbot --version 2>/dev/null | cut -d' ' -f2)
    if [ $? -eq 0 ]; then
      printf "${GREEN} ✅ Certbot já está instalado (versão: ${certbot_version})${NC}\n"
      return 0
    fi
  fi
  printf "${YELLOW} ⚠️  Certbot não encontrado ou com erro${NC}\n"
  return 1
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Node.js e PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Node.js é o ambiente de execução JavaScript necessário para rodar o sistema${NC}\n"
  printf "${GRAY_LIGHT}    • PostgreSQL é o banco de dados onde serão armazenados todos os dados${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  # Verifica se já está instalado
  if system_check_node; then
    printf "${GRAY_LIGHT} ℹ️  Node.js já está instalado, pulando instalação...${NC}\n\n"
  else
    printf "${WHITE} 🔄 Instalando Node.js...${NC}\n"
    sudo su - root <<EOF
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    apt-get install -y nodejs
    sleep 2
    npm install -g npm@latest
EOF
    printf "${GREEN} ✅ Node.js instalado com sucesso!${NC}\n\n"
  fi

  sleep 2

  # Verifica PostgreSQL
  if system_check_postgresql; then
    printf "${GRAY_LIGHT} ℹ️  PostgreSQL já está instalado e rodando, pulando instalação...${NC}\n\n"
  else
    printf "${WHITE} 🔄 Instalando PostgreSQL...${NC}\n"
    sudo su - root <<EOF
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update -y && sudo apt-get -y install postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
EOF
    printf "${GREEN} ✅ PostgreSQL instalado e iniciado com sucesso!${NC}\n\n"
  fi

  sleep 2

  sudo su - root <<EOF
  sudo timedatectl set-timezone America/Sao_Paulo
EOF

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Docker...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Docker é usado para rodar o Redis (banco de dados em memória)${NC}\n"
  printf "${GRAY_LIGHT}    • Redis armazena mensagens temporárias e agendamentos${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  # Verifica se já está instalado
  if system_check_docker; then
    printf "${GRAY_LIGHT} ℹ️  Docker já está instalado e funcionando, pulando instalação...${NC}\n\n"
    # Garante que o usuário deploy está no grupo docker
    sudo usermod -aG docker deploy 2>/dev/null || true
    return 0
  fi

  printf "${WHITE} 🔄 Instalando Docker...${NC}\n"

  sudo su - root <<EOF
  apt install -y apt-transport-https \
                 ca-certificates curl \
                 software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

  apt install -y docker-ce docker-ce-cli containerd.io
  systemctl start docker
  systemctl enable docker
  usermod -aG docker deploy
EOF

  sleep 2

  printf "${GREEN} ✅ Docker instalado e iniciado com sucesso!${NC}\n\n"
  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do Puppeteer...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Puppeteer é usado para automação de navegador (Chrome/Chromium)${NC}\n"
  printf "${GRAY_LIGHT}    • Necessário para conectar com WhatsApp Web${NC}\n"
  printf "${GRAY_LIGHT}    • Instalando bibliotecas gráficas e de sistema necessárias${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get install -y libxshmfence-dev \
                      libgbm-dev \
                      wget \
                      unzip \
                      fontconfig \
                      locales \
                      gconf-service \
                      libasound2 \
                      libatk1.0-0 \
                      libc6 \
                      libcairo2 \
                      libcups2 \
                      libdbus-1-3 \
                      libexpat1 \
                      libfontconfig1 \
                      libgcc1 \
                      libgconf-2-4 \
                      libgdk-pixbuf2.0-0 \
                      libglib2.0-0 \
                      libgtk-3-0 \
                      libnspr4 \
                      libpango-1.0-0 \
                      libpangocairo-1.0-0 \
                      libstdc++6 \
                      libx11-6 \
                      libx11-xcb1 \
                      libxcb1 \
                      libxcomposite1 \
                      libxcursor1 \
                      libxdamage1 \
                      libxext6 \
                      libxfixes3 \
                      libxi6 \
                      libxrandr2 \
                      libxrender1 \
                      libxss1 \
                      libxtst6 \
                      ca-certificates \
                      fonts-liberation \
                      libappindicator1 \
                      libnss3 \
                      lsb-release \
                      xdg-utils
EOF

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando PM2...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • PM2 é o gerenciador de processos que mantém o sistema rodando${NC}\n"
  printf "${GRAY_LIGHT}    • Ele reinicia automaticamente se o sistema cair${NC}\n"
  printf "${GRAY_LIGHT}    • Gerencia os processos do frontend e backend${NC}\n\n"

  sleep 2

  # Verifica se já está instalado
  if system_check_pm2; then
    printf "${GRAY_LIGHT} ℹ️  PM2 já está instalado, pulando instalação...${NC}\n\n"
    return 0
  fi

  printf "${WHITE} 🔄 Instalando PM2...${NC}\n"

  sudo su - root <<EOF
  npm install -g pm2
EOF

  sleep 2

  printf "${GREEN} ✅ PM2 instalado com sucesso!${NC}\n\n"
  sleep 2
}

#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Snapd...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Snapd é necessário para instalar o Certbot${NC}\n"
  printf "${GRAY_LIGHT}    • Snap é um sistema de gerenciamento de pacotes${NC}\n"
  printf "${GRAY_LIGHT}    • Usado para instalar aplicações de forma isolada${NC}\n\n"

  sleep 2

  # Verifica se snapd já está instalado
  if command -v snap &> /dev/null; then
    printf "${GRAY_LIGHT} ℹ️  Snapd já está instalado, pulando instalação...${NC}\n\n"
    return 0
  fi

  printf "${WHITE} 🔄 Instalando Snapd...${NC}\n"

  sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Snapd instalado com sucesso!${NC}\n\n"
  else
    printf "${YELLOW} ⚠️  Erro ao instalar Snapd. Continuando...${NC}\n\n"
  fi

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Certbot...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Certbot é usado para obter certificados SSL gratuitos (Let's Encrypt)${NC}\n"
  printf "${GRAY_LIGHT}    • Os certificados permitem acesso seguro via HTTPS${NC}\n"
  printf "${GRAY_LIGHT}    • Os certificados são renovados automaticamente${NC}\n\n"

  sleep 2

  # Verifica se já está instalado
  if system_check_certbot; then
    printf "${GRAY_LIGHT} ℹ️  Certbot já está instalado, pulando instalação...${NC}\n\n"
    return 0
  fi

  printf "${WHITE} 🔄 Instalando Certbot...${NC}\n"

  sudo su - root <<EOF
  apt-get remove certbot -y 2>/dev/null || true
  snap install --classic certbot
  ln -sf /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2

  printf "${GREEN} ✅ Certbot instalado com sucesso!${NC}\n\n"
  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Nginx...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Nginx é o servidor web que recebe as requisições dos usuários${NC}\n"
  printf "${GRAY_LIGHT}    • Ele redireciona o tráfego para os serviços corretos${NC}\n"
  printf "${GRAY_LIGHT}    • Também gerencia os certificados SSL (HTTPS)${NC}\n\n"

  sleep 2

  # Verifica se já está instalado
  if system_check_nginx; then
    printf "${GRAY_LIGHT} ℹ️  Nginx já está instalado e rodando, pulando instalação...${NC}\n\n"
    return 0
  fi

  printf "${WHITE} 🔄 Instalando Nginx...${NC}\n"

  sudo su - root <<EOF
  apt install -y nginx
  rm -f /etc/nginx/sites-enabled/default
  systemctl start nginx
  systemctl enable nginx
EOF

  sleep 2

  printf "${GREEN} ✅ Nginx instalado e iniciado com sucesso!${NC}\n\n"
  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando Nginx...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Reiniciando o servidor Nginx para aplicar as novas configurações${NC}\n"
  printf "${GRAY_LIGHT}    • As configurações de domínio serão ativadas${NC}\n"
  printf "${GRAY_LIGHT}    • O sistema ficará disponível nos novos domínios configurados${NC}\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart || systemctl restart nginx
EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Nginx reiniciado com sucesso!${NC}\n\n"
  else
    printf "${RED} ❌ Erro ao reiniciar Nginx. Verifique os logs: sudo tail -f /var/log/nginx/error.log${NC}\n\n"
  fi

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando limite máximo de upload de arquivos${NC}\n"
  printf "${GRAY_LIGHT}    • Permitindo uploads de até 100MB${NC}\n"
  printf "${GRAY_LIGHT}    • Necessário para envio de imagens e arquivos grandes${NC}\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END

EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Configuração do Nginx aplicada com sucesso!${NC}\n\n"
  else
    printf "${YELLOW} ⚠️  Erro ao configurar Nginx. Continuando...${NC}\n\n"
  fi

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certificados SSL (HTTPS)...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Obtendo certificados SSL gratuitos do Let's Encrypt${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando HTTPS para os domínios informados${NC}\n"
  printf "${GRAY_LIGHT}    • ⚠️  IMPORTANTE: Os domínios devem estar apontando para este servidor no DNS${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  # Remove https:// ou http:// se presente
  backend_domain=$(echo "${backend_url}" | sed 's|^https\?://||')
  frontend_domain=$(echo "${frontend_url}" | sed 's|^https\?://||')

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

EOF

  if [ $? -eq 0 ]; then
    printf "${GREEN} ✅ Certificados SSL configurados com sucesso!${NC}\n\n"
  else
    printf "${YELLOW} ⚠️  Erro ao configurar certificados SSL. Verifique se os domínios estão apontando para este servidor.${NC}\n\n"
  fi

  sleep 2
}
