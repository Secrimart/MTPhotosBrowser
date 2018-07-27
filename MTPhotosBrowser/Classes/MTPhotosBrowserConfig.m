//
//  MTPhotosBrowserConfig.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import "MTPhotosBrowserConfig.h"

@implementation MTPhotosBrowserConfig
- (instancetype)init {
    if (self) {
        self.captionLabelInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        self.captionBarStyle = UIBarStyleBlackTranslucent;
        self.captionAutoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        
        self.zoomPhotosToFill = YES;
        self.displayNavArrows = NO;
        self.displayActionButton = YES;
        
        self.enableGrid = YES;
        self.enableSwipeToDismiss = YES;
        self.startOnGrid = NO;
        self.delayToHideElements = 5;
        
        self.displaySelectionButtons = NO;
        self.alwaysShowControls = NO;
        self.autoPlayOnAppear = NO;
        
        self.customImageSelectedIconName = nil;
        self.customImageSelectedSmallIconName = nil;
        
        self.clearImageCacheWhenDealloc = YES;
    }
    return self;
}

- (UIColor *)photoBackgroundColor {
    if (_photoBackgroundColor) return _photoBackgroundColor;
    _photoBackgroundColor = [UIColor blackColor];
    
    return _photoBackgroundColor;
}

- (UIColor *)imageBackgroundColor {
    if (_imageBackgroundColor) return _imageBackgroundColor;
    _imageBackgroundColor = [UIColor blackColor];
    
    return _imageBackgroundColor;
}

- (UIColor *)captionLabelTextColor {
    if (_captionTintColor) return _captionTintColor;
    _captionTintColor = [UIColor whiteColor];
    
    return _captionTintColor;
}

- (UIFont *)captionLabelFont {
    if (_captionLabelFont) return _captionLabelFont;
    _captionLabelFont = [UIFont systemFontOfSize:14.f];
    
    return _captionLabelFont;
}

@end
