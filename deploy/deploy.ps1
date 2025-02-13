Param (
    [Parameter(HelpMessage = "Template specs resource group")] 
    [string] $TemplateSpecsResourceGroupName = "template-specs-rg",

    [Parameter(HelpMessage = "Deployment target resource group")] 
    [string] $ResourceGroupName = "template-specs-demo-rg",

    [Parameter(HelpMessage = "Deployment target resource group location")] 
    [string] $Location = "North Europe",

    [string] $Template = "azuredeploy.json",
    [string] $TemplateParameters = "$PSScriptRoot\azuredeploy.parameters.json",
    [switch] $PreserveDeploymentContainer
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:RELEASE_DEFINITIONNAME)) {
    Write-Host (@"
Not executing inside Azure DevOps Release Management.
Make sure you have done "Login-AzAccount" and
"Select-AzSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else {
    $deploymentName = $env:RELEASE_RELEASENAME
}

# Target deployment resource group
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue)) {
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['templateSpecsResourceGroupName'] = $TemplateSpecsResourceGroupName

$result = New-AzResourceGroupDeployment `
    -DeploymentName $deploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $Template `
    -TemplateParameterFile $TemplateParameters `
    @additionalParameters `
    -Mode Complete -Force `
    -Verbose

# if ($null -eq $result.Outputs.apimGateway) {
#     Throw "Template deployment didn't return web app information correctly and therefore deployment is cancelled."
# }

# $result | Select-Object -ExcludeProperty TemplateLinkString

# $apimGateway = $result.Outputs.apimGateway.value

# # Publish variable to the Azure DevOps agents so that they
# # can be used in follow-up tasks such as application deployment
# Write-Host "##vso[task.setvariable variable=Custom.APIMGateway;]$apimGateway"

# Write-Host "Validating that our *MANDATORY* API is up and running..."
# $webAppUri = "$apimGateway/users"
# $data = @{
#     id      = 1
#     name    = "Doe"
#     address = @{
#         street     = "My street 1"
#         postalCode = "12345"
#         city       = "My city"
#         country    = "My country"
#     }
# }
# $body = ConvertTo-Json $data
# $running = 0
# for ($i = 0; $i -lt 60; $i++) {
#     try {
#         $request = Invoke-WebRequest -Body $body -ContentType "application/json" -Method "POST" -DisableKeepAlive -Uri $webAppUri -ErrorAction SilentlyContinue
#         Write-Host "API status code $($request.StatusCode)."

#         if ($request.StatusCode -eq 200) {
#             Write-Host "API is up and running."
#             $running++
#         }
#     }
#     catch {
#         Start-Sleep -Seconds 3
#     }

#     if ($running -eq 1) {
#         if (!$PreserveDeploymentContainer.IsPresent) {
#             Write-Host "After successful deployment removing the deployment storage container..."
#             Remove-AzStorageContainer -Name $DeploymentContainer -Force
#         }
#         return
#     }
# }

# Throw "Mandatory API didn't respond on defined time."
