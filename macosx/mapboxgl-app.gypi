{
  'includes': [
    '../gyp/common.gypi',
  ],
  'targets': [
    {
      'target_name': 'osxsdk',
      'product_name': 'Mapbox',
      'type': 'shared_library',
      'mac_bundle': 1,
      
      'dependencies': [
        'mbgl.gyp:core',
        'mbgl.gyp:platform-<(platform_lib)',
        'mbgl.gyp:http-<(http_lib)',
        'mbgl.gyp:asset-<(asset_lib)',
        'mbgl.gyp:cache-<(cache_lib)',
      ],

      'xcode_settings': {
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'CURRENT_PROJECT_VERSION': '0',
        'DEFINES_MODULE': 'YES',
        'DYLIB_INSTALL_NAME_BASE': '@rpath',
        'INFOPLIST_FILE': '../macosx/framework/Info.plist',
        'LD_RUNPATH_SEARCH_PATHS': [
          '$(inherited)',
          '@executable_path/../Frameworks',
          '@loader_path/Frameworks',
        ],
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.mapbox.MapboxGL',
        'OTHER_LDFLAGS': [ '-stdlib=libc++', '-lstdc++' ],
        'SDKROOT': 'macosx',
        'SKIP_INSTALL': 'YES',
        'SUPPORTED_PLATFORMS': 'macosx',
        'VERSIONING_SYSTEM': 'apple-generic',
      },
      
      'mac_framework_headers': [
        'framework/Mapbox.h',
        '<!@(find ../include/mbgl/{darwin,osx} -type f \! -name \'.*\')',
      ],
      
      'sources': [
        'framework/Mapbox.m',
      ],
      
      'configurations': {
        'Debug': {
          'xcode_settings': {
            'GCC_OPTIMIZATION_LEVEL': '0',
          },
        },
        'Release': {
          'xcode_settings': {
            'GCC_OPTIMIZATION_LEVEL': 's',
          },
        },
      },
      
      'direct_dependent_settings': {
        'libraries': [
          '$(SDKROOT)/System/Library/Frameworks/Cocoa.framework',
          '$(SDKROOT)/System/Library/Frameworks/CoreLocation.framework',
        ],
      },
    },
    
    {
      'target_name': 'osxapp',
      'product_name': 'Mapbox GL',
      'type': 'executable',
      'product_extension': 'app',
      'mac_bundle': 1,
      'mac_bundle_resources': [
        'app/Credits.rtf',
        'app/Icon.icns',
        'app/MainMenu.xib',
      ],

      'dependencies': [
        'osxsdk',
      ],

      'sources': [
        'app/AppDelegate.h',
        'app/AppDelegate.m',
        'app/DroppedPinAnnotation.h',
        'app/DroppedPinAnnotation.m',
        'app/LocationCoordinate2DTransformer.h',
        'app/LocationCoordinate2DTransformer.m',
        'app/TimeIntervalTransformer.h',
        'app/TimeIntervalTransformer.m',
        'app/NSValue+Additions.h',
        'app/NSValue+Additions.m',
        'app/main.m',
      ],

      'xcode_settings': {
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'INFOPLIST_FILE': '../macosx/app/Info.plist',
        'LD_RUNPATH_SEARCH_PATHS': [
          '$(inherited)',
          '@executable_path/../Frameworks',
        ],
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.mapbox.MapboxGL',
        'SDKROOT': 'macosx',
        'SUPPORTED_PLATFORMS':'macosx',
      },
      
      'configurations': {
        'Debug': {
          'xcode_settings': {
            'COPY_PHASE_STRIP': 'NO',
          },
        },
        'Release': {
          'xcode_settings': {
            'COPY_PHASE_STRIP': 'YES',
          },
        },
      },
      
      'copies': [
        {
          'destination': '<(PRODUCT_DIR)/$(FRAMEWORKS_FOLDER_PATH)',
          'files': [
            '<(PRODUCT_DIR)/Mapbox.framework',
          ],
          'xcode_code_sign': 1,
        }
      ],
    },
  ]
}
