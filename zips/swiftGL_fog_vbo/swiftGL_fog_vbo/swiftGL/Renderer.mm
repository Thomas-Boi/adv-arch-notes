//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"


// small struct to hold object-specific information
struct RenderObject
{
    GLuint vao, ibo;    // VAO and index buffer object IDs

    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
};

// macro to hep with GL calls
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// uniform variables for shaders
// these are created in the shaders
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_LIGHT_SPECULAR_POSITION,
    UNIFORM_LIGHT_DIFFUSE_POSITION,
    UNIFORM_LIGHT_DIFFUSE_COMPONENT,
    UNIFORM_LIGHT_SHININESS,
    UNIFORM_LIGHT_SPECULAR_COMPONENT,
    UNIFORM_LIGHT_AMBIENT_COMPONENT,
    UNIFORM_USE_FOG,
    UNIFORM_USE_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    // OpenGL IDs
    GLuint programObject;
    GLuint crateTexture;

    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;

    // render objects
	// two objects
    RenderObject objects[2];

    // moving camera automatically
    float dist, distIncr;
}

@end

@implementation Renderer

@synthesize isRotating;
@synthesize rotAngle;
@synthesize useFog;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    // First cube (centre, textured)
	// init the vao and ibo (index buffer object)
	// vao contains the data to be drawn
	// the ibo determins which order opengl will
	// interpret that data (index of element in vao)
    glGenVertexArrays(1, &objects[0].vao);
    glGenBuffers(1, &objects[0].ibo);

    // get cube data
    objects[0].numIndices = glesRenderer.GenCube(1.0f, &objects[0].vertices, &objects[0].normals, &objects[0].texCoords, &objects[0].indices);

    // set up VBOs (one per attribute)
	// see the vertex attribs enum
    glBindVertexArray(objects[0].vao);
    GLuint vbo[3];
	// create buffer
    glGenBuffers(3, vbo);

    // pass on position data
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
	// pass the vertices into the OpenGL buffer
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[0].vertices, GL_STATIC_DRAW);
	
	// bind these vertices to ATTRIB_POSITION 
    glEnableVertexAttribArray(ATTRIB_POSITION);
	
	// associate the position pointer to the 
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    // pass on normals
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[0].normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    // pass on texture coordinates
    glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
    glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), objects[0].texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[0].ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[0].indices[0]) * objects[0].numIndices, objects[0].indices, GL_STATIC_DRAW);


    // Second cube (to the side, not textured) - repeat above, minus the texture
    glGenVertexArrays(1, &objects[1].vao);
    glGenBuffers(1, &objects[1].ibo);

	// create the vertices, indices etc...
    objects[1].numIndices = glesRenderer.GenCube(1.0f, &objects[1].vertices, &objects[1].normals, NULL, &objects[1].indices);

    glBindVertexArray(objects[1].vao);

	// pass the position to opengl buffers
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[1].vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

	// pass the normals 
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[1].normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

	// no texture => skip it 
	
	// draw
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[1].ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[1].indices[0]) * objects[1].numIndices, objects[1].indices, GL_STATIC_DRAW);

    // deselect the VAOs just to be clean
    glBindVertexArray(0);
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders])
        return;

    // initialize rotation and camera distance
    rotAngle = 0.0f;
    isRotating = 1; // make the cube rotate
    dist = -5.0; // the z-index
    distIncr = 0.05f;

    // texture and fog uniforms
    useFog = 0; // default is off
	
	// load in the texture and associate it with the shader
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
	
	// to have multiple textures, load a new one then call bind texture
	// below
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);


    // set up lighting values
	// color of specular light
	// note that the vector should have values between 0 and 1
	// but colors is usually in 255
    specularComponent = GLKVector4Make(0.8f, 0.1f, 0.1f, 1.0f);
	// where is the light coming from?
	// vector form, this is global position
    specularLightPosition = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
	
    shininess = 1000.0f;
    ambientComponent = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
    objects[0].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    objects[0].diffuseComponent = GLKVector4Make(0.1f, 0.8f, 0.1f, 1.0f);
    objects[1].diffuseLightPosition = GLKVector4Make(-2.0f, 1.0f, 0.0f, 1.0f);
    objects[1].diffuseComponent = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);

    // clear to black background
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    
    // update rotation and camera position
    if (isRotating)
    {
        rotAngle += 0.001f * elapsedTime;
        if (rotAngle >= 360.0f)
            rotAngle = 0.0f;
    }
	
	// flipping code that zoom in and out
    dist += distIncr;
    if ((dist >= -2.0f) || (dist <= -8.0f))
        distIncr = -distIncr;

	// make specular light move with camera (just a little bit behind the camera
	// comment this out to see what happens (it's kinda hard to see)
    specularLightPosition = GLKVector4Make(0.0f, 0.0f, dist+2, 1.0f);   

    
    // perspective projection matrix
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    
    // initialize MVP matrix for both objects to set the "camera"
	// this code puts everything in relation to the camera 
	// here, we are moving everything `dist` in terms of z position
    objects[0].mvp = objects[1].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, dist);
	
	// do rotation here as well. 
	// note 

    // apply transformations to first (textured cube)
	// pass in current mvp that was set above by default and rotate it
	// this is just the model view matrix
    objects[0].mvm = objects[0].mvp = GLKMatrix4Rotate(objects[0].mvp, rotAngle, 1.0, 0.0, 1.0 );
    objects[0].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[0].mvp), NULL);
	
	// now apply the perspective (mvp)
    objects[0].mvp = GLKMatrix4Multiply(perspective, objects[0].mvp);

    // move second cube to the right (along positive-x axis), and apply projection matrix
	// notice how we use GLKTranslate rather than GLKRotate for above
	// this is shifting to the right side 1.5 unit
    objects[1].mvm = objects[1].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 1.5, 0.0, 0.0), objects[1].mvp);
    objects[1].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[1].mvp), NULL);
    objects[1].mvp = GLKMatrix4Multiply(perspective, objects[1].mvp);
}

