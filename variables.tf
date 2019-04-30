variable "resource_id" {
  type        = string
  description = "The ID of the resource."
}

variable "name" {
  type        = string
  default     = ""
  description = "The name of the autoscale setting."
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The name of an existing resource group for the autoscale setting."
}

variable "scale_count" {
  type        = number
  default     = null
  description = "The (default) number of instances for this resource."
}

variable "min_count" {
  type        = number
  default     = 1
  description = "The minimum number of instances for this resource."
}

variable "max_count" {
  type        = number
  default     = 2
  description = "The maximum number of instances for this resource."
}

variable "email_administrator" {
  type    = bool
  default = null
}

variable "email_co_administrator" {
  type    = bool
  default = null
}

variable "rules" {
  type        = any
  description = "List of autoscale scaling rules."
}
