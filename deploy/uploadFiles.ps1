<#
.SYNOPSIS
Uploads all CSV files in the specified folder to a folder in an Azure Data Lake using the Azure CLI.

.PARAMETER dataLakeName
The name of the Azure Data Lake storage account.

.PARAMETER fileSystemName
The name of the file system in the Azure Data Lake where the CSV files will be uploaded.

.PARAMETER resourceGroupName
The name of the resource group containing the Azure Data Lake storage account.

.PARAMETER subscriptionId
The ID of the Azure subscription to use for the operation.
#>
Param (
    [Parameter(Mandatory = $true)]
    [string]$dataLakeName,

    [Parameter(Mandatory = $true)]
    [string]$fileSystemName,
    
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId
)

az account set --subscription $subscriptionId

$sourceFolderPath = Join-Path $PSScriptRoot -ChildPath "../" -AdditionalChildPath @("data")
$dataLakeFolder = "data"

$dataLakeAccountKey = az storage account keys list `
    --account-name $dataLakeName `
    --resource-group $resourceGroupName `
    --query "[?keyName=='key1'].value" `
    -o tsv

az storage fs directory upload `
    -f $fileSystemName `
    --account-name $dataLakeName `
    --account-key $dataLakeAccountKey `
    --source $sourceFolderPath `
    --destination-path $dataLakeFolder `
    --recursive