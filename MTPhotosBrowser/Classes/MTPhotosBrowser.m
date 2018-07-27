//
//  MTPhotosBrowser.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/19.
//

#import "MTPhotosBrowser.h"
#import "MTPhotosBrowserPrivate.h"
#import "UIImage+MTImagePathInBundle.h"

#define PADDING                  10

@import QuartzCore;
@import SDWebImage;

static void * MTVideoPlayerObservation = &MTVideoPlayerObservation;

@implementation MTPhotosBrowser

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    // 释放照片对象数组
    NSArray *copyPhotos = [self.photos copy];
    for (id photo in copyPhotos) {
        if (photo != [NSNull null]) {
            if (preserveCurrent &&
                photo == [self photoAtIndex:self.currentIndex]) {
                // 保留当前显示的照片对象
                continue;
            }
            [photo unloadUnderlyingImage];
        }
    }
    
    // 释放缩略图照片对象数组
    copyPhotos = [self.thumbPhotos copy];
    for (id photo in copyPhotos) {
        if (photo != [NSNull null]) {
            [photo unloadUnderlyingImage];
        }
    }
}



//MARK: - Init
- (instancetype)init {
    if (self = [super init]) {
        [self initialisation];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialisation];
    }
    return self;
}

- (void)initialisation {
    // Defaults
    self.hidesBottomBarWhenPushed = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum) {
        self.isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    } else {
        self.isVCBasedStatusBarAppearance = YES; // default
    }
    
    self.hasBelongedToViewController = NO;
    self.photoCount = NSNotFound;
    self.previousLayoutBounds = CGRectZero;
    
    self.currentPageIndex = 0;
    self.previousPageIndex = NSUIntegerMax;
    self.currentVideoIndex = NSUIntegerMax;
    
    self.performingLayout = NO;
    self.rotating = NO;
    self.viewIsActive = NO;
    
    self.visiblePages = [[NSMutableSet alloc] init];
    self.recycledPages = [[NSMutableSet alloc] init];
    self.photos = [[NSMutableArray alloc] init];
    self.thumbPhotos = [[NSMutableArray alloc] init];
    
    self.currentGridContentOffset = CGPointMake(0, CGFLOAT_MAX);
    self.didSavePreviousStateOfNavBar = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMTPhotoLoadingDidEndNOtification:)
                                                 name:MTPHOTO_LOADIND_DID_END_NOTIFICATION
                                               object:nil];
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    if (self = [self init]) {
        self.fixedPhotosArray = photosArray;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<MTPhotosBrowserDelegate>)delegate {
    if (self = [self init]) {
        self.delegate = delegate;
    }
    return self;
}

- (instancetype)initWithConfig:(MTPBConfig *)config withDelegate:(id<MTPhotosBrowserDelegate>)delegate {
    if (self = [self init]) {
        self.config = config;
        self.delegate = delegate;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // 释放除了当前照片之外的所有内容，缓存、图片等
    [self releaseAllUnderlyingPhotos:YES];
    // 释放页面回收站数据集
    [self.recycledPages removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self clearCurrentVideo];
    
    self.pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos:NO];
    
    // 清除三方库SDWebImage的缓存
    if (self.config.clearImageCacheWhenDealloc) {
        [[SDImageCache sharedImageCache] clearMemory];
    }
}

//MARK: - View Loading
- (void)viewDidLoad {
    // 依据实际配置情况，调整网格初始页面配置逻辑
    if (self.config.startOnGrid) self.config.enableGrid = YES;
    if (self.config.enableGrid) {
        self.config.enableGrid = [self.delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)];
    }
    if (!self.config.enableGrid) self.config.startOnGrid = NO;
    
    // setup
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    
    // 添加滚动视图
    [self.view addSubview:self.pagingScrollView];
    
    // 刷新
    [self reloadData];
    
    // 滑动取消
    if (self.config.enableSwipeToDismiss) {
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonPressed:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
        [self.view addGestureRecognizer:swipeGesture];
    }
    
    [super viewDidLoad];
}

