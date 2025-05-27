# DevOps CI/CD Infrastructure

This module contains AWS CloudFormation templates that defines the infrastructure for a complete CI/CD deployment pipeline for a Java web application.

## Architecture Overview

The infrastructure consists of three main stacks:

1. **Build Infrastructure Stack** - Core resources for building applications
2. **CI/CD Pipeline Stack** - Complete CI/CD pipeline configuration
3. **Deployment Server Stack** - Target environment for application deployment

## Stack Details

### 1. Build Infrastructure Stack (`build-infra-stack.yaml`)

This stack creates the foundational resources required for the CI/CD pipeline:

**Resources:**

**IAM Roles and Policies**:
- This build infrastructure describes several IAM roles and policies that enable secure interactions between AWS services.

#### A. CodeBuild Service Role (`IAMRoleCodebuildnextworkdevopscicdservicerole`)

**Purpose**: Allows CodeBuild to perform build operations

**Trust Relationship**: Trusted by the `codebuild.amazonaws.com` service

**Attached Policies**:

- **CodeBuildBasePolicy**:
  - Create and manage CloudWatch log groups/streams
  - Access S3 buckets for artifact storage
  - Create and update CodeBuild reports

- **CodeBuildCloudWatchLogsPolicy**: 
  - Enables logging to CloudWatch

- **CodeBuildCodeConnectionsSourceCredentialsPolicy**: 
  - Allows access to GitHub via CodeStar connections

- **CodeArtifact Consumer Policy**: 
  - Enables reading from CodeArtifact repositories

#### B. EC2 Instance Role (`IAMRoleEC2instancenextworkcicd`)

**Purpose**: Grants EC2 deployment targets access to required services

**Trust Relationship**: Trusted by the `ec2.amazonaws.com` service

**Attached Policies**:

- **CodeArtifact Consumer Policy**:
  - Get authorization tokens for CodeArtifact
  - Access repository endpoints
  - Read artifacts from repositories

#### C. CodeDeploy Service Role (`IAMRoleNextWorkCodeDeployRole`)

**Purpose**: Enables CodeDeploy to deploy applications to EC2 instances

**Trust Relationship**: Trusted by the `codedeploy.amazonaws.com` service

**Attached Policies**:

- **AWSCodeDeployRole** (AWS managed policy):
  - Tag EC2 instances
  - Perform deployment operations
  - Access Auto Scaling groups if needed

#### D. CodePipeline Service Role (`CodePipelineServiceRole`)

**Purpose**: Allows CodePipeline to orchestrate the CI/CD workflow

**Trust Relationship**: Trusted by the `codepipeline.amazonaws.com` service

**Inline Policy**: `CodePipelineSourcePolicy` grants permissions to:
  - Access S3 buckets for artifact storage
  - Start and monitor CodeBuild builds
  - Create and manage CodeDeploy deployments
  - Use CodeStar connections to access GitHub
  
#### Policy Relationships

- The CodeBuild service role uses multiple policies to separate concerns:
  - Logging permissions
  - S3 access permissions
  - GitHub connection permissions
  - CodeArtifact access permissions

- Both the CodeBuild role and EC2 instance role share the CodeArtifact consumer policy to access artifacts

- All roles follow the principle of least privilege, granting only the permissions needed for their specific functions

**CodeArtifact Domain and Repositories**:
  - `nextwork` domain
  - `maven-central-store` repository (connects to Maven Central)
  - `nextwork-devops-cicd` repository (for project artifacts)
- **CodeStar Connection**: GitHub connection for source code access
- **S3 Bucket**: For storing build artifacts
- **CodeBuild Project**: Configured for Java application builds
- **CodeDeploy Application**: For deploying to EC2 instances

#### Parameters:
- `GitHubRepoOwner`: GitHub repository owner
- `GithubRepo`: GitHub repository name
- `GitHubConnectionArn`: ARN of the GitHub CodeStar connection

#### Outputs:
- `CodePipelineServiceRoleArn`: ARN of the CodePipeline service role
- `CodeBuildProjectName`: Name of the CodeBuild project

### 2. CI/CD Pipeline Stack (`cicd-pipeline-stack.yaml`)

This stack creates the complete CI/CD pipeline that connects source code, build, and deployment stages:

#### Resources:
- **S3 Bucket**: For pipeline artifacts with versioning enabled
- **CodePipeline**: Three-stage pipeline:
  - **Source Stage**: Fetches code from GitHub repository
  - **Build Stage**: Builds the application using CodeBuild
  - **Deploy Stage**: Deploys to target environment using CodeDeploy

