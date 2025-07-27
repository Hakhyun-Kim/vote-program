Write-Host "========================================" -ForegroundColor Green
Write-Host "Solana Voting Program Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Docker is installed
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker is installed: $dockerVersion" -ForegroundColor Green
    } else {
        throw "Docker not found"
    }
} catch {
    Write-Host "✗ Docker is not installed." -ForegroundColor Red
    Write-Host "Please install Docker Desktop from:" -ForegroundColor Yellow
    Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if docker-compose is available
try {
    $composeVersion = docker-compose --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker Compose is available: $composeVersion" -ForegroundColor Green
    } else {
        throw "Docker Compose not found"
    }
} catch {
    Write-Host "✗ Docker Compose is not available." -ForegroundColor Red
    Write-Host "Please install Docker Desktop with Compose." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Docker is installed. Starting setup..." -ForegroundColor Green
Write-Host ""

# Build and run the container
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to build Docker image." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Starting Solana voting program..." -ForegroundColor Green
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "1. Start a local Solana validator" -ForegroundColor White
Write-Host "2. Build the voting program" -ForegroundColor White
Write-Host "3. Run all tests" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the program" -ForegroundColor Cyan
Write-Host ""

# Run the container
docker-compose up

Write-Host ""
Write-Host "Program finished. Press Enter to exit..." -ForegroundColor Green
Read-Host 