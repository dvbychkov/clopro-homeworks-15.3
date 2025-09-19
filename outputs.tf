output "public_vm_external_ip" {
  value = yandex_compute_instance.public_vm.network_interface.0.nat_ip_address
}

output "public_vm_internal_ip" {
  value = yandex_compute_instance.public_vm.network_interface.0.ip_address
}

output "private_vm_internal_ip" {
  value = yandex_compute_instance.private_vm.network_interface.0.ip_address
}

output "nat_instance_external_ip" {
  value = yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address
}

output "nat_instance_internal_ip" {
  value = yandex_compute_instance.nat_instance.network_interface.0.ip_address
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = yandex_kms_symmetric_key.bucket_key.id
}

output "kms_key_name" {
  description = "Name of the KMS encryption key"
  value       = yandex_kms_symmetric_key.bucket_key.name
}

output "kms_key_algorithm" {
  description = "Encryption algorithm used by KMS key"
  value       = yandex_kms_symmetric_key.bucket_key.default_algorithm
}

output "bucket_name" {
  description = "Name of the encrypted storage bucket"
  value       = yandex_storage_bucket.my_bucket.id
}

output "bucket_domain_name" {
  description = "Domain name of the encrypted storage bucket"
  value       = yandex_storage_bucket.my_bucket.bucket_domain_name
}

output "picture_url" {
  description = "Public URL of the uploaded picture (stored encrypted)"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.my_bucket.id}/${yandex_storage_object.picture.key}"
}

output "bucket_encryption_status" {
  description = "Encryption status of the bucket"
  value       = "Encrypted with KMS key: ${yandex_kms_symmetric_key.bucket_key.name}"
}

output "instance_group_id" {
  description = "ID of the instance group"
  value       = yandex_compute_instance_group.lamp_group.id
}

output "load_balancer_ip" {
  description = "External IP of the load balancer"
  value       = tolist(tolist(yandex_lb_network_load_balancer.lamp_lb.listener)[0].external_address_spec)[0].address
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${tolist(tolist(yandex_lb_network_load_balancer.lamp_lb.listener)[0].external_address_spec)[0].address}"
}
