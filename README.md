# Example

## Create Azure Resources

The deployment script creates the following resources:

- An Azure Synapse Workspace
- An Azure Data Lake Storage Account

1. Open a Powershell session and go to the repository root.
2. Login to Azure by running `az login`.
3. Run the deployment script.

```powershell
.\deploy\deploy.ps1 -location westeurope -subscriptionId [your subscription id]
```

> NOTE: Use the **westeurope** region as this seems to work best with this example.

4. The resource group that the script creates is shown in the script output.

```bash
Your resource group name is synapsepoc-civdbl-rg
```

## Open the Azure Synapse Workspace

When the deployment script successfuly completes, open the resource group in the Azure Portal. Click the **Synapse Workspace** resource. Then click the **Open Synapse Studio** link.

In the navigation menu on the left, click **Data**. Then click the **Linked** tab. Expand the **Azure Data Lake Storage Gen2** node in the tree view. The first child node is the Azure Synapse Workspace name. Expand that node and the child node is the name of the Azure Data Lake Filesystem (the name ends in **fs**) Copy that name as you will need it in order to upload the data files to it.

## Upload Data Files

Run a script to upload the CSV files located in the `data` folder to the Azure Data Lake.

1. Open a Powershell session and go to the repository root.
2. Login to Azure by running `az login`.
3. Run the upload script.

```powershell
.\deploy\uploadFiles.ps1 -dataLakeName [your data lake name] -fileSystemName [your data lake file system name] -resourceGroupName [your resource group name] -subscriptionId [your subscription id]
```

4. After the script successfully completes, go back to the Azure Synapse Workspace and click on the Data Lake file system tree view node. You should see a **data** folder in the right-hand pane. Double-click the folder, double click the **totals** folder and you should see 53 csv files.
