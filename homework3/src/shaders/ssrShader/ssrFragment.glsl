#ifdef GL_ES
precision highp float;
#endif

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;


varying mat4 vWorldToScreen;
varying highp vec4 vPosWorld;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  float depth = (vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture2D(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture2D(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture2D(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture2D(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 L = vec3(0.0);
  vec3 kd=GetGBufferDiffuse(uv);
  L=kd/3.14*max(0.0,dot(normalize(wo),GetGBufferNormalWorld(uv)))*uLightRadiance;
  return L;
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 Le = vec3(0.0);
  Le=GetGBufferuShadow(uv)*EvalDiffuse(vec3(0.0,0.0,0.0),uLightDir,uv);
  
  
  return Le;
}

bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  //cube
  float stepsize=0.04;
  //cave
  //float stepsize=0.1;
  
  for(int i=0;i<50;++i)
  {
    ori+=dir*stepsize;
    float depth=GetDepth(ori);
    vec2 uv=GetScreenCoordinate(ori);
    float curdepth=GetGBufferDepth(uv);
    if(uv.x>1.0||uv.x<0.0||uv.y>1.0||uv.y<0.0)
    {
      return false;
    }
    if(depth>curdepth+0.1)
    {
      hitPos=ori;
      return true;
    }
  }
  return false;
}

#define SAMPLE_NUM 50

void main() {
  float s = InitRand(gl_FragCoord.xy);


  vec3 L = vec3(0.0);
  //L = GetGBufferDiffuse(gl_FragCoord.xy);
  //L = GetGBufferDiffuse(GetScreenCoordinate(vPosWorld.xyz));
  L=EvalDirectionalLight(GetScreenCoordinate(vPosWorld.xyz));
  vec3 color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  gl_FragColor = vec4(vec3(color.rgb), 1.0);
  vec3 indcol=vec3(0.0);
  float count=0.0;
  
  
  
  // vec3 hitpos;
  // vec3 normal=GetGBufferNormalWorld(GetScreenCoordinate(vPosWorld.xyz));
  
  // bool hit=RayMarch(vPosWorld.xyz,reflect(vPosWorld.xyz-uCameraPos.xyz,normal),hitpos);
  // if(hit)
  // {
    
  //   gl_FragColor = vec4(GetGBufferDiffuse(GetScreenCoordinate(hitpos)),1.0);
    
    
  // }
  // else
  // {
  //   gl_FragColor = vec4(0.0,0.0,0.0, 1.0);
  // }
    
  vec3 dcol=EvalDirectionalLight(GetScreenCoordinate(vPosWorld.xyz));
  gl_FragColor=vec4(dcol,1.0);
  gl_FragColor=vec4(dcol,1.0);
  for(int i=0;i<SAMPLE_NUM;++i)
  {
    float pdf=0.0;
    vec3 dir=SampleHemisphereUniform(s,pdf);
    
    s+=0.1;
    vec3 hitpos;
    vec3 normal=GetGBufferNormalWorld(GetScreenCoordinate(vPosWorld.xyz));
    vec3 t=vec3(0,0,1);
    vec3 n=cross(normal,t);
    t=cross(normal,n);
    dir=mat3(t,n,normal)*dir;
    
    if(dot(dir,normal)>0.0)
    {
      bool hit=RayMarch(vPosWorld.xyz,dir,hitpos);
      if(hit)
      {
        indcol+=EvalDirectionalLight(GetScreenCoordinate(hitpos))*EvalDiffuse(vec3(0.0,0.0,0.0),dir,GetScreenCoordinate(vPosWorld.xyz))/pdf;
        //indcol+=EvalDiffuse(vec3(0.0,0.0,0.0),dir,GetScreenCoordinate(vPosWorld.xyz));
        //indcol+=EvalDirectionalLight(GetScreenCoordinate(hitpos));
        //gl_FragColor = vec4(GetGBufferDiffuse(GetScreenCoordinate(hitpos)),1.0);
        //gl_FragColor = vec4(GetScreenCoordinate(hitpos),0.0,1.0);
        count+=1.0;
      }
      else
      {
        //gl_FragColor = vec4(0.0,0.0,0.0, 1.0);
      }
      
    }
  }
  L=dcol+indcol/max(1.0,count);
  color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  gl_FragColor = vec4(vec3(color.rgb), 1.0);
  //gl_FragColor=vec4(finalcol,1.0);
  //  float p=count/5.0;


  //gl_FragColor=vec4(p,p,p,1.0);
  //float dep=GetDepth(vPosWorld.xyz)/10.0;
  //float dep=GetGBufferDepth(GetScreenCoordinate(vPosWorld.xyz));
  //gl_FragColor = vec4(dep,dep,dep, 1.0);
}
