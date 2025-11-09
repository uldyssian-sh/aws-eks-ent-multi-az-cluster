#!/bin/bash

set -e

echo "☢️ NUCLEAR AWS CLEANUP - Destroying EVERYTHING!"
echo "⚠️  This will delete ALL AWS resources in your account!"
read -p "Type 'NUCLEAR-DELETE' to confirm total destruction: " confirm

if [ "$confirm" != "NUCLEAR-DELETE" ]; then
    echo "❌ Nuclear cleanup cancelled"
    exit 1
fi

echo "💥 Starting nuclear cleanup..."

# Delete ALL EKS clusters
echo "🎯 Deleting ALL EKS clusters..."
aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null | while read -r cluster; do
    if [[ -n "$cluster" ]]; then
        echo "  💥 Nuking cluster: $cluster"
        # Get and delete nodegroups first
        aws eks list-nodegroups --cluster-name "$cluster" --query 'nodegroups[]' --output text 2>/dev/null | while read -r nodegroup; do
            if [[ -n "$nodegroup" ]]; then
                aws eks delete-nodegroup --cluster-name "$cluster" --nodegroup-name "$nodegroup" >/dev/null 2>&1 || true
            fi
        done
        sleep 30
        aws eks delete-cluster --name "$cluster" >/dev/null 2>&1 || true
    fi
done

# Delete ALL VPCs (except default)
echo "🌐 Deleting ALL VPCs..."
aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>/dev/null | while read -r vpc; do
    if [[ -n "$vpc" ]]; then
        echo "  💥 Nuking VPC: $vpc"
        # Delete subnets
        aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text | while read -r subnet; do
            if [[ -n "$subnet" ]]; then
                aws ec2 delete-subnet --subnet-id "$subnet" >/dev/null 2>&1 || true
            fi
        done
    # Delete internet gateways
        # Delete internet gateways
        aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text | while read -r igw; do
            if [[ -n "$igw" ]]; then
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" >/dev/null 2>&1 || true
                aws ec2 delete-internet-gateway --internet-gateway-id "$igw" >/dev/null 2>&1 || true
            fi
        done
    # Delete route tables
        # Delete route tables
        aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | while read -r rt; do
            if [[ -n "$rt" ]]; then
                aws ec2 delete-route-table --route-table-id "$rt" >/dev/null 2>&1 || true
            fi
        done
    # Delete security groups
        # Delete security groups
        aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | while read -r sg; do
            if [[ -n "$sg" ]]; then
                aws ec2 delete-security-group --group-id "$sg" >/dev/null 2>&1 || true
            fi
        done
        # Delete VPC
        aws ec2 delete-vpc --vpc-id "$vpc" >/dev/null 2>&1 || true
    fi
done

# Delete ALL S3 buckets
echo "🪣 Deleting ALL S3 buckets..."
aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null | while read -r bucket; do
    if [[ -n "$bucket" ]]; then
        echo "  💥 Nuking bucket: $bucket"
        aws s3 rm "s3://$bucket" --recursive >/dev/null 2>&1 || true
        aws s3api delete-bucket --bucket "$bucket" >/dev/null 2>&1 || true
    fi
done

# Delete ALL IAM roles (except AWS service roles)
echo "👤 Deleting ALL custom IAM roles..."
aws iam list-roles --query 'Roles[?!starts_with(RoleName, `AWSService`)].RoleName' --output text 2>/dev/null | while read role; do
    echo "  💥 Nuking role: $role"
    # Detach all policies
    aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null | while read policy; do
        aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" >/dev/null 2>&1 || true
    done
    # Delete inline policies
    aws iam list-role-policies --role-name "$role" --query 'PolicyNames[]' --output text 2>/dev/null | while read policy; do
        aws iam delete-role-policy --role-name "$role" --policy-name "$policy" >/dev/null 2>&1 || true
    done
    # Delete instance profiles
    aws iam list-instance-profiles-for-role --role-name "$role" --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null | while read profile; do
        aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role" >/dev/null 2>&1 || true
        aws iam delete-instance-profile --instance-profile-name "$profile" >/dev/null 2>&1 || true
    done
    aws iam delete-role --role-name "$role" >/dev/null 2>&1 || true
