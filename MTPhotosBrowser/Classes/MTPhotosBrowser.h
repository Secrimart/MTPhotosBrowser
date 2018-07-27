//
//  MTPhotosBrowser.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/19.
//

#import <UIKit/UIKit.h>
#import "MTPhotosBrowserConfig.h"
#import "MTPhotoProtocol.h"
#import "MTPhoto.h"
#import "MTCaptionView.h"

@class MTPhotosBrowser;

@protocol MTPhotosBrowserDelegate <NSObject>
@required

/**
 提供浏览器需要显示的照片总数

 @param photoBrowser 浏览器实例对象
 @return 照片总数
 */
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MTPhotosBrowser *)photoBrowser;

/**
 提供浏览器照片对象

 @param photoBrowser 浏览器实例对象
 @param index 需要的照片对象索引
 @return 照片对象
 */
- (id<MTPhotoProtocol>)photoBrowser:(MTPhotosBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

/**
 提供浏览器缩略图照片对象

 @param photoBrowser 浏览器实例对象
 @param index 需要的缩略图照片对象索引
 @return 缩略图照片对象
 */
- (id <MTPhotoProtocol>)photoBrowser:(MTPhotosBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;

/**
 提供照片页面中显示的照片提示信息视图

 @param photoBrowser 浏览器实例对象
 @param index 需要的提示信息视图索引
 @return 提示信息视图
 */
- (MTCaptionView *)photoBrowser:(MTPhotosBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;

/**
 提供照片页面导航条中显示的标题

 @param photoBrowser 浏览器实例对象
 @param index 需要的标题索引
 @return 标题
 */
- (NSString *)photoBrowser:(MTPhotosBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index;

/**
 当照片资源已经显示完成后，通过该代理方法通知浏览器调用者

 @param photoBrowser 浏览器实例对象
 @param index 照片资源索引
 */
- (void)photoBrowser:(MTPhotosBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;

/**
 浏览器导航栏中的交互按钮单击后，通过该代理方法通知浏览器调用者进行后续处理
 如果调用者不实现该代理，浏览器将显示 UIActivityViewController

 @param photoBrowser 浏览器实例对象
 @param index 照片资源索引
 */
- (void)photoBrowser:(MTPhotosBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index;

/**
 提供指定索引的照片选择状态

 @param photoBrowser 浏览器实例对象
 @param index 照片资源索引
 @return YES 以选中; NO 未选中
 */
- (BOOL)photoBrowser:(MTPhotosBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index;

/**
 浏览器中照片资源选中状态变化后，通过该代理方法通知浏览器调用者执行处理

 @param photoBrowser 浏览器实例对象
 @param index 照片资源索引
 @param selected 照片资源选中状态
 */
- (void)photoBrowser:(MTPhotosBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected;

/**
 浏览器中通过完成按钮关闭浏览器时，通过该代理方法通知浏览器调用者执行处理
 如果调用者没有实现该代理方法，浏览器将被自动关闭（dismiss）

 @param photoBrowser 浏览器实例对象
 */
- (void)photoBrowserDidFinishModalPresentation:(MTPhotosBrowser *)photoBrowser;

@end

@interface MTPhotosBrowser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>

/**
 浏览器代理
 */
@property (nonatomic, weak) id <MTPhotosBrowserDelegate> delegate;

/**
 浏览器配置对象
 */
@property (nonatomic, strong) MTPBConfig *config; // 浏览器相关配置信息

/**
 浏览器显示的当前照片索引
 */
@property (nonatomic, readonly) NSUInteger currentIndex;

/**
 通过照片数组初始化浏览器

 @param photosArray 照片数组
 @return 浏览器实例
 */
- (instancetype)initWithPhotos:(NSArray *)photosArray;

/**
 通过代理对象初始化浏览器，
 照片资源初始化由实现的代理方法提供

 @param delegate 实现代理的对象
 @return 浏览器实例
 */
- (instancetype)initWithDelegate:(id <MTPhotosBrowserDelegate>)delegate;

/**
 通过浏览器配置对象和代理对象初始化浏览器

 @param config 浏览器配置对象
 @param delegate 实现代理的对象
 @return 浏览器实例
 */
- (instancetype)initWithConfig:(MTPBConfig *)config withDelegate:(id <MTPhotosBrowserDelegate>)delegate;

/**
 重新加载浏览器
 */
- (void)reloadData;

/**
 这是当前显示的照片索引

 @param index 照片索引
 */
- (void)setCurrentPhotoIndex:(NSUInteger)index;

/**
 显示下一张照片

 @param animated 是否使用动画
 */
- (void)showNextPhotoAnimated:(BOOL)animated;

/**
 显示上一张照片

 @param animated 是否使用动画
 */
- (void)showPreviousPhotoAnimated:(BOOL)animated;

@end
