terraform {
    required_version = ">= 1.0.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region  = "af-south-1"
    # profile = var.aws_profile
}

variable "scp_target_id" {
    description = "Organization root/OU/account ID to attach the SCP to (e.g. r-xxxx or ou-xxxxx or 123456789012)"
    type        = string
    # Khoi tech AWS Account ID
    # default     = "899824927281" 
    default = "854924711147"
}

variable "required_tag_keys" {
    description = "List of tag keys required on resource-creating API calls"
    type        = list(string)
    default     = ["Name", "Team", "Environment", "Automation"]
}

# Service Control Policy enforcing that resource-creation APIs must include required tags.
# Attach this policy to a root / OU / account via scp_target_id.
resource "aws_organizations_policy" "tagging_standards" {
  name        = "Require-Tags-SCP"
  description = "Deny creation of resources when required tags are not provided"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      # Name
      {
        Sid      = "DenyCreateWithoutNameTag"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/Name" = "true"
          }
        }
      },
      # Team
      {
        Sid      = "DenyCreateWithoutTeamTag"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/Team" = "true"
          }
        }
      },
      # Environment
      {
        Sid      = "DenyCreateWithoutEnvironmentTag"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/Environment" = "true"
          }
        }
      },
      # Automation
      {
        Sid      = "DenyCreateWithoutAutomationTag"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/Automation" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "attach_tagging_scp" {
    policy_id = aws_organizations_policy.tagging_standards.id
    target_id = var.scp_target_id
}