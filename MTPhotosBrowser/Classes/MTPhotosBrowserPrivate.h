//
//  MTPhotosBrowserPrivate.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/19.
//

#import <UIKit/UIKit.h>
#import "MTPhotoProtocol.h"
#import "MTGridViewController.h"
#import "MTZoomingScrollView.h"
#import "MTCaptionView.h"

@import MBProgressHUD;
@import MediaPlayer;

@interface MTPhotosBrowser ()
//MARK: - Data Property
/**
 存储属性，记录照片资源的数量
 */
@property (nonatomic) NSUInteger photoCount;

/**
 存储属性，可变数组存储照片资源对象
 */
@property (nonatomic, strong) NSMutableArray *photos;

/**
 存储属性，可变数组存储照片资源缩略图
 */
@property (nonatomic, strong) NSMutableArray *thumbPhotos;

/**
 存储属性，数组存储初始化时提供的照片资源对象
 */
@property (nonatomic, strong) NSArray *fixedPhotosArray;

//MARK: - Views Property
/**
 视图属性，用于横向滑动切换照片视图的滚动视图
 */
@property (nonatomic, strong) UIScrollView *pagingScrollView;

/**
 视图属性，分享、功能视图控制器
 */
@property (nonatomic, strong) UIActivityViewController *activityViewController;

//MARK: - Paging & layout Property
/**
 存储属性，可变数据集存储可见的照片视图
 */
@property (nonatomic, strong) NSMutableSet *visiblePages;

/**
 存储属性，可变数据集存储可回收使用的照片视图
 */
@property (nonatomic, strong) NSMutableSet *recycledPages;

/**
 存储属性，记录当前显示的照片页面索引
 */
@property (nonatomic) NSUInteger currentPageIndex;

/**
 存储属性，记录前一照片页面索引
 */
@property (nonatomic) NSUInteger previousPageIndex;

/**
 存储属性，记录前一照片页面的布局边界
 */
@property (nonatomic) CGRect previousLayoutBounds;

/**
 存储属性，设备旋转前临时记录当前页面索引，确保设备旋转后仍然保存页面显示位置
 */
@property (nonatomic) NSUInteger pageIndexBeforeRotation;

//MARK: - Navigation & controls Property
/**
 视图属性，浏览器操作条视图
 */
@property (nonatomic, strong) UIToolbar *toolBar;

/**
 存储属性，浏览器操作工具条隐藏倒计时计时器，
 倒计时时间可通过 browser.config.delayToHideElements 进行配置
 */
@property (nonatomic, strong) NSTimer *controlVisibilityTimer;

/**
 视图属性，浏览器操作工具条中前一页翻页按钮
 */
@property (nonatomic, strong) UIBarButtonItem *previousButton;

/**
 视图属性，浏览器操作工具条中下一页翻页按钮
 */
@property (nonatomic, strong) UIBarButtonItem *nextButton;

/**
 视图属性，浏览器操作工具条中操作列表弹出按钮
 */
@property (nonatomic, strong) UIBarButtonItem *actionButton;

/**
 视图属性，浏览器操作工具条中完成按钮
 */
@property (nonatomic, strong) UIBarButtonItem *doneButton;

/**
 视图属性，浏览器操作加载过程视图
 */
@property (nonatomic, strong) MBProgressHUD *progressHUD;

//MARK: - Grid Property
/**
 视图属性，浏览器网格视图控制器，使用UICollectionViewController构建
 */
@property (nonatomic, strong) MTGridViewController *gridController;

/**
 视图属性，浏览器网格模式下导航栏中左侧按钮
 预留，暂时无用
 */
@property (nonatomic, strong) UIBarButtonItem *gridPreviousLeftNavItem;

/**
 视图属性，浏览器网格模式下导航栏中右侧按钮
 */
@property (nonatomic, strong) UIBarButtonItem *gridPreviousRightNavItem;

//MARK: - Appearance Property
/**
 存储属性，记录浏览器push方式使用时，原有导航栏的隐藏状态
 */
@property (nonatomic) BOOL previousNavBarHidden;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏的半透明状态
 */
@property (nonatomic) BOOL previousNavBarTranslucent;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏的样式
 */
@property (nonatomic) UIBarStyle previousNavBarStyle;

/**
 存储属性，记录浏览器push方式使用时，原有状态条的显示样式
 */
@property (nonatomic) UIStatusBarStyle previousStatusBarStyle;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏的前景色
 */
@property (nonatomic, strong) UIColor *previousNavBarTintColor;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏工具条的前景色
 */
@property (nonatomic, strong) UIColor *previousNavBarBarTintColor;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏返回按钮
 */
@property (nonatomic, strong) UIBarButtonItem *previousViewControllerBackButton;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏背景图片
 */
@property (nonatomic, strong) UIImage *previousNavigationBarBackgroundImageDefault;

/**
 存储属性，记录浏览器push方式使用时，原有导航栏横向背景图片
 */
