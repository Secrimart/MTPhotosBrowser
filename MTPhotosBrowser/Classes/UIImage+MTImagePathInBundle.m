//
//  UIImage+MTImagePathInBundle.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import "UIImage+MTImagePathInBundle.h"

@implementation UIImage (MTImagePathInBundle)

+ (instancetype)imageForResourcePath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle {
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:path ofType:type]];
}

@end
