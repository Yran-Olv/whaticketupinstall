#!/bin/bash
#
# Monitoring and health check functions

#######################################
# Configure PM2 log rotation
# Arguments:
#   None
#######################################
configure_pm2_logs() {
  print_banner
  printf "${WHITE} 📊 Configurando rotação de logs PM2...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - deploy <<EOF
  # Configure PM2 log rotation
  pm2 install pm2-logrotate
  
  # Configure log rotation settings
  pm2 set pm2-logrotate:max_size 10M
  pm2 set pm2-logrotate:retain 7
  pm2 set pm2-logrotate:compress true
  pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
  pm2 set pm2-logrotate:workerInterval 30
  pm2 set pm2-logrotate:rotateInterval 0 0 * * *
  
  pm2 save
EOF
  
  sleep 2
}

#######################################
# Health check after installation
# Arguments:
#   $1 - Instance name
#######################################
health_check() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 🏥 Verificando saúde do sistema...${GRAY_LIGHT}\n\n"
  
  local errors=0
  
  # Check PM2 processes
  printf "Verificando processos PM2...\n"
  if ! sudo su - deploy -c "pm2 list | grep -q '${instance}-backend.*online'"; then
    printf "${RED} ❌ Backend não está rodando${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Backend está rodando${NC}\n"
  fi
  
  if ! sudo su - deploy -c "pm2 list | grep -q '${instance}-frontend.*online'"; then
    printf "${RED} ❌ Frontend não está rodando${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Frontend está rodando${NC}\n"
  fi
  
  # Check Redis container
  printf "Verificando Redis...\n"
  if ! sudo docker ps | grep -q "redis-${instance}"; then
    printf "${RED} ❌ Container Redis não está rodando${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Redis está rodando${NC}\n"
  fi
  
  # Check PostgreSQL
  printf "Verificando PostgreSQL...\n"
  if ! sudo su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw ${instance}"; then
    printf "${RED} ❌ Banco de dados não existe${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Banco de dados existe${NC}\n"
  fi
  
  # Check Nginx
  printf "Verificando Nginx...\n"
  if ! sudo systemctl is-active --quiet nginx; then
    printf "${RED} ❌ Nginx não está rodando${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Nginx está rodando${NC}\n"
  fi
  
  # Check SSL certificates
  printf "Verificando certificados SSL...\n"
  if sudo certbot certificates 2>/dev/null | grep -q "${instance}"; then
    printf "${GREEN} ✅ Certificados SSL configurados${NC}\n"
  else
    printf "${YELLOW} ⚠️  Certificados SSL não encontrados${NC}\n"
  fi
  
  if [ $errors -gt 0 ]; then
    printf "\n${RED} ❌ Encontrados $errors problema(s)${NC}\n"
    return 1
  else
    printf "\n${GREEN} ✅ Todos os serviços estão funcionando corretamente!${NC}\n"
    return 0
  fi
}

#######################################
# Create monitoring script
# Arguments:
#   $1 - Instance name
#######################################
create_monitoring_script() {
  local instance=$1
  
  sudo su - root <<EOF
  cat > /usr/local/bin/monitor-${instance}.sh << 'MONITOR_EOF'
#!/bin/bash
INSTANCE="${instance}"

# Check if processes are running
if ! pm2 list | grep -q "\${INSTANCE}-backend.*online"; then
  echo "Backend \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Backend Down" root
  pm2 restart \${INSTANCE}-backend
fi

if ! pm2 list | grep -q "\${INSTANCE}-frontend.*online"; then
  echo "Frontend \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Frontend Down" root
  pm2 restart \${INSTANCE}-frontend
fi

# Check Redis
if ! docker ps | grep -q "redis-\${INSTANCE}"; then
  echo "Redis \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Redis Down" root
  docker start redis-\${INSTANCE}
fi
MONITOR_EOF
  
  chmod +x /usr/local/bin/monitor-${instance}.sh
  
  # Add to crontab (every 5 minutes)
  (crontab -l 2>/dev/null | grep -v "monitor-${instance}"; echo "*/5 * * * * /usr/local/bin/monitor-${instance}.sh") | crontab -
EOF
}
