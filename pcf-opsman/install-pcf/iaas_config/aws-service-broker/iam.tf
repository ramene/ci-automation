# Users
resource "aws_iam_user" "aws_service_broker_iam_user" {
    name = "${var.environment}_aws_service_broker_iam_user"
    path = "/system/"
}
resource "aws_iam_access_key" "aws_service_broker_iam_user_access_key" {
    user = "${aws_iam_user.aws_service_broker_iam_user.name}"
}
resource "aws_iam_user_policy_attachment" "AWS_service_broker_AdminPolicy_role_attach" {
    user = "${aws_iam_user.aws_service_broker_iam_user.name}"
    policy_arn = "${aws_iam_policy.aws_service_broker_policy.arn}"
}

# Policies
resource "aws_iam_policy" "aws_service_broker_policy" {
    name = "PCFInstallationPolicy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:PutBucketAcl",
                "s3:PutBucketLogging",
                "s3:PutBucketTagging",
                "s3:GetObject",
                "s3:ListBucket",
                "iam:CreateAccessKey",
                "iam:CreateUser",
                "iam:GetUser",
                "iam:GetPolicy",
                "iam:DeleteAccessKey",
                "iam:DeleteUser",
                "iam:DeleteUserPolicy",
                "iam:ListAccessKeys",
                "iam:ListAttachedUserPolicies",
                "iam:PutUserPolicy",
                "rds:CreateDBCluster",
                "rds:CreateDBInstance",
                "rds:DeleteDBCluster",
                "rds:DeleteDBInstance",
                "rds:DescribeDBClusters",
                "rds:DescribeDBInstances",
                "rds:DescribeDBSnapshots",
                "rds:DeleteDBSnapshot",
                "rds:CreateDBParameterGroup",
                "rds:ModifyDBParameterGroup",
                "rds:DeleteDBParameterGroup",
                "dynamodb:ListTables",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "sqs:CreateQueue",
                "sqs:DeleteQueue"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "aws_service_broker_policy_rds" {
    name = "PCFAppDeveloperPolicy-rds"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1471636048000",
            "Effect": "Allow",
            "Action": [
                "rds:ListTagsForResource",
                "rds:DescribeDbInstances"
            ],
            "Resource": [
                "arn:aws:broker:resource::"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "aws_service_broker_policy_s3" {
    name = "PCFAppDeveloperPolicy-s3"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "allowtagging",
          "Effect": "Allow",
          "Action": [
              "s3:GetBucketTagging",
              "s3:PutBucketTagging"
          ],
          "Resource": [
              "arn:aws:broker:resource::"
          ]
       }
   ]
}
EOF
}

resource "aws_iam_policy" "aws_service_broker_policy_sqs" {
    name = "PCFAppDeveloperPolicy-sqs"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1471890189000",
            "Effect": "Allow",
            "Action": [
                "sqs:ListQueues",
                "sqs:PurgeQueue",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
            ],
            "Resource": [
                "arn:aws:broker:resource::"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_policy" "aws_service_broker_policy_dynamodb" {
    name = "PCFAppDeveloperPolicy-dynamodb"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1471873911000",
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": [
                "arn:aws:broker:resource::"
            ]
        }
    ]
}
EOF
}
