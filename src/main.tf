locals {
  enabled         = module.this.enabled
  logging_enabled = local.enabled && var.logging_enabled

  # Determine deployment mode
  # Either 'vpc' or 'transit_gateway' based on which component name is provided
  is_vpc_mode = var.vpc_component_name != null && var.vpc_component_name != ""
  is_tgw_mode = var.transit_gateway_component_name != null && var.transit_gateway_component_name != ""

  # Validate that exactly one deployment mode is specified
  deployment_mode_valid = local.is_vpc_mode != local.is_tgw_mode

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
  logging_config = local.logging_enabled ? {
    flow = {
      log_destination_type = "S3"
      log_type             = "FLOW"
      log_destination = {
        bucketName = try(module.flow_logs_bucket.outputs.bucket_id, "")
        prefix     = null
      }
    },
    alert = {
      log_destination_type = "S3"
      log_type             = "ALERT"
      log_destination = {
        bucketName = try(module.alert_logs_bucket.outputs.bucket_id, "")
        prefix     = null
      }
    }
  } : {}

  # VPC-specific outputs (only used in VPC mode)
  vpc_outputs         = local.is_vpc_mode ? module.vpc.outputs : {}
  firewall_subnet_ids = local.is_vpc_mode ? try(local.vpc_outputs.named_private_subnets_map[var.firewall_subnet_name], []) : []

  # Transit Gateway-specific outputs (only used in TGW mode)
  transit_gateway_outputs = local.is_tgw_mode ? module.transit_gateway.outputs : {}
  transit_gateway_id      = local.is_tgw_mode ? try(local.transit_gateway_outputs.transit_gateway_id, null) : null

  # Availability Zone IDs for TGW mode
  # If user provided explicit AZ IDs, use those
  # Otherwise, auto-select all available AZs in the region
  availability_zone_ids = local.is_tgw_mode ? (
    length(var.availability_zone_ids) > 0
    ? var.availability_zone_ids
    : try(data.aws_availability_zones.available[0].zone_ids, [])
  ) : []
}

module "network_firewall" {
  source  = "cloudposse/network-firewall/aws"
  version = "1.0.1"

  # VPC mode: attach firewall to VPC subnets
  # Either 'vpc_id' or 'transit_gateway_id' must be provided, but not both
  vpc_id     = local.is_vpc_mode ? local.vpc_outputs.vpc_id : null
  subnet_ids = local.is_vpc_mode ? local.firewall_subnet_ids : []

  # Transit Gateway mode: attach firewall directly to Transit Gateway
  # Uses availability_zone_ids instead of subnet_ids
  # AZ IDs are either explicitly provided or auto-selected from available AZs
  transit_gateway_id    = local.transit_gateway_id
  availability_zone_ids = local.availability_zone_ids

  network_firewall_name                     = var.network_firewall_name
  network_firewall_description              = var.network_firewall_description
  network_firewall_policy_name              = var.network_firewall_policy_name
  policy_stateful_engine_options_rule_order = var.policy_stateful_engine_options_rule_order
  stateful_default_actions                  = var.stateful_default_actions
  stateless_default_actions                 = var.stateless_default_actions
  stateless_fragment_default_actions        = var.stateless_fragment_default_actions
  stateless_custom_actions                  = var.stateless_custom_actions
  delete_protection                         = var.delete_protection
  firewall_policy_change_protection         = var.firewall_policy_change_protection
  subnet_change_protection                  = var.subnet_change_protection

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
  logging_config = local.logging_config

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group
  rule_group_config = var.rule_group_config

  context = module.this.context
}
