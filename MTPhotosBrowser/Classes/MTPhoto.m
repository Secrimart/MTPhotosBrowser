//
//  MTPhoto.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import "MTPhoto.h"

@import AssetsLibrary;
@import SDWebImage;

@interface MTPhoto ()

/**
 控制属性，是否正在加载
 */
@property (nonatomic) BOOL loadingInProgress;

/**
 代理句柄，SDWebImageOperation代理
 */
@property (nonatomic, weak) id<SDWebImageOperation> webImageOperation;

/**
 资源属性，本地相册图片请求ID
 */
@property (nonatomic) PHImageRequestID assetRequestID;

/**
 资源属性，本地相册视频请求ID
 */
@property (nonatomic) PHImageRequestID assetVideoRequestID;

/**
 资源属性，存放UIImage对象
 */
@property (nonatomic, strong) UIImage *image;

/**
 资源属性，存放资源的NSURL对象
 */
@property (nonatomic, strong) NSURL *photoURL;

/**
 资源属性，存放本地相册资源对象
 */
@property (nonatomic, strong) PHAsset *asset;

/**
 资源属性，本地相册资源尺寸
 */
@property (nonatomic) CGSize assetTargetSize;

@end

@implementation MTPhoto
// 在protocol中添加property时，其实就是声明了 getter 和 setter 方法，在实现这个protocol协议的类中，我们要自己手动添加实例变量，并且需要实现setter/getter方法
@synthesize underlyingImage = _underlyingImage;

//MARK: - Class Methods
+ (MTPhoto *)photoWithImage:(UIImage *)image {
    return [[MTPhoto alloc] initWithImage:image];
}

+ (MTPhoto *)photoWithURL:(NSURL *)url {
    return [[MTPhoto alloc] initWithURL:url];
}

+ (MTPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    return [[MTPhoto alloc] initWithAsset:asset targetSize:targetSize];
}

+ (MTPhoto *)videoWithURL:(NSURL *)url {
    return [[MTPhoto alloc] initWithVideoURL:url];
}

//MARK: - Init
- (id)init {
    if ((self = [super init])) {
        self.emptyImage = YES;
        [self setup];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    if ((self = [super init])) {
        self.image = image;
        [self setup];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        self.photoURL = url;
        [self setup];
    }
    return self;
}

- (id)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    if ((self = [super init])) {
        self.asset = asset;
        self.assetTargetSize = targetSize;
        self.isVideo = asset.mediaType == PHAssetMediaTypeAudio;
        [self setup];
    }
    return self;
}

- (id)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        self.videoURL = url;
        self.emptyImage = YES;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.assetRequestID = PHInvalidImageRequestID;
    self.assetVideoRequestID = PHInvalidImageRequestID;
}

- (void)dealloc {
    [self cancelAnyLoading];
}

//MARK: - Private Methods

/**
 资源加载完成
 */
- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // 加载控制器复位
    self.loadingInProgress = NO;
    // 发送加载完成通知
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

/**
 发送加载完成通知
 */
- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:MTPHOTO_LOADIND_DID_END_NOTIFICATION object:self];
}

/**
 取消本地相册视频请求
 */
- (void)cancelVideoRequest {
    if (self.assetVideoRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.assetVideoRequestID];
        self.assetVideoRequestID = PHInvalidImageRequestID;
    }
}

/**
 取消本地相册图片请求
 */
- (void)cancelImageRequest {
    if (self.assetRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.assetRequestID];
        self.assetRequestID = PHInvalidImageRequestID;
    }
}

/**
 异步加载相册资源
 
 @param url 资源URL
 */
- (void)performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            [assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                CGImageRef iref = [rep fullScreenImage];
                if (iref) {
                    self.underlyingImage = [UIImage imageWithCGImage:iref];
                }
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            } failureBlock:^(NSError *error) {
                self.underlyingImage = nil;
                DLog(@"Photo from asset library error: %@",error);
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }];
        } @catch (NSException *exception) {
            DLog(@"Photo from asset library error: %@",exception);
            [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
        }
    });
    
}

/**
 异步加载本地图片文件资源
 
 @param url 资源URL
 */
- (void)performLoadUnderlyingImageAndNotifyWithLocalFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            self.underlyingImage = [UIImage imageWithContentsOfFile:url.path];
            if (!self.underlyingImage) {
                DLog(@"Error loading photo from path: %@", url.path);
            }
        } @finally {
            [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
        }
    });
}

