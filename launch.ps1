<#
$netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

if($netAssembly)
{
    $bindingFlags = [Reflection.BindingFlags] "Static,GetProperty,NonPublic"
    $settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")

    $instance = $settingsType.InvokeMember("Section", $bindingFlags, $null, $null, @())

    if($instance)
    {
        $bindingFlags = "NonPublic","Instance"
        $useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing", $bindingFlags)

        if($useUnsafeHeaderParsingField)
        {
          $useUnsafeHeaderParsingField.SetValue($instance, $true)
        }
    }
}
#>
$certificatePath = Join-Path $PSScriptRoot "ServerCert.pfx"
$certificatePassword = "password"
$Job = Start-Job -ScriptBlock {
    Set-Location $using:PWD
     dotnet run -- $using:certificatePath  $using:certificatePassword
}
$TimeOut = (Get-Date).AddSeconds(10)
while(
    ($Job.ChildJobs[0].Output -join '') -notmatch 'Now listening on' -and 
    (Get-Date) -lt $TimeOut
){
    Start-Sleep -Milliseconds 1
}
$clientCertPath = Join-Path $PSScriptRoot "ClientCert.pfx"
$Pfx = Get-PfxCertificate -FilePath $clientCertPath 
#$Res = Invoke-WebRequest -Uri 'https://127.0.0.1:8443' -CertificateThumbprint C8747A1C4A46E52EEC688A6766967010F86C58E3 -SkipCertificateCheck
$Res = Invoke-WebRequest -Uri 'https://127.0.0.1:8443' -Certificate $Pfx -SkipCertificateCheck
#$Res.RawContent -split [System.Environment]::NewLine -match 'Status:' | Out-Host

'--------Invoke-WebRequest--------' | Out-Host
$Res.Content | Out-Host
'---------------------------------' | Out-Host
'--------Invoke-RestMethod--------' | Out-Host
Invoke-RestMethod -Uri 'https://127.0.0.1:8443' -Certificate $Pfx -SkipCertificateCheck
'---------------------------------' | Out-Host
$Job | Stop-Job
$Job | Receive-Job | Out-Host
$JOb | Remove-Job
Remove-Variable Job