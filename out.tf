output "tf-admin-node-ip" {
  value = "${scaleway_server.tf-admin-node.public_ip}"
}
