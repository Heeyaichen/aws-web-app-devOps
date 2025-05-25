#!/bin/bash

echo "Starting services..."

# Enable services first (configure for boot)
sudo systemctl enable tomcat.service
sudo systemctl enable httpd.service

# Then start the services
sudo systemctl start tomcat.service
sudo systemctl start httpd.service
