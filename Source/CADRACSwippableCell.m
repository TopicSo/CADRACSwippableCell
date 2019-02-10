//
//  CADRACSwippableCell.m
//  CADRACSwippableCell
//
//  Created by Joan Romano on 18/02/14.
//  Copyright (c) 2014 Crows And Dogs. All rights reserved.
//

#import "CADRACSwippableCell.h"

#import "UIColor+CADRACSwippableCellAdditions.h"
#import "UIView+CADRACSwippableCellAdditions.h"

@import ReactiveObjC;

@interface CADRACSwippableCell () <UIGestureRecognizerDelegate>{
    BOOL canSnapshottingView;
}


@property (nonatomic, strong) RACSubject *revealViewSignal;
@property (nonatomic, strong) UIView *contentSnapshotView;

@end

@implementation CADRACSwippableCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self setupView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupView];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)setupView
{
    self.revealViewSignal = [RACSubject subject];
    canSnapshottingView = false;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:nil];
    panGesture.delegate = self;
    
    __weak CADRACSwippableCell *weakSelf = self;
    
    RACSignal *gestureSignal = [panGesture rac_gestureSignal],
    *beganOrChangedSignal = [gestureSignal filter:^BOOL(UIGestureRecognizer *gesture) {
        return gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateBegan;
    }],
    *endedOrCancelledSignal = [gestureSignal filter:^BOOL(UIGestureRecognizer *gesture) {
        return gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled;
    }];
    
    RAC(weakSelf, contentSnapshotView.center) = [beganOrChangedSignal map:^id(id value) {
        return [NSValue valueWithCGPoint:[weakSelf centerPointForTranslation:[panGesture translationInView:weakSelf]]];
    }];
    
    [beganOrChangedSignal subscribeNext:^(UIPanGestureRecognizer *panGesture) {
        [weakSelf.contentView addSubview:weakSelf.revealView];
        [weakSelf.contentView addSubview:weakSelf.contentSnapshotView];
        
        [panGesture setTranslation:CGPointZero inView:weakSelf];
    }];
    
    [[endedOrCancelledSignal filter:^BOOL(UIPanGestureRecognizer *gestureRecognizer) {
        return fabs(CGRectGetMinX(weakSelf.contentSnapshotView.frame)) >= CGRectGetWidth(weakSelf.revealView.frame)/2 ||
        [weakSelf shouldShowRevealViewForVelocity:[gestureRecognizer velocityInView:weakSelf]];
    }] subscribeNext:^(id x) {
        [weakSelf showRevealViewAnimated:YES];
    }];
    
    [[endedOrCancelledSignal filter:^BOOL(UIPanGestureRecognizer *gestureRecognizer) {
        return fabs(CGRectGetMinX(weakSelf.contentSnapshotView.frame)) < CGRectGetWidth(weakSelf.revealView.frame)/2 ||
        [weakSelf shouldHideRevealViewForVelocity:[gestureRecognizer velocityInView:weakSelf]];
    }] subscribeNext:^(id x) {
        [weakSelf hideRevealViewAnimated:YES];
    }];
    
    [[RACSignal merge:@[RACObserve(weakSelf, allowedDirection), RACObserve(weakSelf, revealView)]] subscribeNext:^(id x) {
        [weakSelf setNeedsLayout];
    }];
    
    [[self rac_prepareForReuseSignal] subscribeNext:^(id x) {
        [weakSelf.contentSnapshotView removeFromSuperview];
        weakSelf.contentSnapshotView = nil;
        
        [weakSelf.revealView removeFromSuperview];
        weakSelf.revealView = nil;
    }];
    
    [[[self rac_signalForSelector:@selector(updateConstraints)] filter:^BOOL(id value) {
        return weakSelf.contentSnapshotView != nil;
    }] subscribeNext:^(id x) {
        NSDictionary *bind = @{@"contentSnapshotView":weakSelf.contentSnapshotView};
        [weakSelf.contentSnapshotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentSnapshotView]|" options:0 metrics:nil views:bind]];
        [weakSelf.contentSnapshotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentSnapshotView]|" options:0 metrics:nil views:bind]];
        
        [weakSelf updateConstraints];
    }];
    
    [self addGestureRecognizer:panGesture];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    canSnapshottingView = true;
    
    self.revealView.frame = (CGRect){
        .origin = CGPointMake(self.allowedDirection == CADRACSwippableCellAllowedDirectionRight ? 0.0f : CGRectGetWidth(self.frame) - CGRectGetWidth(self.revealView.frame), 0.0f),
        .size = self.revealView.frame.size
    };
}

#pragma mark - Public