@property (nonatomic, strong) UIImage *previousNavigationBarBackgroundImageLandscapePhone;

//MARK: - Video Property
/**
 视图属性，视频资源播放器的视图控制器
 */
@property (nonatomic, strong) MPMoviePlayerViewController *currentVideoPlayerViewController;

/**
 存储属性，记录当前视频资源索引
 */
@property (nonatomic) NSUInteger currentVideoIndex;

/**
 视图属性，视频资源播放时的加载指示器
 */
@property (nonatomic, strong) UIActivityIndicatorView *currentVideoLoadingIndicator;

//MARK: - Misc Property
/**
 逻辑属性，浏览器实例是否已经被作为子视图控制器，添加到容器中使用过。
 该属性为了控制浏览器，作为子视图控制器，不被重新使用
 */
@property (nonatomic) BOOL hasBelongedToViewController;

/**
 逻辑属性，状态条的样式是由工程级控制还是有视图控制器控制
 用于浏览器展示和关闭时对状态条样式更改代码段控制
 */
@property (nonatomic) BOOL isVCBasedStatusBarAppearance;

/**
 逻辑属性，状态条显示和隐藏逻辑控制属性
 */
@property (nonatomic) BOOL statusBarShouldBeHidden;

/**
 逻辑属性，在浏览器实例展示前状态条是否已经隐藏
 如果该属性为YES，表示状态条已经隐藏，浏览器将忽略对状态条的所有操作
 */
@property (nonatomic) BOOL leaveStatusBarAlone;

/**
 逻辑属性，视图布局过程逻辑控制属性
 视图未完成布局，将锁定滑动
 */
@property (nonatomic) BOOL performingLayout;

/**
 逻辑属性，设备旋转过程逻辑控制属性
 设备旋转未完成，将锁定滑动
 */
@property (nonatomic) BOOL rotating;

/**
 逻辑属性，视图是否已经显示完毕
 视图未显示完毕，将锁定滑动
 */
@property (nonatomic) BOOL viewIsActive;

/**
 逻辑属性，浏览器push方式使用时，是否存储了原有导航样式
 如果为存储，恢复时，不进行导航样式修改
 */
@property (nonatomic) BOOL didSavePreviousStateOfNavBar;

/**
 逻辑属性，是否需要设置pagingScrollView的布局位置
 貌似无用
 */
@property (nonatomic) BOOL skipNextPagingScrollViewPositioning;

/**
 逻辑属性，是否已经完成展现初始化工作
 -viewWillAppear:中用于禁止初始化代码多次调用
 */
@property (nonatomic) BOOL viewHasAppearedInitially;

/**
 存储属性，用于记录Grid样式展示的页面位置，已达到查看大图返回后Grid位置不变
 */
@property (nonatomic) CGPoint currentGridContentOffset;

//MARK: - Layout Method
/**
 布局可见的照片页，-viewWillLayoutSubview方法中调用
 设置toolBar、pagingScrollView、page.captionView、page.selectedButton、page.playButton等UI控件的Frame
 */
- (void)layoutVisiblePages;

/**
 组织控制子视图
 根据逻辑属性添加显示的子视图
 */
- (void)performLayout;

/**
 获取浏览器展现前的视图控制器StatusBar的隐藏状态

 @return YES 已隐藏; NO 未隐藏
 */
- (BOOL)presentingViewControllerPrefersStatusBarHidden;

//MARK: - Nav Bar Appearance Method

/**
 设置浏览器导航栏样式

 @param animated 导航栏展现隐藏是否显示动画
 */
- (void)setNavBarAppearance:(BOOL)animated;

/**
 存储浏览器展现前的图控制器中的导航条相关样式
 */
- (void)storePreviousNavBarAppearance;

/**
 所使用存储的浏览器展现前的视图控制器导航到信息，设置当前导航信息

 @param animated 导航栏展现隐藏是否显示动画
 */
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

//MARK: - Paging Method

/**
 照片页面处理方法
 页面初始化、切换等方式时处理可见照片页面数组、回收照片页面数组，
 */
- (void)tilePages;

/**
 判断指定索引的照片页面是否显示
 照片页面滑动过程中，前后两个页面都是显示页面

 @param index 指定的照片页面索引
 @return YES 页面可用; NO 页面不可用
 */
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;

/**
 依据页面索引获取照片页面对象
 在可见照片页面组数中查询指定索引的页面对象

 @param index 页面索引
 @return nil 可见页面数组中不包含指定索引页面; 否则，返回指定照片页面索引的页面对象
 */
