//
//  MTPhoto.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <Foundation/Foundation.h>
#import "MTPhotoProtocol.h"

@import Photos;

@interface MTPhoto : NSObject <MTPhotoProtocol>

/**
 照片的说明文字
 */
@property (nonatomic, strong) NSString *caption;

/**
 视频播放地址
 */
@property (nonatomic, strong) NSURL *videoURL;

/**
 控制属性，是否为空图片，空图片不加载失败背景图片
 */
@property (nonatomic) BOOL emptyImage;

/**
 控制属性，是否为视频
 */
@property (nonatomic) BOOL isVideo;

/**
 类方法，通过UIImage对象初始化MTPhoto对像

 @param image 图片兑现
 @return MTPhoto对象
 */
+ (MTPhoto *)photoWithImage:(UIImage *)image;

/**
 类方法，通过NSURL对象初始化MTPhoto对象

 @param url 资源的URL
 @return MTPhoto对象
 */
+ (MTPhoto *)photoWithURL:(NSURL *)url;

/**
 类方法，通过PHAsset(系统相册图片)对象初始化MTPhoto对象

 @param asset 系统相册图片资源对象
 @param targetSize 构建图片的尺寸
 @return MTPhoto对象
 */
+ (MTPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;

/**
 类方法，通过NSURL对象初始化一个视频属性的MTPhoto对象

 @param url 资源的URL
 @return MTPhoto对象
 */
+ (MTPhoto *)videoWithURL:(NSURL *)url;


- (instancetype)init;

/**
 方法，通过UIImage对象初始化MTPhoto对像
 
 @param image 图片兑现
 @return MTPhoto对象
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 方法，通过NSURL对象初始化MTPhoto对象
 
 @param url 资源的URL
 @return MTPhoto对象
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 方法，通过PHAsset(系统相册图片)对象初始化MTPhoto对象
 
 @param asset 系统相册图片资源对象
 @param targetSize 构建图片的尺寸
 @return MTPhoto对象
 */
- (instancetype)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;

/**
 方法，通过NSURL对象初始化一个视频属性的MTPhoto对象
 
 @param url 资源的URL
 @return MTPhoto对象
 */
- (instancetype)initWithVideoURL:(NSURL *)url;

@end
