//
//  MTZoomingScrollView.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/19.
//

#import "MTZoomingScrollView.h"
#import "UIImage+MTImagePathInBundle.h"
#import "MTPhotosBrowser.h"
#import "MTPhotosBrowserPrivate.h"

@import DACircularProgress;

@interface MTZoomingScrollView ()

/**
 存储属性，浏览器对象
 */
@property (nonatomic, weak) MTPhotosBrowser *browser;

/**
 视图属性，背景交互视图
 */
@property (nonatomic, strong) UIView *tapView;

/**
 视图属性，交互图片视图
 */
@property (nonatomic, strong) UIImageView *photoImageView;

/**
 视图属性，加载进度指示器
 */
@property (nonatomic, strong) DACircularProgressView *loadingIndicator;

/**
 视图属性，加载错误图片视图
 */
@property (nonatomic, strong) UIImageView *loadingError;

@end

@implementation MTZoomingScrollView

- (instancetype)initWithPhotoBrowser:(MTPhotosBrowser *)browser {
    if (self = [super init]) {
        self.index = NSUIntegerMax;
        self.browser = browser;
        
        [self addSubview:self.tapView];
        [self addSubview:self.photoImageView];
        
        [self addSubview:self.loadingIndicator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setProgressFromNotification:) name:MTPHOTO_PROGRESS_NOTIFICATION object:nil];
        
        self.backgroundColor = browser.config.photoBackgroundColor;
        self.photoImageView.backgroundColor = browser.config.imageBackgroundColor;
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
    }
    return self;
}

- (void)dealloc {
    if ([self.photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [self.photo cancelAnyLoading];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [self hideImageFailure];
    
    self.photo = nil;
    self.captionView = nil;
    self.selectedButton = nil;
    self.playButton = nil;
    
    self.photoImageView.hidden = NO;
    self.photoImageView.image = nil;
    
    self.index = NSUIntegerMax;
}

- (BOOL)displayingVideo {
    return [self.photo respondsToSelector:@selector(isVideo)] && self.photo.isVideo;
}

- (void)setImageHidden:(BOOL)hidden {
    self.photoImageView.hidden = hidden;
}

//MARK: - Layout
- (void)layoutSubviews {
    // 更新交互视图的Frame，使之填满Bounds
    [self.tapView setFrame:self.bounds];
    
    // 居中显示进度条
    if (!self.loadingIndicator.hidden) {
        CGRect rect = self.loadingIndicator.frame;
        rect.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(rect))/2.f);
        rect.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(rect))/2.f);
        [self.loadingIndicator setFrame:rect];
    }
    
    // 居中显示加载异常视图
    if (self.loadingError) {
        CGRect rect = self.loadingError.frame;
        rect.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(rect))/2.f);
        rect.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(rect))/2.f);
        [self.loadingError setFrame:rect];
    }
    
    [super layoutSubviews];
    
    // 设置 图片交互视图 的居中显示
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.photoImageView.frame;
    
    // X轴居中
    if (CGRectGetWidth(frameToCenter) < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // y轴居中
    if (CGRectGetHeight(frameToCenter) < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Frame发生变化时重置 图片交互视图的 Frame
    if (!CGRectEqualToRect(self.photoImageView.frame, frameToCenter)) {
        [self.photoImageView setFrame:frameToCenter];
    }
}

//MARK: - Setup
- (CGFloat)initialZoomScaleWithMinScale {
    // 使用最小缩放比例初始化 从当前缩放比例
    CGFloat zoomScale = self.minimumZoomScale;
    
    // 图片存在且浏览器设置需要填充显示时，根据图片尺寸计算填充显示的缩放比例
    if (self.photoImageView && self.browser.config.zoomPhotosToFill) {
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = self.photoImageView.image.size;
        // 视图宽高比
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        // 图片宽高比
        CGFloat imageAR = imageSize.width / imageSize.height;
        // X轴缩放比例
        CGFloat xScale = boundsSize.width / imageSize.width;
        // Y轴缩放比例
        CGFloat yScale = boundsSize.height / imageSize.height;
        
        // 视图与图片的宽高比必须±0.17之间，才会根据图片进行当前缩放比例适配，否则直接使用最小缩放比例
        if (ABS(boundsAR - imageAR) < 0.17) {
            // X和Y轴最大缩放比例
            zoomScale = MAX(xScale, yScale);
            // 当前缩放比例需要在 最小值和最大值之间
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    // 重新设置
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // 没有图片的时，直接返回，不再做缩放计算
    if (!self.photoImageView.image) return;
    
    // 图片视图复位
    CGRect frame = CGRectZero;
    frame.size = self.photoImageView.frame.size;
    [self.photoImageView setFrame:frame];
    
    CGSize boundSize = self.bounds.size;
    CGSize imageSize = self.photoImageView.image.size;
    
    // 最小缩放比例，以图片宽高的长边填满Bounds对应边长为准
    CGFloat xScale = boundSize.width / imageSize.width;
    CGFloat yScale = boundSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    // 固定最大缩放比例为3，当设备为Pad是比例为4
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        maxScale = 4;
    }
    
    // 如果图片的宽和高都小于Bounds，图片显示原有大小，不可以在缩小
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0f;
    }
    
    // 设置ScrollView的缩放范围
    self.minimumZoomScale = minScale;
    self.maximumZoomScale = maxScale;
    
    // 设置当前显示的缩放比例
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // 已居中填满的方式显示图片
    if (self.zoomScale != minScale) {
        CGFloat xOffset = (imageSize.width * self.zoomScale - boundSize.width) / 2.f;
        CGFloat yOffset = (imageSize.height * self.zoomScale - boundSize.height) / 2.f;
        
        self.contentOffset = CGPointMake(xOffset, yOffset);
    }
    
    // 关闭ScrollView的滑动能力
    self.scrollEnabled = NO;
    
    // 视频资源不提供缩放能力
    if ([self displayingVideo]) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }
    
    // 重新布局
    [self setNeedsLayout];
}

