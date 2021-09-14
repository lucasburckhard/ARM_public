Param(
[Parameter(Mandatory=$true)][string]$ResourceGroup, 
[Parameter(Mandatory=$true)][string]$StorageName
)
$key=$(az storage account keys list -g "$resourcegroup" -n "$storagename" --query [0].value -o tsv)

az storage blob delete -c 'dsc' -n 'dsc.zip' --account-name "$storagename" --account-key $key

az storage blob upload --container-name 'dsc' --file '.\dsc.zip' --name 'dsc.zip' --account-key $key --account-name "$storagename"
