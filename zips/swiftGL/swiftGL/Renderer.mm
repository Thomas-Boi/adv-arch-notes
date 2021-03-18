//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"



//===========================================================================
//  GL uniforms, attributes, etc.

// List of uniform values used in shaders
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_MODELVIEW_MATRIX,
    // ### Add uniforms for lighting parameters here...
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// List of vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE_COORDINATE,
    NUM_ATTRIBUTES
};

#define BUFFER_OFFSET(i) ((char *)NULL + (i))



//===========================================================================
//  Class interface
@interface Renderer () {

    // iOS hooks
    GLKView *theView;

    
    // GL ES variables
    GLESRenderer glesRenderer;
    GLuint _program;
    GLuint crateTexture;
    
    // GLES buffer IDs
    GLuint _vertexArray;
    GLuint _vertexBuffers[3];
    GLuint _indexBuffer;

    // Transformation matrices
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    GLKMatrix4 _modelViewMatrix;
    
    // Lighting parameters
    // ### Add lighting parameter variables here...

    
    // Model
    float *vertices, *normals, *texCoords;
    GLuint *indices, numIndices;

    
    // Misc UI variables
    std::chrono::time_point<std::chrono::steady_clock> lastTime;
}

@end



//===========================================================================
//  Class implementation
@implementation Renderer

// UI properties
@synthesize isRotating;
@synthesize rotAngle, xRot, yRot;


//=======================
// Initial setup of GL using iOS view
//=======================
- (void)setup:(GLKView *)view
{
    // Create GL context
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }

    // Set up context
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    
    // Load in and set up shaders
    if (![self setupShaders])
        return;
    
    // Initialize UI element variables
    rotAngle = 0.0f;
    isRotating = 1;

    // Initialize GL color and other parameters
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}


//=======================
// Load and set up shaders
//=======================
- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    _program = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (_program == 0)
        return false;
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_POSITION, "position");
    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    glBindAttribLocation(_program, ATTRIB_TEXTURE_COORDINATE, "texCoordIn");
    
    // Link shader program
    _program = glesRenderer.LinkProgram(_program);

    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texSampler");
    // ### Add lighting uniform locations here...

    // Set up lighting parameters
    // ### Set default lighting parameter values here...

    return true;
}


//=======================
// Load model(s)
//=======================
- (void)loadModels
{
    // Create VAOs
    glGenVertexArrays(1, &_vertexArray);
    glBindVertexArray(_vertexArray);

    // Create VBOs
    glGenBuffers(NUM_ATTRIBUTES, _vertexBuffers);   // One buffer for each attribute
    glGenBuffers(1, &_indexBuffer);                 // Index buffer

    // Generate vertex attribute values from model
    int numVerts;
    numIndices = glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices, &numVerts);

    // Set up VBOs...
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    // Normal vector
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    // Texture coordinate
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTURE_COORDINATE);
    glVertexAttribPointer(ATTRIB_TEXTURE_COORDINATE, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    
    // Set up index buffer
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*numIndices, indices, GL_STATIC_DRAW);
    
    // Reset VAO
    glBindVertexArray(0);

    // Load texture to apply and set up texture in GL
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
}


//=======================
// Load in and set up texture image (adapted from Ray Wenderlich)
//=======================
- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

//=======================
// Clean up code before deallocating renderer object
//=======================
- (void)dealloc
{
    // Delete GL buffers
    glDeleteBuffers(3, _vertexBuffers);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArrays(1, &_vertexArray);
     
     // Delete vertices buffers
     if (vertices)
         free(vertices);
     if (indices)
         free(indices);
     if (normals)
         free(normals);
     if (texCoords)
         free(texCoords);
     
     // Delete shader program
     if (_program) {
         glDeleteProgram(_program);
         _program = 0;
     }
}


//=======================
// Update each frame
//=======================
- (void)update
{
    // Calculate elapsed time
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;

    // Do UI tasks
    if (isRotating)
    {
        rotAngle += 0.001f * elapsedTime;
        if (rotAngle >= 360.0f)
            rotAngle = 0.0f;
    }

    // Set up base model view matrix (place camera)
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotAngle, 0.0f, 1.0f, 0.0f);
    
    // Set up model view matrix (place model in world)
    _modelViewMatrix = GLKMatrix4Identity;
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, xRot, 1.0f, 0.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, yRot, 0.0f, 1.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, rotAngle, 0.0f, 1.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, _modelViewMatrix);
    
    // Calculate normal matrix
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(_modelViewMatrix), NULL);
    
    // Calculate projection matrix
    float aspect = fabsf(theView.bounds.size.width / theView.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);

    // Calculate model-view-projection matrix
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, _modelViewMatrix);
}


//=======================
// Draw calls for each frame
//=======================
- (void)draw:(CGRect)drawRect;
{
    // Clear window
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Select VAO and shaders
    glBindVertexArray(_vertexArray);
    glUseProgram(_program);
    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    // ### Set values for lighting parameter uniforms here...
    
    // Select VBO and draw
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, 0);
}


@end

