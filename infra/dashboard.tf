resource "aws_cloudwatch_dashboard" "order_pipeline" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Queue depth (main vs DLQ)"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.order_queue.name, { label = "Main queue" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.order_dlq.name, { label = "Dead-letter queue" }]
          ]
          period = 60
          stat   = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Lambda errors by function"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.order_api.function_name, { label = "Order API" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.order_processor.function_name, { label = "Order Processor" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.notifier.function_name, { label = "Notifier" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.inventory_updater.function_name, { label = "Inventory Updater" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Order Processor p99 latency"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.order_processor.function_name, { stat = "p99" }]
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Lambda invocations by function"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.order_api.function_name, { label = "Order API" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.order_processor.function_name, { label = "Order Processor" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.notifier.function_name, { label = "Notifier" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.inventory_updater.function_name, { label = "Inventory Updater" }]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}

output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.order_pipeline.dashboard_name}"
}