Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Prod", "Stage", "Mooncake", "Blackforest", "Fairfax", "Test", "Canary", IgnoreCase = $true)]
    [string]$Environment = "Prod",

    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path -Path $_})]
    [string] $ModulesPath = "C:\Cosmos\RDTools"
)



if(-not (Get-Module -Name RD.Fabric.Controller.PowerShell.Cmdlet))
{
    Import-module $(Join-Path -Path $ModulesPath -ChildPath FCClient\RD.Fabric.Controller.PowerShell.Cmdlet.dll) -Force | Out-Null
}
if(-not (Get-Module -Name DocumentDBPSModule))
{
    Import-Module $(Join-Path -Path $ModulesPath -ChildPath DocumentDBPSModule\DocumentDBPSModule.psd1) -Force  | Out-Null
}

if(-not (Get-Module -Name Azure))
{
    Import-module $(Join-Path -Path $ModulesPath -ChildPath AzurePowershell\Azure.psd1) -Force | Out-Null
}

if(-not (Get-Module -Name ServiceFabric))
{
    Import-Module $(Join-Path -Path $ModulesPath -ChildPath WinFabricClient\ServiceFabric.psd1) -Global -Force | Out-Null
}


$settings = Get-EnvironmentSettings $Environment
$UpdateFederationsMap = @()
$NewFederationsMap = @()
$Locations = ($settings.FederationMap | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name
foreach($Location in $Locations)
{
    $Federations = ($settings.FederationMap.$Location | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name    
    foreach($Federation in $Federations)    
    {        
        $GetDeploymentId = Get-FederationMapViaAcis -SubscriptionId $settings.FederationMap.$Location.$Federation.SubscriptionId -FederationName $Federation
        $Tenant = $settings.FederationMap.$Location.$Federation.TenantId
        $Cluster = $settings.FederationMap.$Location.$Federation.Cluster
        if($GetDeploymentId)
        {
            if([string]::IsNullOrWhiteSpace($Tenant) -or [string]::IsNullOrWhiteSpace($Cluster))
            {
                $NewFederationsMap += New-Object `
                            -TypeName PsObject `
                            -Property @{
                                FederationName = $Federation;
                                TenantId = $GetDeploymentId.TenantId
                                SubscriptionId = $settings.FederationMap.$Location.$Federation.SubscriptionId;
                                Location = $Location;
                                CloudName = $GetDeploymentId.Cluster;                            
                            }
            }elseif($Tenant -ne $GetDeploymentId.TenantId -and $Cluster -ne $GetDeploymentId.Cluster)
            {                
                $FederationMap = New-Object `
                            -TypeName PsObject `
                            -Property @{
                                FederationName = $Federation;
                                TenantId = $GetDeploymentId.TenantId
                                SubscriptionId = $settings.FederationMap.$Location.$Federation.SubscriptionId;
                                Location = $Location;
                                CloudName = $GetDeploymentId.Cluster;                            
                            }
                $FederationMap | Format-Table -AutoSize
                $UpdateFederationsMap += $FederationsMap
            }
        }
    }
}

Write-Host ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Cyan
Write-Host ":::::::::::::::::::::::::::::New Federations Map:::::::::::::::::::::::::::::::::::::::" -ForegroundColor Cyan
Write-Host ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Cyan
$NewFederationsMap | Format-Table -AutoSize

Write-Host ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Blue
Write-Host ":::::::::::::::::::::::::::::Update Federations Map::::::::::::::::::::::::::::::::::::" -ForegroundColor Blue
Write-Host ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Blue
$UpdateFederationsMap | Format-Table -AutoSize