//
//  Copyright © Borna Noureddin. All rights reserved.
//

#version 300 es
precision highp float;

in vec3 eyeNormal;
in vec4 eyePos;
in vec2 texCoordOut;
out vec4 fragColor;

uniform sampler2D texSampler;

// ### Set up lighting parameters as uniforms

void main()
{
    // ### Calculate phong model using lighting parameters and interpolated values from vertex shader

    // ### Modify this next line to modulate texture with calculated phong shader values
    fragColor = texture(texSampler, texCoordOut);
    fragColor.a = 1.0;
}
