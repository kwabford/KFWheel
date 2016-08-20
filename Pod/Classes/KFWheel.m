//
//  KFWheel.m
//  offlineWeb
//
//  Created by Kwab Fordjour on 2015-12-10.
//  Copyright © 2015 Kwab Fordjour. All rights reserved.
//

#import "KFWheel.h"

#define DEBUG 0

@interface KFWheel () {
    UIColor *_orientationMarkerColor;
    CAShapeLayer *_gradientMask;
    CAGradientLayer *_knobTrackGradientLayer;
    
    CGPoint _midPoint;
    NSTimeInterval last_timestamp;
    
    CGFloat _cumulatedAngle;
    CGFloat _dTheta;
    CGFloat _angularVelocity;
    
    CGFloat _innerRadius;
    CGFloat _outerRadius;
    
    NSTimer *knobTransformPollingTimer;
    UIAttachmentBehavior* attachmentBehavior;
    UIDynamicItemBehavior *rotationBehaviour;
    
    
    
}

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;


@end

@implementation KFWheel

@synthesize orientationMarker, knobRotatingView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initShared];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initShared];
    }
    return self;
}

- (void) initShared
{
//    self.backgroundColor = self.tintColor;
    self.orientationMarkerColor = [UIColor redColor];
    
    self.value = 0.0;
    self.minimumValue = 0.0;
    self.maximumValue = 100.0;
    
    _cumulatedAngle = 0;
    _angularVelocity = 0;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.animator.delegate = self;
    self.angularResistance = 1.0;
    
    // Set up orientation marker
    
//    CGFloat mSize = size/6;
//    
//    self.orientationMarker = [[UIView alloc] init];
//    
//    self.orientationMarker.frame = CGRectMake(size/2, 0.0, mSize, mSize);;
//    self.orientationMarker.backgroundColor = self.orientationMarkerColor;
//    
//    [self addSubview:self.orientationMarker];
}

- (void)tintColorDidChange
{
//    self.backgroundColor = self.tintColor;
    [self updateGradient];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.knobRotatingView.userInteractionEnabled = NO;
    UIView *v = self.knobRotatingView; //[[UIView alloc] initWithFrame:self.bounds];
    CGRect r = self.frame;
    r.origin = CGPointZero;
    CGFloat size = MIN(r.size.width, r.size.height);
    
    _outerRadius  = size/2;
    _innerRadius = (6 * _outerRadius)/10;
    _midPoint = [self convertPoint:self.center fromView:self.superview];
    
    
    [self.animator removeBehavior:attachmentBehavior];
    attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.knobRotatingView
                                                   offsetFromCenter:UIOffsetMake(0.0f, 0.0f)
                                                   attachedToAnchor:_midPoint];
    
    [attachmentBehavior setDamping:1000];
    [attachmentBehavior setLength:0];
    [attachmentBehavior setFrequency:0];
    
    [self.animator addBehavior:attachmentBehavior];

    
//    attachmentBehavior.anchorPoint = _midPoint;
    
    CGFloat calculatedRadius = _innerRadius + ((_outerRadius - _innerRadius)/2);
    
    NSLog(@"_outerRadius:\t%.3f\t_innerRadius:\t%.3f\t_midPoint.x:\t%.3f\tcalculatedRadius:\t%.3f",_outerRadius,_innerRadius, _midPoint.x, calculatedRadius);
    
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter: _midPoint//center
                                                              radius: calculatedRadius
                                                          startAngle: M_PI
                                                            endAngle: M_PI + (2 * M_PI)
                                                           clockwise: YES];

    
//    [_knobTrackGradientLayer removeFromSuperlayer];
//    _knobTrackGradientLayer = nil;
    
    if (_knobTrackGradientLayer == nil)
    {
        _gradientMask = [CAShapeLayer layer];
        _gradientMask.fillColor = [[UIColor clearColor] CGColor];
        _gradientMask.strokeColor = [[UIColor blackColor] CGColor];
        _gradientMask.lineWidth = _outerRadius - _innerRadius;
        _gradientMask.frame = CGRectMake(0, 0, v.bounds.size.width, v.bounds.size.height);
        
        _gradientMask.path = circlePath.CGPath;
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0.5,1.0);
        gradientLayer.endPoint = CGPointMake(0.5,0.0);
        gradientLayer.frame = CGRectMake(0, 0, v.bounds.size.width, v.bounds.size.height);
        _knobTrackGradientLayer = gradientLayer;
        
        [self updateGradient];
        
        [_knobTrackGradientLayer setMask:_gradientMask];
        
        [v.layer addSublayer:_knobTrackGradientLayer];
    } else {
        
        _gradientMask.path = circlePath.CGPath;
        _gradientMask.lineWidth = _outerRadius - _innerRadius;
        _gradientMask.frame = r;
        
        _knobTrackGradientLayer.frame = r;
    }
    
}


