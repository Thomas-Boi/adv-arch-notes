//
//  ViewController.m
//  glesbasics
//
//  Created by Borna Noureddin on 2020-01-14.
//  Copyright © 2020 BCIT. All rights reserved.
//

#import "ViewController.h"
#import "Transformations.h"

@interface ViewController () {
    Renderer *glesRenderer; // ###
    Transformations *transformations;
    __weak IBOutlet UILabel *positionLabel;
    __weak IBOutlet UILabel *rotationLabel;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // ### <<<
    // set up the opengl window and draw

    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view];
    [glesRenderer loadModels];
    
    // Initialize transformations
    // by default everything is normal
    transformations = [[Transformations alloc] initWithDepth:5.0f Scale:1.0f Translation:GLKVector2Make(0.0f, 0.0f) Rotation:GLKVector3Make(0.0f, 0.0f, 45.0f)];
    
    // ### >>>
    
}

- (void)update
{
    GLKMatrix4 modelViewMatrix = [transformations getModelViewMatrix];
    [glesRenderer update:modelViewMatrix]; // ###
    
    // need to format text and display the position
    // positionLabel.text = transformations.globalPosition;
    // rotationLabel.text = transformations.globalRotation;
    
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [glesRenderer draw:rect]; // ###
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Begin transformations
    [transformations start];
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)sender
{
    if (glesRenderer.isRotating) return;
    [transformations scale:[sender scale]];
}

- (IBAction)pan:(UIPanGestureRecognizer *)sender
{
    if (glesRenderer.isRotating) return;
    
    if (sender.numberOfTouches == 1)
    {
        [self rotateCube:sender];
        
    }
    else if (sender.numberOfTouches == 2)
    {
        [self moveCube:sender];
        
    }
    
}

- (void)moveCube:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:sender.view];
    float x = translation.x/sender.view.frame.size.width;
    float y = translation.y/sender.view.frame.size.height;
    GLKVector2 translate = GLKVector2Make(x, y);
    [transformations translate:translate withMultiplier:5.0f];
}

- (void)rotateCube:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:sender.view];
    // only get the horizontal component
    float x = translation.x/sender.view.frame.size.width;
    [transformations rotate:x withMultiplier:5.0f];
}

- (IBAction)doubleTap:(UITapGestureRecognizer *)sender
{
    glesRenderer.isRotating = !glesRenderer.isRotating;
}
@end
