output "minecraft_server_public_ip" {
  description = "Public IP address of the Minecraft server"
  value       = aws_instance.minecraft_server.public_ip
}

output "minecraft_server_public_dns" {
  description = "Public DNS name of the Minecraft server"
  value       = aws_instance.minecraft_server.public_dns
}

output "minecraft_server_connection_command" {
  description = "Command to test Minecraft server connection"
  value       = "nmap -sV -Pn -p T:25565 ${aws_instance.minecraft_server.public_ip}"
}

output "minecraft_server_address" {
  description = "Minecraft server address for client connection"
  value       = "${aws_instance.minecraft_server.public_ip}:25565"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.minecraft_server.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.minecraft_sg.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.minecraft_vpc.id
} 