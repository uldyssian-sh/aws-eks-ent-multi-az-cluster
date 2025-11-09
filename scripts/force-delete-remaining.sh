#!/bin/bash
# Force delete remaining AWS resources after EKS cluster cleanup
# This script forcefully removes resources that may be left behind
# WARNING: This will delete resources in the specified region

set -euo pipefail

echo "🔥 Force deleting ALL remaining resources in us-west-2..."

REGION="us-west-2"

# Wait for EKS cluster deletion to complete
echo "⏳ Waiting for EKS cluster deletion..."
aws eks wait cluster-deleted --name aws-eks-ent-multi-az-cluster-dev --region "$REGION" 2>/dev/null || echo "  ✅ Cluster deletion in progress"

# Force delete all security groups
echo "🛡️ Force deleting security groups..."
aws ec2 describe-security-groups --region "$REGION" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | while read -r sg; do
    if [[ -n "$sg" ]]; then
        echo "  💥 Deleting SG: $sg"
        aws ec2 delete-security-group --group-id "$sg" --region "$REGION" >/dev/null 2>&1 || echo "    ⚠️ SG $sg deletion failed (may be in use)"
    fi
done

# Force delete all subnets in VPCs
echo "🌐 Force deleting subnets..."
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read -r vpc; do
    if [[ -n "$vpc" ]]; then
        echo "  🔍 Processing VPC: $vpc"
        aws ec2 describe-subnets --region "$REGION" --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text | while read -r subnet; do
            if [[ -n "$subnet" ]]; then
                echo "    💥 Deleting subnet: $subnet"
                aws ec2 delete-subnet --subnet-id "$subnet" --region "$REGION" >/dev/null 2>&1 || echo "      ⚠️ Subnet deletion failed"
            fi
        done
    fi
done

# Force delete internet gateways
echo "🌍 Force deleting internet gateways..."
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read -r vpc; do
    if [[ -n "$vpc" ]]; then
        aws ec2 describe-internet-gateways --region "$REGION" --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text | while read -r igw; do
            if [[ -n "$igw" ]]; then
                echo "  💥 Detaching and deleting IGW: $igw"
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region "$REGION" >/dev/null 2>&1 || true
                aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$REGION" >/dev/null 2>&1 || true
            fi
        done
    fi
done

# Force delete NAT gateways
echo "🚪 Force deleting NAT gateways..."
aws ec2 describe-nat-gateways --region "$REGION" --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text | while read -r nat; do
    if [[ -n "$nat" ]]; then
        echo "  💥 Deleting NAT Gateway: $nat"
        aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region "$REGION" >/dev/null 2>&1 || true
    fi
done

# Force delete route tables
echo "🛣️ Force deleting route tables..."
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read -r vpc; do
    if [[ -n "$vpc" ]]; then
        aws ec2 describe-route-tables --region "$REGION" --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | while read -r rt; do
            if [[ -n "$rt" ]]; then
                echo "  💥 Deleting route table: $rt"
                aws ec2 delete-route-table --route-table-id "$rt" --region "$REGION" >/dev/null 2>&1 || true
            fi
        done
    fi
done

# Wait a bit for dependencies to clear
echo "⏳ Waiting for dependencies to clear..."
sleep 30

# Force delete security groups again
echo "🛡️ Second pass - deleting security groups..."
aws ec2 describe-security-groups --region "$REGION" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | while read -r sg; do
    if [[ -n "$sg" ]]; then
        echo "  💥 Deleting SG: $sg"
        aws ec2 delete-security-group --group-id "$sg" --region "$REGION" >/dev/null 2>&1 || echo "    ⚠️ SG $sg still in use"
    fi
done

# Force delete VPCs
echo "🏠 Force deleting VPCs..."
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read -r vpc; do
    if [[ -n "$vpc" ]]; then
        echo "  💥 Deleting VPC: $vpc"
        aws ec2 delete-vpc --vpc-id "$vpc" --region "$REGION" >/dev/null 2>&1 || echo "    ⚠️ VPC $vpc deletion failed"
    fi
done

# Check what's left
echo "🔍 Final check - remaining resources:"
echo "  EKS clusters:"
aws eks list-clusters --region $REGION --query 'clusters[]' --output text || echo "    None"
echo "  VPCs:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text || echo "    None"
echo "  Security groups:"
aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text || echo "    None"

echo "✅ Force deletion completed!"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
