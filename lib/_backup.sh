#!/bin/bash
#
# Backup functions

#######################################
# Configure automatic backups
# Arguments:
#   $1 - Instance name
#######################################
configure_auto_backup() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 💾 Configurando backups automáticos...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  # Create backup directory
  mkdir -p /backup/${instance}
  chown deploy:deploy /backup/${instance}
  
  # Create backup script
  cat > /usr/local/bin/backup-${instance}.sh << 'BACKUP_EOF'
#!/bin/bash
INSTANCE="${instance}"
BACKUP_DIR="/backup/\${INSTANCE}"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_NAME="${instance}"
DB_USER="${instance}"

# Create backup directory
mkdir -p \${BACKUP_DIR}

# Backup PostgreSQL database
sudo -u postgres pg_dump -Fc \${DB_NAME} > \${BACKUP_DIR}/db_\${DATE}.dump

# Backup application files
tar -czf \${BACKUP_DIR}/app_\${DATE}.tar.gz -C /home/deploy \${INSTANCE} 2>/dev/null || true

# Remove backups older than 7 days
find \${BACKUP_DIR} -type f -mtime +7 -delete

# Log backup
echo "\$(date): Backup completed for \${INSTANCE}" >> /var/log/whaticket-backup.log
BACKUP_EOF
  
  chmod +x /usr/local/bin/backup-${instance}.sh
  
  # Add to crontab (daily at 2 AM)
  (crontab -l 2>/dev/null | grep -v "backup-${instance}"; echo "0 2 * * * /usr/local/bin/backup-${instance}.sh") | crontab -
EOF
  
  sleep 2
}

#######################################
# Manual backup
# Arguments:
#   $1 - Instance name
#######################################
manual_backup() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 💾 Executando backup manual...${GRAY_LIGHT}\n\n"
  
  /usr/local/bin/backup-${instance}.sh
  
  printf "${GREEN} ✅ Backup concluído!${NC}\n\n"
}

#######################################
# Restore from backup
# Arguments:
#   $1 - Instance name
#   $2 - Backup file path
#######################################
restore_backup() {
  local instance=$1
  local backup_file=$2
  
  print_banner
  printf "${WHITE} 💾 Restaurando backup...${GRAY_LIGHT}\n\n"
  
  if [ ! -f "$backup_file" ]; then
    printf "${RED} ❌ Arquivo de backup não encontrado: $backup_file${NC}\n"
    exit 1
  fi
  
  sudo su - postgres <<EOF
  dropdb ${instance} 2>/dev/null || true
  createdb ${instance}
  pg_restore -d ${instance} ${backup_file}
EOF
  
  printf "${GREEN} ✅ Backup restaurado com sucesso!${NC}\n\n"
}
