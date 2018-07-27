//
//  UIImage+MTImagePathInBundle.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <UIKit/UIKit.h>

@interface UIImage (MTImagePathInBundle)

+ (instancetype)imageForResourcePath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle;

@end
