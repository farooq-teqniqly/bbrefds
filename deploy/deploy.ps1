<#
.SYNOPSIS
Uploads all CSV files in the specified folder to a folder in an Azure Data Lake using the Azure CLI.

.PARAMETER solutionName
A unique prefix for Azure resources.

.PARAMETER location
The location the Azure resources will be created in.

.PARAMETER subscriptionId
The ID of the Azure subscription to use for the operation.
#>
Param (
    [Parameter(Mandatory = $true)]
    [string]$solutionName,

    [Parameter(Mandatory = $true)]
    [string]$location,
    
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId
)

$baseName = "$solutionName"
$deploymentName = "$baseName-deployment-$(Get-Random)"
$resourceGroupName = "$baseName-rg"


az account set --subscription $subscriptionId
az group create --name $resourceGroupName --location $location

az deployment group create `
    --resource-group $resourceGroupName `
    --name $deploymentName `
    --template-file azuredeploy.json `
    --parameters solutionName=$solutionName