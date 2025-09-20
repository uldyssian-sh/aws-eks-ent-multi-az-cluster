#!/bin/bash

set -e

echo "🔥 Force deleting ALL remaining resources in us-west-2..."

REGION="us-west-2"

# Wait for EKS cluster deletion to complete
echo "⏳ Waiting for EKS cluster deletion..."
aws eks wait cluster-deleted --name aws-eks-ent-multi-az-cluster-dev --region $REGION 2>/dev/null || echo "  ✅ Cluster deletion in progress"

# Force delete all security groups
echo "🛡️ Force deleting security groups..."
aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | while read sg; do
    echo "  💥 Deleting SG: $sg"
    aws ec2 delete-security-group --group-id "$sg" --region $REGION >/dev/null 2>&1 || echo "    ⚠️ SG $sg deletion failed (may be in use)"
done

# Force delete all subnets in VPCs
echo "🌐 Force deleting subnets..."
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read vpc; do
    echo "  🔍 Processing VPC: $vpc"
    aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text | while read subnet; do
        echo "    💥 Deleting subnet: $subnet"
        aws ec2 delete-subnet --subnet-id "$subnet" --region $REGION >/dev/null 2>&1 || echo "      ⚠️ Subnet deletion failed"
    done
done

# Force delete internet gateways
echo "🌍 Force deleting internet gateways..."
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read vpc; do
    aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text | while read igw; do
        echo "  💥 Detaching and deleting IGW: $igw"
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region $REGION >/dev/null 2>&1 || true
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region $REGION >/dev/null 2>&1 || true
    done
done

# Force delete NAT gateways
echo "🚪 Force deleting NAT gateways..."
aws ec2 describe-nat-gateways --region $REGION --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text | while read nat; do
    echo "  💥 Deleting NAT Gateway: $nat"
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region $REGION >/dev/null 2>&1 || true
done

# Force delete route tables
echo "🛣️ Force deleting route tables..."
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read vpc; do
    aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | while read rt; do
        echo "  💥 Deleting route table: $rt"
        aws ec2 delete-route-table --route-table-id "$rt" --region $REGION >/dev/null 2>&1 || true
    done
done

# Wait a bit for dependencies to clear
echo "⏳ Waiting for dependencies to clear..."
sleep 30

# Force delete security groups again
echo "🛡️ Second pass - deleting security groups..."
aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | while read sg; do
    echo "  💥 Deleting SG: $sg"
    aws ec2 delete-security-group --group-id "$sg" --region $REGION >/dev/null 2>&1 || echo "    ⚠️ SG $sg still in use"
done

# Force delete VPCs
echo "🏠 Force deleting VPCs..."
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text | while read vpc; do
    echo "  💥 Deleting VPC: $vpc"
    aws ec2 delete-vpc --vpc-id "$vpc" --region $REGION >/dev/null 2>&1 || echo "    ⚠️ VPC $vpc deletion failed"
done

# Check what's left
echo "🔍 Final check - remaining resources:"
echo "  EKS clusters:"
aws eks list-clusters --region $REGION --query 'clusters[]' --output text || echo "    None"
echo "  VPCs:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text || echo "    None"
echo "  Security groups:"
aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text || echo "    None"

echo "✅ Force deletion completed!"