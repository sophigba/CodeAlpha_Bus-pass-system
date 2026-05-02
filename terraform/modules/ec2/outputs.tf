# terraform/modules/ec2/outputs.tf

output "asg_name" {
  description = "Auto Scaling Group name passed to ALB"
  value       = aws_autoscaling_group.buspass_asg.name
}
