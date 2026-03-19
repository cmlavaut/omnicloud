locals {
  env = terraform.workspace

  base_env = {
    backend = {
      name      = "backend"
      subnet_id = module.vpc.private_subnets[0]
      sg_ids    = [module.backend_sg.security_group_id]
      public    = false
      role      = "backend"
    }
    hostjump = {
      name      = "hostjump"
      subnet_id = module.vpc.public_subnets[1]
      sg_ids    = [module.management_sg.security_group_id]
      public    = true
      role      = "host"
    }
  }

  ec2_instances_by_env = {
    dev  = local.base_env
    qa   = local.base_env
    prod = local.base_env
  }

  ec2_instances = local.ec2_instances_by_env[local.env]
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "app-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.100.0/24", "10.10.200.0/24"]

  public_subnet_names = [
    "app-vpc-pub1",
    "app-vpc-pub2"
  ]

  private_subnet_names = [
    "app-vpc-priv1",
    "app-vpc-priv2"
  ]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true

  nat_gateway_tags = {
    Name = "nat-app-vpc"
  }

  igw_tags = {
    Name = "igw-app-vpc"
  }
}

module "management_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "management_sg"
  description = "Allow conection to management subnet"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow management SSH"
      cidr_blocks = "189.203.206.98/32"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Allow jenkisnserver"
      cidr_blocks = "189.203.206.98/32"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "management_sg"
  }
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb_sg"
  description = "Allow HTTP to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = {
    Name = "alb_sg"
  }
}

module "frontend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "frontend_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      from_port                = 3030
      to_port                  = 3030
      protocol                 = "tcp"
      description              = "Allow HTTP"
      source_security_group_id = module.alb_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "Allow SSH"
      source_security_group_id = module.management_sg.security_group_id
    },
    {
      from_port                = 8
      to_port                  = 0
      protocol                 = "icmp"
      description              = "Allow ICMP (ping)"
      source_security_group_id = module.management_sg.security_group_id
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH"
      cidr_blocks = "189.203.206.98/32"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "frontend_sg"
  }
}

module "backend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "backend_sg"
  description = "Allow conection to backend EC2"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Allow backend"
      source_security_group_id = module.frontend_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "Allow SSH"
      source_security_group_id = module.management_sg.security_group_id
    },
    {
      from_port                = 8
      to_port                  = 0
      protocol                 = "icmp"
      description              = "Allow ICMP (ping)"
      source_security_group_id = module.management_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "backend_sg"
  }
}
module "database_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "database_sg"
  description = "Allow conection to Database Amazon RDS"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Allow database conection"
      source_security_group_id = module.backend_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "Allow HTTP"
      source_security_group_id = module.management_sg.security_group_id
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Allow database conection"
      source_security_group_id = module.management_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "database_sg"
  }
}


#Creando la key y las EC2 como servers
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-terraform-key"
  public_key = file("/home/camila/.ssh/ec2_terraform.pub")
}

resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-${local.env}"
  image_id      = var.imgec2
  instance_type = local.instance_type
  key_name      = aws_key_pair.ec2_key.key_name

  vpc_security_group_ids = [module.frontend_sg.security_group_id]
  iam_instance_profile {
    name = "kmi-SSMEC2"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "frontend-${local.env}"
      Role        = "frontend"
      Environment = local.env
    }
  }
}

resource "aws_autoscaling_group" "frontend" {
  name = "${local.env}-frontend-asg"

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  target_group_arns = [module.alb.target_groups["web_tg"].arn]
}

#Crear el ALB
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.name_prefix}-alb"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  load_balancer_type         = "application"
  internal                   = false
  create_security_group      = false
  security_groups            = [module.alb_sg.security_group_id]
  enable_deletion_protection = false

  # Listener HTTP
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "web_tg"
      }
    }
  }

  # Target Group
  target_groups = {
    web_tg = {
      protocol          = "HTTP"
      port              = 3030
      target_type       = "instance"
      create_attachment = false

      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
  tags = local.tags
}

module "ec2_instance" {
  for_each = local.ec2_instances
  source   = "terraform-aws-modules/ec2-instance/aws"

  name                   = each.value.name
  instance_type          = local.instance_type
  ami                    = var.imgec2
  iam_instance_profile   = "kmi-SSMEC2"
  create_security_group  = false
  key_name               = aws_key_pair.ec2_key.key_name
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.sg_ids
  associate_public_ip_address = contains(
    module.vpc.public_subnets,
    each.value.subnet_id
  )
  root_block_device = {
    type      = "gp3"
    size      = 20
    encrypted = true
  }

  tags = {
    Name        = each.value.name
    Role        = each.value.role
    Environment = local.env
  }
}

resource "aws_db_subnet_group" "appdb" {
  name = "appdb-group"
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

  tags = {
    Name = "appdb-group"
  }
}

#Creando la Database RDS
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "appdb"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.rds_type
  allocated_storage = var.storage

  db_name  = var.dbname
  username = var.dbusername
  port     = "3306"

  iam_database_authentication_enabled = true
  family                              = "mysql8.0"
  major_engine_version                = "8.0"
  multi_az                            = true
  db_subnet_group_name                = aws_db_subnet_group.appdb.name
  vpc_security_group_ids              = [module.database_sg.security_group_id]
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
  enabled_cloudwatch_logs_exports     = ["general"]
  create_cloudwatch_log_group         = true
  skip_final_snapshot                 = true
  deletion_protection                 = false

  tags = {
    Name = "appdb"
  }
}

#crear metricas con CloudWatch para monitoreo de frontend EC2
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high-${local.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "memory-high-${local.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "disk-high-${local.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
    path                 = "/"
    fstype               = "xfs"
  }
}