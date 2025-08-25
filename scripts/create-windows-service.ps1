
# Create Windows Service for TimeTracker
# Run as Administrator

param(
    [string]$InstallPath = "C:\TimeTracker",
    [string]$ServiceName = "TimeTracker"
)

Write-Host "Creating Windows Service for TimeTracker..." -ForegroundColor Green

# Install PM2 as Windows service
Set-Location $InstallPath
pm2-startup install

# Start the application
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save

# Create Windows service using PM2
pm2-startup set -p

Write-Host "Windows service created successfully!" -ForegroundColor Green
Write-Host "Service name: $ServiceName" -ForegroundColor Yellow

# Alternative: Create native Windows service
$servicePath = "C:\TimeTracker\scripts\service-wrapper.exe"
$serviceArgs = @(
    "create",
    $ServiceName,
    "binPath=`"$servicePath`"",
    "DisplayName=`"TimeTracker Application Server`"",
    "start=auto"
)

try {
    & sc.exe @serviceArgs
    Write-Host "Native Windows service created: $ServiceName" -ForegroundColor Green
} catch {
    Write-Host "Using PM2 service instead" -ForegroundColor Yellow
}

# Set service to start automatically
Set-Service -Name $ServiceName -StartupType Automatic
Start-Service -Name $ServiceName

Write-Host "Service configured to start automatically" -ForegroundColor Green
param(
    [string]$InstallPath = "C:\TimeTracker"
)

$ErrorActionPreference = "Stop"

Write-Host "Creating Windows Service for TimeTracker..." -ForegroundColor Green

# Install PM2 globally if not already installed
npm install -g pm2
npm install -g pm2-windows-service

# Set working directory
Set-Location $InstallPath

# Create PM2 ecosystem file if it doesn't exist
if (!(Test-Path "ecosystem.config.js")) {
    Write-Host "Creating PM2 ecosystem configuration..." -ForegroundColor Yellow
    @"
module.exports = {
  apps: [{
    name: 'timetracker-pro',
    script: 'server/index.js',
    instances: 1,
    exec_mode: 'fork',
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000,
      SQL_SERVER: 'HUB-SQL1TST-LIS',
      SQL_USER: 'timetracker',
      SQL_PASSWORD: 'iTT!`$Lo7gm`"i\'JAg~5Y\\',
      SQL_DATABASE: 'timetracker'
    },
    error_file: 'C:\\TimeTracker\\logs\\err.log',
    out_file: 'C:\\TimeTracker\\logs\\out.log',
    log_file: 'C:\\TimeTracker\\logs\\combined.log',
    time: true,
    max_memory_restart: '1G',
    restart_delay: 4000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
"@ | Out-File -FilePath "ecosystem.config.js" -Encoding UTF8
}

# Install PM2 as Windows service
Write-Host "Installing PM2 as Windows service..." -ForegroundColor Yellow
pm2-service-install

# Start application with PM2
Write-Host "Starting TimeTracker application..." -ForegroundColor Yellow
pm2 start ecosystem.config.js --env production
pm2 save

Write-Host "Windows service created successfully!" -ForegroundColor Green
Write-Host "Service can be managed through Windows Services or PM2 commands" -ForegroundColor White
