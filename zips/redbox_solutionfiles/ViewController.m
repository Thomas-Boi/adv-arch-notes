//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController() {
    // Renderer is imported in the header file so don't need to reimport here
    Renderer *glesRenderer;
}
@end


@implementation ViewController

- (IBAction)theButton:(id)sender {
    NSLog(@"You pressed the Button!");
}

- (void)viewDidLoad {
    // in obj-c, this is how you 'call a method'
    // in obj-c, this is called 'send a message'
    // so we are sending a message to super's viewDidLoad method == call it
    // see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocObjectsClasses.html#//apple_ref/doc/uid/TP30001163-CH11-SW1
    // note [] only applies to OOP and objects
    // normal function can be called normally
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // ### <<<
    // send a message to Renderer's alloc method (aka call it) then pass the return
    // result into another message call. Now, call the return obj's init method.
    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view]; // send a message to setup method with view as a param
    [glesRenderer loadModels];
    // ### >>>
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)update
{
    [glesRenderer update]; // ###
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [glesRenderer draw:rect]; // ### send message to draw method with rect as param
}


@end