//MARK: - show and hide loading indicator
- (void)setProgressFromNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification object];
        id <MTPhotoProtocol> photoWithProgress = [dict objectForKey:@"photo"];
        if (photoWithProgress == self.photo) {
            float progress = [[dict valueForKey:@"progress"] floatValue];
            self.loadingIndicator.progress = MAX(MIN(1, progress), 0);
        }
    });
}

- (void)hideLoadingIndicator {
    self.loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    self.loadingIndicator.progress = 0;
    self.loadingIndicator.hidden = NO;
    [self hideImageFailure];
}

//MARK: - show and hide image
// 获取并显示图像
- (void)displayImage {
    if (self.photo &&
        !self.photoImageView.image) {
        // 初始化设置
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeZero;
        
        // 从浏览器中获取需要显示图片
        UIImage *img = [self.browser imageForPhoto:self.photo];
        if (img) {
            // 隐藏 加载进度条
            [self hideLoadingIndicator];
            
            // 添加图片 并 显示
            [self.photoImageView setImage:img];
            [self.photoImageView setHighlighted:NO];
            
            // 设置图片视图的Frame
            CGRect photoImageViewFrame = CGRectZero;
            photoImageViewFrame.size = img.size;
            [self.photoImageView setFrame:photoImageViewFrame];
            self.contentSize = photoImageViewFrame.size;
            
            // 设置图片放大缩小范围
            [self setMaxMinZoomScalesForCurrentBounds];
            
        } else {
            // 图片不存在 进入图片显示失败处理流程
            [self displayImageFailure];
        }
    }
    
}

- (void)displayImageFailure {
    // 隐藏 加载进度条
    [self hideLoadingIndicator];
    self.photoImageView.image = nil;
    
    // 如果资源对象的 emptyImage 为NO时 添加并显示 加载异常视图
    if (![self.photo respondsToSelector:@selector(emptyImage)] ||
        !self.photo.emptyImage) {
        
        // 加载异常视图 居中显示
        CGRect frame = self.loadingError.frame;
        frame.origin.x = floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.f);
        frame.origin.y = floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2);
        self.loadingError.frame = frame;
    }
}

- (void)hideImageFailure {
    if (self.loadingError) {
        [self.loadingError removeFromSuperview];
        self.loadingError = nil;
    }
}

//MARK: - Getter And Setter
- (UIView *)tapView {
    if (_tapView) return _tapView;
    _tapView = [[UIView alloc] initWithFrame:self.bounds];
    _tapView.tapDelegate = self;
    _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    return _tapView;
}

- (UIImageView *)photoImageView {
    if (_photoImageView) return _photoImageView;
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _photoImageView.tapDelegate = self;
    _photoImageView.contentMode = UIViewContentModeCenter;
    
    return _photoImageView;
}

- (DACircularProgressView *)loadingIndicator {
    if (_loadingIndicator) return _loadingIndicator;
    _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.f, 30.f, 40.f, 40.f)];
    _loadingIndicator.userInteractionEnabled = NO;
    _loadingIndicator.thicknessRatio = 0.1;
    _loadingIndicator.roundedCorners = NO;
    _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    return _loadingIndicator;
}

- (UIImageView *)loadingError {
    if (_loadingError) return _loadingError;
    _loadingError = [UIImageView new];
    _loadingError.image = [UIImage imageForResourcePath:@"JLPhotosBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    _loadingError.userInteractionEnabled = NO;
    _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [_loadingError sizeToFit];
    [self addSubview:_loadingError];
    
    return _loadingError;
}

- (void)setPhoto:(id<MTPhotoProtocol>)photo {
    // 取消正在加载或原有的资源对象
    if (_photo) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    
    _photo = photo;
    UIImage *img = [self.browser imageForPhoto:photo];
    if (img) {
        [self displayImage];
    } else {
        [self showLoadingIndicator];
    }
}

//MARK: - UIScrollView Delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.browser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    [self.browser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.browser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

//MARK: - Tap Detection Delegate
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    if (view == self.photoImageView) {
        [self handleSingleTap:[touch locationInView:view]];
    } else {
        // Translate touch location to image view location
        CGFloat touchX = [touch locationInView:view].x;
        CGFloat touchY = [touch locationInView:view].y;
        touchX *= 1/self.zoomScale;
        touchY *= 1/self.zoomScale;
        touchX += self.contentOffset.x;
        touchY += self.contentOffset.y;
        [self handleSingleTap:CGPointMake(touchX, touchY)];
    }
}

- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    if (view == self.photoImageView) {
        [self handleDoubleTap:[touch locationInView:view]];
    } else {
        // Translate touch location to image view location
        CGFloat touchX = [touch locationInView:view].x;
        CGFloat touchY = [touch locationInView:view].y;
        touchX *= 1/self.zoomScale;
        touchY *= 1/self.zoomScale;
        touchX += self.contentOffset.x;
        touchY += self.contentOffset.y;
        [self handleDoubleTap:CGPointMake(touchX, touchY)];
    }
}

- (void)handleSingleTap:(CGPoint)touchPoint {
    [self.browser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Dont double tap to zoom if showing a video
    if ([self displayingVideo]) {
        return;
    }
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:self.browser];
    
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    } else {
        
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
    
    // Delay controls
    [self.browser hideControlsAfterDelay];
}

@end
