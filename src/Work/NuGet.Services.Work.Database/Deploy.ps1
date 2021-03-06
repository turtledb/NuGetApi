$Root = $OctopusOriginalPackageDirectoryPath

Write-Host "Package was extracted to '$Root'"

$sqlRoot = "$(cat 'env:\ProgramFiles(x86)')\Microsoft SQL Server\110"
if(!(Test-Path $sqlRoot)) {
    throw "Could not find SQL Server 2012 installation in $sqlRoot!"
}
$dacfx = Join-Path $sqlRoot "DAC\bin\Microsoft.SqlServer.Dac.dll"
if(!(Test-Path $dacfx)) {
    throw "Could not find DACfx in $dac!"
}

Add-Type -Path $dacfx

$options = New-Object Microsoft.SqlServer.Dac.DacDeployOptions
$options.BlockOnPossibleDataLoss = $true

$d = New-Object Microsoft.SqlServer.Dac.DacServices $OctopusParameters['Deployment.Sql.MasterConnection']
$p = New-Object Microsoft.SqlServer.Dac.DacPackage "$Root\NuGet.Services.Work.Database.dacpac"

Register-ObjectEvent $d "Message" -Action {
    Write-Host "$($EventArgs.Message.MessageType.ToString()): $($EventArgs.Message.Message)"
}

# Deploy!
$d.Deploy($p, $OctopusParameters['Deployment.Sql.Database'], $true, $options)