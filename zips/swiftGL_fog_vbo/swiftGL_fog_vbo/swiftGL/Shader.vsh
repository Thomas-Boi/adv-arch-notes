#version 300 es

// vertex attributes
layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texCoordIn;

// output of vertex shader (these will be interpolated for each call to the fragment shader)
// these variables can be used in the fragment shader
out vec3 eyeNormal;
out vec4 eyePos;
out vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix; // coord in the screen
uniform mat4 modelViewMatrix; // coord in the camera
uniform mat3 normalMatrix;

void main()
{
    // Calculate normal vector in eye coordinates
    eyeNormal = (normalMatrix * normal);
    
    // Calculate vertex position in view coordinates
    eyePos = modelViewMatrix * position;
    
    // Pass through texture coordinate
	// aka do no change
    texCoordOut = texCoordIn;

    // Set gl_Position with transformed vertex position
    gl_Position = modelViewProjectionMatrix * position;
}
