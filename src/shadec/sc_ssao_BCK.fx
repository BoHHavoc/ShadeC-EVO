#include <scUnpackNormals>
#include <scUnpackDepth>

static int NOISE_SIZE = 4; //noise filter size
static int ITERATIONS = 4; // number of ssao iterations, max 4, was vecSkill1.x

float4x4 matViewInv;

bool AUTORELOAD;

float4 vecSkill1;
float4 vecSkill5; //frustum points
float4 vecSkill9; //x = clip far
//float3 sc_camPosScreenCoords_var;
//static const float SHADOW_EPSILON = 0.0011f;
float4 vecViewPort;


texture mtlSkin1;
sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
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
sampler randSampler = sampler_state
{
	Texture = <mtlSkin1>;
	AddressU = WRAP;
	AddressV = WRAP;
};

float3 getPosition(float2 inUV)
{
	//half2 depthBuffer = tex2D(gBufferSampler, inUV).xw;
	half depth = UnpackDepth(tex2D(normalsAndDepthSampler, inUV).zw);
	//if(depth == 0) depth = 1;
   //depth = 1-depth;
   //compute world position
	half3 viewRay = 0;
	viewRay.x = lerp(vecSkill5.x, vecSkill5.y, inUV.x);
	viewRay.y = lerp(vecSkill5.z, vecSkill5.w, inUV.y);
	viewRay.z = vecSkill9.x;
	float3 vPos = (depth) * (viewRay);
   
	return vPos;
}

half doAmbientOcclusion(in float2 tcoord,in float2 uv, in float3 p, in float3 cnorm)
{
	float3 pos =  getPosition(tcoord + uv);
	float3 diff = pos - p;
 	float3 v = normalize(diff);
	float d = length(diff)*vecSkill1.z;
	//d = pow(d,4);
	//d = normalize(d);
	
	
	//cnorm = lerp(cnorm, decodeNormals(tex2D(gBufferSampler, tcoord + uv).yz), 1);
	
	//v = lerp(1,0, saturate(length(pos)-length(p)-12));
	half ao = max(0.0,dot(cnorm,v)-vecSkill1.w)*(1.0/(1.0+d))*vecSkill1.x;
	//if(length(pos) < length(p)-12) ao = 0;//saturate((length(p)-12)-length(pos));
	//ao = dot(cnorm,v)*(1/(1+d));
	
	//float ao = max(0.0,dot(cnorm,v)-vecSkill1.w)*(1.0/(1.0+d));
	//ao = saturate(ao-(0.15));
	//ao = 1-pow(1-ao,20);
	//ao *= vecSkill1.x/4;
	
	
	
	//float ao = max(0.0,dot(cnorm,v)-vecSkill1.w)*(1.0/(1.0+d));
	//ao = 1-pow(1-saturate(ao),40);
	//ao = 1-pow(1-saturate(saturate(ao)-0.5),2);
	//half3 color = tex2D(colorSampler, tcoord + uv).rgb * ao;
	
	return ao;
}

float ssao2(float3 p, float3 n, float2 rand, float2 tex, float g_sample_rad, float inDepth)
{
	const float2 vec[4] = {float2(1,1), float2(-1,-1),float2(1,-1),float2(-1,1)};
	
	float ao = 0.0f;
	float rad = ((g_sample_rad)/(inDepth));
	rad = max(rad,0.0000012);
	
	//SSAO
	//int ITERATIONS = lerp(vecSkill1.x+2,2, saturate(inDepth/(vecSkill1.y*1400)));//lerp(vecSkill1.x+2.0,1.0,inDepth/(vecSkill1.y*2800));
	//int ITERATIONS = lerp(1,4, 0);//lerp(vecSkill1.x+2.0,1.0,inDepth/(vecSkill1.y*2800));
	for (int j = 0; j < ITERATIONS; j++)
	{
		float2 coord1 = reflect(vec[j],rand)*rad;
		float2 coord2 = float2(coord1.x*0.707 - coord1.y*0.707, coord1.x*0.707 + coord1.y*0.707);
		
		ao += doAmbientOcclusion(tex,coord1*1500.5, p, n);
		ao += doAmbientOcclusion(tex,coord2*2500.35, p, n);
		//ao += doAmbientOcclusion(tex,coord1*3000.40, p, n);
		//ao += doAmbientOcclusion(tex,coord2*3250.43, p, n);

	} 
	ao/=(float)ITERATIONS*4.0;
	
	
	//END
	
	return ao;
}


float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	inTex.xy *= 2;
	
	//vecSkill1.y = 1;
	//vecSkill1.x = 5;
		
	float4 gBuffer = tex2D(normalsAndDepthSampler, inTex.xy);
		
	float depth = UnpackDepth(gBuffer.zw);//(tex2D(depthSampler,inTex.xy).x);
	//if(depth == 0) depth = 1;
	//compute world position
	float3 viewRay = 0;
	viewRay.x = lerp(vecSkill5.x, vecSkill5.y, inTex.x);
	viewRay.y = lerp(vecSkill5.z, vecSkill5.w, inTex.y);
	viewRay.z = vecSkill9.x;
	float3 vPos = (depth) * (viewRay);
	float3 wPos = mul(float4(vPos,1), matViewInv);

   
   
   float2 rand = normalize(tex2D(randSampler, vecViewPort.xy * inTex.xy / (NOISE_SIZE)).xy  * 2.0f - 1.0f);
     
   float3 normal = UnpackNormals(gBuffer.xy);
  
	float depthScale = vPos.z;//(mul(float4(wp,1), matViewProj).z);
	half ssao = ssao2(vPos, normal, rand, inTex, vecSkill1.y * 0.001, depthScale);
  
   half4 result = half4(0,0,0,1-saturate(ssao));//pow(saturate(1-ssao),0.125);//1-pow(ssao*ssao,4);//pow(saturate(ssao)+0.5,2);//pow(saturate(ssao),0.5) * tex2D(colorSampler,inTex).rgb;
  
   
   //if(depth == 0)
   //{
   //	result.xyz = 0;
   //	result.w = 1;
   //}
   
  	//result.xyz = normal;
  	result.xyz = result.a;
	return result;
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