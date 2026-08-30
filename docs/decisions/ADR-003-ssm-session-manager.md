# ADR-003: Using SSM Session Manager Instead of SSH for Instance Access

Date: 2026-08-26
Status: Accepted

## Context

I needed a way to access the EC2 instances for administration and testing. The traditional approach is to create a Bastion Host (also called a jump server) in the public subnet, open port 22 (SSH) on its security group, and use SSH key pairs to connect. From the Bastion, you then SSH into private instances.

This approach works but introduces several security concerns: an open port 22 is a permanent attack surface that will attract automated scanners and brute force attempts, SSH keys must be generated, distributed, and rotated carefully, and if a key is lost or leaked the exposure can be significant.

## Decision

I replaced the SSH-based Bastion pattern with AWS Systems Manager Session Manager. The EC2 instances have the `LabInstanceProfile` attached, which includes the `AmazonSSMManagedInstanceCore` policy. No inbound port is open on any security group. Access is established entirely through the SSM API over HTTPS.

## Why This Solution

SSM Session Manager eliminates the open port completely. There is no port 22 to scan, no key pair to manage, and no risk of a leaked private key. Access is controlled entirely through IAM: if a user does not have the `ssm:StartSession` permission, they cannot connect regardless of network access.

All sessions are automatically logged in AWS CloudWatch, providing a full audit trail of who connected, when, and what commands were run. This is something that standard SSH does not provide out of the box.

The instances in private subnets need outbound HTTPS (port 443) to reach the SSM endpoints, which is handled through the NAT Gateway. This is the only outbound traffic required.

## Consequences and Trade-offs

SSM Session Manager requires the SSM Plugin to be installed on the local machine in addition to the AWS CLI. This is an extra setup step for anyone cloning this project. It also requires the instance to be running and reachable by the SSM service, which depends on the NAT Gateway being available for private instances. In exchange, the security posture is significantly stronger: no open ports, no key management, and a full audit trail by default.
