#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-south-1"
DEPLOY_SERVER_STACK="deployment-server-stack"
BUILD_INFRA_STACK="build-infra-stack"
PIPELINE_STACK="cicd-pipeline-stack"
TEMPLATE_DIR="./cloudformation-templates"

# Function to get current IP
get_my_ip() {
    echo $(curl -s https://checkip.amazonaws.com)
}

echo "👉 1. Deploying CFN stacks…"

aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $DEPLOY_SERVER_STACK \
  --template-file $TEMPLATE_DIR/deployment-server-stack.yaml \
  --parameter-overrides MyIP="$(get_my_ip)/32" \
  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $BUILD_INFRA_STACK \
  --template-file $TEMPLATE_DIR/build-infra-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation deploy \
  --region $AWS_REGION \
  --stack-name $PIPELINE_STACK \
  --template-file $TEMPLATE_DIR/cicd-pipeline-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM

echo "👉 2. Running drift detection on $DEPLOY_SERVER_STACK"

DETECT_ID=$(aws cloudformation detect-stack-drift \
  --stack-name $DEPLOY_SERVER_STACK \
  --region $AWS_REGION \
  --query "StackDriftDetectionId" \
  --output text)

aws cloudformation wait stack-drift-detection-complete \
  --stack-name $DEPLOY_SERVER_STACK \
  --region $AWS_REGION

DRIFT_STATUS=$(aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id $DETECT_ID \
  --region $AWS_REGION \
  --query "DetectionStatus" \
  --output text)

RESOURCE_DRIFTED=$(aws cloudformation describe-stack-resource-drifts \
  --stack-name $DEPLOY_SERVER_STACK \
  --region $AWS_REGION \
  --query "StackResourceDrifts[?StackResourceDriftStatus=='MODIFIED'].LogicalResourceId" \
  --output text)

if [[ "$DRIFT_STATUS" != "DETECTION_COMPLETE" ]]; then
  echo "❌ Drift detection failed: $DRIFT_STATUS"
  exit 1
elif [[ -n "$RESOURCE_DRIFTED" ]]; then
  echo "⚠️  Detected drift in resources: $RESOURCE_DRIFTED"
  exit 2
else
  echo "✅ No drift detected."
fi

echo "👉 3. Starting CodePipeline execution…"

aws codepipeline start-pipeline-execution \
  --name nextwork-devops-cicd \
  --region $AWS_REGION

echo "🎉 All set! Your pipeline is now running." 
