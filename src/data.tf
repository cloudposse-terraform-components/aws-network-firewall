# Data source to automatically lookup available Availability Zones in TGW mode
# Only used when availability_zone_ids is not explicitly provided
data "aws_availability_zones" "available" {
  count = local.enabled && local.is_tgw_mode && length(var.availability_zone_ids) == 0 ? 1 : 0

  state = "available"

  # Filter out local zones (they don't have zone IDs in the same format)
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
