## cat > terraform/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "tech-exercise"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "tech-exercise-cluster"
}

variable "mongodb_user" {
  description = "MongoDB username"
  type        = string
  default     = "mongouser"
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  default     = "SuperSecure123!"
  sensitive   = true
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = "todoapp"
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "tech-exercise-key"
}

variable "your_name" {
  description = "Your name for the proexercise.txt file"
  type        = string
  default     = "Your Name Here"
}
