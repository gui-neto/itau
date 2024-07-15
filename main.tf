provider "aws" {
  region = "us-east-2"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = "vpc-0fbd412b6204e756f"
  cidr_block        = "172.31.48.0/20"  # Novo CIDR block para evitar conflito
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = "vpc-0fbd412b6204e756f"
  cidr_block        = "172.31.64.0/20"  # Novo CIDR block para evitar conflito
  availability_zone = "us-east-2c"
}

# Removendo a criação do Internet Gateway, já existe um associado ao VPC
# resource "aws_internet_gateway" "igw" {
#   vpc_id = "vpc-0fbd412b6204e756f"
# }

resource "aws_route_table" "routetable" {
  vpc_id = "vpc-0fbd412b6204e756f"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-076984785dd450113"  # Substitua por ID correto do Internet Gateway
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.routetable.id
}

# Security Group
resource "aws_security_group" "sg" {
  vpc_id = "vpc-0fbd412b6204e756f"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "flask-cluster"
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_execution_role_new" {
  name = "ecs_task_execution_role_new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role_new.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Definition
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_new.arn

  container_definitions = jsonencode([
    {
      name      = "flask-app"
      image     = var.docker_image
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    }
  ])
}

# Load Balancer
resource "aws_lb" "flask_lb_new" {
  name               = "flask-lb-new"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = var.subnets
}

resource "aws_lb_target_group" "flask_tg_new" {
  name        = "flask-tg-new"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "flask_listener" {
  load_balancer_arn = aws_lb.flask_lb_new.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg_new.arn
  }
}

# ECS Service
resource "aws_ecs_service" "flask_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.flask_tg_new.arn
    container_name   = "flask-app"
    container_port   = 5000
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"  # AMI compatível com x86_64
  instance_type = "t2.micro"
  key_name      = "itau"  # Par de chaves fornecido
}
