//
//  Copyright © Borna Noureddin. All rights reserved.
// this defines the code declared in Renderer.h.
// this is objective-c code but also accepts c++ code
// compare this with ViewController.m, which is obj-c but accepts c code

// include and import are almost the same thing
// see https://stackoverflow.com/questions/439662/what-is-the-difference-between-import-and-include-in-objective-c
#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    NUM_ATTRIBUTES
};

// add to the Renderer interface in Renderer.h
// in c++ ad obj-c, they recommend instance variables
// to be declared and defined in the .mm/.cpp files
// rather than in the header files
@interface Renderer () {
    GLKView *theView; // what Swift will display on the screen
    GLESRenderer glesRenderer; // init an instance of GLESRenderer
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    GLKMatrix4 mvp; // model view projection

    float *vertices; // vertices for the sqaure
    int *indices, numIndices;
}

@end

// define the Renderer defined in Renderer.h
@implementation Renderer

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    numIndices = glesRenderer.GenSquare(1.0f, &vertices, &indices);
}

// :(GLKVIEW *)view == accepts 1 param:  a pointer to a view
// this is obj-c's way to declare params
- (void)setup:(GLKView *)view
{
    // send a message to EAGLContext's method
    // then when the obj returned, send a message to its method initWithAPI.
    // note: [] only applies to object
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders]) // create the shaders
        return;

    // make screen black
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}


// This function is called every time our screen is updated or needs refreshing
- (void)update
{
    
    // These lines are just used to use the system clock to do autorotation
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    
    // Perspective
    // This code builds the model-view-projection matrix using some calls to GLKit's math functions.
    // This matrix will then be applied to each vertex in the shaders.
    // First mvp is set to a translation matrix that represents
    // a translation of 5 units along the negative z axis.
    // This is equivalent to moving the camera 5 units along the positive z axis.
    // This is necessary because the default camear is at the origin pointing
    // toward the negative z axis, which means that anything along the
    // positive z axis (which is half the cube) would be behind the camera and
    // therefore not visible.
    // You can see the consequences of this by changing the last argument in the
    // call to GLKMatrix4Translate() to zero and see what happens.
    // The first argument to GLKMatrix4Translate() tells GLKit to mutiply the
    // identity matrix by the new translation matrix.
    mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);

    // Now we apply a perspective projection matrix to our model-view-projection matrix (mvp).
    // First we calculate the aspect ratio, so it can be preserved.
    // Then we calculate a perspective projection matrix using GLKMatrix4MakePerspective().
    // This creates a perspective projection based on a 60 degree field of view,
    // with a near plan of z=1 and a far plane of z=20. This defines to viewing angle
    // and view volume, as well as the projection plane.
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);

    // Finally, we multiply the perspective projection matrix above with our rotation+translation
    // mvp matrix from above, and this becomes our final matrix to use with all our vertices.
    mvp = GLKMatrix4Multiply(perspective, mvp);
}

// accepts a
// This function is called whenever the screen needs to be redrawn
- (void)draw:(CGRect)drawRect;
{
    // Here we have to tell our shaders to use our mvp matrix calculated in our update() function.
    // In the setupSahders function we used glGetUniformLocation() to get the location
    // of the modelViewProjectionMatrix shader variable from the compiled shaders.
    // Now we use that location (uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX]) to
    // set the value of that shader variable to mvp using the glUniformMatrix4fv() function.
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);

    // This tells OpenGL how to set up the viewport, to clear the screen, and to use the
    // vertex and fragment shaders we set up in setupShaders().
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    // recall vertices and indices are set up in LoadModel
    // Now we have to tell the shaders what our vertices are.
    // We use glVertexAttribPointer() to setup the coordinators of our vertices in
    // a vertex buffer object, and use the glEnableVertexAttribArray() to
    // indicate to OpenGL that we want to enable that VBO (which contains now
    // the coordinators of the vertices of our cube).
    glVertexAttribPointer ( 0, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    
    // Since we are just drawing a solid colour cube, we can use the glVertexAttrib4f()
    // function to set the second vertex attribute (which the shaders will expect
    // to be the colour of each vertex) to be a certain value for all vertices.
    // Here we set the colour to an opaque red (R,G,B,A=1,0,0,1).
    // 1 is the index of the attribs
    glVertexAttrib4f ( 1, 1.0f, 1.0f, 0.0f, 1.0f );
    
    // Now we tell OpenGL to use the VBOs and vertex attributes we set up above to
    // draw the cube.
    // Specifically, we tell it to treat each set of 3 vertices in the buffer as the
    // vertices of a cube, and use the indices C array to specify the order in
    // which to draw the vertices.
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");

    return true;
}

@end

