//
//  MTZoomingScrollView.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/19.
//

#import <UIKit/UIKit.h>
#import "MTPhotoProtocol.h"
#import "UIView+MTTapDetecting.h"

@class MTPhoto, MTCaptionView, MTPhotosBrowser;
@interface MTZoomingScrollView : UIScrollView<UIScrollViewDelegate, MTTapDetectionViewDelegate>

/**
 存储属性，序号
 */
@property (nonatomic) NSUInteger index;

/**
 存储属性，资源
 */
@property (nonatomic) id<MTPhotoProtocol> photo;

/**
 视图属性，资源说明视图
 */
@property (nonatomic, weak) MTCaptionView *captionView;

/**
 视图属性，资源选定按钮
 */
@property (nonatomic, weak) UIButton *selectedButton;

/**
 视图属性，视频资源播放按钮
 */
@property (nonatomic, weak) UIButton *playButton;

/**
 构造方法，通过MTPhotosBrowser对象构建资源页面

 @param browser MTPhotosBrowser浏览器对象，用于获取图像资源和配置信息
 @return 资源页面实例
 */
- (instancetype)initWithPhotosBrowser:(MTPhotosBrowser *)browser;

- (void)prepareForReuse;

- (void)displayImage;
- (void)displayImageFailure;

- (void)setImageHidden:(BOOL)hidden;
- (void)setMaxMinZoomScalesForCurrentBounds;

- (BOOL)displayingVideo;

@end
