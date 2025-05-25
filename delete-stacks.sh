#!/bin/bash

# The resource ArtifactBucket is in a DELETE_FAILED state
# This AWS::S3::Bucket resource is in a DELETE_FAILED state.

# Resource handler returned message: "The bucket you tried to delete is not empty. You must delete all versions in the bucket. (Service: S3, Status Code: 409, Request ID: BA2TXM2RZNFVVCH1, Extended Request ID: 0YjnzQ0QFYkjtTlXb5upjf5BbBqlsbuNgEhjQJwXvVWWacdij6iyuQcwNuIFbhfpdgnaWsOON/E=) (SDK Attempt Count: 1)" (RequestToken: 41ed260a-4900-51a5-8458-c39ff9ea9eb0, HandlerErrorCode: GeneralServiceException)
# Seems like i need to delete the S3 bucket manually before deleting the stack.

# Exit on error
# set -e  

# echo "Starting cleanup process..."

# # Function to check if stack exists
# check_stack_exists() {
#     aws cloudformation describe-stacks --stack-name $1 >/dev/null 2>&1
#     return $?
# }

# # Function to delete stack with error handling
# delete_stack() {
#     local stack_name=$1
#     echo "Attempting to delete stack: $stack_name"
    
#     if check_stack_exists "$stack_name"; then
#         # Get S3 buckets in the stack
#         local buckets=$(aws cloudformation describe-stack-resources \
#             --stack-name "$stack_name" \
#             --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
#             --output text)
        
#         # Empty and delete each bucket
#         for bucket in $buckets; do
#             echo "Emptying bucket: $bucket"
#             # Delete all object versions
#             aws s3api list-object-versions \
#                 --bucket "$bucket" \
#                 --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}} + {Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
#                 --output json 2>/dev/null | \
#             jq -r '.Objects[] | select(.Key != null) | "\(.Key),\(.VersionId)"' | \
#             while IFS=, read -r key version; do
#                 echo "Deleting object: $key (version: $version)"
#                 aws s3api delete-object \
#                     --bucket "$bucket" \
#                     --key "$key" \
#                     --version-id "$version" 2>/dev/null || true
#             done

#             # Delete the bucket itself
#             echo "Deleting bucket: $bucket"
#             aws s3api delete-bucket --bucket "$bucket" 2>/dev/null || true
#         done

#         # Delete the stack
#         echo "Deleting stack: $stack_name"
#         aws cloudformation delete-stack --stack-name "$stack_name"
        
#         echo "Waiting for stack deletion to complete..."
#         if aws cloudformation wait stack-delete-complete --stack-name "$stack_name"; then
#             echo "✅ Successfully deleted $stack_name"
#         else
#             echo "❌ Failed to delete $stack_name"
#             return 1
#         fi
#     else
#         echo "Stack $stack_name does not exist"
#     fi
# }

# # Delete stacks in reverse order of dependencies
# echo "Starting stack deletion sequence..."

# # 1. Delete CICD Pipeline Stack
# delete_stack "cicd-pipeline-stack"

# # 2. Delete Build Infrastructure Stack
# delete_stack "build-infra-stack"

# # 3. Delete Deployment Server Stack
# delete_stack "deployment-server-stack"

# echo "Stack deletion process complete!"

# # Final verification
# echo "Performing final verification..."
# for stack in "cicd-pipeline-stack" "build-infra-stack" "deployment-server-stack"; do
#     if ! check_stack_exists "$stack"; then
#         echo "✅ $stack successfully deleted"
#     else
#         echo "❌ $stack still exists - manual cleanup may be required"
#     fi
# done


# #!/bin/bash
# Exit on error
set -e

echo "Starting cleanup process..."

# Define stack names
PIPELINE_STACK="cicd-pipeline-stack"
BUILD_INFRA_STACK="build-infra-stack"
DEPLOY_SERVER_STACK="deployment-server-stack"

# Empty the artifact bucket from the pipeline stack
echo "Emptying artifact buckets..."
ARTIFACT_BUCKETS=$(aws cloudformation describe-stack-resources \
    --stack-name $PIPELINE_STACK \
    --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
    --output text 2>/dev/null || echo "")

if [ -z "$ARTIFACT_BUCKETS" ]; then
    echo "No artifact buckets found in pipeline stack"
else
    for BUCKET in $ARTIFACT_BUCKETS; do
        echo "Emptying bucket: $BUCKET"
        # Delete all objects including versions
        aws s3 rm s3://$BUCKET --recursive --force
        # Delete all object versions
        aws s3api list-object-versions \
            --bucket $BUCKET \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}} + {Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
            --output json 2>/dev/null | \
        jq -r '.Objects[] | select(.Key != null and .VersionId != null) | "\(.Key) \(.VersionId)"' | \
        while read -r key version; do
            [ -n "$key" ] && [ -n "$version" ] && \
            aws s3api delete-object --bucket $BUCKET --key "$key" --version-id "$version"
        done
    done
fi

# Also check for the S3 bucket in the build-infra stack
INFRA_BUCKET="nextwork-devops-cicd-chen"
echo "Emptying infrastructure bucket: $INFRA_BUCKET"
aws s3 rm s3://$INFRA_BUCKET --recursive --force 2>/dev/null || echo "Bucket not found or already empty"
aws s3api list-object-versions \
    --bucket $INFRA_BUCKET \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}} + {Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json 2>/dev/null | \
jq -r '.Objects[] | select(.Key != null and .VersionId != null) | "\(.Key) \(.VersionId)"' | \
while read -r key version; do
    [ -n "$key" ] && [ -n "$version" ] && \
    aws s3api delete-object --bucket $INFRA_BUCKET --key "$key" --version-id "$version" 2>/dev/null || true
done

# Delete the stacks in the correct order
echo "Deleting CI/CD-Pipeline Stack..."
aws cloudformation delete-stack --stack-name $PIPELINE_STACK 2>/dev/null || echo "Pipeline stack doesn't exist or already deleted"
aws cloudformation wait stack-delete-complete --stack-name $PIPELINE_STACK 2>/dev/null || echo "Wait failed for pipeline stack"

echo "Deleting Build-Infrastructure Stack..."
aws cloudformation delete-stack --stack-name $BUILD_INFRA_STACK
aws cloudformation wait stack-delete-complete --stack-name $BUILD_INFRA_STACK || echo "Wait failed for build infra stack"

echo "Deleting Deployment-Server stack..."
aws cloudformation delete-stack --stack-name $DEPLOY_SERVER_STACK
aws cloudformation wait stack-delete-complete --stack-name $DEPLOY_SERVER_STACK || echo "Wait failed for deployment server stack"

echo "Stack deletion process complete!"
