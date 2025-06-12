# AWS Academy Credentials Configuration Script
# This script helps you configure AWS credentials for the project

Write-Host "AWS Academy Credentials Configuration" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Please follow these steps to get your AWS Academy credentials:" -ForegroundColor Yellow
Write-Host "1. Go to your AWS Academy course page" -ForegroundColor White
Write-Host "2. Click on 'Learner Lab' module" -ForegroundColor White
Write-Host "3. Click 'Start Lab' button" -ForegroundColor White
Write-Host "4. Wait for the lab to start (green indicator)" -ForegroundColor White
Write-Host "5. Click 'AWS Details' button" -ForegroundColor White
Write-Host "6. Click 'Show' to reveal credentials" -ForegroundColor White
Write-Host ""

# Get credentials from user
Write-Host "Enter your AWS Academy credentials:" -ForegroundColor Cyan

$AccessKeyId = Read-Host "AWS Access Key ID"
$SecretAccessKey = Read-Host "AWS Secret Access Key" -AsSecureString
$SessionToken = Read-Host "AWS Session Token"
$Region = Read-Host "AWS Region [default: us-east-1]"

# Convert secure string back to plain text
$SecretAccessKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretAccessKey))

# Set default region if not provided
if ([string]::IsNullOrWhiteSpace($Region)) {
    $Region = "us-east-1"
}

# Set environment variables
$env:AWS_ACCESS_KEY_ID = $AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $SecretAccessKeyPlain
$env:AWS_SESSION_TOKEN = $SessionToken
$env:AWS_DEFAULT_REGION = $Region

Write-Host ""
Write-Host "✓ AWS credentials configured successfully!" -ForegroundColor Green
Write-Host "Region set to: $Region" -ForegroundColor Green

# Test AWS connection
Write-Host ""
Write-Host "Testing AWS connection..." -ForegroundColor Blue

try {
    $identity = aws sts get-caller-identity --output table 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ AWS connection successful!" -ForegroundColor Green
        Write-Host $identity
    } else {
        Write-Host "✗ AWS connection failed. Please check your credentials." -ForegroundColor Red
    }
} catch {
    Write-Host "✗ AWS CLI not found or connection failed." -ForegroundColor Red
}

Write-Host ""
Write-Host "Your credentials are now configured for this PowerShell session." -ForegroundColor Yellow
Write-Host "To persist these settings, you can add them to your PowerShell profile." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run the deployment script" -ForegroundColor Cyan
Write-Host "  .\deploy.sh (in WSL) or deploy.bat" -ForegroundColor Cyan 