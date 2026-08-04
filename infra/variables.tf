variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for resource names"
  type        = string
  default     = "order-pipeline"
}

variable "alert_email" {
  description = "Email address to receive operational alerts"
  type        = string
}