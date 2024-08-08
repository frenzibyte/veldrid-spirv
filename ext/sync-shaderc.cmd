@setlocal
@echo off

python %~dp0update_shaderc_sources.py --dir %~dp0shaderc --file %~dp0known_good.json

:: Android NDK 27+ need this policy set on shaderc (as well as other tools)
echo cmake_policy(SET CMP0057 NEW^) >%~dp0shaderc\CMakeLists.txt.new
type %~dp0shaderc\CMakeLists.txt >>%~dp0shaderc\CMakeLists.txt.new
move /y %~dp0shaderc\CMakeLists.txt.new %~dp0shaderc\CMakeLists.txt
cat %~dp0shaderc\CMakeLists.txt
