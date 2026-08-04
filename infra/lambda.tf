# --- Package each Lambda's code + node_modules into a zip ---
data "archive_file" "order_api" {
  type        = "zip"
  source_dir  = "${path.module}/../services/order-api"
  output_path = "${path.module}/build/order-api.zip"
}

data "archive_file" "order_processor" {
  type        = "zip"
  source_dir  = "${path.module}/../services/order-processor"
  output_path = "${path.module}/build/order-processor.zip"
}

data "archive_file" "notifier" {
  type        = "zip"
  source_dir  = "${path.module}/../services/notifier"
  output_path = "${path.module}/build/notifier.zip"
}

data "archive_file" "inventory_updater" {
  type        = "zip"
  source_dir  = "${path.module}/../services/inventory-updater"
  output_path = "${path.module}/build/inventory-updater.zip"
}

# --- Order API Lambda ---
resource "aws_lambda_function" "order_api" {
  function_name    = "${var.project_name}-order-api"
  role              = aws_iam_role.order_api.arn
  handler           = "index.handler"
  runtime           = "nodejs20.x"
  timeout           = 10
  filename          = data.archive_file.order_api.output_path
  source_code_hash  = data.archive_file.order_api.output_base64sha256

  environment {
    variables = {
      ORDER_QUEUE_URL = aws_sqs_queue.order_queue.id
    }
  }
}

# --- Order Processor Lambda ---
resource "aws_lambda_function" "order_processor" {
  function_name    = "${var.project_name}-order-processor"
  role              = aws_iam_role.order_processor.arn
  handler           = "index.handler"
  runtime           = "nodejs20.x"
  timeout           = 15
  filename          = data.archive_file.order_processor.output_path
  source_code_hash  = data.archive_file.order_processor.output_base64sha256

  environment {
    variables = {
      ORDERS_TABLE_NAME      = aws_dynamodb_table.orders.name
      ORDER_EVENTS_TOPIC_ARN = aws_sns_topic.order_events.arn
    }
  }
}

# --- Notifier Lambda ---
resource "aws_lambda_function" "notifier" {
  function_name    = "${var.project_name}-notifier"
  role              = aws_iam_role.notifier.arn
  handler           = "index.handler"
  runtime           = "nodejs20.x"
  timeout           = 10
  filename          = data.archive_file.notifier.output_path
  source_code_hash  = data.archive_file.notifier.output_base64sha256

  environment {
    variables = {
      SENDER_EMAIL = "orders@example.com" # update once you verify a real address in SES
    }
  }
}

# --- Inventory Updater Lambda ---
resource "aws_lambda_function" "inventory_updater" {
  function_name    = "${var.project_name}-inventory-updater"
  role              = aws_iam_role.inventory_updater.arn
  handler           = "index.handler"
  runtime           = "nodejs20.x"
  timeout           = 10
  filename          = data.archive_file.inventory_updater.output_path
  source_code_hash  = data.archive_file.inventory_updater.output_base64sha256

  environment {
    variables = {
      ORDERS_TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }
}

output "order_api_function_name" {
  value = aws_lambda_function.order_api.function_name
}