
output id {
  value = data.azurerm_application_insights.self.id
}

output instrumentation_key {
  value = data.azurerm_application_insights.self.instrumentation_key
}

output name {
  value = local.resource_name
}

output resource_group_name {
  value = var.resource_group_name
}
