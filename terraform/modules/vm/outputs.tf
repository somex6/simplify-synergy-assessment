output "arn" {
  description = "The ARN of the instance"
  value       = aws_instance.this.arn
}