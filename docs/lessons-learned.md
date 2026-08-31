# Lessons Learned

This document captures the real problems I ran into while building and testing this project, and what I learned from each one.

---

## 1. Circular dependency in Security Group rules

**What happened:** Terraform threw a `Cycle` error when I tried to apply the configuration. The error message pointed to my Security Groups, but it was not immediately obvious what was wrong.

**Root cause:** I had declared Security Group rules as inline `ingress` and `egress` blocks inside each `aws_security_group` resource. The rules referenced other Security Groups as sources or destinations (`security_groups = [aws_security_group.app.id]`). This created a dependency loop: `web` needed `app` to exist before it could be created, and `app` needed `web` to exist before it could be created. Terraform cannot resolve this.

**Fix:** I separated the Security Group definitions from their rules. The `security_groups.tf` file now declares the four Security Groups with no rules attached. A separate file, `security_group_rules.tf`, uses `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources to attach the rules after all Security Groups are created. Since the rules are separate resources, Terraform can create the Security Groups first (no dependencies between them), then add the rules (which can now reference already-existing Group IDs).

**Takeaway:** When Security Groups reference each other, always declare them empty first and attach rules separately. This is a well-known Terraform pattern for Security Group chains, and I will apply it by default from now on.

---

## 2. AWS Secrets Manager blocked in the sandbox

**What happened:** `terraform apply` failed with `AccessDenied: User is not authorized to perform: secretsmanager:CreateSecret`. The sandbox IAM role does not include Secrets Manager permissions.

**Root cause:** The Vocareum lab environment uses a restricted IAM role (`voclabs`) that only grants access to a defined list of services. Secrets Manager is not on that list.

**Fix:** I added a feature flag (`enable_secrets_manager = false`) that disables the Secrets Manager resources when set to false. The `random_password` resource still generates a strong password, which is used directly in the RDS configuration and accessible via `terraform output -raw db_password` as a secure fallback. The Secrets Manager code remains in the project, documented, and ready to enable on a full-permission account.

**Takeaway:** When working in a constrained environment (sandbox, limited IAM role, organizational SCP), it is worth checking which services are actually available before writing code that depends on them. Feature flags are a clean way to keep the full intent of the architecture visible even when some parts cannot be deployed in every environment.

---

## 3. VPC Flow Logs blocked by missing iam:PassRole

**What happened:** Flow Log creation failed with `not authorized to perform: iam:PassRole on resource: arn:aws:iam::...:role/LabRole`. Even though I was using the pre-existing LabRole (not creating a new one), the sandbox policy still blocks passing that role to the Flow Logs service.

**Root cause:** Creating a VPC Flow Log that writes to CloudWatch requires AWS to grant the Flow Logs service permission to write to the Log Group on your behalf. This happens through `iam:PassRole`, which allows your principal to hand a role to an AWS service. The Vocareum sandbox IAM policy explicitly blocks this action.

**Fix:** Same approach as Secrets Manager: a feature flag (`enable_flow_logs = false`) disables the three related resources (`aws_cloudwatch_log_group`, `data.aws_iam_role`, `aws_flow_log`) in the sandbox. Setting the flag to `true` on a full-permission account re-enables them with no code changes.

**Takeaway:** `iam:PassRole` is a frequently restricted permission in enterprise and sandbox environments. It is not enough to avoid creating new IAM roles; passing an existing role to an AWS service also requires an explicit permission grant.

---

## 4. AWS API rejects non-ASCII characters in Security Group rule descriptions

**What happened:** After fixing the cycle issue, `terraform apply` failed on Security Group rule creation with `InvalidParameterValue: Invalid rule description. Valid descriptions are strings less than 256 characters from the following set: a-zA-Z0-9. _-:/()#,@[]+=&;{}!$*`.

**Root cause:** Some rule descriptions contained an em dash character (the long dash `\u2014`), which looks like a normal dash but is not in the allowed character set for AWS Security Group descriptions.

**Fix:** I replaced all em dashes in description strings with a regular hyphen or rephrased the sentence to avoid the character entirely.

**Takeaway:** AWS API character restrictions are strict and sometimes silent at the Terraform planning stage (the plan passes, the apply fails). When writing descriptions for AWS resources, stick to plain ASCII characters. This also applies to tags, resource names, and any other string field sent to the AWS API.

---

## 5. Missing output for App Server instance ID

**What happened:** After a successful `terraform apply`, I tried to connect to the App Server using `aws ssm start-session --target $(terraform output -raw app_instance_id)` and got an error: output `app_instance_id` does not exist.

**Root cause:** I had defined `bastion_instance_id` as an output but forgot to add the equivalent for the App Server. The App Server only had an `app_server_private_ip` output, which is not what `aws ssm start-session` needs.

**Fix:** I added `app_instance_id` to `outputs.tf`. Rerunning `terraform apply` updated the state without recreating any resources and made the output available.

**Takeaway:** When defining outputs, think about what a user cloning this repo actually needs to run to test the deployment, not just what seems useful. For SSM access, the instance ID is essential. Checking that all outputs map to real operational needs avoids this kind of friction.

---

## 6. SSM Session Manager plugin is a separate install

**What happened:** After the infrastructure was deployed and the IAM permissions were correct, running `aws ssm start-session` failed with an error about a missing plugin.

**Root cause:** The `aws ssm start-session` command requires the AWS Systems Manager Session Manager Plugin, which is a separate binary from the AWS CLI. The AWS CLI itself cannot open SSM sessions without it.

**Fix:** I installed the Session Manager Plugin from the AWS documentation page. After installation, `aws ssm start-session` worked immediately.

**Takeaway:** Document all local prerequisites clearly in the project README, not just the AWS-side requirements. Anyone cloning the project should be able to find the plugin installation instructions without having to debug a cryptic error message.
