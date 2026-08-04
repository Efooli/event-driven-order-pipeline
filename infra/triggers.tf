# --- SQS triggers the Order Processor ---
resource "aws_lambda_event_source_mapping" "order_queue_to_processor" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.order_processor.arn
  batch_size       = 1 # keep simple for the demo — one message per invocation
}

# --- SNS fans out to Notifier and Inventory Updater ---
resource "aws_sns_topic_subscription" "notifier_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifier.arn
}

resource "aws_sns_topic_subscription" "inventory_updater_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.inventory_updater.arn
}

# --- Permissions: allow SNS to invoke each subscribed Lambda ---
resource "aws_lambda_permission" "allow_sns_notifier" {
  statement_id  = "AllowSNSInvokeNotifier"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.order_events.arn
}

resource "aws_lambda_permission" "allow_sns_inventory_updater" {
  statement_id  = "AllowSNSInvokeInventoryUpdater"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory_updater.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.order_events.arn
}