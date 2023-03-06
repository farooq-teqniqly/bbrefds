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

$templateFileName = Join-Path -Path $PSScriptRoot -ChildPath "azuredeploy.json"

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