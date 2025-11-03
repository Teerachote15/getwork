<#
Patch generated Flutter/CMake Windows build files to avoid invoking cmake_install.cmake
This script is a local workaround: it will:
 - Backup existing generated files under build/windows/x64
 - Replace `cmake_install.cmake` with an early-return so it does nothing
 - Replace the PostBuildEvent in INSTALL.vcxproj to a harmless echo (no cmake invocation)

Run this from the `frontend/mobile` folder BEFORE running `flutter build windows` (or right after a failed build that regenerated files).
#>

$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$buildX64 = Join-Path $root "build\windows\x64"

if (!(Test-Path $buildX64)) {
    Write-Host "Build folder not found: $buildX64" -ForegroundColor Yellow
    exit 1
}

function Backup-IfExists($path) {
    if (Test-Path $path) {
        $bak = "$path.bak"
        Copy-Item -Path $path -Destination $bak -Force
        Write-Host "Backed up: $path -> $bak"
    }
}

# Patch cmake_install.cmake
$cmakeInstall = Join-Path $buildX64 "cmake_install.cmake"
if (Test-Path $cmakeInstall) {
    Backup-IfExists $cmakeInstall
    $content = Get-Content $cmakeInstall -Raw
    # Insert an early-return after the CMAKE_INSTALL_CONFIG_NAME block
    if ($content -notmatch "INSTALL SCRIPT DISABLED BY LOCAL PATCH") {
        $insertion = "`n# LOCAL PATCH: disable install script to avoid MSBuild/CMake failures`nmessage(STATUS \"INSTALL SCRIPT DISABLED BY LOCAL PATCH: skipping all install actions\")`nreturn()`n"
        # find the first occurrence of the Install configuration message and insert after it
        $marker = "message(STATUS \"Install configuration: \"\${CMAKE_INSTALL_CONFIG_NAME}\"\")"
        if ($content.Contains($marker)) {
            $new = $content -replace [regex]::Escape($marker), "$marker`n$insertion"
        } else {
            # Fallback: prepend at top
            $new = $insertion + $content
        }
        $new | Set-Content $cmakeInstall -Force -Encoding UTF8
        Write-Host "Patched: $cmakeInstall"
    } else {
        Write-Host "Already patched: $cmakeInstall"
    }
} else {
    Write-Host "Not found: $cmakeInstall" -ForegroundColor Yellow
}

# Patch INSTALL.vcxproj to remove cmake invocation
$installProj = Join-Path $buildX64 "INSTALL.vcxproj"
if (Test-Path $installProj) {
    Backup-IfExists $installProj
    $proj = Get-Content $installProj -Raw
    if ($proj -match "cmake.exe" -and $proj -notmatch "Skipping generated CMake install step") {
        # Replace any <PostBuildEvent>...</PostBuildEvent> blocks that invoke cmake.exe
        $pattern = '(?s)<PostBuildEvent>.*?<Command>.*?cmake.exe.*?cmake_install.cmake.*?</Command>.*?</PostBuildEvent>'
        $replacement = '<PostBuildEvent><UseUtf8Encoding>Always</UseUtf8Encoding><Message>Skipping generated CMake install step (disabled)</Message><Command>echo Skipping generated CMake install step</Command></PostBuildEvent>'
        $newproj = [regex]::Replace($proj, $pattern, $replacement)
        if ($newproj -ne $proj) {
            $newproj | Set-Content $installProj -Force -Encoding UTF8
            Write-Host "Patched: $installProj"
        } else {
            Write-Host "No cmake PostBuildEvent found in $installProj"
        }
    } else {
        Write-Host "Either already patched or no cmake invocation in: $installProj"
    }
} else {
    Write-Host "Not found: $installProj" -ForegroundColor Yellow
}

Write-Host "Done. Now run: flutter build windows -v | Tee-Object flutter_build_windows_verbose.txt" -ForegroundColor Green
