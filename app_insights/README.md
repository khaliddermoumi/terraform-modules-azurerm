
# Application Insights Classic Resource

This module creates a workspace based Application Insights resource.

By the time of writing, there is another AI module ("app_insights"), which is built with standard terraform resources. 
The difference between the modules is that the existing module does not create a workspace based Application Insights 
resource, but this one does.
The reason for this is that there is no support on terraform currently (2020-10) for the creation of workspace based
resources [see github issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/7667). 
As the underlying client library which terraform azure provider uses, azure-go-sdk, does not 
support this feature yet (as of v48), there is no straightforward way to built it into terraform yet. 
It also cannot be expected that this feature will soon be supported by terraform, as first the go SDK needs to be 
updated, then the terraform-azurerm-provider needs to upgrade the go SDK several times, and then it can be built into
the provider. As this will likely take months from now (2020-10), meanwhile this temporary module was created to
make the feature available.
This module uses the Azure Management REST API directly to create this resource.

As soon as terraform azure provider supports this feature, it should be built into the main "app_insights" module,
 and this module should be deleted.

## TODO

* if possible, enable "alerting on custom metrics" (see the "Usage" view on the AI resource)
