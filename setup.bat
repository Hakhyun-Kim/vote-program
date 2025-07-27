@echo off
echo ========================================
echo Solana Voting Program Setup
echo ========================================
echo.

:: Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not installed. Please install Docker Desktop from:
    echo https://www.docker.com/products/docker-desktop/
    echo.
    pause
    exit /b 1
)

:: Check if docker-compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker Compose is not available. Please install Docker Desktop with Compose.
    pause
    exit /b 1
)

echo Docker is installed. Starting setup...
echo.

:: Build and run the container
echo Building Docker image...
docker-compose build

if %errorlevel% neq 0 (
    echo Failed to build Docker image.
    pause
    exit /b 1
)

echo.
echo Starting Solana voting program...
echo This will:
echo 1. Start a local Solana validator
echo 2. Build the voting program
echo 3. Run all tests
echo.
echo Press Ctrl+C to stop the program
echo.

:: Run the container
docker-compose up

echo.
echo Program finished. Press any key to exit...
pause >nul 