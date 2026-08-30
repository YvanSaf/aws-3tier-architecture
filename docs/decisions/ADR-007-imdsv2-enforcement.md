# ADR-007: Enforcing IMDSv2 on All EC2 Instances

Date: 2026-08-26
Status: Accepted

## Context

The EC2 Instance Metadata Service (IMDS) is an endpoint available at `http://169.254.169.254` from inside any EC2 instance. It provides information about the instance, including the IAM credentials associated with its instance profile. These credentials are used by the AWS SDK and CLI on the instance to make API calls.

IMDSv1, the original version, allows any process on the instance to query the metadata endpoint with a simple HTTP GET request. This made it vulnerable to Server-Side Request Forgery (SSRF) attacks: if an application running on the instance could be tricked into making HTTP requests to arbitrary URLs, an attacker could point it at `http://169.254.169.254` and retrieve the IAM credentials.

The Capital One breach in 2019 was caused exactly by this type of attack.

## Decision

All three EC2 instances (Bastion, Web Server, App Server) are configured with `http_tokens = "required"` in their `metadata_options` block. This enforces IMDSv2 exclusively and rejects any request that does not include a valid session token obtained through a PUT request first.

## Why This Solution

IMDSv2 adds a session-oriented protocol to the metadata endpoint. Before reading any metadata, the caller must first obtain a session token by making a PUT request. This token is then included in all subsequent GET requests. A simple SSRF attack that causes an HTTP GET to an arbitrary URL cannot obtain this token, because SSRF typically cannot forge PUT requests with the required headers. This makes the metadata endpoint inaccessible to that class of attack.

Enforcing IMDSv2 at the Terraform level means the protection is applied at instance launch time and cannot be disabled by an application or a misconfigured script running on the instance.

## Consequences and Trade-offs

Some older AWS SDKs and tools do not support IMDSv2. If a tool or script running on the instance tries to query the metadata endpoint without a token, the request will be silently rejected. For this project, Amazon Linux 2 with the current AWS CLI version supports IMDSv2 natively, so there is no compatibility issue. The only observable consequence is that the raw `curl http://169.254.169.254/...` command without a token returns nothing, which is the expected and desired behavior.
