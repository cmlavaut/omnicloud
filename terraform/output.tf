# Definición del Output para la IP Pública
output "ip_publica_ec2" {
  description = "La dirección IP pública de las instancias EC2 frontend"
  value = [
    for _, m in module.ec2_instance :
    m.public_ip
    if m.public_ip != ""
  ]
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

