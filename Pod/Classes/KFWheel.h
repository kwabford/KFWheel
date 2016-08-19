//
//  KFWheel.h
//  offlineWeb
//
//  Created by Kwab Fordjour on 2015-12-10.
//  Copyright © 2015 Kwab Fordjour. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@class UIImageView, UIImage;

@interface KFWheel : UIControl <NSCoding, UIDynamicAnimatorDelegate> //UISlider

@property(nonatomic) IBInspectable float value;                                 // default 0.0. this value will be pinned to min/max
@property(nonatomic) IBInspectable float minimumValue;                          // default 0.0. the current value may change if outside new min value
@property(nonatomic) IBInspectable float maximumValue;                          // default 1.0. the current value may change if outside new max value
@property(nonatomic) IBInspectable CGFloat angularResistance;

@property (nonatomic) IBOutlet UIView *knobRotatingView;

@property (nonatomic) IBOutlet UIView *orientationMarker;
@property IBInspectable UIColor *orientationMarkerColor;

@end
