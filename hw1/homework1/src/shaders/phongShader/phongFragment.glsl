#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

// Shadow map related variables
#define NUM_SAMPLES 20
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10

#define LIGHT_SIZE 4.0

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;
uniform sampler2D uShadowMap1;

varying vec4 vPositionFromLight;
varying vec4 vPositionFromLight1;

highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

float unpack(vec4 rgbaDepth) {
    const vec4 bitShift = vec4(1.0, 1.0/256.0, 1.0/(256.0*256.0), 1.0/(256.0*256.0*256.0));
    return dot(rgbaDepth, bitShift);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float findBlocker( sampler2D shadowMap,  vec2 uv, float zReceiver ) {
  float res=0.0;
  float nums=0.0;
  float filtersize=1.0/1000.0*20.0;
  for(int i=0;i<BLOCKER_SEARCH_NUM_SAMPLES;++i)
  {
    float shadowdepth=unpack(texture2D(shadowMap,(uv+poissonDisk[i]*filtersize)));
    if(shadowdepth<zReceiver+EPS)
    {
      res+=shadowdepth;
      nums+=1.0;
    }
  }
	res=res/nums;

  return res;
}

float PCF(sampler2D shadowMap, vec4 coords) {
  float res=0.0;
  float filtersize=1.0/1000.0*20.0;
  uniformDiskSamples(coords.xy);
  for(int i=0;i<NUM_SAMPLES;++i)
  {
    res=res+float(step(-EPS,unpack(texture2D(shadowMap,(coords.xy+poissonDisk[i]*filtersize)))-coords.z));
  }
  res=res/float(NUM_SAMPLES);
  return res;
}
float PCF_PCSS(sampler2D shadowMap, vec4 coords,float shadowsize) {
  float res=0.0;
  //ivec2 size=textureSize(shadowMap,0);
  //float filtersize=1.0/float(size.x)*20.0;
  float filtersize=1.0/1000.0*shadowsize*20.0;
  uniformDiskSamples(coords.xy);
  for(int i=0;i<NUM_SAMPLES;++i)
  {
    res=res+float(step(-EPS,unpack(texture2D(shadowMap,(coords.xy+poissonDisk[i]*filtersize)))-coords.z));
  }
  res=res/float(NUM_SAMPLES);
  return res;
}

float PCSS(sampler2D shadowMap, vec4 coords){
  poissonDiskSamples(coords.xy);
  // STEP 1: avgblocker depth
  float avgdepth=findBlocker(shadowMap,coords.xy,coords.z);
  // STEP 2: penumbra size
  float shadowsize=LIGHT_SIZE*(coords.z-avgdepth)/avgdepth;
  // STEP 3: filtering
  float vis=PCF_PCSS(shadowMap,coords,shadowsize);
  
  return vis;

}


float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){
  return step(-EPS,unpack(texture2D(shadowMap,shadowCoord.xy))-shadowCoord.z);
}

vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = 0.05 * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = max(dot(lightDir, normal), 0.0);
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {

  float visibility,visibility1;
  vec3 curvpos=vPositionFromLight.xyz/vPositionFromLight.w;
  vec3 shadowCoord=curvpos/2.0+0.5;
  vec3 curvpos1=vPositionFromLight1.xyz/vPositionFromLight1.w;
  vec3 shadowCoord1=curvpos1/2.0+0.5;
  //visibility = useShadowMap(uShadowMap, vec4(shadowCoord, 1.0));
  //visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0));
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));
  visibility1 = PCSS(uShadowMap1, vec4(shadowCoord1, 1.0));
  vec3 phongColor = blinnPhong();
  
  gl_FragColor = vec4(phongColor * min(visibility,visibility1), 1.0);
  //gl_FragColor = vec4(phongColor, 1.0);
  //gl_FragColor = vec4(depth,depth,depth,1.0);
  //gl_FragColor = vec4(visibility,visibility,visibility,1.0);
  //gl_FragColor = vec4(vPositionFromLight.z,vPositionFromLight.z,vPositionFromLight.z,1.0);
}