/**
 使用SDWebImage加载网络资料
 
 @param url 资源URL
 */
- (void)performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    @try {
        self.webImageOperation = [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            if (expectedSize > 0) {
                float progress = receivedSize / (float)expectedSize;
                NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithFloat:progress], @"progress",
                                      self, @"photo", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:MTPHOTO_PROGRESS_NOTIFICATION object:dict];
            }
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (error) {
                DLog(@"SDWebImage failed to download image: %@", error);
            }
            self.webImageOperation = nil;
            self.underlyingImage = image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self imageLoadingComplete];
            });
        }];
    } @catch (NSException *exception) {
        DLog(@"Photo form web: %@", exception);
        self.webImageOperation = nil;
        [self imageLoadingComplete];
    }
}

/**
 加载Photos中的资源
 
 @param asset 资源
 @param targetSize 目标尺寸
 */
- (void)performLoadUnderlyingImageAndNotifyWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = false;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithDouble: progress], @"progress",
                              self, @"photo", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:MTPHOTO_PROGRESS_NOTIFICATION object:dict];
    };
    
    self.assetRequestID = [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.underlyingImage = result;
            [self imageLoadingComplete];
        });
    }];
}

//MARK: - Video
- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    self.isVideo = YES;
}

- (void)getVideoURL:(void (^)(NSURL *))completion {
    // 已存在视频URL 直接返回
    if (_videoURL) {
        completion(_videoURL);
        // 判定存在视频资源
    } else if (_asset && _asset.mediaType == PHAssetMediaTypeVideo) {
        // 撤销已经存在的
        [self cancelVideoRequest];
        
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        __weak typeof(self) weakSelf = self;
        self.assetVideoRequestID = [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset  options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            weakSelf.assetVideoRequestID = PHInvalidImageRequestID;
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                completion(((AVURLAsset *)asset).URL);
            } else {
                completion(nil);
            }
        }];
    }
}

//MARK: - JLPhoto Protocol Methods
- (UIImage *)underlyingImage {
    return _underlyingImage;
}

/**
 加载底层显示对象
 */
- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // 正在加载 不再重新加载
    if (self.loadingInProgress) return;
    self.loadingInProgress = YES;
    @try {
        // 对象已经存在 通知加载完成
        if (self.underlyingImage) {
            [self imageLoadingComplete];
            // 对象不存在 进行加载工作
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    } @catch (NSException *exception) {
        // 存在异常 清空对象
        self.underlyingImage = nil;
        [self imageLoadingComplete];
        
    } @finally {
    }
    
}

/**
 执行加载底层显示对象
 */
- (void)performLoadUnderlyingImageAndNotify {
    // 通过UIImage初始化时，图片已经存在
    if (self.image) {
        self.underlyingImage = self.image;
        [self imageLoadingComplete];
        
        // 通过相片URL初始化时，需要通过URL获取图片对象
    } else if (self.photoURL) {
        // URL来自于相册
        if ([[[self.photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            // 异步加载相册图片
            [self performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:self.photoURL];
            
            // 资源来自于本地文件
        } else if ([self.photoURL isFileReferenceURL]) {
            // 异步加载本地文件
            [self performLoadUnderlyingImageAndNotifyWithLocalFileURL:self.photoURL];
            
            // 资源来自于网络
        } else {
            // 异步加载网络资源, 使用SDWebImage
            [self performLoadUnderlyingImageAndNotifyWithWebURL:self.photoURL];
            
        }
        
        // 通过PHAssets初始化时，需要加 Photos 资源
    } else if (self.asset) {
        // 加载来自于 Photos 中的资源
        [self performLoadUnderlyingImageAndNotifyWithAsset:self.asset targetSize:self.assetTargetSize];
        
        // 其他情况 空图片
    } else {
        [self imageLoadingComplete];
        
    }
}

- (void)unloadUnderlyingImage {
    self.loadingInProgress = NO;
    self.underlyingImage = nil;
}

- (void)cancelAnyLoading {
    if (self.webImageOperation) {
        [self.webImageOperation cancel];
        self.loadingInProgress = NO;
    }
    [self cancelImageRequest];
    [self cancelVideoRequest];
}

@end
