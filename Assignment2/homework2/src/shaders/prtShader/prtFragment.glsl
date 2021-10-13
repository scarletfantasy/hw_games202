#ifdef GL_ES
precision mediump float;
#endif
uniform mat3 aPrecomputeLR;
uniform mat3 aPrecomputeLG;
uniform mat3 aPrecomputeLB;
uniform sampler2D uSampler;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp mat3 vsh;

void main() {
     //gl_FragColor = textureCube(skybox, vFragPos);
     float r=dot(aPrecomputeLR[0],vsh[0])+dot(aPrecomputeLR[1],vsh[1])+dot(aPrecomputeLR[2],vsh[2]);
     float g=dot(aPrecomputeLG[0],vsh[0])+dot(aPrecomputeLG[1],vsh[1])+dot(aPrecomputeLG[2],vsh[2]);
     float b=dot(aPrecomputeLB[0],vsh[0])+dot(aPrecomputeLB[1],vsh[1])+dot(aPrecomputeLB[2],vsh[2]);
     //vec3 color = texture2D(uSampler, vTextureCoord).rgb;
     //gl_FragColor = vec4(vTextureCoord,0.0, 1.0);
     gl_FragColor = vec4(r, g, b, 1.0);
}