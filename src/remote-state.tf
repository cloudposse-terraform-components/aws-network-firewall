module "vpc" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = var.vpc_component_name

  bypass = var.vpc_component_name == null || var.vpc_component_name == ""

  defaults = {
    vpc_id                    = ""
    named_private_subnets_map = {}
  }

  context = module.this.context
}

module "transit_gateway" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = var.transit_gateway_component_name

  bypass = var.transit_gateway_component_name == null || var.transit_gateway_component_name == ""

  defaults = {
    transit_gateway_id  = ""
    transit_gateway_arn = ""
  }

  context = module.this.context
}

module "flow_logs_bucket" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = var.flow_logs_bucket_component_name

  bypass = !local.logging_enabled || var.flow_logs_bucket_component_name == null || var.flow_logs_bucket_component_name == ""

  defaults = {
    bucket_id  = ""
    bucket_arn = ""
  }

  context = module.this.context
}

module "alert_logs_bucket" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = var.alert_logs_bucket_component_name

  bypass = !local.logging_enabled || var.alert_logs_bucket_component_name == null || var.alert_logs_bucket_component_name == ""

  defaults = {
    bucket_id  = ""
    bucket_arn = ""
  }

  context = module.this.context
}
