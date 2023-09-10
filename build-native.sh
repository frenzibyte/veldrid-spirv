#!/usr/bin/env bash

scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"
_CMakeBuildType=Debug
_CMakeToolchain=
_CMakeEnableBitcode=
_OutputPathPrefix=
_CMakeBuildTarget=veldrid-spirv
_CMakeOsxArchitectures=
_CMakeGenerator=
_CMakeExtraBuildArgs=
_OSDir=

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        debug|-debug)
            _CMakeBuildType=Debug
            ;;
        release|-release)
            _CMakeBuildType=Release
            ;;
        osx)
            _CMakeOsxArchitectures=$2
            _OSDir=osx
            shift
            ;;
        linux-x64)
            _OSDir=linux-x64
            ;;
        ios)
            _CMakeToolchain=-DCMAKE_TOOLCHAIN_FILE=$scriptPath/ios/ios.toolchain.cmake
            _CMakeEnableBitcode=-DENABLE_BITCODE=0
            _CMakeBuildTarget=veldrid-spirv
            _CMakeGenerator="-G Xcode -T buildsystem=1"
            _CMakeExtraBuildArgs="--config Release"
            _OSDir=ios
            ;;
        *)
            __UnprocessedBuildArgs="$__UnprocessedBuildArgs $1"
    esac

    shift
done

_OutputPath=$scriptPath/build/$_CMakeBuildType/$_OSDir
_PythonExePath=$(which python3)
if [[ $_PythonExePath == "" ]]; then
    echo Build failed: could not locate python executable.
    exit 1
fi

mkdir -p $_OutputPath
pushd $_OutputPath
# cmake ../../.. -DCMAKE_BUILD_TYPE=$_CMakeBuildType $_CMakeGenerator $_CMakeToolchain $_CMakePlatform $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath -DCMAKE_OSX_ARCHITECTURES="$_CMakeOsxArchitectures" -DCMAKE_OSX_SYSROOT_INT=~/Downloads/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.4.sdk -DXCODE_VERSION_INT=11.4 -DSDK_VERSION=13.4 -DDEPLOYMENT_TARGET=$_CMakeDeploymentTarget -DCMAKE_C_COMPILER=~/Downloads/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -DCMAKE_CXX_COMPILER=~/Downloads/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++ -DBUILD_LIBTOOL=~/Downloads/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool -DCMAKE_INSTALL_NAME_TOOL=~/Downloads/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool -DSDK_NAME=iphoneos

if [[ $_OSDir == "ios" ]]; then
    mkdir -p device-build
    pushd device-build

    cmake ../../../.. -DCMAKE_BUILD_TYPE=$_CMakeBuildType $_CMakeGenerator $_CMakeToolchain -DPLATFORM=OS64 -DDEPLOYMENT_TARGET=13.4 $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath -DCMAKE_OSX_ARCHITECTURES="$_CMakeOsxArchitectures"
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs

    popd
    
    mkdir -p simulator-build
    pushd simulator-build

    cmake ../../../.. -DCMAKE_BUILD_TYPE=$_CMakeBuildType $_CMakeGenerator $_CMakeToolchain -DPLATFORM=SIMULATOR64 -DDEPLOYMENT_TARGET=13.4 $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath -DCMAKE_OSX_ARCHITECTURES="$_CMakeOsxArchitectures"
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs

    popd

    xcodebuild -create-xcframework -framework ./device/Release-iphoneos/veldrid-spirv.framework -framework ./simulator/Release-iphonesimulator/veldrid-spirv.framework -output ./veldrid-spirv.xcframework
else
    cmake ../../.. -DCMAKE_BUILD_TYPE=$_CMakeBuildType $_CMakeGenerator $_CMakeToolchain $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath -DCMAKE_OSX_ARCHITECTURES="$_CMakeOsxArchitectures"
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs
fi

popd