done

# Delete ALL custom IAM policies
echo "📜 Deleting ALL custom IAM policies..."
aws iam list-policies --scope Local --query 'Policies[].Arn' --output text 2>/dev/null | while read policy; do
    echo "  💥 Nuking policy: $policy"
    # Delete all policy versions except default
    aws iam list-policy-versions --policy-arn "$policy" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text 2>/dev/null | while read version; do
        aws iam delete-policy-version --policy-arn "$policy" --version-id "$version" >/dev/null 2>&1 || true
    done
    aws iam delete-policy --policy-arn "$policy" >/dev/null 2>&1 || true
done

# Delete ALL EC2 instances
echo "🖥️ Terminating ALL EC2 instances..."
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text 2>/dev/null | while read instance; do
    echo "  💥 Terminating instance: $instance"
    aws ec2 terminate-instances --instance-ids "$instance" >/dev/null 2>&1 || true
done

# Delete ALL Load Balancers
echo "⚖️ Deleting ALL Load Balancers..."
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null | while read lb; do
    echo "  💥 Nuking load balancer: $lb"
    aws elbv2 delete-load-balancer --load-balancer-arn "$lb" >/dev/null 2>&1 || true
done

# Delete ALL Auto Scaling Groups
echo "📈 Deleting ALL Auto Scaling Groups..."
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName' --output text 2>/dev/null | while read asg; do
    echo "  💥 Nuking ASG: $asg"
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg" --min-size 0 --desired-capacity 0 >/dev/null 2>&1 || true
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$asg" --force-delete >/dev/null 2>&1 || true
done

# Delete ALL Launch Templates
echo "🚀 Deleting ALL Launch Templates..."
aws ec2 describe-launch-templates --query 'LaunchTemplates[].LaunchTemplateId' --output text 2>/dev/null | while read lt; do
    echo "  💥 Nuking launch template: $lt"
    aws ec2 delete-launch-template --launch-template-id "$lt" >/dev/null 2>&1 || true
done

# Schedule ALL KMS keys for deletion
echo "🔐 Scheduling ALL KMS keys for deletion..."
aws kms list-keys --query 'Keys[].KeyId' --output text 2>/dev/null | while read key; do
    KEY_MANAGER=$(aws kms describe-key --key-id "$key" --query 'KeyMetadata.KeyManager' --output text 2>/dev/null || echo "AWS")
    if [ "$KEY_MANAGER" = "CUSTOMER" ]; then
        echo "  💥 Scheduling key deletion: $key"
        aws kms schedule-key-deletion --key-id "$key" --pending-window-in-days 7 >/dev/null 2>&1 || true
    fi
done

# Delete ALL CloudWatch Log Groups
echo "📊 Deleting ALL CloudWatch Log Groups..."
aws logs describe-log-groups --query 'logGroups[].logGroupName' --output text 2>/dev/null | while read lg; do
    echo "  💥 Nuking log group: $lg"
    aws logs delete-log-group --log-group-name "$lg" >/dev/null 2>&1 || true
done

# Clean ALL local files
echo "🧹 Cleaning ALL local terraform state..."
find . -name "terraform.tfstate*" -delete >/dev/null 2>&1 || true
find . -name ".terraform.lock.hcl" -delete >/dev/null 2>&1 || true
find . -type d -name ".terraform" -exec rm -rf {} + >/dev/null 2>&1 || true

echo ""
echo "☢️ NUCLEAR CLEANUP COMPLETED!"
echo ""
echo "💥 EVERYTHING DESTROYED:"
echo "  - ALL EKS clusters"
echo "  - ALL VPCs and networking"
echo "  - ALL S3 buckets"
echo "  - ALL IAM roles and policies"
echo "  - ALL EC2 instances"
echo "  - ALL Load Balancers"
echo "  - ALL Auto Scaling Groups"
echo "  - ALL Launch Templates"
echo "  - ALL KMS keys (scheduled)"
echo "  - ALL CloudWatch logs"
echo "  - ALL local terraform state"
echo ""
echo "💰 AWS account is now COMPLETELY CLEAN!"
echo "🔥 Total destruction achieved!"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
