
locals {
  # the tags map needs to be filtered, as the ARM REST API will not accept null-value tags:
  non_null_tags = {
    for k, v in var.tags :
    k => v
    if v != null
  }
  # Directories start with "C:..." on Windows; All other OSs use "/" for root.
  is_windows  = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  escape_char = local.is_windows ? "^" : "\\"
  
  # "create or update resource" HTTP PUT call
  create_or_update_body = jsonencode({
    "location" : var.project_config.location,
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
    var.project_config.subscription_id,
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
    var.project_config.subscription_id,
    var.resource_group_name,
    var.name
  )

#  # "destroy resource" HTTP PUT call
#  destroy_command = format(
#    "az rest --method delete --uri https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Insights/components/%s?api-version=2020-02-02-preview",
#    var.project_config.subscription_id,
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
    interpreter = local.is_windows ? ["powershell"] : ["/bin/sh", "-c"]
    command = local.is_windows ? (
      # all this escaping is due to powershell :(
      # we might need to add "`"" -> "\`"" if people start using backticks in tags :|
      # also see: https://github.com/Azure/azure-cli/issues/10562
      format(
        "%s ; %s",
        replace(replace(local.create_or_update_command, "\"", "\\\""), ":\\", ": \\"),
        replace(replace(local.current_billing_features_command, "\"", "\\\""), ":\\", ": \\")
      )) : (
      # unix shells don't need escaping
      format(
        "%s; %s",
        local.create_or_update_command,
        local.current_billing_features_command
    ))
    working_dir = "./"
  }

  ## this destroy provisioner works, but uncommenting it will cause warnings by terraform.
  ## the lifecycle of the resource will also become much more complex if you use this provisioner.
  #  provisioner local-exec {
  #    when        = destroy
  #    command     = local.is_windows ? format("%s", local.destroy_command) : format("%s", local.destroy_command)
  #    interpreter = local.is_windows ? ["cmd", "/k"] : []
  #    working_dir = "./"
  #  }
}

# the motivation of this data reference is to be able to return (output) some important values, such as the
# instrumentation key.
# BTW: doing this outside of the module (with a data reference following the module) may result in timing errors.
data azurerm_application_insights self {
  # the reason to reference the attribute "null_resource.app_insights_resource.id" here is to specify that this
  # data lookup shall only occur after the "null_resource.app_insights_resource" resource, and only whenever it
  # is actually run.
  # in Terraform you could also just specify "depends_on = [null_resource.app_insights_resource]", but the problem
  # is that this statement always runs on every "terraform apply", also causing dependent resources (those that
  # read the output) to be updated every time. because this is unacceptable, it is better to reference the
  # "null_resource.app_insights_resource" resource in a different way. here, the id of the resource is used, but
  # by using the replace() function, the string that is passed is actually completely empty. thus, the statement
  # is effectively just: name = var.name
  # to get rid of these sorts of workarounds, TF should support the creation of workspace-based app insights
  # resources - see: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7667
  name                = format("%s%s", var.name, replace(null_resource.app_insights_resource.id, "/.*/", ""))
  resource_group_name = var.resource_group_name
}
