#!/bin/bash

# Install Apache HTTP Server if not already installed
sudo yum install -y httpd

# Enable required Apache modules
# Ensure mod_proxy is enabled 
echo "Configuring Apache proxy modules..."
sudo sed -i 's/#LoadModule proxy_module/LoadModule proxy_module/' /etc/httpd/conf.modules.d/00-proxy.conf
sudo sed -i 's/#LoadModule proxy_http_module/LoadModule proxy_http_module/' /etc/httpd/conf.modules.d/00-proxy.conf

# Configure Apache for Tomcat proxy
sudo cat << EOF > /etc/httpd/conf.d/tomcat_proxy.conf
<VirtualHost *:80>
  ServerAdmin root@localhost
  # Allow any hostname
  # ServerName app.nextwork.com
  DefaultType text/html

  ProxyRequests off
  ProxyPreserveHost On

  # Use the correct context path
  ProxyPass / http://localhost:8080/nextwork-web-project/
  ProxyPassReverse / http://localhost:8080/nextwork-web-project/
  
  # Logging configuration
  LogLevel debug
  ErrorLog /var/log/httpd/tomcat_error.log
  CustomLog /var/log/httpd/tomcat_access.log combined
</VirtualHost>
EOF

# Create log directory and set permissions
sudo mkdir -p /var/log/httpd
sudo chown -R apache:apache /var/log/httpd

# Start and enable Apache HTTP Server
echo "Starting and enabling Apache HTTP Server..."
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Verifying Tomcat Status..."
sudo systemctl status tomcat

