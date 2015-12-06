#import <Mapbox/Mapbox.h>

#import "../../platform/darwin/NSString+MGLAdditions.h"
#import "../../platform/osx/NSBundle+MGLAdditions.h"
#import "../../platform/osx/NSProcessInfo+MGLAdditions.h"
#import "../../platform/osx/MGLMapView_Private.h"

__attribute__((constructor))
static void InitializeMapbox() {
    static int initialized = 0;
    if (initialized) {
        return;
    }
    
    mgl_linkBundleCategory();
    mgl_linkStringCategory();
    mgl_linkProcessInfoCategory();
    mgl_linkMapViewIBCategory();
    
    [MGLAccountManager class];
    [MGLAnnotationImage class];
    [MGLMapCamera class];
    [MGLMapView class];
    [MGLMultiPoint class];
    [MGLPointAnnotation class];
    [MGLPolygon class];
    [MGLPolyline class];
    [MGLShape class];
    [MGLStyle class];
}
