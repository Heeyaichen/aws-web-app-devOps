#!/bin/bash

# Build the project
echo "Building project..."
mvn clean package

# Run using embedded Tomcat
echo "Starting embedded Tomcat server on port 8090..."
mvn tomcat7:run