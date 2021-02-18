//
//  Copyright © Borna Noureddin. All rights reserved.
// This is a header file for .cpp files.
//

// include guard so the code doesn't get duplicated
#ifndef GLESRenderer_hpp
#define GLESRenderer_hpp

#include <stdlib.h>
// include the opengl library
#include <OpenGLES/ES3/gl.h>

// define a class (job of a header file)
// note that this does
class GLESRenderer
{
public:
    char *LoadShaderFile(const char *shaderFileName);
    GLuint LoadShader(GLenum type, const char *shaderSrc);
    GLuint LoadProgram(const char *vertShaderSrc, const char *fragShaderSrc);

    int GenCube(float scale, float **vertices, float **normals,
                float **texCoords, int **indices);
    int GenSquare(float scale, float **vertices, int **indices);

};

#endif /* GLESRenderer_hpp */
