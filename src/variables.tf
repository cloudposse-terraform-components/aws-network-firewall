variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_component_name" {
  type        = string
  description = "The name of a VPC component where the Network Firewall is provisioned. Ignored when 'vpc_id' is set. Either VPC mode ('vpc_component_name' or 'vpc_id') or 'transit_gateway_component_name' must be provided, but not both"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = <<-EOT
    ID of the VPC where the Network Firewall is provisioned. When set together with 'firewall_subnet_ids',
    the VPC remote state lookup ('vpc_component_name') is skipped and these values are used instead.
    Use this when the VPC is managed outside of this stack, or to pass the values with Atmos YAML functions
    such as `!terraform.state` or `!store`.
    EOT
  default     = null
}

variable "firewall_subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets for the Network Firewall endpoints. Required when 'vpc_id' is set, ignored otherwise"
  default     = []
  nullable    = false
}

variable "transit_gateway_component_name" {
  type        = string
  description = "The name of a Transit Gateway component to attach the Network Firewall to. Either VPC mode ('vpc_component_name' or 'vpc_id') or 'transit_gateway_component_name' must be provided, but not both"
  default     = null
}

variable "network_firewall_name" {
  type        = string
  description = <<-EOT
    Friendly name to give the Network Firewall. If not provided, the name will be derived from the context.
    Changing the name will cause the Firewall to be deleted and recreated.
    EOT
  default     = null
}

variable "network_firewall_description" {
  type        = string
  description = "AWS Network Firewall description. If not provided, the Network Firewall name will be used"
  default     = null
}

variable "network_firewall_policy_name" {
  type        = string
  description = <<-EOT
    Friendly name to give the Network Firewall policy. If not provided, the name will be derived from the context.
    Changing the name will cause the policy to be deleted and recreated.
    EOT
  default     = null
}

variable "policy_stateful_engine_options_rule_order" {
  type        = string
  description = "Indicates how to manage the order of stateful rule evaluation for the policy. Valid values: DEFAULT_ACTION_ORDER, STRICT_ORDER"
  default     = null
}

variable "stateful_default_actions" {
  type        = list(string)
  description = "Default stateful actions"
  default     = ["aws:alert_strict"]
}

variable "stateless_default_actions" {
  type        = list(string)
  description = "Default stateless actions"
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_fragment_default_actions" {
  type        = list(string)
  description = "Default stateless actions for fragmented packets"
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_custom_actions" {
  type = list(object({
    action_name = string
    dimensions  = list(string)
  }))
  description = "Set of configuration blocks describing the custom action definitions that are available for use in the firewall policy's `stateless_default_actions`"
  default     = []
}

variable "delete_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to delete the firewall"
  default     = false
}

variable "firewall_policy_change_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to change the associated firewall policy"
  default     = false
}

variable "subnet_change_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to change the associated subnet(s)"
  default     = false
}

variable "rule_group_config" {
  type        = any
  description = "Rule group configuration. Refer to [networkfirewall_rule_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) for configuration details"
}

variable "logging_enabled" {
  type        = bool
  description = "Flag to enable/disable Network Firewall Flow and Alert Logs"
  default     = false
}

variable "flow_logs_bucket_component_name" {
  type        = string
  description = "Flow logs bucket component name. Ignored when 'flow_logs_bucket_name' is set"
  default     = null
}

variable "flow_logs_bucket_name" {
  type        = string
  description = <<-EOT
    Name of the S3 bucket for Network Firewall flow logs. When set, the 'flow_logs_bucket_component_name'
    remote state lookup is skipped. Use this for a bucket in another account or stack, for example a central
    log archive bucket.
    EOT
  default     = null
}

variable "alert_logs_bucket_component_name" {
  type        = string
  description = "Alert logs bucket component name. Ignored when 'alert_logs_bucket_name' is set"
  default     = null
}

variable "alert_logs_bucket_name" {
  type        = string
  description = <<-EOT
    Name of the S3 bucket for Network Firewall alert logs. When set, the 'alert_logs_bucket_component_name'
    remote state lookup is skipped. Use this for a bucket in another account or stack, for example a central
    log archive bucket.
    EOT
  default     = null
}

variable "firewall_subnet_name" {
  type        = string
  description = "Firewall subnet name. Required when using 'vpc_component_name', not used when 'vpc_id' or 'transit_gateway_component_name' is set"
  default     = "firewall"
}

variable "availability_zone_ids" {
  type        = list(string)
  description = <<-EOT
    List of Availability Zone IDs where firewall endpoints will be created for a transit gateway-attached firewall.
    Only used when 'transit_gateway_component_name' is set, not used when using 'vpc_component_name'.

    If not specified (empty list), all available AZs in the region will be automatically selected.
    If specified, must use AZ ID format (e.g., 'use1-az1', 'usw2-az2'), not AZ names (e.g., 'us-east-1a').

    Example: ["use1-az1", "use1-az2"]
    EOT
  default     = []

  validation {
    condition     = length(var.availability_zone_ids) == 0 || alltrue([for az in var.availability_zone_ids : can(regex("^[a-z]+[0-9]+-az[0-9]+[a-z]?$", az))])
    error_message = "Each availability_zone_id must be in the format like 'use1-az1', 'usw2-az2', etc."
  }
}
