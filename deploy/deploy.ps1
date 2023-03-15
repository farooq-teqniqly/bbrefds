<#
.SYNOPSIS
The deployment script creates the following resources:

    - An Azure Synapse Workspace
    - An Apache Spark pool in the Azure Synapse Workspace
    - An Azure Data Lake Storage Account

The script also uploads several CSV files to the Azure Data Lake.

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

$synapseWorkspaceName = az resource list `
    --resource-group $resourceGroupName `
    --resource-type Microsoft.Synapse/workspaces `
    --query [].name `
    --output tsv

$dataLakeName = az resource list `
    --resource-group $resourceGroupName `
    --resource-type Microsoft.Storage/storageAccounts `
    --query [].name `
    --output tsv

Write-Host "Setting Azure Data Lake permissions..." -ForegroundColor Cyan

$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName

$synapseWorkspaceId = az synapse workspace show `
    --name $synapseWorkspaceName  `
    --resource-group $resourceGroupName  `
    --query identity.principalId -o tsv

az role assignment create `
    --assignee-object-id $synapseWorkspaceId `
    --role "Storage Blob Data Owner" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeName"

az role assignment create `
    --assignee $userName `
    --role "Storage Blob Data Owner" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeName"

Write-Host "Azure Data Lake permissions set." -ForegroundColor Cyan

Write-Host "Uploading files..." -ForegroundColor Cyan

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

$notebookFolderPath = [IO.Path]::Combine($PSScriptRoot, "../", "notebooks")
$notebookFiles = Get-ChildItem $notebookFolderPath -Filter "*.ipynb"

foreach ($notebookFile in $notebookFiles) {
    az synapse notebook import `
        --workspace-name $synapseWorkspaceName  `
        --name $notebookFile.Name.Replace($notebookFile.Extension, "") `
        --file "@$notebookFolderPath/$notebookFile"
}

Write-Host "Upload complete" -ForegroundColor Cyan

Write-Host "Creating Spark pool" -ForegroundColor Cyan

$poolName = "sparkPool01"
$sparkVersion = "3.3"
$nodeCount = 3
$nodeSize = "Small"
$nodeSizeFamily = "MemoryOptimized"

$sparkConfigFileName = [IO.Path]::Combine($PSScriptRoot, "sparkConfig.txt")

az synapse spark pool create `
    --name $poolName `
    --workspace-name $synapseWorkspaceName `
    --spark-version $sparkVersion `
    --enable-auto-scale false `
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