- (void)performLayout {
    // setup
    self.performingLayout = YES;
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    
    // 清除页面重用数据集
    [self.visiblePages removeAllObjects];
    [self.recycledPages removeAllObjects];
    
    // 依据浏览器展示方式 设置导航栏按钮
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        // 模态方式展示 完成按钮
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        // push方式展示 添加返回按钮
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil];
        // Appearance
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        self.previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
        previousViewController.navigationItem.backBarButtonItem = newBackButton;
    }
    
    // 整理添加工具栏按钮项
    BOOL hasItems = NO;
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpace.width = 32; // To balance action button
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    // 浏览器提供网格显示模式时，需要在工具栏中添加网格模式切换按钮
    if (self.config.enableGrid) {
        hasItems = YES;
        [items addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/UIBarButtonItemGrid" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] style:UIBarButtonItemStylePlain target:self action:@selector(showGridAnimated)]];
    } else {
        [items addObject:fixedSpace];
    }
    
    // 浏览器提供手动翻页按钮时，需要在工具栏中添加前一页和后一页的翻页按钮
    if (self.config.displayNavArrows && numberOfPhotos > 1) {
        hasItems= YES;
        [items addObject:fixedSpace];
        [items addObject:self.previousButton];
        [items addObject:fixedSpace];
        [items addObject:self.nextButton];
        [items addObject:fixedSpace];
    } else {
        [items addObject:fixedSpace];
    }
    
    /**
     浏览器提供更多服务能力时，需要向导航栏或工具栏中添加更多服务按钮
     只要工具条存在更多服务按钮优先放入工具条中
     */
    if (self.config.displayActionButton &&
        !(!hasItems && !self.navigationItem.rightBarButtonItem)) {
        // 导航栏右侧按钮被占用时，将更多服务按钮添加在底部工具栏中，例如：模态方式使用浏览器时
        [items addObject:self.actionButton];
    } else {
        if (self.config.displayActionButton) {
            // 工具条中没有功能按钮时，且导航栏右侧按钮没有被占用，将更多服务按钮添加在导航栏右侧按钮位置
            self.navigationItem.rightBarButtonItem = self.actionButton;
        }
        [items addObject:fixedSpace];
    }
    // 工具条添加功能按钮
    [self.toolBar setItems:items];
    
    // 如果工具条中没有功能按钮，页面将显示工具条
    BOOL hideToolbar = YES;
    for (UIBarButtonItem *item in self.toolBar.items) {
        if (item != fixedSpace && item != flexSpace) {
            hideToolbar = NO;
            break;
        }
    }
    
    if (hideToolbar) {
        [self.toolBar removeFromSuperview];
    } else {
        [self.view addSubview:self.toolBar];
    }
    
    // 设置导航栏标题，及功能按钮可用状态
    [self updateNavigation];
    
    // 定位横向滑动视图显示位置，定位当前照片页
    self.pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:self.currentPageIndex];
    // 构建照片页面（按照页面重用机制）
    [self tilePages];
    
    // 视图布局完成
    self.performingLayout = NO;
}

- (BOOL)presentingViewControllerPrefersStatusBarHidden {
    UIViewController *presenting = self.presentingViewController;
    // 模态方式展示浏览器时
    if (presenting) {
        // 当模态调用方为导航栏控制器时，获取导航栏堆栈栈顶的视图控制器
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        // We're in a navigation controller so get previous one!
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO; // 默认不显示状态条
    }
}

