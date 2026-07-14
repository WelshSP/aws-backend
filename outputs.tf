output "developer_private_key" {
  description = "The private key data for the developer's sandbox access. Save this as a .pem file!"
  value       = tls_private_key.developer_key.private_key_pem
  sensitive   = true
}