//
//  UIView+MTTapDetecting.m
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import "UIView+MTTapDetecting.h"
#import <objc/runtime.h>

@import JRSwizzle;

@implementation UIView (MTTapDetecting)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        BOOL result = [[self class] jr_swizzleMethod:@selector(touchesEnded:withEvent:) withMethod:@selector(mt_touchesEnded:withEvent:) error:&error];
        if (!result || error) {
            NSLog(@"Can't swizzle methods - %@", [error description]);
        }
        
    });
}

- (id<MTTapDetectionViewDelegate>)tapDelegate {
    return objc_getAssociatedObject(self, @selector(tapDelegate));
}

- (void)setTapDelegate:(id<MTTapDetectionViewDelegate>)tapDelegate {
    self.userInteractionEnabled = YES;
    
    objc_setAssociatedObject(self, @selector(tapDelegate), tapDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)mt_touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger tapCount = touch.tapCount;
    switch (tapCount) {
        case 1:
            [self handleSingleTap:touch];
            break;
        case 2:
            [self handleDoubleTap:touch];
            break;
        case 3:
            [self handleTripleTap:touch];
            break;
        default:
            break;
    }
    [self mt_touchesEnded:touches withEvent:event];
}

- (void)handleSingleTap:(UITouch *)touch {
    if ([self.tapDelegate respondsToSelector:@selector(view:singleTapDetected:)])
        [self.tapDelegate view:self singleTapDetected:touch];
}

- (void)handleDoubleTap:(UITouch *)touch {
    if ([self.tapDelegate respondsToSelector:@selector(view:doubleTapDetected:)])
        [self.tapDelegate view:self doubleTapDetected:touch];
}

- (void)handleTripleTap:(UITouch *)touch {
    if ([self.tapDelegate respondsToSelector:@selector(view:tripleTapDetected:)])
        [self.tapDelegate view:self tripleTapDetected:touch];
}

@end