//MARK: - Appearance
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Status bar
    // 首次显示前，明确状态栏是否需要修改样式
    if (!self.viewHasAppearedInitially) {
        self.leaveStatusBarAlone = [self presentingViewControllerPrefersStatusBarHidden];
        // 首次出现时，状态栏已隐藏。则，忽略状态条的样式处理
        if (CGRectEqualToRect([[UIApplication sharedApplication] statusBarFrame], CGRectZero)) {
            self.leaveStatusBarAlone = YES;
        }
    }
    // 设置状态栏的，主要用户iOS7以下的系统版本
    if (!self.leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // 记录来源页面的状态栏样式
        self.previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        // 设置浏览器状态栏样式
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    }
    
    // 页面不是有效状态且，浏览器不是模态方式呈现时，记录来源页面中导航栏相关属性，方便回退后，恢复导航栏
    if (!self.viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    // 设置浏览器导航栏 显示属性
    [self setNavBarAppearance:animated];
    
    // 启动浏览器导航栏和工具栏的延时隐藏
    [self hideControlsAfterDelay];
    
    // 首次显示前，如果浏览器第一页需要为网格缩略图页面，则启动展示网格页面
    if (!self.viewHasAppearedInitially) {
        if (self.config.startOnGrid) {
            [self showGrid:NO];
        }
    }
    
    // 保障旋转后页面显示正常
    if (self.currentPageIndex != self.pageIndexBeforeRotation) {
        [self jumpToPageAtIndex:self.pageIndexBeforeRotation animated:NO];
    }
    
    // Layout
    [self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewIsActive = YES;
    
    // 首次显示完成前，如果浏览器配置了自动播放功能，且资源是视频资源
    if (!self.viewHasAppearedInitially) {
        if (self.config.autoPlayOnAppear) {
            MTPhoto *photo = [self photoAtIndex:self.currentPageIndex];
            if ([photo respondsToSelector:@selector(isVideo)] && photo.isVideo) {
                [self playVideoAtIndex:self.currentPageIndex];
            }
        }
    }
    
    self.viewHasAppearedInitially = YES;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Detect if rotation occurs while we're presenting a modal
    self.pageIndexBeforeRotation = self.currentPageIndex;
    
    // Check that we're disappearing for good
    // self.isMovingFromParentViewController just doesn't work, ever. Or self.isBeingDismissed
    if ((self.doneButton && self.navigationController.isBeingDismissed) ||
        ([self.navigationController.viewControllers objectAtIndex:0] != self && ![self.navigationController.viewControllers containsObject:self])) {
        
        // State
        self.viewIsActive = NO;
        [self clearCurrentVideo]; // Clear current playing video
        
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
        
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    // Status bar
    if (!self.leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:self.previousStatusBarStyle animated:animated];
    }
    
    // Super
    [super viewWillDisappear:animated];
    
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent && self.hasBelongedToViewController) {
        [NSException raise:@"MWPhotoBrowser Instance Reuse" format:@"MWPhotoBrowser instances cannot be reused."];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (!parent) self.hasBelongedToViewController = YES;
}

//MARK: - Video
- (void)playVideoAtIndex:(NSUInteger)index {
    
}

- (void)clearCurrentVideo {
    
}

//MARK: - Getter And Setter
- (UIScrollView *)pagingScrollView {
    if (_pagingScrollView) return _pagingScrollView;
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:[self frameForPagingScrollView]];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    return _pagingScrollView;
}

- (UIToolbar *)toolBar {
    if (_toolBar) return _toolBar;
    _toolBar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:[self orientation]]];
    _toolBar.tintColor = [UIColor whiteColor];
    _toolBar.barTintColor = nil;
    [_toolBar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [_toolBar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsCompact];
    _toolBar.barStyle = UIBarStyleBlackTranslucent;
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    return _toolBar;
}

- (UIInterfaceOrientation)orientation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (UIBarButtonItem *)previousButton {
    if (_previousButton) return _previousButton;
    NSString *arrowPathFormat = @"MWPhotoBrowser.bundle/UIBarButtonItemArrow%@";
    UIImage *previousButtonImage = [UIImage imageForResourcePath:[NSString stringWithFormat:arrowPathFormat, @"Left"]
                                                          ofType:@"png"
                                                        inBundle:[NSBundle bundleForClass:[self class]]];
    
    _previousButton = [[UIBarButtonItem alloc] initWithImage:previousButtonImage
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(gotoPreviousPage)];
    
    return _previousButton;
}

- (UIBarButtonItem *)nextButton {
    if (_nextButton) return _nextButton;
    NSString *arrowPathFormat = @"MWPhotoBrowser.bundle/UIBarButtonItemArrow%@";
    UIImage *nextButtonImage = [UIImage imageForResourcePath:[NSString stringWithFormat:arrowPathFormat, @"Right"]
                                                      ofType:@"png"
                                                    inBundle:[NSBundle bundleForClass:[self class]]];
    
    _nextButton = [[UIBarButtonItem alloc] initWithImage:nextButtonImage
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(gotoNextPage)];
    
    return _nextButton;
}

- (UIBarButtonItem *)actionButton {
    if (_actionButton) return _actionButton;
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(actionButtonPressed:)];
    
    return _actionButton;
}

- (UIBarButtonItem *)doneButton {
    if (_doneButton) return _doneButton;
    _doneButton =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(doneButtonPressed:)];
    
    // Set appearance
    [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
    [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
    [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
    [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
    
    return _doneButton;
}

@end
