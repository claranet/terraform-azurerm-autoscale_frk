locals {
  resource_group_name = format("%s", split("/", var.resource_id)[4])

  resource_type = format("%s/%s", split("/", var.resource_id)[5],
  split("/", var.resource_id)[6])

  resource_name = format("%s", split("/", var.resource_id)[8])

  default_profile_name = "default"

  operator_conversion = {
    "="  = "Equals"
    "!=" = "NotEquals"
    ">"  = "GreaterThan"
    ">=" = "GreaterThanOrEqual"
    "<"  = "LessThan"
    "<=" = "LessThanOrEqual"
  }

  time_aggregation_conversion = {
    avg   = "Average"
    min   = "Minimum"
    max   = "Maximum"
    total = "Total"
    count = "Count"
  }

  scale_direction_conversion = {
    to  = "None"
    out = "Increase"
    in  = "Decrease"
  }

  statistic_conversion = {
    avg = "Average"
    min = "Min"
    max = "Max"
  }

  rules = [
    for r in var.rules : merge({
      condition  = ""
      scale      = ""
      cooldown   = 5
      time_grain = "avg 1m"
    }, r)
  ]

  condition_pattern = "/^([\\w\\s]*)\\s([!=><]*)\\s(\\d*)\\s(avg|min|max|total|count)\\s(\\d*[d|h|m|s])$/"

  metric_triggers = [
    for r in local.rules : {
      metric_name        = replace(r.condition, local.condition_pattern, "$1")
      metric_resource_id = var.resource_id
      time_grain         = format("PT%s", upper(split(" ", r.time_grain)[1]))
      statistic          = local.statistic_conversion[split(" ", r.time_grain)[0]]
      time_window        = format("PT%s", upper(replace(r.condition, local.condition_pattern, "$5")))
      time_aggregation   = local.time_aggregation_conversion[replace(r.condition, local.condition_pattern, "$4")]
      operator           = local.operator_conversion[replace(r.condition, local.condition_pattern, "$2")]
      threshold          = format("%d", replace(r.condition, local.condition_pattern, "$3"))
    }
  ]

  scale_pattern = "/^(to|out|in)\\s(\\d*)(%?)$/"

  scale_actions = [
    for r in local.rules : {
      direction = local.scale_direction_conversion[split(" ", r.scale)[0]]
      type = (
        split(" ", r.scale)[0] == "to" ?
        "ExactCount" :
        replace(r.scale, local.scale_pattern, "$3") != "" ?
        "PercentChangeCount" :
        "ChangeCount"
      )
      value    = replace(r.scale, local.scale_pattern, "$2")
      cooldown = format("PT%dM", r.cooldown)
    }
  ]
}

data "azurerm_resource_group" "main" {
  name = coalesce(var.resource_group_name, local.resource_group_name)
}

resource "azurerm_monitor_autoscale_setting" "main" {
  name                = coalesce(var.name, local.resource_name)
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  target_resource_id  = var.resource_id

  profile {
    name = local.default_profile_name

    capacity {
      default = coalesce(var.scale_count, var.min_count)
      minimum = var.min_count
      maximum = var.max_count
    }

    dynamic "rule" {
      for_each = { for k, v in local.rules : k => v }

      content {
        metric_trigger {
          metric_name        = local.metric_triggers[rule.key].metric_name
          metric_resource_id = local.metric_triggers[rule.key].metric_resource_id
          time_grain         = local.metric_triggers[rule.key].time_grain
          statistic          = local.metric_triggers[rule.key].statistic
          time_window        = local.metric_triggers[rule.key].time_window
          time_aggregation   = local.metric_triggers[rule.key].time_aggregation
          operator           = local.metric_triggers[rule.key].operator
          threshold          = local.metric_triggers[rule.key].threshold
        }

        scale_action {
          direction = local.scale_actions[rule.key].direction
          type      = local.scale_actions[rule.key].type
          value     = local.scale_actions[rule.key].value
          cooldown  = local.scale_actions[rule.key].cooldown
        }
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = var.email_administrator
      send_to_subscription_co_administrator = var.email_co_administrator
    }
  }
}
