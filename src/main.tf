locals {
  enabled         = module.this.enabled
  logging_enabled = local.enabled && var.logging_enabled

  # Determine deployment mode
  # Either 'vpc' or 'transit_gateway' based on which inputs are provided.
  # VPC mode reads the VPC from the 'vpc_component_name' remote state, or takes 'vpc_id' and
  # 'firewall_subnet_ids' directly.
  vpc_from_inputs          = var.vpc_id != null && var.vpc_id != ""
  vpc_from_component       = var.vpc_component_name != null && var.vpc_component_name != ""
  vpc_remote_state_enabled = local.vpc_from_component && !local.vpc_from_inputs
  is_vpc_mode              = local.vpc_from_component || local.vpc_from_inputs
  is_tgw_mode              = var.transit_gateway_component_name != null && var.transit_gateway_component_name != ""

  # Validate that exactly one deployment mode is specified
  deployment_mode_valid = local.is_vpc_mode != local.is_tgw_mode

  # Log destinations: a bucket name passed directly wins over the bucket component remote state
  flow_logs_bucket_from_input  = var.flow_logs_bucket_name != null && var.flow_logs_bucket_name != ""
  alert_logs_bucket_from_input = var.alert_logs_bucket_name != null && var.alert_logs_bucket_name != ""

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
  logging_config = local.logging_enabled ? {
    flow = {
      log_destination_type = "S3"
      log_type             = "FLOW"
      log_destination = {
        bucketName = local.flow_logs_bucket_from_input ? var.flow_logs_bucket_name : try(module.flow_logs_bucket.outputs.bucket_id, "")
        prefix     = null
      }
    },
    alert = {
      log_destination_type = "S3"
      log_type             = "ALERT"
      log_destination = {
        bucketName = local.alert_logs_bucket_from_input ? var.alert_logs_bucket_name : try(module.alert_logs_bucket.outputs.bucket_id, "")
        prefix     = null
      }
    }
  } : {}

  # VPC-specific outputs (only used in VPC mode).
  # Not wrapped in a `local.is_vpc_mode ? ... : {}` conditional: the remote-state
  # outputs object and `{}` have different types, which Terraform rejects with
  # "Inconsistent conditional result types". When the VPC remote state is not used,
  # `module.vpc` is bypassed and already returns its `defaults`.
  vpc_outputs = module.vpc.outputs
  vpc_id = local.vpc_from_inputs ? var.vpc_id : (
    local.is_vpc_mode ? local.vpc_outputs.vpc_id : null
  )
  firewall_subnet_ids = local.vpc_from_inputs ? var.firewall_subnet_ids : (
    local.is_vpc_mode ? try(local.vpc_outputs.named_private_subnets_map[var.firewall_subnet_name], []) : []
  )

  # Transit Gateway-specific outputs (only used in TGW mode).
  # Same as `vpc_outputs`: in VPC mode `module.transit_gateway` is bypassed and
  # returns its `defaults`.
  transit_gateway_outputs = module.transit_gateway.outputs
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
  vpc_id     = local.vpc_id
  subnet_ids = local.firewall_subnet_ids

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
