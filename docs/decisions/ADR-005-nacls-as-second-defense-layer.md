# ADR-005: Network ACLs as a Second Layer of Network Defense

Date: 2026-08-26
Status: Accepted

## Context

AWS Security Groups already control traffic at the instance level. The question was whether to also configure Network ACLs (NACLs), which operate at the subnet level. Many architectures skip NACLs because Security Groups alone are sufficient for basic access control, and NACLs add complexity (they are stateless, so return traffic must be explicitly allowed).

## Decision

I configured dedicated NACLs for each subnet tier: one for the public subnet, one for the app subnet, and one shared between the two database subnets. Each NACL only allows the traffic that its tier actually needs and blocks everything else by default.

## Why This Solution

Security Groups and NACLs serve different purposes and operate at different levels. Security Groups are stateful and work at the instance level. NACLs are stateless and work at the subnet boundary. Using both creates a defense-in-depth architecture where two independent controls must both allow a connection before it can succeed.

In practice, this means that even if a Security Group rule were accidentally misconfigured to allow too much traffic, the NACL would still enforce the subnet-level boundary. The two controls are independent: compromising one does not compromise the other.

NACLs also make the network intent explicit and auditable at the infrastructure level. Looking at the NACL rules alone, someone reviewing the infrastructure can immediately understand what traffic is expected to flow between tiers, without needing to trace Security Group references.

## Consequences and Trade-offs

NACLs are stateless, which means every allowed flow requires both an inbound and an outbound rule, including the return traffic on ephemeral ports (1024-65535). This makes the rules more verbose than Security Group rules. It also means that misconfiguring ephemeral port ranges can break connectivity in ways that are not immediately obvious. The trade-off is acceptable because the added visibility and the second layer of enforcement outweigh the extra configuration effort.
