output "wiki-dns" {
  description = "Instructions to set up the wiki.artis3nal.com domain."
  value = "SSH onto the new server with Session Manager and run the 'register-domain' command to set up Let's Encrypt."
//  value       = "Set up wiki.artis3nal.com with the following command: sudo certbot run -a manual -i nginx -d wiki.artis3nal.com --preferred-challenges dns"
}