- (MTZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;

/**
 依据照片资源对象获取照片页面对象
 在可见照片页面组数中查询照片资源所在的页面对象

 @param photo 资源对象
 @return nil 可见页面数组中不包含指定索引页面; 否则，返回照片资源所在的页面对象
 */
- (MTZoomingScrollView *)pageDisplayingPhoto:(id<MTPhotoProtocol>)photo;

/**
 在会中照片资源回收数组中获取可重用的页面对象

 @return 可重用的页面对象
 */
- (MTZoomingScrollView *)dequeueRecycledPage;

/**
 根据索引配置照片资源页面

 @param page 照片资源页面
 @param index 索引
 */
- (void)configurePage:(MTZoomingScrollView *)page forIndex:(NSUInteger)index;

/**
 照片页面完全显示后，根据索引对照片数组进行回收处理，并且预加载前后照片资源，最后这是导航信息

 @param index 页面索引
 */
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

//MARK: - Frames Method

/**
 指定浏览器滚动视图布局数据

 @return Frame
 */
- (CGRect)frameForPagingScrollView;

/**
 根据索引指定照片页面布局数据

 @param index 照片页面索引
 @return Frame
 */
- (CGRect)frameForPageAtIndex:(NSUInteger)index;

/**
 指定浏览器滚动视图内容区域尺寸

 @return 内容区域尺寸
 */
- (CGSize)contentSizeForPagingScrollView;

/**
 根据索引指定照片页面左上点位于浏览器滚动视图内容区域中的位置

 @param index 照片页面索引
 @return 左上点坐标位置
 */
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;

/**
 根据设备方向指定工具条的布局数据

 @param orientation 设备方向
 @return Frame
 */
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;

/**
 根据索引以及提示信息具体内容指定提示信息视图的布局数据

 @param captionView 提示信息视图
 @param index 照片页面索引
 @return Frame
 */
- (CGRect)frameForCaptionView:(MTCaptionView *)captionView atIndex:(NSUInteger)index;

/**
 根据索引以及选择按钮指定选择按钮的布局数据

 @param selectedButton 选择按钮
 @param index 照片页面索引
 @return Frame
 */
- (CGRect)frameForSelectedButton:(UIButton *)selectedButton atIndex:(NSUInteger)index;

//MARK: - Navigation Method
/**
 依据当前页面信息设置导航条的标题和按钮
 */
- (void)updateNavigation;

/**
 浏览器照片页面跳转至指定索引的页面

 @param index 页面索引
 @param animated 是否展示动画
 */
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated;

/**
 浏览器前一页
 */
- (void)gotoPreviousPage;

/**
 浏览器后一页
 */
- (void)gotoNextPage;

//MARK: - Grid Method

/**
 显示缩略图网格布局

 @param animated 是否展示动画
 */
- (void)showGrid:(BOOL)animated;

/**
 隐藏缩略图网格布局
 */
- (void)hideGrid;

//MARK: - Controls Method

/**
 取消浏览器导航控制按钮的延期隐藏
 */
- (void)cancelControlHiding;

/**
 延时隐藏浏览器导航控制按钮
 */
- (void)hideControlsAfterDelay;

/**
 隐藏或显示浏览器导航控制按钮

 @param hidden YES 隐藏导航栏；NO 显示导航栏
 @param animated 是否显示动画
 @param permanent 是否永久显示
 */
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;

/**
 触发浏览器导航栏
 当前导航栏显示，则隐藏；当前导航栏隐藏，在显示
 */
- (void)toggleControls;

/**
 浏览器导航栏是否隐藏

 @return YES 已隐藏； NO 未隐藏
 */
- (BOOL)areControlsHidden;

//MARK: - Data Method
/**
 获取需要浏览器显示的照片总个数

 @return 照片个数
 */
- (NSUInteger)numberOfPhotos;

/**
 根据照片索引获取照片对象
 如果照片对象数组中不存在照片对象，通过代理方法由调用者提供，并存入照片对象数组

 @param index 索引
 @return 照片对象
 */
- (id<MTPhotoProtocol>)photoAtIndex:(NSUInteger)index;

/**
 根据只照片索引获取缩略图照片对象
 如果缩略图照片对象数组中不存在缩略图照片对象，通过代理方法由调用者提供，并存入缩略图照片对象数组

 @param index 索引
 @return 缩略图照片对象
 */
- (id<MTPhotoProtocol>)thumbPhotoAtIndex:(NSUInteger)index;

/**
 获取照片对象中的图片对象
 图片未加载时，调用异步图片加载

 @param photo 照片对象
 @return 图片对象
 */
- (UIImage *)imageForPhoto:(id<MTPhotoProtocol>)photo;

/**
 通过代理方法由调用者提供指定索引照片对象的选择状态

 @param index 指定索引
 @return YES 选中; NO 未选中
 */
- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index;

/**
 通过代理方法通知调用者指定照片是否选中

 @param selected YES 选中; NO 取消选中
 @param index 照片索引
 */
- (void)setPhotoSelected:(BOOL)selected atIndex:(NSUInteger)index;

/**
 预加载前一个和后一个照片对象中的图片资源

 @param photo 照片对象
 */
- (void)loadAdjacentPhotosIfNecessary:(id<MTPhotoProtocol>)photo;

/**
 释放照片资源

 @param preserveCurrent 是否保留当前显示照片资源
 */
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;

@end
