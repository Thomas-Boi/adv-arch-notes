//
//  Copyright © Borna Noureddin. All rights reserved.
// this declares the interface for Renderer.mm

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>

@interface Renderer : NSObject

- (void)setup:(GLKView *)view;
- (void)loadModels;
- (void)update;
- (void)draw:(CGRect)drawRect;

@end

#endif /* Renderer_h */
