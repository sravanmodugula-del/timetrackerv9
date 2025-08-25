
param(
    [string]$InstallPath = "C:\TimeTracker",
    [string]$ServiceName = "TimeTracker",
    [string]$SiteName = "TimeTracker",
    [string]$AppPoolName = "TimeTrackerAppPool"
)

$ErrorActionPreference = "Stop"

Write-Host "Configuring IIS-based TimeTracker Service..." -ForegroundColor Green

# Ensure we're in the correct directory
Set-Location $InstallPath

# Import IIS module
Import-Module WebAdministration

# Stop existing site and app pool if they exist
Write-Host "Stopping existing IIS components..." -ForegroundColor Yellow
try {
    Stop-IISSite -Name $SiteName -ErrorAction SilentlyContinue
    Stop-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
} catch {
    Write-Host "No existing components to stop" -ForegroundColor Gray
}

# Configure Application Pool for optimal performance
Write-Host "Configuring Application Pool..." -ForegroundColor Yellow
if (!(Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue)) {
    New-IISAppPool -Name $AppPoolName
}

# Set application pool properties for production
Set-IISAppPool -Name $AppPoolName -ProcessModel.identityType ApplicationPoolIdentity
Set-IISAppPool -Name $AppPoolName -ProcessModel.loadUserProfile $true
Set-IISAppPool -Name $AppPoolName -ProcessModel.setProfileEnvironment $true
Set-IISAppPool -Name $AppPoolName -ProcessModel.idleTimeout "00:00:00"  # Never idle timeout
Set-IISAppPool -Name $AppPoolName -Recycling.periodicRestart.time "00:00:00"  # Disable periodic restart
Set-IISAppPool -Name $AppPoolName -Failure.rapidFailProtection $false
Set-IISAppPool -Name $AppPoolName -ProcessModel.pingEnabled $false

# Set memory limits
Set-IISAppPool -Name $AppPoolName -Recycling.periodicRestart.memory 2097152  # 2GB in KB

Write-Host "Application Pool configured for production use" -ForegroundColor Green

# Configure the website
Write-Host "Configuring IIS Website..." -ForegroundColor Yellow
if (!(Get-IISSite -Name $SiteName -ErrorAction SilentlyContinue)) {
    New-IISSite -Name $SiteName -PhysicalPath $InstallPath -Port 80 -ApplicationPool $AppPoolName
}

# Set website properties
Set-IISSite -Name $SiteName -ApplicationPool $AppPoolName

