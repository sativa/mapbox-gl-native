#!/usr/bin/env bash

set -e
set -o pipefail
set -u

NAME=Mapbox
OUTPUT=build/osx/pkg
OSX_SDK_VERSION=`xcrun --sdk macosx --show-sdk-version`
LIBUV_VERSION=1.7.5

if [[ ${#} -eq 0 ]]; then # e.g. "make xpackage"
    BUILDTYPE="Release"
    GCC_GENERATE_DEBUGGING_SYMBOLS="YES"
else # e.g. "make xpackage-strip"
    BUILDTYPE="Release"
    GCC_GENERATE_DEBUGGING_SYMBOLS="NO"
fi

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

rm -rf ${OUTPUT}
mkdir -p "${OUTPUT}"

step "Recording library version…"
VERSION="${OUTPUT}"/version.txt
echo -n "https://github.com/mapbox/mapbox-gl-native/commit/" > ${VERSION}
HASH=`git log | head -1 | awk '{ print $2 }' | cut -c 1-10` && true
echo -n "mapbox-gl-native "
echo ${HASH}
echo ${HASH} >> ${VERSION}

step "Creating build files…"
export MASON_PLATFORM=osx
export BUILDTYPE=${BUILDTYPE:-Release}
export HOST=osx
make Xcode/osx

PROJ_VERSION=${TRAVIS_JOB_NUMBER:-${BITRISE_BUILD_NUMBER:-0}}

step "Building framework for OS X (build ${PROJ_VERSION})…"
xcodebuild -sdk macosx${OSX_SDK_VERSION} \
    ARCHS="x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
    CURRENT_PROJECT_VERSION=${PROJ_VERSION} \
    -project ./build/osx-x86_64/gyp/osx.xcodeproj \
    -configuration ${BUILDTYPE} \
    -target osxsdk \
    -jobs ${JOBS}

step "Copying OS X framework into place…"
cp -r \
    gyp/build/${BUILDTYPE}/${NAME}.framework \
    ${OUTPUT}/${NAME}.framework

# Uncomment when we're ready to release an official version.
#VERSION=$( git tag | grep ^osx | sed 's/^osx-//' | sort -r | grep -v '\-rc.' | grep -v '\-pre.' | sed -n '1p' | sed 's/^v//' )
#if [ "$VERSION" ]; then
#    step "Updating Info.plist (version ${VERSION})…"
#    INFOPLIST_PATH=${NAME}.framework/Versions/Current/Resources/Info.plist
#    plutil \
#        -replace CFBundleShortVersionString -string ${VERSION} \
#        ${OUTPUT}/$INFOPLIST_PATH
#    plutil \
#        -replace CFBundleVersion -string ${VERSION} \
#        ${OUTPUT}/$INFOPLIST_PATH
#fi

stat ${OUTPUT}/${NAME}.framework

step "Copying library resources…"
cp -pv LICENSE.md "${OUTPUT}"
