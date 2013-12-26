float4x4 matProj;
float4x4 matProjInv; //needed for viewspace position reconstruction
#include <scUnpackNormals>
#include <scUnpackDepth>
#include <scCalculatePosVSQuad>

static half NOISE_SIZE = 4; //noise filter size
half SAMPLE_KERNEL_SIZE; // number of ssao iterations
float4 SAMPLE_KERNEL[32];
/*float4 SAMPLE_KERNEL[8] =
{
	0.5,0.5,0.5,0,
	1,0,0.5,0,
	0,1,0.5,0,
	0,0,0.5,0,
	
	1,1,0.5,0,
	-1,1,0.5,0,
	1,-1,0.5,0,
	-1,-1,0.5,0
};
*/

float RADIUS = 50;



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
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
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
	Texture = <mtlSkin4>;
	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};

/*
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
*/


float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	inTex.xy *= 2;
	
	//inTex.x += (0.5/vecViewPort.x); //half pixel fix
	//inTex.y += (0.5/vecViewPort.y); //half pixel fix

	float4 gBuffer = tex2D(normalsAndDepthSampler, inTex.xy);
	
	float depth = UnpackDepth(gBuffer.zw);//(tex2D(depthSampler,inTex.xy).x);
	float3 normal = UnpackNormals(gBuffer.xy);
	//normal = mul(half4(normal, 0), matViewInv).xyz;
	
	//if(depth == 0) depth = 1;
	//compute world position
	/*
	float3 viewRay = 0;
	viewRay.x = lerp(vecSkill5.x, vecSkill5.y, inTex.x);
	viewRay.y = lerp(vecSkill5.z, vecSkill5.w, inTex.y);
	viewRay.z = vecSkill9.x;
	float3 vPos = (depth) * (viewRay);
	*/
	float3 vPos = CalculatePosVSQuad(inTex, depth*vecSkill9.x);
	//float3 wPos = mul(float4(vPos,1), matViewInv);
   
   //float2 rand = normalize(tex2D(randSampler, vecViewPort.xy * inTex.xy / (NOISE_SIZE)).xy  * 2.0f - 1.0f);
	
	//change-of-basis matrix calculation	
	float3 rvec = tex2D(randSampler, vecViewPort.xy * inTex.xy / (NOISE_SIZE)).xyz  * 2.0f - 1.0f;
	float3 tangent = normalize(rvec - normal * dot(rvec, normal));
	float3 bitangent = cross(normal, tangent);
	float3x3 tbn = float3x3(tangent, bitangent, normal);
	//   
	
	
	//ssao
	float occlusion = 0.0;
	half3 color = 0;
	for (int i = 0; i < SAMPLE_KERNEL_SIZE; ++i) {
	//	get sample position:
		float3 sample = mul(SAMPLE_KERNEL[i], tbn); //tbn * SAMPLE_KERNEL[i];
		sample = sample * vecSkill1.y + vPos;
		
	//	project sample position:
		float4 offset = float4(sample, 1.0);
		offset = mul(offset, matProj);//PROJECTION_MATRIX * offset;
		offset.xy /= offset.w;
		offset.xy = offset.xy * 0.5 + 0.5;
		
	//	get sample depth:
		offset.y = 1-offset.y;
		float sample_depth = UnpackDepth(tex2D(normalsAndDepthSampler,  offset.xy).zw) * vecSkill9.x; //texture(LINEAR_DEPTH, offset.xy).r;
				
	//	range check & accumulate:
		float range_check = abs(vPos.z - sample_depth) < vecSkill1.y ? 1.0 : 0.0;
		half ao = (sample_depth <= (sample.z-vecSkill1.z) ? 1.0 : 0.0) * range_check;
	
		//colorbleeding
		//half3 sample_color = tex2D(albedoAndEmissiveSampler, offset.xy).xyz;
		//half3 lighting = tex2D(lightingSampler, offset.xy).xyz * 2;
		//color += sample_color * ao * lighting;
		
		//ao
		occlusion += ao;// * (1-lighting);
		
	}  
   //color = rvec * SAMPLE_KERNEL_SIZE;
   occlusion = 1-saturate((occlusion / SAMPLE_KERNEL_SIZE) * vecSkill1.x);
	return half4(color/SAMPLE_KERNEL_SIZE,occlusion);
}



technique ps20
{
	pass p0
	{
		
      //ZWriteEnable = FALSE;
		AlphaBlendEnable = FALSE;
      
		PixelShader = compile ps_3_0 mainPS();
	}
}