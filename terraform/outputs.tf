output "wiki-dns" {
  description = "Instructions to set up the wiki.artis3nal.com domain."
  value       = "SSH onto the new server with Session Manager and run the '/home/wiki/cert.sh' script to set up Let's Encrypt."
}

output "wiki-instance-id" {
  description = "Instance ID to use for AWS Session Manager connections."
  value       = aws_spot_instance_request.wiki.spot_instance_id
}