#pragma mark - Sending Actions
/**
 * https://developer.apple.com/library/ios/documentation/General/Conceptual/Devpedia-CocoaApp/TargetAction.html#//apple_ref/doc/uid/TP40009071-CH3
 **/
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    [super sendAction:action to:target forEvent:event];
}

-(void) setValue:(float)value
{
    _value = value;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}



#pragma mark - Handling Touches

- (BOOL)pointInside:(CGPoint)point
          withEvent:(UIEvent *)event
{
  return [self pointIsValid:point];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    
    // TODO: handle Muliple Touches
    
    CGPoint nowPoint  = [touch locationInView: self];
    
    BOOL shouldBeginTracking = [self pointIsValid:nowPoint];
    
    if (shouldBeginTracking) {
        // Stop a spinning knob
        _angularVelocity = 0;
        [self.animator removeAllBehaviors];
//        [self.animator removeBehavior:rotationBehaviour];
         NSLog(@"* stopRotation * --- knobRotationAngle: %f", _cumulatedAngle);
        if (knobTransformPollingTimer.valid) [knobTransformPollingTimer invalidate];
        
        last_timestamp = event.timestamp;
    }
    
    return shouldBeginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    
    // Calculate Velocity
    NSTimeInterval elapsed_time = event.timestamp - last_timestamp;
    last_timestamp = event.timestamp;
    
    
    CGPoint currentPoint  = [touch locationInView: self];
    CGPoint prevPoint = [touch previousLocationInView: self];
    
    BOOL touchInHitArea = [self pointIsValid:currentPoint];
    // make sure the new point is within the area
    if (touchInHitArea)
    {
        // calculate rotation angle between two points
        _dTheta = [self angleBetweenLinesInRadiansWithLineAStart:_midPoint lineAEnd:prevPoint lineBStart:_midPoint lineBEnd:currentPoint];
        
        if (_cumulatedAngle / (2 * M_PI) < self.minimumValue) {
            
            _dTheta *=  MIN(.5, 1 / pow((self.minimumValue * (2 * M_PI)) - _cumulatedAngle, 8)) ;
            if (DEBUG) NSLog(@"_dTheta %f", _dTheta);
        }
        
        // fix value, if the 12 o'clock position is between prevPoint and nowPoint
        if (_dTheta > M_PI)
        {
            _dTheta -= 2 * M_PI;
        }
        else if (_dTheta < -M_PI)
        {
            _dTheta += 2 * M_PI;
        }
        
        // sum up single steps
        _cumulatedAngle += _dTheta;
        
        
        //Rotate view
        self.knobRotatingView.transform = CGAffineTransformMakeRotation(_cumulatedAngle);
        
        // Update Value if between min and max values
        CGFloat convertedValue = _cumulatedAngle / (2 * M_PI);
//        if (self.minimumValue <= convertedValue  && convertedValue <= self.maximumValue ) {
        self.value = _cumulatedAngle / (2 * M_PI);
//        }
        
        // Update Velocity
        _angularVelocity = (_dTheta/elapsed_time);
        
        if (DEBUG) NSLog(@"_cumulatedAngle: %f _angularVelocity: %f", _cumulatedAngle, _angularVelocity);
    
//        NSLog(@"distanceBetweenPoints: %f _outerRadius: %f", [self distanceBetweenPointsA:currentPoint andB:_midPoint], _outerRadius);
    } else {
        [self endTrackingWithTouch:touch withEvent:event];
    }
    return touchInHitArea;
}

/** Add Velocity Animation Behaviours **/
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGFloat minVelocity = 1.0;
    
    [self.animator removeBehavior:rotationBehaviour];
    
    if (minVelocity < sqrt( pow(_angularVelocity, 2.0)) ) {
        
        rotationBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[self.knobRotatingView]];
        rotationBehaviour.allowsRotation = YES;
        rotationBehaviour.friction = 0;
        rotationBehaviour.angularResistance = self.angularResistance;
        [rotationBehaviour addAngularVelocity:_angularVelocity forItem:self.knobRotatingView];
        
        [self.animator addBehavior:rotationBehaviour];
        
        if (knobTransformPollingTimer.valid) [knobTransformPollingTimer invalidate];
        knobTransformPollingTimer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(animatorUpdateAngleValue) userInfo:nil repeats:YES];
    }
    
    [self addSnapIfNeeded];
    
    if (DEBUG) NSLog(@"endTracking v: %f ", _angularVelocity);
    
    self.value = _cumulatedAngle / (2 * M_PI);
//    self.angleLabel.text = [NSString stringWithFormat:@"fin: self.value: %f \n_cumulatedAngle: %f", self.value, _cumulatedAngle];
}
#pragma mark - Private Helper Methods

/** Calculates the distance between point1 and point 2. */
- (CGFloat) distanceBetweenPointsA:(CGPoint) point1
                              andB:(CGPoint) point2
{
    CGFloat dx = point1.x - point2.x;
    CGFloat dy = point1.y - point2.y;
    return sqrt(dx*dx + dy*dy);
}

