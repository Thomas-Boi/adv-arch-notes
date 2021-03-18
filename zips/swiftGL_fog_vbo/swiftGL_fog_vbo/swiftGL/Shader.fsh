#version 300 es

precision highp float;

// interpolated values from vertex shader
// these values must be defined in the vertex shader
in vec3 eyeNormal;
in vec4 eyePos; // eye == camera coordinate
in vec2 texCoordOut;

// output of fragment shader
// default
out vec4 o_fragColor;

// set up a uniform sampler2D to get texture
uniform sampler2D texSampler;   

// uniforms for lighting parameters
uniform vec4 specularLightPosition;
uniform vec4 diffuseLightPosition;
uniform vec4 diffuseComponent;
uniform float shininess;
uniform vec4 specularComponent;
uniform vec4 ambientComponent;
uniform bool useFog;
uniform bool useTexture; // same shader to shade both cubes

void main()
{
	// apply phong shading
	
    // ambient lighting calculation
	// everything get the color added
    vec4 ambient = ambientComponent;

    // diffuse lighting calculation
	// see slide for details
    vec3 N = normalize(eyeNormal);
    float nDotVP = max(0.0, dot(N, normalize(diffuseLightPosition.xyz)));
    vec4 diffuse = diffuseComponent * nDotVP;
    
    // specular lighting calculation
	// basic for flashlight
	// see the slide to see what E, L, and H are
    vec3 E = normalize(-eyePos.xyz);
    vec3 L = normalize(specularLightPosition.xyz - eyePos.xyz);
    vec3 H = normalize(L+E);
    float Ks = pow(max(dot(N, H), 0.0), shininess);
    vec4 specular = Ks*specularComponent;
    if( dot(L, N) < 0.0 ) {
        // if the dot product is negative, this is a fragment on the other side of the object and hence not affected by the specular light
        specular = vec4(0.0, 0.0, 0.0, 1.0);
    }

	// now we have all the lights
	// add them all to make the output
    // Regular textured simplified Phong
    o_fragColor = ambient + diffuse + specular;
	
	
	// want to use texture?
	// combine the phong shading with the crate texture
    if (useTexture)
        o_fragColor = o_fragColor * texture(texSampler, texCoordOut);

	// use the linear fog function
	// to create a foggy effect
    if (useFog)
    {
        // Fog effect added (linear)
        float fogDist = (gl_FragCoord.z / gl_FragCoord.w);
		
		// the fog color, we can change from white (current)
		// to smt else
        vec4 fogColour = vec4(1.0, 1.0, 1.0, 1.0);
		
		// indicate how foggy the object is 
		// this is set by the value 10. If we switch to 5
		// the obj will be more foggy the further away it is
        float fogFactor = (10.0 - fogDist) / (10.0 - 1.0);
		
		// make sure the fog Factor is between [0, 1]
        fogFactor = clamp(fogFactor, 0.0, 1.0);
        o_fragColor = mix(fogColour, o_fragColor, fogFactor);
    }

	// make sure everything is clear
    o_fragColor.a = 1.0;
}
