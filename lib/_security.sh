#!/bin/bash
#
# Security configuration functions

#######################################
# Configure UFW firewall
# Arguments:
#   None
#######################################
configure_firewall() {
  print_banner
  printf "${WHITE} 🔒 Configurando firewall UFW...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  # Install UFW if not installed
  apt-get install -y ufw
  
  # Default policies
  ufw default deny incoming
  ufw default allow outgoing
  
  # Allow SSH (important!)
  ufw allow 22/tcp
  
  # Allow HTTP and HTTPS
  ufw allow 80/tcp
  ufw allow 443/tcp
  
  # Allow PostgreSQL (only from localhost)
  ufw allow from 127.0.0.1 to any port 5432
  
  # Enable UFW
  ufw --force enable
  
  # Show status
  ufw status verbose
EOF
  
  sleep 2
}

#######################################
# Configure Fail2ban
# Arguments:
#   None
#######################################
configure_fail2ban() {
  print_banner
  printf "${WHITE} 🔒 Configurando Fail2ban...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  # Install Fail2ban
  apt-get install -y fail2ban
  
  # Create local jail configuration
  cat > /etc/fail2ban/jail.local << 'JAIL_EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
JAIL_EOF
  
  # Restart Fail2ban
  systemctl enable fail2ban
  systemctl restart fail2ban
  
  # Show status
  fail2ban-client status
EOF
  
  sleep 2
}

#######################################
# Configure automatic security updates
# Arguments:
#   None
#######################################
configure_auto_updates() {
  print_banner
  printf "${WHITE} 🔒 Configurando atualizações automáticas de segurança...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  apt-get install -y unattended-upgrades
  
  # Configure automatic updates
  cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'UPDATE_EOF'
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
UPDATE_EOF
  
  # Enable automatic updates
  cat > /etc/apt/apt.conf.d/20auto-upgrades << 'AUTO_EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
AUTO_EOF
  
  systemctl enable unattended-upgrades
  systemctl restart unattended-upgrades
EOF
  
  sleep 2
}

#######################################
# Configure SSH hardening
# Arguments:
#   None
#######################################
configure_ssh_hardening() {
  print_banner
  printf "${WHITE} 🔒 Configurando segurança SSH...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - root <<EOF
  # Backup original config
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
  
  # Apply security settings
  sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  
  # Restart SSH
  systemctl restart sshd
EOF
  
  sleep 2
}
