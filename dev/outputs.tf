output "ec2_instance_id" {
  description = "The ID of the EC2 instance (use this for SSM connection)"
  value       = module.ec2_app.instance_id
}

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2_app.public_ip
}
