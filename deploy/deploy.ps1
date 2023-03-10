<#
.SYNOPSIS
Uploads all CSV files in the specified folder to a folder in an Azure Data Lake using the Azure CLI.

.PARAMETER location
The location the Azure resources will be created in.

.PARAMETER subscriptionId
The ID of the Azure subscription to use for the operation.
#>
Param (
    [Parameter(Mandatory = $true)]
    [string]$location,
    
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId
)

function Get-UniquePrefix([int]$length) {
    $alphabet = "abcdefghijklmnopqrstuvwxyz"
    $uniquePrefix = ""

    for ($i = 0; $i -lt $length; $i++) {
        $random = Get-Random -Minimum 0 -Maximum ($alphabet.Length - 1)
        $randomLetter = $alphabet[$random]
        $uniquePrefix += $randomLetter
    }

    return $uniquePrefix
}

$uniquePrefix = Get-UniquePrefix(6)

$deploymentName = "$uniquePrefix-deployment-$(Get-Random)"
$resourceGroupName = "synapsepoc-$uniquePrefix-rg"


Write-Host "Your unique prefix for the Azure resource group and resources is " -NoNewline
Write-Host $uniquePrefix -ForegroundColor Cyan

Write-Host "Your resource group name is " -NoNewline 
Write-Host $resourceGroupName -ForegroundColor Cyan

az account set --subscription $subscriptionId
az group create --name $resourceGroupName --location $location

$templateFileName = [IO.Path]::Combine($PSScriptRoot, "azuredeploy.json")

$output = az deployment group create `
    --resource-group $resourceGroupName `
    --name $deploymentName `
    --template-file $templateFileName `
    --parameters uniquePrefix=$uniquePrefix `
| ConvertFrom-Json

if (!$output) {
    Write-Warning "Deployment failed. Resourse group will be deleted in the background."
    az group delete --name $resourceGroupName --yes --no-wait
    exit 1
}

Write-Host "Uploading files..." -ForegroundColor Cyan

$dataLakeName = az resource list `
    --resource-group $resourceGroupName `
    --resource-type Microsoft.Storage/storageAccounts `
    --query [].name `
    --output tsv

$dataLakeAccountKey = az storage account keys list `
    --account-name $dataLakeName `
    --resource-group $resourceGroupName `
    --query "[?keyName=='key1'].value" `
    -o tsv

$fileSystemName = az storage fs list `
    --account-name $dataLakeName `
    --account-key $dataLakeAccountKey `
    --query "[].name" `
    -o tsv

$sourceFolderPath = [IO.Path]::Combine($PSScriptRoot, "../", "data/totals")
$dataLakeFolder = "data"

az storage fs directory upload `
    -f $fileSystemName `
    --account-name $dataLakeName `
    --account-key $dataLakeAccountKey `
    --source $sourceFolderPath `
    --destination-path $dataLakeFolder `
    --recursive

Write-Host "Upload complete" -ForegroundColor Cyan

Write-Host "Creating Spark pool" -ForegroundColor Cyan

$poolName = "sparkPool01"

$synapseWorkspaceName = az resource list `
    --resource-group $resourceGroupName `
    --resource-type Microsoft.Synapse/workspaces `
    --query [].name `
    --output tsv

$sparkVersion = "3.3"
$nodeCount = 3
$nodeSize = "Small"
$nodeSizeFamily = "MemoryOptimized"

$sparkConfigFileName = [IO.Path]::Combine($PSScriptRoot, "sparkConfig.txt")

az synapse spark pool create `
    --name $poolName `
    --workspace-name $synapseWorkspaceName `
    --spark-version $sparkVersion `
    --node-count $nodeCount `
    --node-size $nodeSize `
    --node-size-family $nodeSizeFamily `
    --enable-auto-pause true `
    --delay 15 `
    --spark-config-file-path $sparkConfigFileName `
    --resource-group $resourceGroupName `


Write-Host "Spark pool created." -ForegroundColor Cyan

Write-Host "Your Azure Synapse workspace url:" -ForegroundColor Cyan

$workspaceUrl = az synapse workspace show `
    --name $synapseWorkspaceName `
    --resource-group $resourceGroupName `
    --query "connectivityEndpoints.web" `
    --output tsv

Write-Host $workspaceUrl -ForegroundColor Yellow