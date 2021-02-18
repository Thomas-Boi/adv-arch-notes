//
//  Transformations.m
//  A01055477_Assignment1
//
//  Created by socas on 2021-02-17.
//

#import "Transformations.h"

@interface Transformations ()
{
    GLKVector3 globalPosition;
    GLKVector3 globalRotation;
    float depth;
    
    float scaleStart;
    float scaleEnd;
    
    GLKVector2 translateStart;
    GLKVector2 translateEnd;
    
    float rotationStart;
    GLKQuaternion rotationEnd;
    GLKVector3 rotationAxis;
}

@property(nonatomic) GLKVector3 globalPosition;
@property(nonatomic) GLKVector3 globalRotation;
@end


@implementation Transformations

@synthesize globalPosition=globalPosition;
@synthesize globalRotation=globalRotation;

- (id)initWithDepth:(float)z Scale:(float)s Translation:(GLKVector2)t Rotation:(GLKVector3)r
{
    if (self = [super init])
    {
        depth = z;
        scaleEnd = s;
        translateEnd = t;
        rotationAxis = GLKVector3Make(0.0f, 1.0f, 1.0f);
        
        globalPosition = GLKVector3Make(t.x, t.y, depth);
        globalRotation = GLKVector3Make(r.x, r.y, r.z);
        
        r.z = GLKMathDegreesToRadians(r.z);
        rotationEnd = GLKQuaternionIdentity;
        GLKQuaternion rotQuat = GLKQuaternionMakeWithAngleAndVector3Axis(-r.z, rotationAxis);
        rotationEnd = GLKQuaternionMultiply(rotQuat , rotationEnd);
    }
    return self;
}

- (void)start
{
    scaleStart = scaleEnd;
    translateStart = GLKVector2Make(0.0f, 0.0f);
    rotationStart = 0.0f;
}

- (void)scale:(float)s
{
    scaleEnd = s * scaleStart;
}

- (void)translate:(GLKVector2)t withMultiplier:(float)m
{
    t = GLKVector2MultiplyScalar(t, m);
        
    float dx = translateEnd.x + (t.x-translateStart.x);
    // reverse direction cause in Swift, downward is positive but in OpenGL, upward
    // is positive
    float dy = translateEnd.y - (t.y-translateStart.y);
        
    translateEnd = GLKVector2Make(dx, dy);
    translateStart = GLKVector2Make(t.x, t.y);
    globalPosition.x += t.x;
    globalRotation.y += t.y;
}

- (void)rotate:(float)rotation withMultiplier:(float)m
{
    // reverse sign so the rotation is counter clockwise when swipe left to right
    float deltaRotation = -(rotation - rotationStart) * m;
    rotationStart = rotation;
    GLKQuaternion rotQuat = GLKQuaternionMakeWithAngleAndVector3Axis(deltaRotation, rotationAxis);
    
    globalRotation.y += deltaRotation;
    globalRotation.z += deltaRotation;
    rotationEnd = GLKQuaternionMultiply(rotQuat, rotationEnd);
}

- (void)reset
{
    
}

- (GLKMatrix4)getModelViewMatrix
{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    GLKMatrix4 quaternionMatrix = GLKMatrix4MakeWithQuaternion(rotationEnd);
    
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, translateEnd.x, translateEnd.y, -depth);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, quaternionMatrix);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scaleEnd, scaleEnd, scaleEnd);
    return modelViewMatrix;
}
@end
