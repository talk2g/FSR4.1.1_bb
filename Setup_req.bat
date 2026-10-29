@echo off
setlocal enabledelayedexpansion

title Setup Dependencies for Lantern Engine Build...
echo ========================================================
echo   Lantern Engine ^& Launcher Prerequisites Setup
echo ========================================================
echo.

:: 1. Check & Install .NET 8 SDK
echo [1/4] Checking .NET 8 SDK...
set "DOTNET_DIR=%LocalAppData%\Microsoft\dotnet"
if exist "%DOTNET_DIR%" set "PATH=%DOTNET_DIR%;%PATH%"

where dotnet >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] .NET 8 SDK not found. Installing locally to %DOTNET_DIR%...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://dot.net/v1/dotnet-install.ps1', '$env:TEMP\dotnet-install.ps1'); & '$env:TEMP\dotnet-install.ps1' -Channel 8.0 -InstallDir '$env:LocalAppData\Microsoft\dotnet'"
    set "PATH=%DOTNET_DIR%;%PATH%"
)

where dotnet >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install .NET 8 SDK. Please install it manually from https://dotnet.microsoft.com/download/dotnet/8.0
    goto :error
)
echo [OK] .NET 8 SDK is ready.
echo.

:: 2. Check MSYS2
echo [2/4] Checking MSYS2 installation...
if not exist "C:\msys64\usr\bin\bash.exe" (
    echo [INFO] MSYS2 not found at C:\msys64. Attempting to install via winget...
    winget install --id MSYS2.MSYS2 --silent --accept-package-agreements --accept-source-agreements
    if not exist "C:\msys64\usr\bin\bash.exe" (
        echo [ERROR] MSYS2 installation failed or needs a restart.
        echo Please download and install MSYS2 to C:\msys64 manually from: https://www.msys2.org/
        goto :error
    )
)
echo [OK] MSYS2 is installed at C:\msys64.
echo.

:: 3. Install MSYS2 CLANG64 Packages
echo [3/4] Installing MSYS2 CLANG64 compiler, libraries, and tools...
echo [INFO] This downloads Clang, CMake, Ninja, Vulkan, SDL3, FFmpeg, Boost, etc. Please wait...
"C:\msys64\usr\bin\pacman.exe" -S --needed --noconfirm ^
    mingw-w64-clang-x86_64-clang ^
    mingw-w64-clang-x86_64-lld ^
    mingw-w64-clang-x86_64-llvm ^
    mingw-w64-clang-x86_64-cmake ^
    mingw-w64-clang-x86_64-ninja ^
    mingw-w64-clang-x86_64-pkgconf ^
    mingw-w64-clang-x86_64-vulkan-headers ^
    mingw-w64-clang-x86_64-vulkan-loader ^
    mingw-w64-clang-x86_64-sdl3 ^
    mingw-w64-clang-x86_64-zlib ^
    mingw-w64-clang-x86_64-expat ^
    mingw-w64-clang-x86_64-fmt ^
    mingw-w64-clang-x86_64-boost ^
    mingw-w64-clang-x86_64-robin-map ^
    mingw-w64-clang-x86_64-xxhash ^
    mingw-w64-clang-x86_64-zydis ^
    mingw-w64-clang-x86_64-glslang ^
    mingw-w64-clang-x86_64-ffmpeg ^
    mingw-w64-clang-x86_64-miniupnpc ^
    mingw-w64-clang-x86_64-openssl ^
    mingw-w64-clang-x86_64-protobuf ^
    mingw-w64-clang-x86_64-nlohmann-json

if %errorlevel% neq 0 (
    echo [ERROR] Failed to install one or more MSYS2 packages.
    goto :error
)
echo [OK] All MSYS2 CLANG64 packages installed.
echo.

:: 4. Install Vulkan Memory Allocator (VMA) & Compatibility Fixes
echo [4/4] Setting up AMD VMA and compiler header fixes...
if not exist "C:\msys64\clang64\include\vma" mkdir "C:\msys64\clang64\include\vma"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$vmaPath = 'C:\msys64\clang64\include\vma\vk_mem_alloc.h';" ^
    "if (-not (Test-Path $vmaPath)) { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/master/include/vk_mem_alloc.h' -OutFile $vmaPath };" ^
    "Copy-Item $vmaPath 'C:\msys64\clang64\include\vk_mem_alloc.h' -Force"

:: Patch _countof in corecrt.h if missing
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$h = 'C:\msys64\clang64\include\corecrt.h';" ^
    "if (Test-Path $h) { $c = Get-Content $h -Raw; if ($c -notmatch '_countof') { Add-Content $h \"`n#ifndef _countof`n#define _countof(_Array) (sizeof(_Array) / sizeof(_Array[0]))`n#endif`n\" } }"

echo [OK] VMA and header fixes applied.
echo.

echo ========================================================
echo   SUCCESS! All dependencies and tools are ready!
echo   You can now run 'build-all.bat' to build the project.
echo ========================================================
echo.
cmd /k
exit /b 0

:error
echo.
echo ========================================================
echo   SETUP FAILED! Check the error messages above.
echo ========================================================
echo.
cmd /k
exit /b 1
