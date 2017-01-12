//
//  CSSFPSGraph.m
//  CSSLayout
//
//  Created by 沈强 on 2017/1/11.
//  Copyright © 2017年 qiang.shen. All rights reserved.
//

#import "CSSFPSGraph.h"

@interface CSSFPSGraph()

@property (nonatomic, strong, readonly) CAShapeLayer *graph;

@property (nonatomic, strong, readonly) UILabel *label;

@end

@implementation CSSFPSGraph {
  CAShapeLayer *_graph;
  UILabel *_label;
  
  CGFloat *_frames;
  UIColor *_color;
  
  NSTimeInterval _prevTime;
  NSUInteger _frameCount;
  NSUInteger _FPS;
  NSUInteger _maxFPS;
  NSUInteger _minFPS;
  NSUInteger _length;
  NSUInteger _height;
  CADisplayLink *_uiDisplayLink;
}

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
  if ((self = [super initWithFrame:frame])) {
    _frameCount = -1;
    _prevTime = -1;
    _maxFPS = 0;
    _minFPS = 60;
    _length = (NSUInteger)floor(frame.size.width);
    _height = (NSUInteger)floor(frame.size.height);
    _frames = calloc(sizeof(CGFloat), _length);
    _color = color;
    
    [self.layer addSublayer:self.graph];
    [self addSubview:self.label];
    _uiDisplayLink = [CADisplayLink displayLinkWithTarget:self
                                                 selector:@selector(onTick:)];
    [_uiDisplayLink addToRunLoop:[NSRunLoop mainRunLoop]
                         forMode:NSRunLoopCommonModes];
  }
  return self;
}

- (void)dealloc {
  free(_frames);
}


- (CAShapeLayer *)graph {
  if (!_graph) {
    _graph = [CAShapeLayer new];
    _graph.frame = self.bounds;
    _graph.backgroundColor = [_color colorWithAlphaComponent:0.2].CGColor;
    _graph.fillColor = _color.CGColor;
  }
  
  return _graph;
}

- (UILabel *)label {
  if (!_label) {
    _label = [[UILabel alloc] initWithFrame:self.bounds];
    _label.font = [UIFont boldSystemFontOfSize:13];
    _label.textAlignment = NSTextAlignmentCenter;
  }
  
  return _label;
}

- (void)onTick:(CADisplayLink *)uiDisplayLink {
  NSTimeInterval timestamp = uiDisplayLink.timestamp;
  
  _frameCount++;
  if (_prevTime == -1) {
    _prevTime = timestamp;
  } else if (timestamp - _prevTime >= 1) {
    _FPS = round(_frameCount / (timestamp - _prevTime));
    _minFPS = MIN(_minFPS, _FPS);
    _maxFPS = MAX(_maxFPS, _FPS);
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_label.text = [NSString stringWithFormat:@"%lu", (unsigned long)self->_FPS];
    });
    
    CGFloat scale = 60.0 / _height;
    for (NSUInteger i = 0; i < _length - 1; i++) {
      _frames[i] = _frames[i + 1];
    }
    _frames[_length - 1] = _FPS / scale;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, _height);
    for (NSUInteger i = 0; i < _length; i++) {
      CGPathAddLineToPoint(path, NULL, i, _height - _frames[i]);
    }
    CGPathAddLineToPoint(path, NULL, _length - 1, _height);
    
    _graph.path = path;
    CGPathRelease(path);
    
    _prevTime = timestamp;
    _frameCount = 0;
  }
}


@end
