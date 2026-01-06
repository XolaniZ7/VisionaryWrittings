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
  region = "af-south-1"
  # profile = var.aws_profile
}

locals {
  required_tags_null_condition = {
    Null = {
      "aws:RequestTag/Name"        = "true"
      "aws:RequestTag/Team"        = "true"
      "aws:RequestTag/Environment" = "true"
      "aws:RequestTag/Automation"  = "true"
    }
  }
}

resource "aws_iam_policy" "require_standard_tags_daily" {
  name        = "Require-Standard-Tags-Daily"
  description = "Require Name/Team/Environment/Automation tags for common daily services (separated statements, single policy)."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ============================================================
      # EC2: Require tags on INSTANCE creation only (avoid ENI pain)
      # ============================================================
      {
        Sid    = "EC2DenyRunInstancesWithoutRequiredTags"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = [
          "arn:aws:ec2:*:*:instance/*"
        ]
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # EBS: Require tags when volumes/snapshots are created directly
      # (Note: volumes created implicitly during RunInstances are NOT
      # blocked by this, because we are not scoping RunInstances to volume/*)
      # ============================================================
      {
        Sid    = "EC2DenyCreateVolumeWithoutRequiredTags"
        Effect = "Deny"
        Action = "ec2:CreateVolume"
        Resource = [
          "arn:aws:ec2:*:*:volume/*"
        ]
        Condition = local.required_tags_null_condition
      },
      {
        Sid    = "EC2DenyCreateSnapshotWithoutRequiredTags"
        Effect = "Deny"
        Action = "ec2:CreateSnapshot"
        Resource = [
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # RDS/Aurora: Require tags on DB instance/cluster create
      # ============================================================
      {
        Sid    = "RDSDenyCreateDBInstanceWithoutRequiredTags"
        Effect = "Deny"
        Action = "rds:CreateDBInstance"
        Resource = [
          "arn:aws:rds:*:*:db:*"
        ]
        Condition = local.required_tags_null_condition
      },
      {
        Sid    = "RDSDenyCreateDBClusterWithoutRequiredTags"
        Effect = "Deny"
        Action = "rds:CreateDBCluster"
        Resource = [
          "arn:aws:rds:*:*:cluster:*"
        ]
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # Lambda: Require tags on function create
      # ============================================================
      {
        Sid    = "LambdaDenyCreateFunctionWithoutRequiredTags"
        Effect = "Deny"
        Action = "lambda:CreateFunction"
        Resource = [
          "arn:aws:lambda:*:*:function:*"
        ]
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # ECR: Require tags on repo create
      # ============================================================
      {
        Sid    = "ECRDenyCreateRepositoryWithoutRequiredTags"
        Effect = "Deny"
        Action = "ecr:CreateRepository"
        Resource = "*"
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # ECS: Require tags on cluster create
      # (Task definition registration can be noisy; keep it out unless needed)
      # ============================================================
      {
        Sid    = "ECSDenyCreateClusterWithoutRequiredTags"
        Effect = "Deny"
        Action = "ecs:CreateCluster"
        Resource = "*"
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # EKS: Require tags on cluster/nodegroup create
      # ============================================================
      {
        Sid    = "EKSDenyCreateClusterWithoutRequiredTags"
        Effect = "Deny"
        Action = "eks:CreateCluster"
        Resource = "*"
        Condition = local.required_tags_null_condition
      },
      {
        Sid    = "EKSDenyCreateNodegroupWithoutRequiredTags"
        Effect = "Deny"
        Action = "eks:CreateNodegroup"
        Resource = "*"
        Condition = local.required_tags_null_condition
      },

      # ============================================================
      # S3: Enforce tagging on buckets via PutBucketTagging
      # (CreateBucket tag-on-create is inconsistent; this is safer)
      # ============================================================
      {
        Sid    = "S3DenyPutBucketTaggingWithoutRequiredTags"
        Effect = "Deny"
        Action = "s3:PutBucketTagging"
        Resource = "arn:aws:s3:::*"
        Condition = local.required_tags_null_condition
      }
    ]
  })
}

resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group_policy_attachment" "attach_require_standard_tags_daily" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.require_standard_tags_daily.arn
}
