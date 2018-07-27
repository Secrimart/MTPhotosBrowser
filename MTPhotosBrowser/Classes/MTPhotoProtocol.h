//
//  MTPhotoProtocol.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <Foundation/Foundation.h>

// Define NOtifications
#define MTPHOTO_LOADIND_DID_END_NOTIFICATION @"MTPHOTO_LOADIND_DID_END_NOTIFICATION" // 加载完成通知
#define MTPHOTO_PROGRESS_NOTIFICATION @"MTPHOTO_PROGRESS_NOTIFICATION" // 加载进度通知

// Debug Logging
#if Debug
#define DLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define DLog(x, ...)
#endif

/**
 遵循该协议可以定义自己的照片模型
 当然也可以使用MTPhoto或其子类来存储项目中使用的照片模型
 */
@protocol MTPhotoProtocol <NSObject>

@required

/**
 用于显示的底层图片
 当属性为nil时，表示没有可以马上使用的图片资源，需要通过 -loadUnderlyingImageAndNotify 方法进行图片加载
 该属性不能直接赋值，必须使用 方法 -loadUnderlyingImageAndNotify 加载
 */
@property (nonatomic, strong) UIImage *underlyingImage;

/**
 图片加载至内存，加载完成时发送通知
 */
- (void)loadUnderlyingImageAndNotify;

/**
 方法用于从一个数据源中异步加载一个图片资源，当加载完成或失败后发送通知
 [[NSNotificationCenter defaultCenter] postNotificationName:MTPHOTO_LOADIND_DID_END_NOTIFICATION object:self];
 */
- (void)performLoadUnderlyingImageAndNotify;

/**
 用户释放底层图片，以便于重新加载
 */
- (void)unloadUnderlyingImage;

@optional

/**
 当图片为空时，不显示加载错误的图标（比如 显示视频时）
 */
@property (nonatomic) BOOL emptyImage;
// 视频
@property (nonatomic) BOOL isVideo;
- (void)getVideoURL:(void (^)(NSURL *url))completion;

// Return a caption string to be displayed over the image
// Return nil to display no caption

/**
 返回图片说明信息，用于并显示在图片上
 返回nil时，图片上不显示
 
 @return 说明信息
 */
- (NSString *)caption;

/**
 取消所有的异步图片加载
 */
- (void)cancelAnyLoading;

@end
