float4x4 matProj;
float4x4 matProjInv; //needed for viewspace position reconstruction
#include <scUnpackNormals>
#include <scUnpackDepth>
#include <scCalculatePosVSQuad>
//#include <scNormalsFromPosition>
//#include <scNormalsFromDepth>
#include <scUnpackLighting>

bool AUTORELOAD;

float4 vecSkill1; // x = intensity, y = radius, z = anti self occlusion
//float4 vecSkill5; //frustum points
float4 vecSkill9; //x = clip far
//float3 sc_camPosScreenCoords_var;
//static const float SHADOW_EPSILON = 0.0011f;
float4 vecViewPort;



texture mtlSkin1;
sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

texture mtlSkin3;
sampler lightingSampler = sampler_state 
{ 
   Texture = <mtlSkin3>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};
/*
texture sc_ssao_texSampleMask_bmap;
sampler sampleMaskSampler = sampler_state
{
	Texture = <sc_ssao_texSampleMask_bmap>;
	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};


texture mtlSkin2;
sampler albedoAndEmissiveSampler = sampler_state 
{ 
   Texture = <mtlSkin2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

texture mtlSkin3;
sampler lightingSampler = sampler_state 
{ 
   Texture = <mtlSkin3>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

texture mtlSkin4;
texture sc_map_random2x2_bmap;
sampler randSampler = sampler_state
{
	Texture = <sc_map_random2x2_bmap>;
	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};
*/
/*
//parameters
float SampleRadius <string uiname="Sample Radius";> = 10.1;
float Intensity <string uiname="Intensity";> = 0.46;
//float Scale <string uiname="Scale";> = 0.6;
float Scale <string uiname="Scale";> = 0.001;
float Bias <string uiname="Bias";> = 0.04;
float SelfOcclusion <string uiname="Self Occlusion";> = 0.07;

float doAmbientOcclusion(in float2 tcoord,in float2 uv, in float3 p, in float3 cnorm)
{


  half depth = UnpackDepth(tex2D(normalsAndDepthSampler, tcoord + uv).zw);
  float3 diff = CalculatePosVSQuad(tcoord, depth*vecSkill9.x) - p;
  const float3 v = normalize(diff);
  //return CalculatePosVSQuad(tcoord + uv, depth*vecSkill9.x).y;
  const float  d = length(diff)*Scale;
  return max(0.0-SelfOcclusion,dot(cnorm,v)-Bias)*(1.0/(1.0+d*d))*Intensity;
}
*/


half getRandom(in float2 uv)
{
  return ((frac(uv.x * (vecViewPort.x*0.25))*0.25)+(frac(uv.y*(vecViewPort.y*0.25))*0.5));
}

float compareDepths( in float depth1, in float depth2, in half aorange, in half3 normal )
{
	
	float far = vecSkill9.x;
	float near = 1;
	//float aoCap = 1.0;
	//float aoMultiplier = vecSkill1.x*100;//500.0;
	//float depthTolerance = 0.0000;
	//float SelfOcclusion = 0.0005;
	//float aorange = 30.0;// units in space the AO effect extends to (this gets divided by the camera far range
	//float diff = sqrt(clamp(1.0-(depth1-depth2) / (aorange/(far-near)),0.0,1.0));
	//float ao = min(aoCap,max(0-SelfOcclusion,depth1-depth2-depthTolerance) * aoMultiplier) * diff;
	float diff = sqrt(clamp(1.0-(depth1-depth2) / (aorange/(far-1)),0.0,1.0));
	//return min(1,max(-vecSkill1.z,depth1-depth2) * vecSkill1.x*100) * diff;
	return min(1,max(-vecSkill1.z,depth1-depth2) * 100) * diff;

//	float3 diff = depth2 - depth1;
//	const float3 v = normalize(diff);
//	const float  d = length(diff)*2;
//	return max(0.0,dot(normal,v)-0.04)*(1.0/(1.0+d));
/*
	half Bias = 0.04;
	half SelfOcclusion = 0.1;
	half Scale = 0.6;
	half Intensity = 0.46;
  float3 diff = depth2 - depth1;
  const float3 v = normalize(diff);
  //return CalculatePosVSQuad(tcoord + uv, depth*vecSkill9.x).y;
  const float  d = length(diff)*Scale;
  return max(0.0-SelfOcclusion,dot(normal,v)-Bias)*(1.0/(1.0+d*d))*Intensity;
  */
}

