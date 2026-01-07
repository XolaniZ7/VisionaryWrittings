provider "aws" {
  region = "af-south-1"
}

#########################################################
# IAM Groups
#########################################################

resource "aws_iam_group" "developers" { name = "Developers" }
resource "aws_iam_group" "devops" { name = "DevOps" }
resource "aws_iam_group" "finance" { name = "Finance" }
resource "aws_iam_group" "contractors" { name = "Contractors" }
resource "aws_iam_group" "admins" { name = "Admins" }

############################
# Admins Policy
# - Full admin
# - But require MFA for ALL actions
############################

resource "aws_iam_policy" "admins" {
  name        = "AdminsPolicy"
  description = "Full admin access, but all actions require MFA."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow everything
      {
        Sid      = "AllowAll"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      # Deny if MFA is not present
      {
        Sid    = "DenyAllIfNoMFA"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

############################
# Finance Policy
# - View-only billing / cost reports
############################

resource "aws_iam_policy" "finance" {
  name        = "FinancePolicy"
  description = "Finance can view billing and cost reports, read-only."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewBillingAndCosts"
        Effect = "Allow"
        Action = [
          "aws-portal:ViewBilling",
          "aws-portal:ViewUsage",
          "ce:Get*",
          "ce:Describe*",
          "cur:Describe*",
          "budgets:ViewBudget",
          "budgets:Describe*",
          "organizations:Describe*",
          "organizations:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

############################
# 1) Developers Policy
# - Can read logs
# - Can deploy/manage DEV only (Environment = Dev)
############################

resource "aws_iam_policy" "developers" {
  name        = "DevelopersPolicy"
  description = "Developers can read logs and deploy/manage Dev resources (tagged Environment=Dev), but not Prod."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Logs read-only
      {
        Sid    = "ReadLogs"
        Effect = "Allow"
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:FilterLogEvents",
          "logs:ListTagsLogGroup",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
      },
      # Allow actions for Dev resources only - based on tag Environment=Dev
      {
        Sid    = "DeployAndManageDevOnly"
        Effect = "Allow"
        Action = [
          # Typical deploy-related actions – adjust to your stack
          "ecs:*",
          "ecr:*",
          "lambda:*",
          "cloudformation:*",
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = "Dev"
          }
        }
      }
      # NOTE: There is NO explicit allow on Prod resources,
      # so by default they cannot deploy/manage Prod.
    ]
  })
}


#########################################################
# Custom Read-Only Policy
#########################################################

resource "aws_iam_policy" "readonly_policy" {
  name        = "Readonly-ECS-ECR-RDS-S3-Route53"
  description = "Read-only access to ECS, ECR, RDS, S3 and Route53"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      ############################
      # ECS Read Only
      ############################
      {
        Effect = "Allow",
        Action = [
          "ecs:Describe*",
          "ecs:List*",
          "ecs:Get*",
        ],
        Resource = "*"
      },

      ############################
      # ECR Read Only
      ############################
      {
        Effect = "Allow",
        Action = [
          "ecr:Describe*",
          "ecr:List*",
          "ecr:Get*",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = "*"
      },

      ############################
      # RDS Read Only
      ############################
      {
        Effect = "Allow",
        Action = [
          "rds:Describe*",
          "rds:ListTagsForResource",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots"
        ],
        Resource = "*"
      },

      ############################
      # S3 Read Only
      ############################
      {
        Effect = "Allow",
        Action = [
          "s3:Get*",
          "s3:List*"
        ],
        Resource = "*"
      },

      ############################
      # Route53 Read Only
      ############################
      {
        Effect = "Allow",
        Action = [
          "route53:List*",
          "route53:Get*",
          "route53:TestDNSAnswer"
        ],
        Resource = "*"
      }

    ]
  })
}

############################
# DevOps Policy
# - Can manage ECS/ECR/RDS
# - Explicitly cannot access Billing
############################

resource "aws_iam_policy" "devops" {
  name        = "DevOpsPolicy"
  description = "DevOps can manage ECS, ECR, and RDS but not Billing."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow ECS/ECR/RDS full management
      {
        Sid    = "AllowECSECRRDS"
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "rds:*",
          "route53:*",
          "s3:*",
          "iam:PassRole"      # required for many ECS/RDS operations
        ]
        Resource = "*"
      },
      # Explicitly deny any Billing / Cost Explorer access
      {
        Sid    = "DenyBillingAndCosts"
        Effect = "Deny"
        Action = [
          "aws-portal:*",
          "billing:*",
          "ce:*",
          "cur:*",
          "budgets:*",
          "account:*"
        ]
        Resource = "*"
      }
    ]
  })
}

##########################################################
# Attach Admins Policy to Admins Group
#########################################################
resource "aws_iam_group_policy_attachment" "admins_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.admins.arn
}

##########################################################
# Attach developers Policy to Develpers Group
#########################################################
resource "aws_iam_group_policy_attachment" "developers_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers.arn
}

##########################################################
# Attach Read Only Policy to Contracters Group
#########################################################
resource "aws_iam_group_policy_attachment" "contractors_attach" {
  group      = aws_iam_group.contractors.name
  policy_arn = aws_iam_policy.readonly_policy.arn
}

##########################################################
# Attach finance Policy to Finance Group
#########################################################
resource "aws_iam_group_policy_attachment" "finance_attach" {
  group      = aws_iam_group.finance.name
  policy_arn = aws_iam_policy.finance.arn
}


resource "aws_iam_group_policy_attachment" "devops_attach" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops.arn
}
