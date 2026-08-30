# ADR-002: Complete Network Isolation for the Database Tier

Date: 2026-08-26
Status: Accepted

## Context

Once I decided to place the database in its own private subnet, I had to decide what kind of routing that subnet would have. The default approach used in many tutorials is to route all private subnets through a NAT Gateway, which gives them outbound internet access for things like software updates. That felt like too much access for a database.

## Decision

The database subnets have no route to the internet at all, not even outbound through the NAT Gateway. The route table attached to those subnets contains only the local VPC route (10.0.0.0/16). There is no 0.0.0.0/0 entry of any kind.

## Why This Solution

A database server has no legitimate reason to initiate outbound connections to the internet. It does not need to download updates (RDS is managed by AWS), it does not call external APIs, and it should not be able to send data outside the VPC under any circumstances. Giving it a NAT route would be creating a path that serves no purpose but could be exploited if the database were ever compromised.

Removing that route entirely means that even if an attacker gained access to the RDS instance, they could not use it to exfiltrate data to an external server or connect to a command-and-control endpoint.

## Consequences and Trade-offs

This configuration is slightly more restrictive than what most guides recommend, which means it requires more care when testing. For example, pinging an external address from inside a database subnet will always fail, which is the expected and desired behavior. The constraint is that RDS managed services must handle all patching themselves (which they do), so there is no operational downside for a managed database engine like MariaDB on RDS.
