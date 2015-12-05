#!/usr/bin/env bash

set -e
set -o pipefail
set -u

NAME=Mapbox
OUTPUT=build/ios/pkg
IOS_SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
LIBUV_VERSION=1.7.5
ENABLE_BITCODE=YES

if [[ ${#} -eq 0 ]]; then # e.g. "make ipackage"
    BUILDTYPE="Release"
    BUILD_FOR_DEVICE=true
    GCC_GENERATE_DEBUGGING_SYMBOLS="YES"
elif [[ ${1} == "no-bitcode" ]]; then # e.g. "make ipackage-no-bitcode"
    BUILDTYPE="Release"
    BUILD_FOR_DEVICE=true
    GCC_GENERATE_DEBUGGING_SYMBOLS="YES"
    ENABLE_BITCODE=NO
elif [[ ${1} == "sim" ]]; then # e.g. "make ipackage-sim"
    BUILDTYPE="Debug"
    BUILD_FOR_DEVICE=false
    GCC_GENERATE_DEBUGGING_SYMBOLS="YES"
else # e.g. "make ipackage-strip"
    BUILDTYPE="Release"
    BUILD_FOR_DEVICE=true
    GCC_GENERATE_DEBUGGING_SYMBOLS="NO"
fi

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT


rm -rf ${OUTPUT}
mkdir -p "${OUTPUT}"/static
mkdir -p "${OUTPUT}"/dynamic


step "Recording library version…"
VERSION="${OUTPUT}"/version.txt
echo -n "https://github.com/mapbox/mapbox-gl-native/commit/" > ${VERSION}
HASH=`git log | head -1 | awk '{ print $2 }' | cut -c 1-10` && true
echo -n "mapbox-gl-native "
echo ${HASH}
echo ${HASH} >> ${VERSION}


step "Creating build files…"
export MASON_PLATFORM=ios
export BUILDTYPE=${BUILDTYPE:-Release}
export HOST=ios
make Xcode/ios

PROJ_VERSION=${TRAVIS_JOB_NUMBER:-${BITRISE_BUILD_NUMBER:-0}}

if [[ "${BUILD_FOR_DEVICE}" == true ]]; then
    step "Building intermediate static libraries for iOS devices (build ${PROJ_VERSION})…"
    xcodebuild -sdk iphoneos${IOS_SDK_VERSION} \
        ARCHS="arm64 armv7 armv7s" \
        ONLY_ACTIVE_ARCH=NO \
        GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
        ENABLE_BITCODE=${ENABLE_BITCODE} \
        DEPLOYMENT_POSTPROCESSING=YES \
        -project ./build/ios-all/gyp/mbgl.xcodeproj \
        -configuration ${BUILDTYPE} \
        -target everything \
        -jobs ${JOBS}
    
    step "Building framework for iOS devices (build ${PROJ_VERSION})…"
    xcodebuild -sdk iphoneos${IOS_SDK_VERSION} \
        ARCHS="arm64 armv7 armv7s" \
        ONLY_ACTIVE_ARCH=NO \
        GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
        ENABLE_BITCODE=${ENABLE_BITCODE} \
        DEPLOYMENT_POSTPROCESSING=YES \
        CURRENT_PROJECT_VERSION=${PROJ_VERSION} \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY= \
        -project ./build/ios-all/gyp/ios.xcodeproj \
        -configuration ${BUILDTYPE} \
        -target iossdk \
        -jobs ${JOBS}
fi

step "Building intermediate static libraries for iOS Simulator (build ${PROJ_VERSION})…"
xcodebuild -sdk iphonesimulator${IOS_SDK_VERSION} \
    ARCHS="x86_64 i386" \
    ONLY_ACTIVE_ARCH=NO \
    GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
    -project ./build/ios-all/gyp/mbgl.xcodeproj \
    -configuration ${BUILDTYPE} \
    -target everything \
    -jobs ${JOBS}

step "Building framework for iOS Simulator (build ${PROJ_VERSION})…"
xcodebuild -sdk iphonesimulator${IOS_SDK_VERSION} \
    ARCHS="x86_64 i386" \
    ONLY_ACTIVE_ARCH=NO \
    GCC_GENERATE_DEBUGGING_SYMBOLS=${GCC_GENERATE_DEBUGGING_SYMBOLS} \
    ENABLE_BITCODE=${ENABLE_BITCODE} \
    CURRENT_PROJECT_VERSION=${PROJ_VERSION} \
    -project ./build/ios-all/gyp/ios.xcodeproj \
    -configuration ${BUILDTYPE} \
    -target iossdk \
    -jobs ${JOBS}

LIBS=(core.a platform-ios.a asset-fs.a cache-sqlite.a http-nsurl.a)

# https://medium.com/@syshen/create-an-ios-universal-framework-148eb130a46c
if [[ "${BUILD_FOR_DEVICE}" == true ]]; then
    step "Assembling static library for iOS devices…"
    libtool -static -no_warning_for_no_symbols \
        `find mason_packages/ios-${IOS_SDK_VERSION} -type f -name libuv.a` \
        `find mason_packages/ios-${IOS_SDK_VERSION} -type f -name libgeojsonvt.a` \
        -o ${OUTPUT}/static/lib${NAME}.a \
        ${LIBS[@]/#/gyp/build/${BUILDTYPE}-iphoneos/libmbgl-} \
        ${LIBS[@]/#/gyp/build/${BUILDTYPE}-iphonesimulator/libmbgl-}
    
    step "Copying iOS Simulator framework into place…"
    cp -r \
        gyp/build/${BUILDTYPE}-iphoneos/${NAME}.framework \
        ${OUTPUT}/dynamic/
    
    step "Merging simulator framework into device framework…"
    lipo \
        gyp/build/${BUILDTYPE}-iphoneos/${NAME}.framework/${NAME} \
        gyp/build/${BUILDTYPE}-iphonesimulator/${NAME}.framework/${NAME} \
        -create -output ${OUTPUT}/dynamic/${NAME}.framework/${NAME} | echo
else
    step "Assembling static library for iOS Simulator…"
    libtool -static -no_warning_for_no_symbols \
        `find mason_packages/ios-${IOS_SDK_VERSION} -type f -name libuv.a` \
        `find mason_packages/ios-${IOS_SDK_VERSION} -type f -name libgeojsonvt.a` \
        -o ${OUTPUT}/static/lib${NAME}.a \
        ${LIBS[@]/#/gyp/build/${BUILDTYPE}-iphonesimulator/libmbgl-}
    
    step "Copying iOS Simulator framework into place…"
    cp -r \
        gyp/build/${BUILDTYPE}-iphonesimulator/${NAME}.framework \
        ${OUTPUT}/dynamic/${NAME}.framework
fi

stat ${OUTPUT}/static/lib${NAME}.a
stat ${OUTPUT}/dynamic/${NAME}.framework

step "Copying library resources…"
cp -pv LICENSE.md "${OUTPUT}"
cp -rv ios/app/Settings.bundle "${OUTPUT}"
mkdir -p "${OUTPUT}/static/${NAME}.bundle"
cp -pv platform/ios/resources/* "${OUTPUT}/static/${NAME}.bundle"

step "Generating API documentation…"
if [ -z `which appledoc` ]; then
    echo "Unable to find appledoc. See https://github.com/mapbox/mapbox-gl-native/blob/master/docs/BUILD_IOS_OSX.md"
    exit 1
fi
DOCS_OUTPUT="${OUTPUT}/documentation"
DOCS_VERSION=$( git tag | grep ^ios | sed 's/^ios-//' | sort -r | grep -v '\-rc.' | grep -v '\-pre.' | sed -n '1p' | sed 's/^v//' )
rm -rf /tmp/mbgl
mkdir -p /tmp/mbgl/
README=/tmp/mbgl/README.md
cat ios/docs/pod-README.md > ${README}
echo >> ${README}
echo -n "#" >> ${README}
cat CHANGELOG.md | sed -n "/^## iOS ${DOCS_VERSION}/,/^##/p" | sed '$d' >> ${README}
# Copy headers to a temporary location where we can substitute macros that appledoc doesn't understand.
cp -r "${OUTPUT}/dynamic/${NAME}.framework/Headers" /tmp/mbgl
perl \
    -pi \
    -e 's/NS_(?:(MUTABLE)_)?(ARRAY|SET|DICTIONARY)_OF\(\s*(.+?)\s*\)/NS\L\u$1\u$2\E <$3>/g' \
    /tmp/mbgl/Headers/*.h
appledoc \
    --output ${DOCS_OUTPUT} \
    --project-name "Mapbox iOS SDK ${DOCS_VERSION}" \
    --project-company Mapbox \
    --create-html \
    --no-create-docset \
    --no-install-docset \
    --company-id com.mapbox \
    --index-desc ${README} \
    /tmp/mbgl/Headers
cp ${README} "${OUTPUT}"
