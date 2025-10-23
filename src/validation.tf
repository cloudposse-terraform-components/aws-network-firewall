# Validation: Ensure exactly one deployment mode is specified
resource "null_resource" "validate_deployment_mode" {
  count = local.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.deployment_mode_valid
      error_message = "Exactly one of 'vpc_component_name' or 'transit_gateway_component_name' must be provided, not both or neither."
    }

    precondition {
      condition     = !local.is_vpc_mode || (var.firewall_subnet_name != null && var.firewall_subnet_name != "")
      error_message = "When using VPC mode (vpc_component_name is set), 'firewall_subnet_name' must be provided."
    }

    precondition {
      condition     = !local.is_tgw_mode || var.firewall_subnet_name == "firewall"
      error_message = "When using Transit Gateway mode (transit_gateway_component_name is set), 'firewall_subnet_name' is not used and should be left at default."
    }
  }
}
