#import "SpectacleWindowPositionCalculator.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "SpectacleJavaScriptEnvironment.h"
#import "SpectacleWindowPositionCalculationRegistry.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleUtilities.h"

@implementation SpectacleWindowPositionCalculator
{
  SpectacleWindowPositionCalculationRegistry *_windowPositionCalculationRegistry;
  SpectacleJavaScriptEnvironment *_javaScriptEnvironment;
}

- (instancetype)initWithErrorHandler:(void(^)(NSString *message))errorHandler
{
  if (self = [super init]) {
    _windowPositionCalculationRegistry = [SpectacleWindowPositionCalculationRegistry new];
    _javaScriptEnvironment = [[SpectacleJavaScriptEnvironment alloc] initWithContextBuilder:^(JSContext *context) {
      context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSString *errorName = [exception[@"name"] toString];
        NSString *errorMessage = [exception[@"message"] toString];
        errorHandler([NSString stringWithFormat:@"%@\n%@", errorName, errorMessage]);
      };
      context[@"windowPositionCalculationRegistry"] = _windowPositionCalculationRegistry;
      context[@"CGRectContainsRect"] = ^BOOL(CGRect rect1, CGRect rect2) {
        return CGRectContainsRect(rect1, rect2);
      };
      context[@"CGRectEqualToRect"] = ^BOOL(CGRect rect1, CGRect rect2) {
        return CGRectEqualToRect(rect1, rect2);
      };
      context[@"CGRectGetMinX"] = ^CGFloat(CGRect rect) {
        return CGRectGetMinX(rect);
      };
      context[@"CGRectGetMinY"] = ^CGFloat(CGRect rect) {
        return CGRectGetMinY(rect);
      };
      context[@"CGRectGetMidX"] = ^CGFloat(CGRect rect) {
        return CGRectGetMidX(rect);
      };
      context[@"CGRectGetMidY"] = ^CGFloat(CGRect rect) {
        return CGRectGetMidY(rect);
      };
      context[@"CGRectGetMaxX"] = ^CGFloat(CGRect rect) {
        return CGRectGetMaxX(rect);
      };
      context[@"CGRectGetMaxY"] = ^CGFloat(CGRect rect) {
        return CGRectGetMaxY(rect);
      };
    }];
  }
  return self;
}

- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action
{
  JSValue *windowPositionCalculation = [_windowPositionCalculationRegistry windowPositionCalculationWithAction:action];
  if (!windowPositionCalculation) {
    return nil;
  }
  JSValue *result = [windowPositionCalculation callWithArguments:@[
                                                                   [_javaScriptEnvironment valueWithRect:windowRect],
                                                                   [_javaScriptEnvironment valueWithRect:visibleFrameOfSourceScreen],
                                                                   [_javaScriptEnvironment valueWithRect:visibleFrameOfDestinationScreen],
                                                                   ]];
  SpectacleWindowPositionCalculationResult *windowResult = [SpectacleWindowPositionCalculationResult resultWithAction:action windowRect:[result toRect]];
  int gapSizeMacOSBottom = 4;
  int heightOffset = 0;
  int widthOffset = 0;
  int xOffset = 0;
  int yOffset = 0;
  
  if (windowResult.action == kSpectacleWindowActionFullscreen) {
    heightOffset = gapSize * 2;
    widthOffset = gapSize * 2;
    xOffset = gapSize;
    yOffset = gapSize;
  }
  else if (windowResult.action == kSpectacleWindowActionLeftHalf) {
    widthOffset = gapSize + gapSize / 2;
    heightOffset = gapSize * 2;
    xOffset = gapSize;
    yOffset = gapSize;
  }
  else if (windowResult.action == kSpectacleWindowActionRightHalf) {
    widthOffset = gapSize + gapSize / 2;
    heightOffset = gapSize * 2;
    xOffset = gapSize / 2;
    yOffset = gapSize;
  }
  else if (windowResult.action == kSpectacleWindowActionUpperLeft) {
    heightOffset = gapSize + gapSize / 2;
    widthOffset = gapSize + gapSize / 2;
    xOffset = gapSize;
    yOffset = gapSize / 2;
  }
  else if (windowResult.action == kSpectacleWindowActionUpperRight) {
    heightOffset = gapSize + gapSize / 2;
    widthOffset = gapSize + gapSize / 2;
    xOffset = gapSize / 2;
    yOffset = gapSize / 2;
  }
  else if (windowResult.action == kSpectacleWindowActionLowerLeft) {
    heightOffset = gapSize + gapSize / 2;
    widthOffset = gapSize + gapSize / 2;
    xOffset = gapSize;
    yOffset = gapSize;
  }
  else if (windowResult.action == kSpectacleWindowActionLowerRight) {
    heightOffset = gapSize + gapSize / 2;
    widthOffset = gapSize + gapSize / 2;
    xOffset = gapSize / 2;
    yOffset = gapSize;
  }
  else if (windowResult.action == kSpectacleWindowActionTopHalf) {
    widthOffset = gapSize * 2;
    heightOffset = gapSize + gapSize / 2;
    xOffset = gapSize;
    yOffset = gapSize / 2;
  }
  else if (windowResult.action == kSpectacleWindowActionBottomHalf) {
    widthOffset = gapSize * 2;
    heightOffset = gapSize + gapSize / 2;
    xOffset = gapSize;
    yOffset = gapSize;
  }
  
  CGRect windowRectGap = windowResult.windowRect;
  windowRectGap.size.height -= heightOffset;
  windowRectGap.size.width -= widthOffset;
  windowRectGap.origin.x += xOffset;
  windowRectGap.origin.y += yOffset;
  
  if (gapSize != 0 && ((int)visibleFrameOfDestinationScreen.origin.y % 10) == gapSizeMacOSBottom) {
    windowRectGap.origin.y -= gapSizeMacOSBottom;
    windowRectGap.size.height += gapSizeMacOSBottom;
  }
  
  SpectacleWindowPositionCalculationResult *windowResultGap = [[SpectacleWindowPositionCalculationResult alloc] initWithAction:windowResult.action windowRect:windowRectGap];
  return windowResultGap;
}

@end
