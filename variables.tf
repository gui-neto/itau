variable "docker_image" {
  description = "Docker image for Flask app"
  type        = string
}

variable "subnets" {
  description = "Subnets for ECS tasks"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for ECS tasks"
  type        = string
}