- (void)draw:(CGRect)drawRect;
{
    // pass on global lighting, fog and texture values
	// pass the uniform to the shader
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_POSITION], 1, specularLightPosition.v);
    glUniform1i(uniforms[UNIFORM_LIGHT_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT], 1, ambientComponent.v);
    glUniform1i(uniforms[UNIFORM_USE_FOG], useFog);

    // set up GL for drawing
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    // for first cube, use texture and object-specific diffuse light, then pass on the object-specific matrices and VAO/IBO
	// we are passing the values to the uniform ID that we got 
	// when we set up the shaders => passing these values to the shaders
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[0].diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[0].diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[0].mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[0].mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[0].normalMatrix.m);
	
	// bind the vertex array to opengl
	// this will pass the VBOs that we created earlier to opengl through
	// the VAO
    glBindVertexArray(objects[0].vao);
	
	// bind the index buffer object
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[0].ibo);
	
	// draw the element, telling opengl to intepret the data as 
	// triangles
    glDrawElements(GL_TRIANGLES, (GLsizei)objects[0].numIndices, GL_UNSIGNED_INT, 0);
    
    // for second cube, turn off texture and use object-specific diffuse light, then pass on the object-specific matrices and VAO/IBO
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 0);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[1].diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[1].diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[1].mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[1].mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[1].normalMatrix.m);
	
	// bind draw the second element
	// since opengl is a state machine, we can draw different objects
	// by binding different VAO and IBOs
    glBindVertexArray(objects[1].vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[1].ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)objects[1].numIndices, GL_UNSIGNED_INT, 0);
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
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(programObject, "modelViewMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    uniforms[UNIFORM_LIGHT_SPECULAR_POSITION] = glGetUniformLocation(programObject, "specularLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION] = glGetUniformLocation(programObject, "diffuseLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT] = glGetUniformLocation(programObject, "diffuseComponent");
    uniforms[UNIFORM_LIGHT_SHININESS] = glGetUniformLocation(programObject, "shininess");
    uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT] = glGetUniformLocation(programObject, "specularComponent");
    uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT] = glGetUniformLocation(programObject, "ambientComponent");
    uniforms[UNIFORM_USE_FOG] = glGetUniformLocation(programObject, "useFog");
    uniforms[UNIFORM_USE_TEXTURE] = glGetUniformLocation(programObject, "useTexture");

    return true;
}


// Load in and set up texture image (adapted from Ray Wenderlich)
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
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

@end

