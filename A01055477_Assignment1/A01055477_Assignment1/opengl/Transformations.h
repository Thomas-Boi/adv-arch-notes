//
//  Transformations.h
//  A01055477_Assignment1
//
//  Created by socas on 2021-02-17.
//

#ifndef Transformations_h
#define Transformations_h

#import <GLKit/GLKit.h>

@interface Transformations : NSObject

- (id)initWithDepth:(float)z Scale:(float)s Translation:(GLKVector2)t Rotation:(GLKVector3)r;
- (void)start;
- (void)scale:(float)s;
- (void)translate:(GLKVector2)t withMultiplier:(float)m;
- (void)rotate:(float)rotation withMultiplier:(float)m;
- (void)reset;
- (GLKMatrix4)getModelViewMatrix;

@end

#endif /* Transformations_h */
