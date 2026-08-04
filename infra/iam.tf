# Trust policy shared by all Lambda roles — allows the Lambda service to assume the role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- Order API role ---
resource "aws_iam_role" "order_api" {
  name               = "${var.project_name}-order-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "order_api_permissions" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.order_queue.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "order_api_permissions" {
  name   = "${var.project_name}-order-api-permissions"
  role   = aws_iam_role.order_api.id
  policy = data.aws_iam_policy_document.order_api_permissions.json
}

# --- Order Processor role ---
resource "aws_iam_role" "order_processor" {
  name               = "${var.project_name}-order-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "order_processor_permissions" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.order_queue.arn]
  }
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [aws_dynamodb_table.orders.arn]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.order_events.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "order_processor_permissions" {
  name   = "${var.project_name}-order-processor-permissions"
  role   = aws_iam_role.order_processor.id
  policy = data.aws_iam_policy_document.order_processor_permissions.json
}

# --- Notifier role ---
resource "aws_iam_role" "notifier" {
  name               = "${var.project_name}-notifier-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "notifier_permissions" {
  statement {
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"] # SES doesn't support resource-level restriction for sending
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "notifier_permissions" {
  name   = "${var.project_name}-notifier-permissions"
  role   = aws_iam_role.notifier.id
  policy = data.aws_iam_policy_document.notifier_permissions.json
}

# --- Inventory Updater role ---
resource "aws_iam_role" "inventory_updater" {
  name               = "${var.project_name}-inventory-updater-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "inventory_updater_permissions" {
  statement {
    actions   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
    resources = [aws_dynamodb_table.orders.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "inventory_updater_permissions" {
  name   = "${var.project_name}-inventory-updater-permissions"
  role   = aws_iam_role.inventory_updater.id
  policy = data.aws_iam_policy_document.inventory_updater_permissions.json
}