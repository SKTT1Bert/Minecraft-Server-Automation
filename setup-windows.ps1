# Windows Setup Script for Minecraft Server Deployment
# This script helps Windows users set up the project

Write-Host "Setting up Minecraft Server Deployment Project..." -ForegroundColor Green

# Check if running in WSL or PowerShell
if ($env:WSL_DISTRO_NAME) {
    Write-Host "Detected WSL environment. Using Linux commands..." -ForegroundColor Yellow
    
    # Make scripts executable in WSL
    bash -c "chmod +x deploy.sh destroy.sh"
    Write-Host "Scripts made executable" -ForegroundColor Green
} else {
    Write-Host "Detected Windows PowerShell environment" -ForegroundColor Yellow
    Write-Host "Note: You'll need to use WSL or Git Bash to run the bash scripts" -ForegroundColor Yellow
    
    # Create Windows batch file alternatives
    @"
@echo off
echo Starting Minecraft Server Deployment...
wsl ./deploy.sh
"@ | Out-File -FilePath "deploy.bat" -Encoding ASCII
    
    @"
@echo off
echo Starting Infrastructure Destruction...
wsl ./destroy.sh
"@ | Out-File -FilePath "destroy.bat" -Encoding ASCII
    
    Write-Host "Created Windows batch files: deploy.bat and destroy.bat" -ForegroundColor Green
}

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Blue

$missing = @()

# Check Terraform
try {
    $terraformVersion = & terraform version 2>$null
    Write-Host "✓ Terraform: Found" -ForegroundColor Green
} catch {
    Write-Host "✗ Terraform: Not found" -ForegroundColor Red
    $missing += "Terraform"
}

# Check AWS CLI
try {
    $awsVersion = & aws --version 2>$null
    Write-Host "✓ AWS CLI: Found" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI: Not found" -ForegroundColor Red
    $missing += "AWS CLI"
}

# Check Ansible (in WSL)
if ($env:WSL_DISTRO_NAME) {
    try {
        $ansibleVersion = & ansible --version 2>$null
        Write-Host "✓ Ansible: Found" -ForegroundColor Green
    } catch {
        Write-Host "✗ Ansible: Not found" -ForegroundColor Red
        $missing += "Ansible"
    }
} else {
    try {
        $ansibleVersion = wsl ansible --version 2>$null
        Write-Host "✓ Ansible: Found in WSL" -ForegroundColor Green
    } catch {
        Write-Host "✗ Ansible: Not found in WSL" -ForegroundColor Red
        $missing += "Ansible (in WSL)"
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`nMissing prerequisites:" -ForegroundColor Red
    foreach ($item in $missing) {
        Write-Host "  - $item" -ForegroundColor Red
    }
    Write-Host "`nPlease install missing tools before proceeding." -ForegroundColor Yellow
} else {
    Write-Host "`n✓ All prerequisites found!" -ForegroundColor Green
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Configure AWS credentials: aws configure" -ForegroundColor White
Write-Host "2. Run deployment:" -ForegroundColor White
if ($env:WSL_DISTRO_NAME) {
    Write-Host "   ./deploy.sh" -ForegroundColor Cyan
} else {
    Write-Host "   deploy.bat (or use WSL: wsl ./deploy.sh)" -ForegroundColor Cyan
} 