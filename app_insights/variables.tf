
# Notes:
# * there's no "retention" variable, as retention time can be set only when Application Insights is not
#   connected to a Log Analytics workspace
# * there is no "application_type" variable, as the field is for legacy reasons and will not impact the type
# of App Insights resource you deploy.

variable daily_data_cap_in_gb {
  description = "Daily data volume cap in GB."
  type        = number
  default     = 2
}

variable daily_data_cap_notifications_disabled {
  description = "Whether to disable cap notifications to the subscription admin."
  type        = bool
  default     = true
}

variable log_analytics_workspace_resource_id {
  type = string
}

variable name {
  default     = ""
  type        = string
}

#variable project_config {
#  type        = map(string)
#  description = "Project configuration, as supplied by the 'project_config' output of the 'context' module."
#}

variable resource_group_name {
  type = string
}

variable tags {
  type        = map(string)
}
