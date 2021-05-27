
locals {
  # the tags map needs to be filtered, as the ARM REST API will not accept null-value tags:
  non_null_tags = {
    for k, v in var.tags :
    k => v
    if v != null
  }
  # file paths start with "/" on linux/unix. if not linux/unix, we assume windows.
  is_unix  = (substr(pathexpand("~"), 0, 1) == "/")
  escape_char = local.is_unix ? "\\" : "^"
  
  # "create or update resource" HTTP PUT call
  create_or_update_body = jsonencode({
    "location" : var.location,
    "kind" : "web",
    "tags" : local.non_null_tags,
    "properties" : {
      "Application_Type" : "web",
      "Flow_Type" : "Bluefield",
      "Request_Source" : "CustomDeployment",
      "WorkspaceResourceId" : var.log_analytics_workspace_resource_id
    }
  })
  create_or_update_command = format(
    "az rest --header 'Content-Type=application/json' --method put --body '%s' --uri https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Insights/components/%s?api-version=2020-02-02-preview",
    local.create_or_update_body,
    var.subscription_id,
    var.resource_group_name,
    var.name
  )

  # "billing features" HTTP PUT call
  current_billing_features_body = jsonencode({
    "CurrentBillingFeatures" : [
      "Basic"
    ],
    "DataVolumeCap" : {
      "Cap" : var.daily_data_cap_in_gb,
      "StopSendNotificationWhenHitCap" : var.daily_data_cap_notifications_disabled,
      "StopSendNotificationWhenHitThreshold" : var.daily_data_cap_notifications_disabled,
    }
  })
  current_billing_features_command = format(
    "az rest --method put --body '%s' --uri https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Insights/components/%s/currentbillingfeatures?api-version=2020-02-02-preview",
    local.current_billing_features_body,
    var.subscription_id,
    var.resource_group_name,
    var.name
  )

#  # "destroy resource" HTTP PUT call
#  destroy_command = format(
#    "az rest --method delete --uri https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Insights/components/%s?api-version=2020-02-02-preview",
#    var.subscription_id,
#    var.resource_group_name,
#    var.name
#  )
}

resource null_resource app_insights_resource {

  # changes to the resource are just supported for a few parameters.
  # if you want to change other parameters, destroy and re-create.
  triggers = {
    daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
    daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
    tags                                  = jsonencode(local.non_null_tags)
  }

  provisioner local-exec {
    interpreter = local.is_unix ? ["/bin/sh", "-c"] : ["powershell"]
    command = local.is_unix ? (
      # unix shells don't need escaping
      format(
        "%s; %s",
        local.create_or_update_command,
        local.current_billing_features_command
      )) : (
      # all this escaping is due to powershell :(
      # we might need to add "`"" -> "\`"" if people start using backticks in tags :|
      # also see: https://github.com/Azure/azure-cli/issues/10562
      format(
        "%s ; %s",
        replace(replace(local.create_or_update_command, "\"", "\\\""), ":\\", ": \\"),
        replace(replace(local.current_billing_features_command, "\"", "\\\""), ":\\", ": \\")
      )
    )
    working_dir = "./"
  }

  ## this destroy provisioner works, but uncommenting it will cause warnings by terraform.
  ## the lifecycle of the resource will also become more complex if you use this provisioner.
  #  provisioner local-exec {
  #    when        = destroy
  #    command     = local.is_windows ? format("%s", local.destroy_command) : format("%s", local.destroy_command)
  #    interpreter = local.is_windows ? ["cmd", "/k"] : []
  #    working_dir = "./"
  #  }
}

# the motivation of this data reference is to be able to return (output) some important values, such as the
# instrumentation key.
data azurerm_application_insights self {
  name = var.name
  resource_group_name = var.resource_group_name
  depends_on = [null_resource.app_insights_resource]
}
