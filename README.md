# Azure Autoscale

Create autoscale setting in Azure.

## Example Usage

```hcl
module "autoscale" {
  source = "innovationnorway/autoscale/azurerm"

  resource_id = azurerm_app_service_plan.example.id

  min_count = 1
  max_count = 5

  rules = [
    {
      condition = "CpuPercentage > 75 avg 5m"
      scale     = "out 2"
    },
    {
      condition = "CpuPercentage > 75 avg 10m"
      scale     = "to 5"
    },
    {
      condition = "CpuPercentage < 25 avg 15m"
      scale     = "in 50%"
    },
  ]
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `resource_id` | `string` | The ID of the resource. |
| `min_count` | `number` | The minimum number of instances for this resource. Default: `1`. |
| `max_count` | `number` | The maximum number of instances for this resource. Default: `2`. |
| `rules` | `list` | List of autoscale scaling rules. |

The `rules` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `condition` | `string` | **Required**. The condition which triggers the scaling action. |
| `scale` | `string` | **Required**. The direction and amount to scale. |
| `cooldown` | `number` | The number of minutes that must elapse before another scaling event can occur. Default: `5`. |
| `time_grain` | `string` | The way metrics are polled across instances. Default: `avg 1m`. |
