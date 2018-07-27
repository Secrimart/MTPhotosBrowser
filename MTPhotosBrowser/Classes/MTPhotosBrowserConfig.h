//
//  MTPhotosBrowserConfig.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <Foundation/Foundation.h>

@interface MTPhotosBrowserConfig : NSObject

//MARK: - about Caption View Config
@property (nonatomic) UIEdgeInsets captionLabelInsets;  // default {}
@property (nonatomic) UIBarStyle captionBarStyle; // default UIBarStyleBlackTranslucent

@property (nonatomic, strong) UIColor *captionTintColor; // default nil
@property (nonatomic, strong) UIColor *captionBarTintColor; // default nil
@property (nonatomic, strong) UIImage *captionBarBackgroundImage; // default nil

// default width|topMargin|leftMargin|rightMargin
@property (nonatomic) UIViewAutoresizing captionAutoresizingMask;

@property (nonatomic, strong) UIColor *captionLabelTextColor; // default whiteColor
@property (nonatomic, strong) UIFont *captionLabelFont; // default systemFontOfSize:14

//MARK: - about Photos View Config
/**
 存储属性，设置照片资源背景视图颜色色
 默认 [UIColor blackColor]
 */
@property (nonatomic, strong) UIColor *photoBackgroundColor;
/**
 存储属性，设置照片背景色
 */
@property (nonatomic, strong) UIColor *imageBackgroundColor;

//MARK: - about browser config
/**
 资源是否填充显示，默认值YES
 */
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic) BOOL displayNavArrows;
@property (nonatomic) BOOL displayActionButton;
@property (nonatomic) BOOL displaySelectionButtons;
@property (nonatomic) BOOL alwaysShowControls;
@property (nonatomic) BOOL enableGrid;
@property (nonatomic) BOOL enableSwipeToDismiss;
@property (nonatomic) BOOL startOnGrid;
@property (nonatomic) BOOL autoPlayOnAppear;
@property (nonatomic) NSUInteger delayToHideElements;

// Customise image selection icons as they are the only icons with a colour tint
// Icon should be located in the app's main bundle
@property (nonatomic, strong) NSString *customImageSelectedIconName;
@property (nonatomic, strong) NSString *customImageSelectedSmallIconName;

/**
 <#Desc#>
 */
@property (nonatomic) BOOL clearImageCacheWhenDealloc;

@end

typedef MTPhotosBrowserConfig MTPBConfig;
