@echo off
REM Binary setup helper script for Radiant Stratum Proxy

echo [*] Binary Setup Helper
echo ======================

echo [*] Checking Radiant binaries...

if exist "binaries\radiant\radiantd" (
    echo [OK] Radiant Daemon: Found
) else (
    echo [!!] Radiant Daemon: Missing
    echo     Expected: binaries\radiant\radiantd
)

if exist "binaries\radiant\radiant-cli" (
    echo [OK] Radiant CLI: Found
) else (
    echo [!!] Radiant CLI: Missing
    echo     Expected: binaries\radiant\radiant-cli
)

echo.
echo [*] Directory structure:
echo binaries\
echo +-- radiant\
if exist "binaries\radiant" (
    for %%f in (binaries\radiant\*) do (
        echo     +-- %%~nxf
    )
) else (
    echo     +-- ^(directory missing^)
)

echo.

REM Count missing binaries
set missing=0
if not exist "binaries\radiant\radiantd" set /a missing+=1
if not exist "binaries\radiant\radiant-cli" set /a missing+=1

if %missing%==0 (
    echo [SUCCESS] All required binaries are present!
    echo.
    echo [*] Next steps:
    echo 1. Build Docker images: docker compose build
    echo 2. Start services: docker compose up -d
    echo 3. Check logs: docker compose logs -f
) else (
    echo [WARNING] Missing %missing% required binaries
    echo.
    echo [*] To fix:
    echo 1. Download Radiant Node from https://github.com/radiantblockchain/radiant-node/releases
    echo 2. Extract radiantd and radiant-cli to binaries\radiant\
    echo 3. Run this script again to verify
    echo 4. Build Docker images: docker compose build
)

echo.
echo [HELP] Documentation:
echo   Binary requirements: See binaries\README.md
echo   Radiant setup: See binaries\radiant\README.md

pause