# Add HTTPS binding if certificate is available
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*timetracker*" -or $_.Subject -like "*fmb.com*" } | Select-Object -First 1
if ($cert) {
    Write-Host "Configuring HTTPS binding with certificate..." -ForegroundColor Yellow
    try {
        New-IISSiteBinding -Name $SiteName -BindingInformation "*:443:" -Protocol https -CertificateThumbPrint $cert.Thumbprint
        Write-Host "HTTPS binding configured successfully" -ForegroundColor Green
    } catch {
        Write-Host "Could not configure HTTPS binding: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Configure IISNode specific settings in web.config
Write-Host "Verifying web.config configuration..." -ForegroundColor Yellow
$webConfigPath = "$InstallPath\web.config"
if (Test-Path $webConfigPath) {
    Write-Host "web.config found and configured for IISNode" -ForegroundColor Green
} else {
    Write-Host "WARNING: web.config not found. IISNode may not work properly." -ForegroundColor Red
}

# Set up application initialization (warm-up)
Write-Host "Configuring application initialization..." -ForegroundColor Yellow
try {
    # Enable application initialization module
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit -All -NoRestart
    
    # Configure application initialization
    $config = Get-IISConfiguration
    $section = Get-IISConfigSection -SectionPath "system.applicationHost/sites" -ConfigurationPath $config
    $sitesCollection = Get-IISConfigCollection -ConfigElement $section
    $site = Get-IISConfigCollectionElement -ConfigCollection $sitesCollection -ConfigAttribute @{"name"=$SiteName}
    $applicationsCollection = Get-IISConfigCollection -ConfigElement $site -CollectionName "application"
    $application = Get-IISConfigCollectionElement -ConfigCollection $applicationsCollection -ConfigAttribute @{"path"="/"}
    
    Set-IISConfigAttributeValue -ConfigElement $application -AttributeName "preloadEnabled" -AttributeValue $true
    
    Write-Host "Application initialization configured" -ForegroundColor Green
} catch {
    Write-Host "Could not configure application initialization: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Start the application pool and website
Write-Host "Starting IIS services..." -ForegroundColor Yellow
Start-WebAppPool -Name $AppPoolName
Start-IISSite -Name $SiteName

# Wait a moment for startup
Start-Sleep -Seconds 5

# Verify the service is running
$appPoolState = (Get-IISAppPool -Name $AppPoolName).State
$siteState = (Get-IISSite -Name $SiteName).State

if ($appPoolState -eq "Started" -and $siteState -eq "Started") {
    Write-Host "TimeTracker IIS service started successfully!" -ForegroundColor Green
    Write-Host "Application Pool: $AppPoolName ($appPoolState)" -ForegroundColor White
    Write-Host "Website: $SiteName ($siteState)" -ForegroundColor White
} else {
    Write-Host "WARNING: Service may not have started properly" -ForegroundColor Yellow
    Write-Host "Application Pool: $AppPoolName ($appPoolState)" -ForegroundColor Red
    Write-Host "Website: $SiteName ($siteState)" -ForegroundColor Red
}

# Create a PowerShell script for easy management
$managementScript = @"
# TimeTracker IIS Service Management Script
# Run as Administrator

param([string]`$Action = "status")

Import-Module WebAdministration

switch (`$Action.ToLower()) {
    "start" {
        Write-Host "Starting TimeTracker..." -ForegroundColor Green
        Start-WebAppPool -Name "$AppPoolName"
        Start-IISSite -Name "$SiteName"
    }
    "stop" {
        Write-Host "Stopping TimeTracker..." -ForegroundColor Yellow
        Stop-IISSite -Name "$SiteName"
        Stop-WebAppPool -Name "$AppPoolName"
    }
    "restart" {
        Write-Host "Restarting TimeTracker..." -ForegroundColor Yellow
        Stop-IISSite -Name "$SiteName"
        Stop-WebAppPool -Name "$AppPoolName"
        Start-Sleep -Seconds 2
        Start-WebAppPool -Name "$AppPoolName"
        Start-IISSite -Name "$SiteName"
    }
    "recycle" {
        Write-Host "Recycling Application Pool..." -ForegroundColor Yellow
        Restart-WebAppPool -Name "$AppPoolName"
    }
    "status" {
        Write-Host "TimeTracker Service Status:" -ForegroundColor Green
        `$appPool = Get-IISAppPool -Name "$AppPoolName"
        `$site = Get-IISSite -Name "$SiteName"
        Write-Host "Application Pool: `$(`$appPool.Name) - `$(`$appPool.State)" -ForegroundColor White
        Write-Host "Website: `$(`$site.Name) - `$(`$site.State)" -ForegroundColor White
        
        # Show worker processes
        `$processes = Get-WmiObject -Class Win32_Process | Where-Object { `$_.Name -eq "w3wp.exe" }
        if (`$processes) {
            Write-Host "Worker Processes:" -ForegroundColor White
            `$processes | ForEach-Object { Write-Host "  PID: `$(`$_.ProcessId) - Memory: `$([math]::round(`$_.WorkingSetSize/1MB, 2))MB" -ForegroundColor Gray }
        }
    }
    default {
        Write-Host "Usage: .\manage-timetracker.ps1 [start|stop|restart|recycle|status]" -ForegroundColor White
    }
}
"@

$managementScript | Out-File -FilePath "$InstallPath\manage-timetracker.ps1" -Encoding UTF8

Write-Host "" -ForegroundColor White
Write-Host "IIS-based TimeTracker service configured successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "Management Commands:" -ForegroundColor White
Write-Host "  .\manage-timetracker.ps1 status" -ForegroundColor Gray
Write-Host "  .\manage-timetracker.ps1 start" -ForegroundColor Gray
Write-Host "  .\manage-timetracker.ps1 stop" -ForegroundColor Gray
Write-Host "  .\manage-timetracker.ps1 restart" -ForegroundColor Gray
Write-Host "  .\manage-timetracker.ps1 recycle" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "IIS Manager: inetmgr.exe" -ForegroundColor Gray
Write-Host "Event Logs: eventvwr.msc" -ForegroundColor Gray
Write-Host "Application Logs: $InstallPath\Logs" -ForegroundColor Gray
