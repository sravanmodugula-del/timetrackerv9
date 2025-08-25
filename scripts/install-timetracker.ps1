
# TimeTracker Windows Installation Script
# Run as Administrator in PowerShell

param(
    [string]$InstallPath = "C:\TimeTracker",
    [string]$Domain = "localhost",
    [string]$SqlServer = "HUB-SQL1TST-LIS",
    [string]$SqlUser = "timetracker",
    [string]$SqlPassword = "iTT!$Lo7gm`"i'JAg~5Y\"
)

Write-Host "Starting TimeTracker Installation..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Create installation directory
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Force -Path $InstallPath
    Write-Host "Created installation directory: $InstallPath" -ForegroundColor Yellow
}

Set-Location $InstallPath

# Clone or extract application files (assuming you have the source)
# For this example, we'll assume files are already extracted to current directory

# Install application dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install --production

# Install additional Windows-specific packages
npm install mssql tedious
npm install pm2-windows-startup pm2-windows-service

# Generate Prisma Client
Write-Host "Generating Prisma Client..." -ForegroundColor Yellow
npx prisma generate

# Build the application
Write-Host "Building application..." -ForegroundColor Yellow
npm run build

# Create Windows service user
$ServiceUser = "NT SERVICE\TimeTracker"
Write-Host "Creating service user: $ServiceUser" -ForegroundColor Yellow

# Create environment file
$envContent = @"
NODE_ENV=production
PORT=3000
DB_SERVER=$SqlServer
DB_USER=$SqlUser
DB_PASSWORD=$SqlPassword
DB_NAME=timetracker
DB_PORT=1433
DB_ENCRYPT=false
DB_TRUST_CERT=true
SESSION_SECRET=$(([System.Web.Security.Membership]::GeneratePassword(32, 8)))
APP_URL=https://$Domain
ALLOWED_ORIGINS=https://$Domain
TZ=America/Los_Angeles
"@

$envContent | Out-File -FilePath "$InstallPath\.env" -Encoding utf8
Write-Host "Environment file created" -ForegroundColor Green

# Set proper file permissions
$acl = Get-Acl $InstallPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $InstallPath $acl

Write-Host "File permissions configured" -ForegroundColor Green

# Create PM2 ecosystem file for Windows
$ecosystemContent = @"
module.exports = {
  apps: [{
    name: 'timetracker',
    script: 'server/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '$InstallPath/logs/err.log',
    out_file: '$InstallPath/logs/out.log',
    log_file: '$InstallPath/logs/combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
};
"@

$ecosystemContent | Out-File -FilePath "$InstallPath\ecosystem.config.js" -Encoding utf8

# Create logs directory
New-Item -ItemType Directory -Force -Path "$InstallPath\logs"

Write-Host "TimeTracker installation completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure IIS reverse proxy" -ForegroundColor White
Write-Host "2. Install SSL certificate" -ForegroundColor White
Write-Host "3. Start the application with PM2" -ForegroundColor White
param(
    [string]$InstallPath = "C:\TimeTracker",
    [string]$Domain = "timetracker.fmb.com",
    [string]$SqlServer = "HUB-SQL1TST-LIS",
    [string]$SqlUser = "timetracker",
    [string]$SqlPassword = "iTT!`$Lo7gm`"i'JAg~5Y\"
)

$ErrorActionPreference = "Stop"

Write-Host "Installing TimeTracker Application..." -ForegroundColor Green

# Create installation directory
New-Item -Path $InstallPath -ItemType Directory -Force
New-Item -Path "$InstallPath\Logs" -ItemType Directory -Force

# Set working directory
Set-Location $InstallPath

# Clone or copy application files
Write-Host "Copying application files..." -ForegroundColor Yellow
# Assuming files are already present, otherwise use git clone or copy commands

# Install Node.js dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install --production

# Generate Prisma client
Write-Host "Generating Prisma client..." -ForegroundColor Yellow
npx prisma generate

# Create environment file
Write-Host "Creating environment configuration..." -ForegroundColor Yellow
@"
NODE_ENV=production
PORT=3000
SQL_SERVER=$SqlServer
SQL_USER=$SqlUser
SQL_PASSWORD=$SqlPassword
SQL_DATABASE=timetracker
DATABASE_URL=sqlserver://${SqlServer}:1433;database=timetracker;user=${SqlUser};password=${SqlPassword};encrypt=true;trustServerCertificate=true
DOMAIN=$Domain
SESSION_SECRET=$(([System.Web.Security.Membership]::GeneratePassword(32, 8)))
"@ | Out-File -FilePath "$InstallPath\.env" -Encoding UTF8

Write-Host "TimeTracker application installed successfully!" -ForegroundColor Green
