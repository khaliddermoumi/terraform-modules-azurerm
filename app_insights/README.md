
# Application Insights Resource Module

This module creates a workspace based Application Insights resource.
It was created as there is no "native" support on terraform currently (2021-05) for the creation of 
workspace based App Insights resources [see github issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/7667). 
As the underlying client library which terraform azure provider uses, azure-go-sdk, does not 
support this feature yet, there is no straightforward way to built it into terraform yet. 
Meanwhile, this temporary module was created to make the feature available.
This module uses the Azure Management REST API directly to create this resource.