- (void)showRevealViewAnimated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.1 : 0.0
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.contentSnapshotView.center = CGPointMake(
                            self.allowedDirection == CADRACSwippableCellAllowedDirectionRight ?
                               CGRectGetWidth(self.frame)/2 + CGRectGetWidth(self.revealView.frame) :
                               CGRectGetWidth(self.frame)/2 - CGRectGetWidth(self.revealView.frame),
                             self.contentSnapshotView.center.y);
                     }
                     completion:^(BOOL finished) {
                         [(RACSubject *)self.revealViewSignal sendNext:@(YES)];
                     }];
}

- (void)hideRevealViewAnimated:(BOOL)animated
{
    if (CGPointEqualToPoint(self.contentSnapshotView.center, self.contentView.center))
        return;
    
    [UIView animateWithDuration:animated ? 0.1 : 0.0
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.contentSnapshotView.center = CGPointMake(CGRectGetWidth(self.frame)/2, self.contentSnapshotView.center.y);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:animated ? 0.1 : 0.0
                                               delay:0.0f
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{
                                              self.contentSnapshotView.center = CGPointMake(self.allowedDirection == CADRACSwippableCellAllowedDirectionRight ? self.center.x+2.0f : self.center.x-2.0f, self.contentSnapshotView.center.y);
                                          } completion:^(BOOL finished) {
                                              [UIView animateWithDuration:animated ? 0.1 : 0.0
                                                                    delay:0.0f
                                                                  options:UIViewAnimationOptionCurveLinear
                                                               animations:^{
                                                                   self.contentSnapshotView.center = CGPointMake(CGRectGetWidth(self.frame)/2, self.contentSnapshotView.center.y);
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [(RACSubject *)self.revealViewSignal sendNext:@(NO)];
                                                                   [self.contentSnapshotView removeFromSuperview];
                                                                   self.contentSnapshotView = nil;
                                                                   [self.revealView removeFromSuperview];
                                                               }];
                                          }];
                     }];
}

#pragma mark - Private

- (BOOL)shouldShowRevealViewForVelocity:(CGPoint)velocity
{
    BOOL shouldShow = NO,
         velocityIsBiggerThanOffset = fabs(velocity.x) > CGRectGetWidth(self.revealView.frame)/2;
    
    switch (self.allowedDirection)
    {
        case CADRACSwippableCellAllowedDirectionLeft:
            shouldShow = velocity.x < 0 && velocityIsBiggerThanOffset;
            break;

        case CADRACSwippableCellAllowedDirectionRight:
            shouldShow = velocity.x > 0 && velocityIsBiggerThanOffset;
            break;
    }
    
    return shouldShow;
}

- (BOOL)shouldHideRevealViewForVelocity:(CGPoint)velocity
{
    BOOL shouldHide = NO,
         velocityIsBiggerThanOffset = fabs(velocity.x) > CGRectGetWidth(self.revealView.frame)/2;
    
    switch (self.allowedDirection)
    {
        case CADRACSwippableCellAllowedDirectionLeft:
            shouldHide = velocity.x > 0 && velocityIsBiggerThanOffset;
            break;
            
        case CADRACSwippableCellAllowedDirectionRight:
            shouldHide = velocity.x < 0 && velocityIsBiggerThanOffset;
            break;
    }
    
    return shouldHide;
}

- (CGPoint)centerPointForTranslation:(CGPoint)translation
{
    CGPoint centerPoint = CGPointMake(0.0f, self.contentSnapshotView.center.y);
    
    switch (self.allowedDirection)
    {
        case CADRACSwippableCellAllowedDirectionRight:
            centerPoint.x = MAX(CGRectGetWidth(self.frame)/2, MIN(self.contentSnapshotView.center.x + translation.x,
                                                                  CGRectGetWidth(self.revealView.frame) + CGRectGetWidth(self.frame)/2));
            break;
        case CADRACSwippableCellAllowedDirectionLeft:
            centerPoint.x = MIN(CGRectGetWidth(self.frame)/2, MAX(self.contentSnapshotView.center.x + translation.x,
                                                                  CGRectGetWidth(self.frame)/2 - CGRectGetWidth(self.revealView.frame)));
            break;
    }
    
    return centerPoint;
}

#pragma mark - UIGestureRecognizer Delegate

// Would be awesome to do this with RAC
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isMemberOfClass:[UIPanGestureRecognizer class]])
    {
        UIPanGestureRecognizer *gesture = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint point = [gesture velocityInView:self];
        
        if (fabs(point.x) > fabs(point.y))
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return otherGestureRecognizer != self.superCollectionView.panGestureRecognizer;
}

#pragma mark - Lazy

- (UIView *)contentSnapshotView
{
    if (!_contentSnapshotView && canSnapshottingView)
    {
        _contentSnapshotView = [self snapshotViewAfterScreenUpdates:NO];
        _contentSnapshotView.backgroundColor = [UIColor firstNonClearBackgroundColorInHierarchyForView:self];
    }
    
    return _contentSnapshotView;
}

@end