float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	//inTex.x += (0.5/vecViewPort.x); //half pixel fix
	//inTex.y += (0.5/vecViewPort.y); //half pixel fix
	
	inTex.xy *= 2;
	
	

	float4 gBuffer = tex2D(normalsAndDepthSampler, inTex.xy);
	gBuffer.w = UnpackDepth(gBuffer.zw);
	gBuffer.xyz = UnpackNormals(gBuffer.xy);		
	
	half rand = getRandom(inTex); //random noise
	//half4 sampleMask = tex2D(sampleMaskSampler, inTex*vecViewPort.xy/4); //sample mask (needed to fetch correct normal (left, right, top, bottom) )
	
	//extrude texture coordinates along normals
	//this effectively "scales" the objects/projection, just like in a vertexshader where you scale the size of an object by its normals!
	half aoRadius = vecSkill1.y;
	//half3 normal = NormalsFromDepth(gBuffer.w * vecSkill9.x); //returns view space normals...just what we need!
	half3 normal = gBuffer.xyz;
	normal.y = -normal.y;
	//normal = NormalsFromDepth(gBuffer.w * vecSkill9.x);
	//normal.xy = normal.xy * sampleMask.x + normal.yx * sampleMask.y - normal.yx * sampleMask.z - normal.xy * sampleMask.w;
	normal.xyz *= rand;
	
	float2 EN = (normal.xy * aoRadius);
	float2 offset_EN = EN / (gBuffer.w * (vecViewPort.xy*4));
	float2 samp_UV = inTex + offset_EN;
	//
	
	//half lighting = tex2D(lightingSampler, inTex).xyz*2;
	
	half depth2 = UnpackDepth(tex2D(normalsAndDepthSampler, samp_UV).zw);
	half ao = compareDepths(gBuffer.w,depth2, (aoRadius+3)*2, normal);
	
	
	samp_UV = inTex + (((normal.xy + normal.yx)/2 * aoRadius) / (gBuffer.w * (vecViewPort.xy*4)));
	depth2 = UnpackDepth(tex2D(normalsAndDepthSampler, samp_UV).zw);
	ao += compareDepths(gBuffer.w,depth2, (aoRadius+3)*2, normal);
	
	samp_UV = inTex + (((normal.xy - normal.yx)/2 * aoRadius) / (gBuffer.w * (vecViewPort.xy*4)));
	depth2 = UnpackDepth(tex2D(normalsAndDepthSampler, samp_UV).zw);
	ao += compareDepths(gBuffer.w,depth2, (aoRadius+3)*2, normal);
	
	samp_UV = inTex + (((normal.yx)/2 * aoRadius) / (gBuffer.w * (vecViewPort.xy*4)));
	depth2 = UnpackDepth(tex2D(normalsAndDepthSampler, samp_UV).zw);
	ao += compareDepths(gBuffer.w,depth2, (aoRadius+3)*2, normal);
	
	samp_UV = inTex + (((-normal.yx)/2 * aoRadius) / (gBuffer.w * (vecViewPort.xy*4)));
	depth2 = UnpackDepth(tex2D(normalsAndDepthSampler, samp_UV).zw);
	ao += compareDepths(gBuffer.w,depth2, (aoRadius+3)*2, normal);
	
	ao = ((ao/5));
	ao = 1-saturate(ao*(1-saturate(UnpackLighting(tex2D(lightingSampler, inTex)).xyz))*vecSkill1.x);
	//ao = saturate( ao + saturate(UnpackLighting(tex2D(lightingSampler, inTex)).xyz) );
	//ao =  lighting;
	//ao = ao*(1-(tex2D(lightingSampler, inTex).xyz*2));

	return half4(0,0,0,ao);//half4(1-saturate(ao.xxx),1);
}



technique ps20
{
	pass p0
	{
		
      //ZWriteEnable = FALSE;
		AlphaBlendEnable = FALSE;
      
		PixelShader = compile ps_2_a mainPS();
	}
}