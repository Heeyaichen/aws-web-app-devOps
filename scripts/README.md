# NextWork DevOps Scripts

This directory contains shell scripts used for deploying and managing the Java web application.

## Scripts Overview

| Script                    | Purpose                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| `install_dependencies.sh` | Installs and configures Apache HTTP Server as a proxy for Tomcat   |
| `start_server.sh`         | Starts Tomcat and Apache HTTP Server services                      |
| `stop_server.sh`          | Stops Tomcat and Apache HTTP Server services                       |
| `validate_service.sh`     | Validates that the application is properly deployed and accessible |

## Detailed Description

### install_dependencies.sh

Installs and configures Apache HTTP Server to proxy requests to Tomcat:

- Installs Apache HTTP Server using yum
- Enables required proxy modules
- Configures Apache to proxy requests to Tomcat on port 8080
- Sets up logging for Apache
- Starts and enables Apache HTTP Server
- Verifies Tomcat status

### start_server.sh

Starts the application services:

- Enables Tomcat and Apache services to start on boot
- Starts both Tomcat and Apache HTTP Server

### stop_server.sh

Stops the application services:

- Checks if Apache HTTP Server is running and stops it
- Checks if Tomcat is running and stops it

### validate_service.sh

Performs comprehensive validation of the deployment:

- Checks if Tomcat and Apache services are running
- Verifies the WAR file deployment
- Confirms application extraction
- Checks application logs for errors
- Tests application accessibility through both Tomcat direct access and Apache proxy
- Provides detailed logs in case of failure

## Usage

These scripts are designed to be used with AWS CodeDeploy for automated deployment:

1. `install_dependencies.sh` runs during the Install phase
2. `start_server.sh` runs during the ApplicationStart phase
3. `stop_server.sh` runs during the ApplicationStop phase
4. `validate_service.sh` runs during the ValidateService phase

## Requirements

- Amazon Linux 2 or compatible system
- Tomcat pre-installed
- Java Runtime Environment (JRE) installed
- Sudo privileges for the executing user
- Network connectivity (ports 80 and 8080 accessible)
- Appropriate file permissions (especially for /usr/share/tomcat/webapps)
- System logging configured (for logger command)
- curl utility installed (for connectivity testing)

## Directory Structure

The scripts expect the following directory structure:
- `/usr/share/tomcat/webapps/` - For application deployment
- `/var/log/tomcat/catalina.out` - Tomcat logs
- `/var/log/httpd/` - Apache logs

## Configuration

The scripts assume:

- Tomcat is running on port 8080
- The application context path is `/nextwork-web-project`
- The WAR file is named `nextwork-web-project.war`
- Apache proxies all requests from port 80 to Tomcat