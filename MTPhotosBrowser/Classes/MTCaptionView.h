//
//  MTCaptionView.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <UIKit/UIKit.h>
#import "MTPhotoProtocol.h"
#import "MTPhotosBrowserConfig.h"

@interface MTCaptionView : UIToolbar

// 通过实现MTPhotoProtocol协议的资源对象 初始化资源对象说明视图
- (instancetype)initWithPhoto:(id <MTPhotoProtocol>)photo;

// 设置具体说明内容，说明信息使用初始化时传入的实现JLPHoto协议资源对象的Caption属性
// 如果需要个人化设置资源对象的说明内容，可以在子类中复写该方法，并通过浏览器的
// -photoBrowser:captionViewForPhotoAtIndex: 代理方法将子类传递给浏览器使用
- (void)setupCaption;

// 设置说明内容的显示样式
- (void)setupCaptionConfig:(MTPBConfig *)config;

// 复写UIView的 -sizeThisFits: 对资源说明视图的高度进行重计算。
// 子类可以复写
- (CGSize)sizeThatFits:(CGSize)size;

@end
