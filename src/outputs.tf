output "network_firewall_name" {
  description = "Network Firewall name"
  value       = module.network_firewall.network_firewall_name
}

output "network_firewall_arn" {
  description = "Network Firewall ARN"
  value       = module.network_firewall.network_firewall_arn
}

output "network_firewall_status" {
  description = "Nested list of information about the current status of the Network Firewall"
  value       = module.network_firewall.network_firewall_status
}

output "network_firewall_policy_name" {
  description = "Network Firewall policy name"
  value       = module.network_firewall.network_firewall_policy_name
}

output "network_firewall_policy_arn" {
  description = "Network Firewall policy ARN"
  value       = module.network_firewall.network_firewall_policy_arn
}

output "az_subnet_endpoint_stats" {
  description = "List of objects with each object having three items: AZ, subnet ID, VPC endpoint ID. Only applicable in VPC mode"
  value       = module.network_firewall.az_subnet_endpoint_stats
}

output "transit_gateway_attachment_id" {
  description = "The unique identifier of the transit gateway attachment. Only applicable in Transit Gateway mode"
  value       = module.network_firewall.transit_gateway_attachment_id
}

output "transit_gateway_owner_account_id" {
  description = "The AWS account ID that owns the transit gateway. Only applicable in Transit Gateway mode"
  value       = module.network_firewall.transit_gateway_owner_account_id
}
