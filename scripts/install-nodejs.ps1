
# Install Node.js 20.x LTS on Windows
# Run as Administrator

Write-Host "Installing Node.js 20.x LTS..." -ForegroundColor Green

# Download and install Node.js
$nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
$nodeInstaller = "$env:TEMP\nodejs-installer.msi"

Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
Start-Process msiexec.exe -Wait -ArgumentList "/i $nodeInstaller /quiet /norestart"

# Add Node.js to PATH if not already there
$nodePath = "C:\Program Files\nodejs"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$nodePath", "Machine")
}

# Refresh environment variables
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

# Verify installation
node --version
npm --version

# Install PM2 globally for process management
npm install -g pm2
npm install -g pm2-windows-startup

Write-Host "Node.js and PM2 installed successfully!" -ForegroundColor Green

# Clean up
Remove-Item $nodeInstaller -Force
