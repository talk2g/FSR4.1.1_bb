@echo off
setlocal enabledelayedexpansion

title Building Lantern Engine and Launcher...
echo ========================================================
echo        Lantern Engine ^& Launcher Build Script
echo ========================================================
echo.

:: 1. Setup .NET SDK in PATH
if exist "%LocalAppData%\Microsoft\dotnet" (
    set "PATH=%LocalAppData%\Microsoft\dotnet;%PATH%"
)
where dotnet >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] .NET SDK not found. Please install .NET 8 SDK.
    goto :error
)

:: 2. Check MSYS2
if not exist "C:\msys64\usr\bin\bash.exe" (
    echo [ERROR] MSYS2 not found at C:\msys64.
    goto :error
)

:: Get current folder in Unix format for MSYS2 bash
set "RAW_DIR=%~dp0"
set "RAW_DIR=%RAW_DIR:~0,-1%"
set "RAW_DIR=%RAW_DIR:\=/%"
set "DRIVE=%RAW_DIR:~0,1%"
set "REST=%RAW_DIR:~2%"
:: convert drive letter to lowercase
for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    if /i "%DRIVE%"=="%%i" set "DRIVE=%%i"
)
set "UNIX_PATH=/%DRIVE%%REST%"

:: 3. Build Engine
echo [1/3] Building Lantern Engine (Clang64 / Vulkan)...
"C:\msys64\usr\bin\env.exe" MSYSTEM=CLANG64 CHERE_INVOKING=1 /usr/bin/bash.exe -lc ^
  "export PATH=/clang64/bin:$PATH; export CC=clang; export CXX=clang++; export BB_PGO=off; export BB_LTO=thin; cd '%UNIX_PATH%/engine' && chmod +x build.sh && ./build.sh"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Engine compilation failed. See above for details.
    goto :error
)
echo [OK] Engine compiled successfully.
echo.

:: 4. Build Launcher
echo [2/3] Building Launcher (Single-File standalone)...
pushd "launcher\windows\BloodborneLauncher"
dotnet publish -c Release -r win-x64 --self-contained true -o "%~dp0dist" --nologo -v m
set "DOTNET_STATUS=%errorlevel%"
popd

if %DOTNET_STATUS% neq 0 (
    echo.
    echo [ERROR] Launcher build failed. See above for details.
    goto :error
)
echo [OK] Launcher published successfully.
echo.

:: 5. Package files into dist/
echo [3/3] Packaging binaries and assets...
if not exist "%~dp0dist\engine\out" mkdir "%~dp0dist\engine\out"

copy /y "%~dp0engine\out\bb-probe.exe" "%~dp0dist\engine\out\" >nul
copy /y "%~dp0engine\out\bb-start.exe" "%~dp0dist\engine\out\" >nul
if exist "%~dp0engine\out\bb-gpu-capabilities.exe" (
    copy /y "%~dp0engine\out\bb-gpu-capabilities.exe" "%~dp0dist\engine\out\" >nul
)
if exist "%~dp0engine\patches" (
    xcopy /y /e /i /q "%~dp0engine\patches" "%~dp0dist\engine\patches" >nul
)
if exist "%~dp0engine\lantern.default.ini" (
    copy /y "%~dp0engine\lantern.default.ini" "%~dp0dist\engine\" >nul
)

echo.
echo ========================================================
echo    SUCCESS! Everything compiled and packaged.
echo    Output folder: %~dp0dist
echo ========================================================
echo.
echo The window will stay open so you can review or copy output.
cmd /k
exit /b 0

:error
echo.
echo ========================================================
echo    BUILD FAILED! Check the error messages above.
echo ========================================================
echo.
echo The window will stay open so you can select and copy the errors.
cmd /k
exit /b 1
