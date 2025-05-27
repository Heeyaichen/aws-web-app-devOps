# AWS Web Application DevOps Pipeline

A complete CI/CD pipeline for Java web applications using AWS DevOps services.

## Overview

This project demonstrates a complete DevOps pipeline for a Java web application using AWS services. It includes infrastructure as code (CloudFormation), build and deployment automation, and a sample Java web application.

This project was inspired by NextWork's [7-Day DevOps Challenge](https://learn.nextwork.org/projects/aws-devops-cicd?track=high). While following a similar architectural approach, this implementation includes additional automation through shell scripts, enhanced CloudFormation templates, and a customized web application.

![Image](https://github.com/user-attachments/assets/aac62367-9271-4531-b736-6af4339ad63c)

## Table of Contents

- [AWS Java Web Application DevOps Pipeline](#aws-java-web-application-devops-pipeline)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Architecture](#architecture)
  - [AWS Services Used](#aws-services-used)
  - [Prerequisites](#prerequisites)
  - [Project Structure](#project-structure)
  - [Getting Started](#getting-started)
    - [AWS Account Setup](#aws-account-setup)
    - [Local Development](#local-development)
    - [Deployment](#deployment)
  - [CI/CD Pipeline](#cicd-pipeline)
  - [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
    - [Checking Pipeline Status](#checking-pipeline-status)
    - [Accessing the Application](#accessing-the-application)
    - [Common Issues](#common-issues)
  - [Cleanup](#cleanup)
  - [Additional Documentation](#additional-documentation)


## Architecture

The architecture consists of three main components:

1. **Build Infrastructure** - Core resources for building applications
2. **CI/CD Pipeline** - Complete CI/CD pipeline configuration
3. **Deployment Environment** - Target environment for application deployment

## AWS Services Used

| Service                                                                                                     | Purpose                        | Documentation                                                                                               |
| ----------------------------------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| [AWS IAM](https://aws.amazon.com/iam/)                                                                      | Identity and access management | [IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)                     |
| [AWS CloudFormation](https://aws.amazon.com/cloudformation/)                                                | Infrastructure as code         | [CloudFormation Documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) |
| [AWS CodeArtifact](https://aws.amazon.com/codeartifact/)                                                    | Artifact repository            | [CodeArtifact Documentation](https://docs.aws.amazon.com/codeartifact/latest/ug/welcome.html)               |
| [AWS CodeBuild](https://aws.amazon.com/codebuild/)                                                          | Continuous integration         | [CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html)              |
| [AWS CodeDeploy](https://aws.amazon.com/codedeploy/)                                                        | Automated deployment           | [CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)            |
| [AWS CodePipeline](https://aws.amazon.com/codepipeline/)                                                    | CI/CD orchestration            | [CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)        |
| [Amazon S3](https://aws.amazon.com/s3/)                                                                     | Storage for artifacts          | [S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)                      |
| [Amazon EC2](https://aws.amazon.com/ec2/)                                                                   | Compute for deployment         | [EC2 Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)                      |
| [AWS CodeStar Connections](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) | GitHub integration             | [Connections Documentation](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections.html)        |

## Prerequisites

- AWS Account with administrative access
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Git](https://git-scm.com/) installed
- [Java 8+](https://www.oracle.com/java/technologies/javase-downloads.html) installed
- [Maven](https://maven.apache.org/) installed
- [jq](https://stedolan.github.io/jq/) installed (for cleanup script)

## Project Structure

```
aws-web-app-devOps/
├── cloudformation-templates/       # CloudFormation templates
│   ├── build-infra-stack.yaml      # Build infrastructure resources
│   ├── cicd-pipeline-stack.yaml    # CI/CD pipeline configuration
│   ├── deployment-server-stack.yaml # Deployment environment
│   └── README.md                   # CloudFormation documentation
├── scripts/                        # Deployment scripts
│   ├── install_dependencies.sh     # Install Apache and configure proxy
│   ├── start_server.sh            # Start application services
│   ├── stop_server.sh             # Stop application services
│   ├── validate_service.sh        # Validate deployment
│   └── README.md                   # Scripts documentation
├── src/                            # Java web application source code
├── appspec.yml                     # AWS CodeDeploy specification
├── bootstrap.sh                    # Automated deployment script
├── buildspec.yml                   # AWS CodeBuild specification
├── delete_stacks.sh               # Cleanup script
├── local_dev.sh                   # Local development script
├── pom.xml                        # Maven project configuration
└── settings.xml                   # Maven settings for CodeArtifact
```

## Getting Started

### AWS Account Setup

1. **Create an IAM User with Admin Access**:
   - Go to [IAM Console](https://console.aws.amazon.com/iam/)
   - Create a new user with programmatic access
   - Attach the `AdministratorAccess` policy
   - Save the access key and secret key

2. **Configure AWS CLI**:
   ```bash
   aws configure
   ```

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/aws-web-app-devOps.git
   cd aws-web-app-devOps
   ```

2. **Run the application locally**:
   ```bash
   ./local_dev.sh
   ```

3. **Access the application**:
   Open your browser and navigate to `http://localhost:8090/nextwork-web-project/`

### Deployment

The entire deployment process is automated using the `bootstrap.sh` script:

```bash
./bootstrap.sh
```

This script will:

1. Deploy the deployment server stack
2. Create or use an existing GitHub connection
3. Deploy the build infrastructure stack
4. Deploy the CI/CD pipeline stack
5. Start the pipeline execution

During the process, you'll need to authorize the GitHub connection when prompted.

## CI/CD Pipeline

The CI/CD pipeline consists of three stages:

1. **Source**: Fetches code from GitHub repository
2. **Build**: Builds the application using CodeBuild
   - Uses Maven with CodeArtifact integration
   - Packages the application as a WAR file
3. **Deploy**: Deploys to EC2 instance using CodeDeploy
   - Installs dependencies
   - Deploys the WAR file to Tomcat
   - Configures Apache as a proxy
   - Validates the deployment

## Monitoring and Troubleshooting

### Checking Pipeline Status

1. Go to [AWS CodePipeline Console](https://console.aws.amazon.com/codepipeline/)
2. Select the `nextwork-devops-cicd` pipeline
3. View the current status and history

### Accessing the Application

After successful deployment, access the application using the EC2 instance's public DNS:

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2/)
2. Find the instance with the tag `role: webserver`
3. Use the Public DNS or IP address in your browser

### Common Issues

- **GitHub Connection**: Ensure the GitHub connection is authorized
- **Build Failures**: Check CodeBuild logs for Maven errors
- **Deployment Failures**: Check CodeDeploy logs and EC2 instance logs
- **Application Not Accessible**: Verify security group settings and service status

## Cleanup

To delete all resources created by this project:

```bash
./delete_stacks.sh
```

This script will:
1. Empty all S3 buckets
2. Delete the CI/CD pipeline stack
3. Delete the build infrastructure stack
4. Delete the deployment server stack

## Additional Documentation

- [CloudFormation Templates Documentation](cloudformation-templates/README.md)
- [Deployment Scripts Documentation](scripts/README.md)
- [AWS DevOps Blog](https://aws.amazon.com/blogs/devops/)
