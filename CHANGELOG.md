
# Changelog Terraform Azure RM Modules Project

## v0.2.0

* removed app_insights module
    * azurerm provider supports workspace model from version 2.71.0
    * please migrate away from the module, as it will be removed some time in the future

## v0.1.1
Date:   Thu May 27 19:51:55 2021 +0200

* app_insights: module refactorings

## v0.1.0
Date:   Thu May 27 18:04:05 2021 +0200

* first version of app_insights module
    * this module supports the app insights workspace model
    * the workspace mode  is unsupported by azurerm provider as of now
