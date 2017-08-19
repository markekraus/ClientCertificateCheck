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
$portNumber = 8443
$certificatePath = "ServerCert.pfx"
$certificatePassword = "password"
$containerProjectPath = $PWD
$containerName = 'clientcertificatecheck'
Set-Location $containerProjectPath
$null = docker build -t $containerName .
$containerId = docker run -d -p ${portNumber}:${portNumber} --name $containerName $containerName $portNumber
#start-sleep 5
$TimeOut = (get-date).AddSeconds(15)
do{
    $containerStatus = docker logs --tail 3 $containerName | Out-String
}while (
    $containerStatus -notmatch 'Now listening on' -and
    (get-date) -lt $TimeOut
)
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
$Null = docker kill $containerName
$Null = docker rm $containerName
# docker ps -a -q | ForEach-Object {$_; docker rm $_ }
# docker images -q | ForEach-Object {$_; docker rmi $_ }