@echo off
echo ========================================
echo Solana Voting Program (No Docker)
echo ========================================
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Node.js is not installed. Please install from:
    echo https://nodejs.org/
    pause
    exit /b 1
)

:: Check if Rust is installed
cargo --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Rust is not installed. Please install from:
    echo https://rustup.rs/
    pause
    exit /b 1
)

:: Check if Solana CLI is installed
solana --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Solana CLI is not installed. Please install from:
    echo https://docs.solana.com/cli/install-solana-cli-tools
    pause
    exit /b 1
)

:: Check if Anchor CLI is installed
anchor --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Anchor CLI...
    npm install -g @coral-xyz/anchor-cli
    if %errorlevel% neq 0 (
        echo Failed to install Anchor CLI.
        pause
        exit /b 1
    )
)

echo All required tools are installed!
echo.

:: Install dependencies
echo Installing Node.js dependencies...
npm install

:: Build the program
echo Building the program...
anchor build

if %errorlevel% neq 0 (
    echo Failed to build the program.
    pause
    exit /b 1
)

echo.
echo Starting Solana validator in background...
start /B solana-test-validator

:: Wait for validator to start
echo Waiting for validator to start...
timeout /t 5 /nobreak >nul

echo.
echo Running tests...
anchor test --skip-local-validator

echo.
echo Tests completed. Press any key to exit...
pause >nul 