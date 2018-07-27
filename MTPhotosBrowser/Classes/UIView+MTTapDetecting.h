//
//  UIView+MTTapDetecting.h
//  MTPhotosBrowser
//
//  Created by Jason Li on 2018/7/18.
//

#import <UIKit/UIKit.h>

@protocol MTTapDetectionViewDelegate;
@interface UIView (MTTapDetecting)

@property (nonatomic, weak) id <MTTapDetectionViewDelegate> tapDelegate;

@end


@protocol MTTapDetectionViewDelegate <NSObject>

@optional

- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch;
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch;
- (void)view:(UIView *)view tripleTapDetected:(UITouch *)touch;

@end
