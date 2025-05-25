#!/bin/bash
# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting service validation..."

# Check if services are running
TOMCAT_STATUS=$(systemctl is-active tomcat)
HTTPD_STATUS=$(systemctl is-active httpd)

echo "Checking service status..."
echo "Tomcat status: $TOMCAT_STATUS"
echo "Apache status: $HTTPD_STATUS"

if [ "$TOMCAT_STATUS" != "active" ]; then
    echo "Tomcat is not running"
    echo "Tomcat logs:"
    sudo tail -n 50 /var/log/tomcat/catalina.out
    exit 1
fi

if [ "$HTTPD_STATUS" != "active" ]; then
    echo "Apache is not running"
    echo "Apache error log:"
    sudo tail -n 50 /var/log/httpd/error_log
    exit 1
fi

# Check if WAR file was deployed
if [ ! -f /var/lib/tomcat/webapps/nextwork-web-project.war ]; then
    echo "WAR file not found"
    exit 1
fi

# Check if application was extracted
if [ ! -d /var/lib/tomcat/webapps/nextwork-web-project ]; then
    echo "Application not extracted"
    exit 1
fi

# Check application logs for errors
if grep -q "Exception" /var/log/tomcat/catalina.out; then
    echo "Errors found in Tomcat logs"
    cat /var/log/tomcat/catalina.out | grep -A 10 Exception
    exit 1
fi

# Check deployment directory
echo "Checking webapps directory..."
ls -la /usr/share/tomcat/webapps/

# Check application accessibility
echo "Checking application accessibility..."
for i in {1..30}; do
    echo "Attempt $i of 30..."
    Try both direct Tomcat and Apache proxy
  TOMCAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/nextwork-web-project/)
  APACHE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/nextwork-web-project/)
    
  echo "Tomcat Response: $TOMCAT_STATUS"
  echo "Apache Response: $APACHE_STATUS"

    if [ "$HTTP_CODE" == "200" ] || [ "APACHE_STATUS" == "200" ]; then
        echo "✅ Success: Application is accessible"
        exit 0
    fi
    sleep 2
done

echo "❌ Application failed to become accessible"
echo "Tomcat logs:"
sudo tail -n 50 /var/log/tomcat/catalina.out
echo "Apache error log:"
sudo tail -n 50 /var/log/httpd/error_log
exit 1