#!/bin/bash
# Cleanup script for AWS resources
set -e

echo "Starting cleanup process..."

# Define stack names
PIPELINE_STACK="cicd-pipeline-stack"
BUILD_INFRA_STACK="build-infra-stack"
DEPLOY_SERVER_STACK="deployment-server-stack"
INFRA_BUCKET="nextwork-devops-cicd-chen"

# Function to check if stack exists
check_stack_exists() {
    aws cloudformation describe-stacks --stack-name $1 >/dev/null 2>&1
    return $?
}

# Function to empty S3 bucket including all versions
empty_bucket() {
    local bucket=$1
    echo "Emptying bucket: $bucket"
    
    # Remove all objects
    aws s3 rm s3://$bucket --recursive 2>/dev/null || true
    
    # Delete all object versions
    aws s3api list-object-versions \
        --bucket $bucket \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
        --output json 2>/dev/null | \
    jq -c '.Objects[]' 2>/dev/null | \
    while read -r object; do
        if [ -n "$object" ]; then
            key=$(echo $object | jq -r '.Key')
            version=$(echo $object | jq -r '.VersionId')
            echo "Deleting object: $key (version: $version)"
            aws s3api delete-object --bucket $bucket --key "$key" --version-id "$version" 2>/dev/null || true
        fi
    done
    
    # Delete all delete markers
    aws s3api list-object-versions \
        --bucket $bucket \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
        --output json 2>/dev/null | \
    jq -c '.Objects[]' 2>/dev/null | \
    while read -r object; do
        if [ -n "$object" ]; then
            key=$(echo $object | jq -r '.Key')
            version=$(echo $object | jq -r '.VersionId')
            echo "Deleting delete marker: $key (version: $version)"
            aws s3api delete-object --bucket $bucket --key "$key" --version-id "$version" 2>/dev/null || true
        fi
    done
}

# Function to delete stack with error handling
delete_stack() {
    local stack_name=$1
    echo "Attempting to delete stack: $stack_name"
    
    if check_stack_exists "$stack_name"; then
        # Get S3 buckets in the stack
        local buckets=$(aws cloudformation describe-stack-resources \
            --stack-name "$stack_name" \
            --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
            --output text)
        
        # Empty and delete each bucket
        for bucket in $buckets; do
            empty_bucket "$bucket"
            
            # Try to delete the bucket directly
            echo "Deleting bucket: $bucket"
            aws s3api delete-bucket --bucket "$bucket" 2>/dev/null || true
        done

        # Delete the stack
        echo "Deleting stack: $stack_name"
        aws cloudformation delete-stack --stack-name "$stack_name"
        
        echo "Waiting for stack deletion to complete..."
        if aws cloudformation wait stack-delete-complete --stack-name "$stack_name"; then
            echo "✅ Successfully deleted $stack_name"
        else
            echo "❌ Failed to delete $stack_name"
            return 1
        fi
    else
        echo "Stack $stack_name does not exist"
    fi
}

# Step 1: Empty all buckets first
echo "Step 1: Emptying all buckets..."

# Empty pipeline stack buckets
if check_stack_exists "$PIPELINE_STACK"; then
    ARTIFACT_BUCKETS=$(aws cloudformation describe-stack-resources \
        --stack-name $PIPELINE_STACK \
        --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
        --output text 2>/dev/null || echo "")
    
    for BUCKET in $ARTIFACT_BUCKETS; do
        empty_bucket "$BUCKET"
    done
fi

# Empty infrastructure bucket
if aws s3api head-bucket --bucket $INFRA_BUCKET 2>/dev/null; then
    empty_bucket "$INFRA_BUCKET"
fi

# Step 2: Delete buckets directly
echo "Step 2: Deleting buckets directly..."

# Delete pipeline stack buckets
if check_stack_exists "$PIPELINE_STACK"; then
    ARTIFACT_BUCKETS=$(aws cloudformation describe-stack-resources \
        --stack-name $PIPELINE_STACK \
        --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
        --output text 2>/dev/null || echo "")
    
    for BUCKET in $ARTIFACT_BUCKETS; do
        echo "Deleting bucket: $BUCKET"
        aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null || true
    done
fi

# Delete infrastructure bucket
if aws s3api head-bucket --bucket $INFRA_BUCKET 2>/dev/null; then
    echo "Deleting infrastructure bucket: $INFRA_BUCKET"
    aws s3api delete-bucket --bucket "$INFRA_BUCKET" 2>/dev/null || true
fi

# Step 3: Delete stacks in reverse order of dependencies
echo "Step 3: Deleting stacks in order..."

# 1. Delete CICD Pipeline Stack
delete_stack "$PIPELINE_STACK"

# 2. Delete Build Infrastructure Stack
delete_stack "$BUILD_INFRA_STACK"

# 3. Delete Deployment Server Stack
delete_stack "$DEPLOY_SERVER_STACK"

# Final verification
echo "Performing final verification..."
for stack in "$PIPELINE_STACK" "$BUILD_INFRA_STACK" "$DEPLOY_SERVER_STACK"; do
    if ! check_stack_exists "$stack"; then
        echo "✅ $stack successfully deleted"
    else
        echo "❌ $stack still exists - manual cleanup may be required"
    fi
done

echo "Stack deletion process complete!"
