resource "aws_sqs_queue" "order_dlq" {
  name                      = "${var.project_name}-order-dlq"
  message_retention_seconds = 1209600 # 14 days, max retention
}

resource "aws_sqs_queue" "order_queue" {
  name                       = "${var.project_name}-order-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount      = 3
  })
}

output "order_queue_url" {
  value = aws_sqs_queue.order_queue.id
}

output "order_queue_arn" {
  value = aws_sqs_queue.order_queue.arn
}

output "order_dlq_arn" {
  value = aws_sqs_queue.order_dlq.arn
}