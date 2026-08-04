resource "aws_sns_topic" "order_events" {
  name = "${var.project_name}-order-events"
}

output "order_events_topic_arn" {
  value = aws_sns_topic.order_events.arn
}