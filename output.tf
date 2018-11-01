output "key_name" {
  value       = "${join("", aws_key_pair.generated.*.key_name)}"
  description = "Name of SSH key"
}

output "public_key" {
  value       = "${join("", tls_private_key.default.*.public_key_openssh)}"
  description = "Contents of the generated public key"
}