- (CGFloat) angleBetweenLinesInRadiansWithLineAStart:(CGPoint) beginLineA
                                            lineAEnd:(CGPoint) endLineA
                                          lineBStart:(CGPoint) beginLineB
                                            lineBEnd:(CGPoint) endLineB
{
    CGFloat a = endLineA.x - beginLineA.x;
    CGFloat b = endLineA.y - beginLineA.y;
    CGFloat c = endLineB.x - beginLineB.x;
    CGFloat d = endLineB.y - beginLineB.y;
    
    CGFloat atanA = atan2(a, b);
    CGFloat atanB = atan2(c, d);
    
    // convert radiants to degrees
    return (atanA - atanB);
}

- (BOOL) pointIsValid:(CGPoint) p
{
    CGFloat distance = [self distanceBetweenPointsA:_midPoint andB:p];
    return _innerRadius <= distance && distance <= _outerRadius;
}

- (void) addSnapIfNeeded
{
    
    if (DEBUG) NSLog(@"addSnapIfNeeded b4 %@", self.animator.behaviors);
    if ([self.animator.behaviors containsObject:self.snapBehavior]) return;
    
    // TODO: make sure works for non-zero minimumValue
    if (_cumulatedAngle/(2 * M_PI) < self.minimumValue) {
        
        if (DEBUG) NSLog(@"addSnapIfNeeded2");
        
        // Remove the previous behavior.
        [self.animator removeBehavior:self.snapBehavior];
        
        UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.knobRotatingView snapToPoint:self.knobRotatingView.center];
        [self.animator addBehavior:snapBehavior];
        
        self.snapBehavior = snapBehavior;
    }
    
}

- (void) animatorUpdateAngleValue
{

    
    
    CGAffineTransform prevTransform = CGAffineTransformMakeRotation(_cumulatedAngle);
    
    CGFloat oldAngle = -atan2(prevTransform.c, prevTransform.a);
    CGFloat newAngle = -atan2(self.knobRotatingView.transform.c, self.knobRotatingView.transform.a);
    
    _dTheta = [self fixDeltaTheta: newAngle - oldAngle];
    
    
    
    if (_cumulatedAngle < self.minimumValue * (2 * M_PI)) {
        
        [self addSnapIfNeeded];
        
        _cumulatedAngle = self.minimumValue * (2 * M_PI);
        
        if (DEBUG) NSLog(@"---------------- animatorUpdateAngleValue ---------------- %f", _cumulatedAngle);
        
    } else {
        _cumulatedAngle += _dTheta;
    }
    
    if (DEBUG) NSLog(@"Auto: %f", _cumulatedAngle);
    
    self.value = _cumulatedAngle / (2 * M_PI);
}

-(CGFloat) fixDeltaTheta:(CGFloat)anAngle
{
    CGFloat angle = anAngle;
    
    // fix value, if anAngle crosses the 12 o'clock position
    // TODO: Refactor into shared utils class
    if (angle > M_PI)
    {
        angle -= 2 * M_PI;
    }
    else if (angle < -M_PI)
    {
        angle += 2 * M_PI;
    }
    
    
    if (DEBUG) NSLog(@"\nanAngle:\t%f\nangle:\t%f", anAngle, angle);
    
    return angle;
}

- (void)updateGradient
{
    NSMutableArray *colors = [NSMutableArray array];
    
    [colors addObject:(id)[self.tintColor CGColor]];
    
    CGFloat h, s, b, a;
    [self.tintColor getHue:&h saturation:&s brightness:&b alpha:&a];
    
    for (int i = 0; i < 3; i++) {
        [colors addObject:(id)[[UIColor colorWithHue:h saturation:1 brightness: pow(0.8, i) alpha:1] CGColor]];
    }
    _knobTrackGradientLayer.colors = colors;
}

#pragma mark - UIDynamicAnimatorDelegate methods

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
    CGFloat finalKnobAngle = -atan2(self.knobRotatingView.transform.c, self.knobRotatingView.transform.a);
    
    if (_cumulatedAngle < self.minimumValue * (2 * M_PI)) {
        _cumulatedAngle = finalKnobAngle;
    }
    
    // TODO: Send value change actions to targets
    self.value = _cumulatedAngle / (2 *  M_PI);
    
    
    if (DEBUG) NSLog(@"dynamicAnimatorDidPause ============================== %f", _cumulatedAngle);
//    self.angleLabel.text = [NSString stringWithFormat:@"+ self.knob.value: %f \nknobRotationAngle: %f", self.knob.value, knobRotationAngle];//+ knobRotationAngle: %f", knobRotationAngle];
    
    if (knobTransformPollingTimer.valid) [knobTransformPollingTimer invalidate];
}


- (void) setOrientationMarkerColor:(UIColor *)orientationMarkerColor
{
    self.orientationMarker.backgroundColor = orientationMarkerColor;
}

- (UIColor *) orientationMarkerColor
{
    
    if (_orientationMarkerColor == nil) {
        _orientationMarkerColor = [UIColor whiteColor];
    }
    
    return self.orientationMarker.backgroundColor;
}

@end
