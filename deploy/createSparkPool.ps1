<#
.SYNOPSIS
Creates an Azure Synapse Spark pool using the Azure CLI.

.PARAMETER poolName
The name of the new Spark pool to create.

.PARAMETER synapseWorkspaceName
The name of the Synapse workspace where the Spark pool will be created.

.PARAMETER sparkVersion
(Optional) The version of Spark to use for the Spark pool. Defaults to 3.3.

.PARAMETER nodeCount
(Optional) The number of nodes to provision for the Spark pool. Defaults to 3 nodes.

.PARAMETER nodeSize
(Optional) The size of each node in the Spark pool. Defaults to Small.

.PARAMETER nodeSizeFamily
(Optional) The type of each node in the Spark pool. Defaults to MemoryOptimized.

.PARAMETER resourceGroupName
The name of the resource group containing the Synapse workspace.
#>
Param (
    [Parameter(Mandatory = $true)]
    [string]$poolName,

    [Parameter(Mandatory = $true)]
    [string]$synapseWorkspaceName,
    
    [Parameter()]
    [string]$sparkVersion = "3.3",

    [Parameter()]
    [int]$nodeCount = 3,

    [Parameter()]
    [string]$nodeSize = "Small",
    
    [Parameter()]
    [string]$nodeSizeFamily = "MemoryOptimized",
    
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName
    
)

az synapse spark pool create `
    --name $poolName `
    --workspace-name $synapseWorkspaceName `
    --spark-version $sparkVersion `
    --node-count $nodeCount `
    --node-size $nodeSize `
    --node-size-family $nodeSizeFamily `
    --enable-auto-pause true `
    --delay 15 `
    --spark-config-file-path "./sparkConfig.txt" `
    --resource-group $resourceGroupName `
