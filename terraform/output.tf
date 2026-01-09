## cat > terraform/outputs.tf << 'EOF'
output "mongodb_vm_public_ip" {
  description = "Public IP of MongoDB VM"
  value       = aws_instance.mongodb_vm.public_ip
}

output "mongodb_vm_private_ip" {
  description = "Private IP of MongoDB VM"
  value       = aws_instance.mongodb_vm.private_ip
}

output "mongodb_connection_string" {
  description = "MongoDB connection string for application"
  value       = "mongodb://${var.mongodb_user}:${var.mongodb_password}@${aws_instance.mongodb_vm.private_ip}:27017/${var.mongodb_database}"
  sensitive   = true
}

output "s3_backup_bucket" {
  description = "S3 bucket for MongoDB backups"
  value       = aws_s3_bucket.backups.id
}

output "s3_backup_bucket_public_url" {
  description = "Public URL to S3 bucket"
  value       = "https://${aws_s3_bucket.backups.id}.s3.amazonaws.com"
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "security_hub_url" {
  description = "AWS Security Hub console URL"
  value       = "https://console.aws.amazon.com/securityhub/home?region=${var.aws_region}"
}

output "guardduty_url" {
  description = "AWS GuardDuty console URL"
  value       = "https://console.aws.amazon.com/guardduty/home?region=${var.aws_region}"
}

output "ssh_command" {
  description = "SSH command to access MongoDB VM"
  value       = "ssh -i ~/.ssh/tech-exercise-key.pem ubuntu@${aws_instance.mongodb_vm.public_ip}"
}
