//
//  MTCaptionView.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import "MTCaptionView.h"
#import "MTPhoto.h"

@interface MTCaptionView ()
/**
 存储属性，浏览器配置对象
 */
@property (nonatomic, strong) MTPBConfig *config;

/**
 存储属性，资源对象
 */
@property (nonatomic, strong) MTPhoto *photo;

/**
 视图属性，图片说明信息展示控件
 */
@property (nonatomic, strong) UILabel *label;

@end

@implementation MTCaptionView

- (instancetype)initWithPhoto:(id<MTPhotoProtocol>)photo {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)]; // 临时布局
    if (self) {
        self.userInteractionEnabled = NO;
        self.photo = photo;
        
        [self setupConfig];
        [self setupCaption];
    }
    return self;
}

- (void)setupCaption {
    if ([self.photo respondsToSelector:@selector(caption)]) {
        self.label.text = [self.photo caption] ? [self.photo caption] : @" ";
    }
    [self addSubview:self.label];
}

- (void)setupCaptionConfig:(MTPBConfig *)config {
    self.config = config;
    [self setupConfig];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat masHeight = CGFLOAT_MAX;
    if (self.label.numberOfLines > 0) {
        masHeight = self.label.font.leading*self.label.numberOfLines;
    }
    UIEdgeInsets insets = self.config.captionLabelInsets;
    CGSize textSize = [self.label.text boundingRectWithSize:CGSizeMake(size.width - (insets.left + insets.right), masHeight)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName:self.label.font}
                                                    context:nil].size;
    
    return CGSizeMake(size.width, textSize.height + insets.top + insets.bottom);
}

- (void)setupConfig {
    self.barStyle = self.config.captionBarStyle;
    self.tintColor = self.config.captionTintColor;
    self.barTintColor = self.config.captionBarTintColor;
    [self setBackgroundImage:self.config.captionBarBackgroundImage
          forToolbarPosition:UIBarPositionAny
                  barMetrics:UIBarMetricsDefault];
    
    // 等宽底边对齐
    self.autoresizingMask = self.config.captionAutoresizingMask;
    
    self.label.textColor = self.config.captionLabelTextColor;
    self.label.font = self.config.captionLabelFont;
    
    [self.label setFrame:[self rectLable]];
}

//MARK: - Getter And Setter
- (UILabel *)label {
    if (_label) return _label;
    _label = [[UILabel alloc] initWithFrame:[self rectLable]];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.opaque = NO;
    _label.backgroundColor = [UIColor clearColor];
    _label.textAlignment = NSTextAlignmentCenter;
    
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.numberOfLines = 0;
    
    return _label;
}

- (MTPBConfig *)config {
    if (_config) return _config;
    _config = [[MTPBConfig alloc] init];
    
    return _config;
}

- (CGRect)rectLable {
    CGRect rect = self.bounds;
    rect.origin.x = self.config.captionLabelInsets.left;
    rect.size.width -= (self.config.captionLabelInsets.left + self.config.captionLabelInsets.right);
    
    return rect;
}

@end
