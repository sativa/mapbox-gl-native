{
  'targets': [
    { 'target_name': 'platform-osx',
      'product_name': 'mbgl-platform-osx',
      'type': 'static_library',
      'standalone_static_library': 1,
      'hard_dependency': 1,
      'dependencies': [
        'version',
      ],

      'sources': [
        '../platform/default/async_task.cpp',
        '../platform/default/run_loop.cpp',
        '../platform/default/timer.cpp',
        '../platform/darwin/log_nslog.mm',
        '../platform/darwin/string_nsstring.mm',
        '../platform/darwin/application_root.mm',
        '../platform/darwin/asset_root.mm',
        '../platform/darwin/image.mm',
        '../platform/darwin/nsthread.mm',
        '../platform/darwin/reachability.m',
        '../platform/darwin/NSException+MGLAdditions.h',
        '../platform/darwin/NSString+MGLAdditions.h',
        '../platform/darwin/NSString+MGLAdditions.m',
        '../platform/darwin/MGLTypes.m',
        '../platform/darwin/MGLStyle.mm',
        '../platform/darwin/MGLGeometry_Private.h',
        '../platform/darwin/MGLGeometry.mm',
        '../platform/darwin/MGLShape.m',
        '../platform/darwin/MGLMultiPoint_Private.h',
        '../platform/darwin/MGLMultiPoint.mm',
        '../platform/darwin/MGLPointAnnotation.m',
        '../platform/darwin/MGLPolyline.mm',
        '../platform/darwin/MGLPolygon.mm',
        '../platform/darwin/MGLMapCamera.mm',
        '../platform/osx/MGLAccountManager_Private.h',
        '../platform/osx/MGLAccountManager.m',
        '../platform/osx/MGLMapView_Private.h',
        '../platform/osx/MGLMapView.mm',
        '../platform/osx/MGLMapView+IBAdditions.m',
        '../platform/osx/MGLOpenGLLayer.h',
        '../platform/osx/MGLOpenGLLayer.mm',
        '../platform/osx/MGLCompassCell.h',
        '../platform/osx/MGLCompassCell.m',
        '../platform/osx/MGLAttributionButton.h',
        '../platform/osx/MGLAttributionButton.m',
        '../platform/osx/MGLAnnotationImage.m',
        '../platform/osx/NSBundle+MGLAdditions.h',
        '../platform/osx/NSBundle+MGLAdditions.m',
        '../platform/osx/NSProcessInfo+MGLAdditions.h',
        '../platform/osx/NSProcessInfo+MGLAdditions.m',
      ],

      'variables': {
        'cflags_cc': [
          '<@(libuv_cflags)',
          '<@(boost_cflags)',
          '<@(variant_cflags)',
        ],
        'libraries': [
          '<@(libuv_static_libs)',
          '$(SDKROOT)/System/Library/Frameworks/Cocoa.framework',
          '$(SDKROOT)/System/Library/Frameworks/CoreLocation.framework',
          '$(SDKROOT)/System/Library/Frameworks/OpenGL.framework',
          '$(SDKROOT)/System/Library/Frameworks/QuartzCore.framework',
          '$(SDKROOT)/System/Library/Frameworks/SystemConfiguration.framework',
        ],
      },

      'include_dirs': [
        '../include/mbgl/osx',
        '../include/mbgl/darwin',
        '../include',
        '../src',
      ],

      'xcode_settings': {
        'OTHER_CPLUSPLUSFLAGS': [ '<@(cflags_cc)' ],
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'CLANG_ENABLE_MODULES': 'YES',
      },

      'link_settings': {
        'libraries': [ '<@(libraries)' ],
      },

      'direct_dependent_settings': {
        'mac_bundle_resources': [
          '<!@(find ../platform/osx/resources -type f \! -name \'.*\')',
        ],
      },
    },
  ],
}
