output "reniec_public_ip" {
  description = "La IP pública de la instancia "
  value       = aws_instance.reniecdb.public_ip
}
