variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  type = map(string)
  default = {
    dev  = "t3.small"
    qa   = "t3.small"
    prod = "t3.medium"
  }
}

variable "rds_type" {
  default = "db.t3.micro"
}

variable "storage" {
  default = 20
}

variable "dbname" {
  default = "movie_db"
}

variable "dbusername" {
  type      = string
  sensitive = true
}

variable "dbpassword" {
  type      = string
  sensitive = true
}

variable "imgec2" {
  default = "ami-0c1fe732b5494dc14"
}


variable "cpu_threshold" {
  default = 80
}

variable "memory_threshold" {
  default = 80
}

variable "disk_threshold" {
  default = 85
}