#### Parameters:
- `GitHubOwner`: GitHub repository owner
- `GitHubRepo`: GitHub repository name
- `GitHubBranch`: GitHub branch to use (default: "main")
- `GitHubConnectionArn`: GitHub connection ARN from CodeStar Connections
- `ApplicationName`: CodeDeploy application name (default: "nextwork-devops-cicd")
- `DeploymentGroupName`: CodeDeploy deployment group name (default: "nextwork-devops-cicd-deployment-group")
- `ArtifactBucketName`: Name of the S3 bucket for artifacts (default: "nextwork-devops-cicd-chen")
- `BuildInfraStackName`: Name of the infrastructure stack that exports resources (default: "build-infra-stack")

#### Outputs:
- `PipelineURL`: URL to the CodePipeline console

### 3. Deployment Server Stack (`deployment-server-stack.yaml`)

This stack creates the target environment for application deployment:

#### Resources:
- **VPC**: Custom VPC with CIDR 10.11.0.0/16
- **Internet Gateway**: For public internet access
- **Public Subnet**: For hosting the web server
- **Route Table**: With routes to the internet
- **Security Group**: Allows HTTP (80) access from anywhere and Tomcat (8080) access from specified IP
- **IAM Role**: For EC2 instance with SSM and S3 read access
- **EC2 Instance**: Amazon Linux instance with Java 11 and Tomcat pre-installed

#### Parameters:
- `AmazonLinuxAMIID`: Amazon Linux AMI ID (default: latest Amazon Linux 2 AMI)
- `MyIP`: Your IP address for security group access rules

#### Outputs:
- `URL`: URL to access the deployed web application

## Deployment Instructions

### Prerequisites
- AWS CLI installed and configured
- Appropriate AWS permissions to create the resources
- GitHub repository with your Java web application
- GitHub connection created in AWS CodeStar Connections

### Deployment Steps

1. **Deploy the Build Infrastructure Stack**:
   ```bash
   aws cloudformation create-stack \
     --stack-name build-infra-stack \
     --template-body file://build-infra-stack.yaml \
     --parameters \
       ParameterKey=GitHubRepoOwner,ParameterValue=YourGitHubUsername \
       ParameterKey=GithubRepo,ParameterValue=YourRepoName \
       ParameterKey=GitHubConnectionArn,ParameterValue=YourConnectionArn \
     --capabilities CAPABILITY_NAMED_IAM
   ```

2. **Deploy the Deployment Server Stack**:
   ```bash
   aws cloudformation create-stack \
     --stack-name deployment-server-stack \
     --template-body file://deployment-server-stack.yaml \
     --parameters \
       ParameterKey=MyIP,ParameterValue=YourIP/32 \
     --capabilities CAPABILITY_IAM
   ```

3. **Deploy the CI/CD Pipeline Stack**:
   ```bash
   aws cloudformation create-stack \
     --stack-name cicd-pipeline-stack \
     --template-body file://cicd-pipeline-stack.yaml \
     --parameters \
       ParameterKey=GitHubOwner,ParameterValue=YourGitHubUsername \
       ParameterKey=GitHubRepo,ParameterValue=YourRepoName \
       ParameterKey=GitHubBranch,ParameterValue=main \
       ParameterKey=GitHubConnectionArn,ParameterValue=YourConnectionArn \
       ParameterKey=BuildInfraStackName,ParameterValue=build-infra-stack
   ```

## Required Application Files

For the CI/CD pipeline to work correctly, your Java web application repository should include:

1. **buildspec.yml**: CodeBuild specification file in the root directory
2. **appspec.yml**: CodeDeploy specification file in the root directory

## Security Considerations

- The deployment server allows HTTP access from anywhere (port 80)
- Tomcat access (port 8080) is restricted to the IP specified in the `MyIP` parameter
- All S3 buckets are encrypted with AES-256
- IAM roles follow the principle of least privilege

## Cleanup

To delete all resources created by these templates:

1. Delete the CI/CD Pipeline Stack:
   ```bash
   aws cloudformation delete-stack --stack-name cicd-pipeline-stack
   ```

2. Delete the Deployment Server Stack:
   ```bash
   aws cloudformation delete-stack --stack-name deployment-server-stack
   ```

3. Delete the Build Infrastructure Stack:
   ```bash
   aws cloudformation delete-stack --stack-name build-infra-stack
   ```

## Troubleshooting

- **Pipeline Failures**: Check the CodePipeline console for specific error messages
- **Build Failures**: Review the CodeBuild logs in CloudWatch
- **Deployment Failures**: Check the CodeDeploy logs and EC2 instance logs
- **Connection Issues**: Verify the GitHub connection is properly configured in CodeStar Connections

## Contributing

Please submit pull requests or issues to improve these templates.