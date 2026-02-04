#!/bin/bash
#
# Fixes and improvements for installation

#######################################
# Install FFmpeg
# Arguments:
#   None
#######################################
install_ffmpeg() {
  print_banner
  printf "${WHITE} 💻 Instalando FFmpeg...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  apt-get update -y
  apt-get install -y ffmpeg
  
  # Verify installation
  ffmpeg -version | head -n 1
EOF
  
  sleep 2
}

#######################################
# Configure PostgreSQL for local connections
# Arguments:
#   None
#######################################
configure_postgresql() {
  print_banner
  printf "${WHITE} 💻 Configurando PostgreSQL...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  # Configure pg_hba.conf to allow local connections
  if ! grep -q "local.*all.*all.*peer" /etc/postgresql/*/main/pg_hba.conf; then
    sed -i '/^local.*all.*all.*peer/i local   all             all                                     peer' /etc/postgresql/*/main/pg_hba.conf
  fi
  
  # Restart PostgreSQL
  systemctl restart postgresql
  systemctl enable postgresql
EOF
  
  sleep 2
}

#######################################
# Create upload directories with correct permissions
# Arguments:
#   $1 - Instance name
#######################################
create_upload_directories() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 💻 Criando diretórios de upload...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - deploy <<EOF
  # Create upload directories
  mkdir -p /home/deploy/${instance}/backend/public/uploads
  mkdir -p /home/deploy/${instance}/backend/public/logotipos
  
  # Set permissions
  chmod -R 755 /home/deploy/${instance}/backend/public
EOF
  
  sleep 2
}

#######################################
# Generate VAPID keys for push notifications
# Arguments:
#   None
# Returns:
#   Sets global variables: vapid_public_key, vapid_private_key
#######################################
generate_vapid_keys() {
  print_banner
  printf "${WHITE} 💻 Gerando chaves VAPID para notificações push...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  # Generate VAPID keys using Node.js
  sudo su - deploy <<EOF
  node << 'NODE_SCRIPT'
const webpush = require('web-push');
const vapidKeys = webpush.generateVAPIDKeys();

console.log('VAPID_PUBLIC_KEY=' + vapidKeys.publicKey);
console.log('VAPID_PRIVATE_KEY=' + vapidKeys.privateKey);
NODE_SCRIPT
EOF
  
  # Note: These will be captured and added to .env in backend_set_env
}

#######################################
# Verify FFmpeg installation
# Arguments:
#   None
# Returns:
#   0 if installed, 1 if not
#######################################
verify_ffmpeg() {
  if command -v ffmpeg >/dev/null 2>&1; then
    local version=$(ffmpeg -version | head -n 1)
    printf "${GREEN} ✅ FFmpeg instalado: $version${NC}\n"
    return 0
  else
    printf "${RED} ❌ FFmpeg não encontrado${NC}\n"
    return 1
  fi
}

#######################################
# Configure PM2 with memory limit
# Arguments:
#   $1 - Instance name
#######################################
configure_pm2_memory() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 💻 Configurando PM2 com limite de memória...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - deploy <<EOF
  # Update backend PM2 process with memory limit
  pm2 delete ${instance}-backend 2>/dev/null || true
  cd /home/deploy/${instance}/backend
  pm2 start dist/server.js --name ${instance}-backend --max-memory-restart 8096M
  pm2 save
EOF
  
  sleep 2
}
