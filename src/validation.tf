# Validation: Ensure exactly one deployment mode is specified
resource "null_resource" "validate_deployment_mode" {
  count = local.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.deployment_mode_valid
      error_message = "Exactly one deployment mode must be configured: VPC mode ('vpc_component_name', or 'vpc_id' with 'firewall_subnet_ids') or Transit Gateway mode ('transit_gateway_component_name'), not both or neither."
    }

    precondition {
      condition     = !local.vpc_remote_state_enabled || (var.firewall_subnet_name != null && var.firewall_subnet_name != "")
      error_message = "When using VPC mode (vpc_component_name is set), 'firewall_subnet_name' must be provided."
    }

    precondition {
      condition     = !local.vpc_remote_state_enabled || try(contains(keys(local.vpc_outputs.named_private_subnets_map), var.firewall_subnet_name), false)
      error_message = "When using VPC mode, the 'firewall_subnet_name' (${coalesce(var.firewall_subnet_name, "unset")}) must exist in the VPC component's named_private_subnets_map. Available subnet names: ${try(join(", ", keys(local.vpc_outputs.named_private_subnets_map)), "none")}"
    }

    precondition {
      condition     = !local.vpc_from_inputs || length(var.firewall_subnet_ids) > 0
      error_message = "When 'vpc_id' is set, 'firewall_subnet_ids' must contain at least one subnet ID."
    }

    precondition {
      condition     = !local.is_tgw_mode || length(local.availability_zone_ids) > 0
      error_message = "When using Transit Gateway mode (transit_gateway_component_name is set), 'availability_zone_ids' must be provided or available AZs must be auto-detected. Failed to determine Availability Zones."
    }
  }
}
