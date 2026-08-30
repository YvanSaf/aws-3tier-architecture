# ADR-001: Four-Subnet Network Architecture Across Two Availability Zones

Date: 2026-08-26
Status: Accepted

## Context

I needed to design the network layout for a 3-tier application (web, app, database) on AWS. The fundamental question was how many subnets to create, in how many Availability Zones, and how to assign each tier to a subnet.

A minimal setup could have used a single public subnet and one private subnet. That would have been simpler to set up, but it would have meant running web servers, app servers, and the database in the same network segment, which removes any meaningful isolation between tiers.

## Decision

I used four subnets spread across two Availability Zones:

- One public subnet in AZ-a for the Bastion Host and Web Server
- One private subnet in AZ-a for the App Server
- One private subnet in AZ-a for the primary RDS instance
- One private subnet in AZ-b for the RDS subnet group (required by AWS even in single-AZ deployments)

## Why This Solution

Placing each tier in its own subnet makes it possible to apply distinct routing rules and network ACLs per tier. The web tier needs inbound access from the internet. The app tier should only communicate with the web tier and the database. The database subnet should have no internet access at all, not even outbound.

Two Availability Zones are included because AWS RDS requires a DB subnet group with subnets in at least two AZs, even when Multi-AZ is disabled. Rather than creating an unused subnet just to satisfy that requirement, I used the second subnet meaningfully as a standby location in case of a future Multi-AZ upgrade.

## Consequences and Trade-offs

This layout adds a small amount of complexity compared to a two-subnet setup. There are more route tables and NACL rules to maintain. However, the security gain is significant: a compromised web server cannot directly reach the database, because they are in separate network segments with separate access controls. The second AZ subnet also prepares the infrastructure for a future Multi-AZ upgrade without requiring a redesign.
