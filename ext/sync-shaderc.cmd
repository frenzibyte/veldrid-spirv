@setlocal
@echo off

python %~dp0update_shaderc_sources.py --dir %~dp0shaderc --file %~dp0known_good.json

:: Android NDK 27+ need this policy set on shaderc (as well as other tools)
ren >%~dp0shaderc\CMakeLists.txt >%~dp0shaderc\CMakeLists.tmp

set p=
for /f %%a in (%~dp0shaderc\CMakeLists.tmp) do (
  if "!p!"=="cmake_minimum_required^(VERSION 2.8.12^)" Echo "cmake_policy^(SET CMP0057 NEW^)" >>%~dp0shaderc\CMakeLists.txt
  Echo %%a >>%~dp0shaderc\CMakeLists.tmp
  set p=%%a
)
del %~dp0shaderc\CMakeLists.tmp
