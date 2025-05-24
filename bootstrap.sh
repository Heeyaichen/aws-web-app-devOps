#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-south-1"
DEPLOY_SERVER_STACK="deployment-server-stack"
BUILD_INFRA_STACK="build-infra-stack"
PIPELINE_STACK="cicd-pipeline-stack"
TEMPLATE_DIR="./cloudformation-templates"
GITHUB_CONNECTION_NAME="devops-github-connection"

# Function to get current IP
get_my_ip() {
    echo $(curl -s https://checkip.amazonaws.com)
}

echo "👉 1. Deploying CFN stacks…"

# Deploy the deployment server stack
aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $DEPLOY_SERVER_STACK \
  --template-file $TEMPLATE_DIR/deployment-server-stack.yaml \
  --parameter-overrides MyIP="$(get_my_ip)/32" \
  --capabilities CAPABILITY_NAMED_IAM

# Check for existing connection and get its ARN
echo "👉 2. Checking for existing GitHub connection..."
CONNECTION_ARN=$(aws codestar-connections list-connections \
  --provider-type GitHub \
  --region $AWS_REGION \
  --query "Connections[?ConnectionName=='${GITHUB_CONNECTION_NAME}'].ConnectionArn | [0]" \
  --output text)

# Create GitHub connection if it doesn't exist
if [ -z "$CONNECTION_ARN" ] || [ "$CONNECTION_ARN" == "None" ]; then
  echo "Creating new GitHub connection..."
  CONNECTION_ARN=$(aws codestar-connections create-connection \
    --provider-type GitHub \
    --connection-name $GITHUB_CONNECTION_NAME \
    --region $AWS_REGION \
    --output text \
    --query 'ConnectionArn')
else
  echo "Found existing connection: $CONNECTION_ARN"
fi

echo "⚠️ Please complete GitHub authorization at:"
echo "https://${AWS_REGION}.console.aws.amazon.com/codesuite/settings/connections"
echo "Press Enter once you have authorized the GitHub connection..."
read -r

# Wait for connection to be available
echo "👉 3. Waiting for connection to be available..."
echo "👉 Checking connection status..."
CONNECTION_STATUS=$(aws codestar-connections get-connection \
  --connection-arn $CONNECTION_ARN \
  --region $AWS_REGION \
  --query 'Connection.ConnectionStatus' \
  --output text)

if [[ "$CONNECTION_STATUS" == "AVAILABLE" ]]; then
  echo "✅ Connection is available."
elif [[ "$CONNECTION_STATUS" == "PENDING_AUTHORIZATION" ]]; then
  echo "⚠️ Connection is still pending authorization. Please authorize it in the AWS console."
else
  echo "❌ Connection failed with status: $CONNECTION_STATUS"
  exit 1
fi

# Deploy build infrastructure with GitHub connection ARN
echo "👉 4. Deploying build infrastructure..."
aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $BUILD_INFRA_STACK \
  --template-file $TEMPLATE_DIR/build-infra-stack.yaml \
  --parameter-overrides GitHubConnectionArn=$CONNECTION_ARN \
  --capabilities CAPABILITY_NAMED_IAM

# Deploy pipeline stack with GitHub connection ARN
echo "👉 5. Deploying pipeline stack..."
aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $PIPELINE_STACK \
  --template-file $TEMPLATE_DIR/cicd-pipeline-stack.yaml \
  --parameter-overrides GitHubConnectionArn=$CONNECTION_ARN \
  --capabilities CAPABILITY_NAMED_IAM

echo "👉 6. Running drift detection on $DEPLOY_SERVER_STACK"
DETECT_ID=$(aws cloudformation detect-stack-drift \
  --stack-name $DEPLOY_SERVER_STACK \
  --region $AWS_REGION \
  --query "StackDriftDetectionId" \
  --output text)

echo "Waiting for drift detection to complete..."
while true; do
  DRIFT_STATUS=$(aws cloudformation describe-stack-drift-detection-status \
    --stack-drift-detection-id $DETECT_ID \
    --region $AWS_REGION \
    --query "DetectionStatus" \
    --output text)
  if [[ "$DRIFT_STATUS" == "DETECTION_COMPLETE" ]]; then
    break
  elif [ "$DRIFT_STATUS" == "DETECTION_FAILED" ]; then
    echo "❌ Drift detection failed: $DRIFT_STATUS"
    exit 1
  fi
  
  echo "Drift detection in progress..."
  sleep 5
done
echo "Drift detection completed with status: $DRIFT_STATUS"

# Check for drifted resources
RESOURCE_DRIFTED=$(aws cloudformation describe-stack-resource-drifts \
  --stack-name $DEPLOY_SERVER_STACK \
  --region $AWS_REGION \
  --query "StackResourceDrifts[?StackResourceDriftStatus=='MODIFIED'].LogicalResourceId" \
  --output text)

if [[ -n "$RESOURCE_DRIFTED" ]]; then
  echo "⚠️  Detected drift in resources: $RESOURCE_DRIFTED"
  exit 2
else
  echo "✅ No drift detected."
fi

# Start pipeline execution
echo "👉 7. Starting CodePipeline execution…"

aws codepipeline start-pipeline-execution \
  --name nextwork-devops-cicd \
  --region $AWS_REGION

echo "🎉 All set! Your pipeline is now running." 
