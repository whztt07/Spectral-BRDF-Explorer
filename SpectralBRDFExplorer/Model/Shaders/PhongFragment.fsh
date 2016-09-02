//
//  Fragment shader
//
//  Created by Fabrizio Duroni on 27/05/16.
//  Copyright © 2016 Fabrizio Duroni. All rights reserved.
//

#version 300 es

precision mediump float;

struct material {
    vec4 ka;
    vec4 kd;
    vec4 ks;
    float sh;
};

struct pointLight {
    vec3 position;
    vec4 color;
};

in vec3 normalInterp;
in vec3 vertPos;
in vec2 textureCoordinate;
in vec4 shadowCoord;

out vec4 o_fragColor;

uniform pointLight light;
uniform material surfaceMaterial;
//uniform sampler2D textureSampler;
uniform int textureActive;
uniform lowp sampler2DShadow shadowMapSampler;

float shadow() {
    
    //Shadow calculate using PCF (percentage closer filtering).
    vec4 offset;
    float pixelSize = 1.0/512.0;
    float pixelSizeHomogenous = pixelSize * shadowCoord.w;
    float bias = -0.001 * shadowCoord.w;
    float shadowPercentage = 0.0;
    
    for(float x = -2.0; x <= 2.0; x += 1.0) {
        
        for(float y = -2.0; y <= 2.0; y += 1.0) {
            
            offset = vec4(x * pixelSizeHomogenous, y * pixelSizeHomogenous, bias, 0.0);
            shadowPercentage += textureProj(shadowMapSampler, shadowCoord + offset);
        }
    }
    
    shadowPercentage = shadowPercentage / 16.0;
    
    return shadowPercentage;
}

void main() {

    // 3x3 kernel with 4 taps per sample, effectively 6x6 PCF
    float shadowPercentage = shadow();
    
    //Calculate light direction and view direction.
    vec3 viewPosition = vec3(0.0, 0.0, 1.0);
    vec3 lightDirection = normalize(light.position - vertPos);
    vec3 viewDirection = normalize(viewPosition - vertPos);
    
    //Cosine theta diffuse lambertian component.
    float cosTheta = max(0.0, dot(normalInterp, normalize(lightDirection)));
    
    vec4 ambient = surfaceMaterial.ka * light.color;
    vec4 diffuse = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 specular = vec4(0.0, 0.0, 0.0, 1.0);
    
    if(cosTheta > 0.0) {
        
        //Reflection vector around normal
        vec3 reflectionDirection = reflect(-lightDirection, normalInterp);
        
        if(textureActive == 0) {
            
            //No texture. Standard lighting.
            diffuse = surfaceMaterial.kd * light.color * cosTheta;
        } else {
            
            //Lighting using texture.
            diffuse = surfaceMaterial.kd * cosTheta;
//            diffuse = surfaceMaterial.kd * texture(textureSampler, textureCoordinate) * cosTheta;
        }
        
        specular = surfaceMaterial.ks * light.color * pow(max(0.0, dot(reflectionDirection, normalInterp)), surfaceMaterial.sh);
    }
    
    //o_fragColor = vec4(shadow, 0,0,1);
    o_fragColor = ambient + (diffuse + specular) * shadowPercentage;
}