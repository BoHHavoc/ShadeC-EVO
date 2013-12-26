#include <scUnpackDepth>
#include <scCalculatePosVSQuad>
#include <scGetPssm>

float4x4 matViewInv; //needed for PSSM, TEMP ONLY, remove this from shader!
float4x4 matTex[4]; // set up from the pssm script
float4 vecSkill1; //lightrange (w)
float4 vecSkill5; //clip_far (w)
float4 vecSkill13; // number of pssm splits (x)
int shadowmapSize; //512, 1024, 2048 ...
float shadowBias;

texture mtlSkin1; //normals (xy) depth (zw)
sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

texture shadowTex1;
texture shadowTex2;
texture shadowTex3;
texture shadowTex4;
			
sampler shadowDepth1Sampler = sampler_state 
{ 
   Texture = <shadowTex1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};
sampler shadowDepth2Sampler = sampler_state 
{ 
  Texture = <shadowTex2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};
sampler shadowDepth3Sampler = sampler_state 
{ 
   Texture = <shadowTex3>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};
sampler shadowDepth4Sampler = sampler_state 
{ 
	Texture = <shadowTex4>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};

texture mtlSkin2;
sampler shadowMaskSampler = sampler_state 
{ 
	Texture = <mtlSkin2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

half4 hardShadowPS(in float2 inTex : TEXCOORD0):COLOR
{
	inTex *= 0.125;
	
	half4 shadow;	
	
	
	//get depth
	half4 gBuffer = tex2D(normalsAndDepthSampler, inTex);
	gBuffer.w = UnpackDepth(gBuffer.zw);
	
	//get view pos
	float3 posVS = CalculatePosVSQuad(inTex, gBuffer.w*vecSkill5.w);
	
	//get world pos
	half4 posWorld = mul(float4(posVS,1), matViewInv);

	//Generate PSSM Projection Coordinates
	half4 shadowTexcoord[4];
	shadowTexcoord[0] = shadowTexcoord[1] = shadowTexcoord[2] = shadowTexcoord[3] = half4(0,0,0,0);
	for(int i=0;i<vecSkill13.x;i++)
		shadowTexcoord[i] = mul(posWorld,matTex[i]);
	
	//shadowBias *= 1;
	shadowTexcoord[0].z -= shadowBias;
	shadowTexcoord[1].z -= shadowBias*2;
	shadowTexcoord[2].z -= shadowBias*3;
	shadowTexcoord[3].z -= shadowBias*4;
	
	//half shadow = GetPssmHard(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);
	shadow = GetPssmHard(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);

	return shadow;
}

half4 softShadowPS(in float2 inTex : TEXCOORD0):COLOR
{
	inTex *= 0.125;
	
	half4 shadow;
	
	//get depth
	half4 gBuffer = tex2D(normalsAndDepthSampler, inTex);
	gBuffer.w = UnpackDepth(gBuffer.zw);
		
	//get view pos
	float3 posVS = CalculatePosVSQuad(inTex, gBuffer.w*vecSkill5.w);
	
	//get world pos
	half4 posWorld = mul(float4(posVS,1), matViewInv);

	//Generate PSSM Projection Coordinates
	half4 shadowTexcoord[4];
	shadowTexcoord[0] = shadowTexcoord[1] = shadowTexcoord[2] = shadowTexcoord[3] = half4(0,0,0,0);
	for(int i=0;i<vecSkill13.x;i++)
		shadowTexcoord[i] = mul(posWorld,matTex[i]);
	
	//shadowBias *= 1;
	shadowTexcoord[0].z -= shadowBias;
	shadowTexcoord[1].z -= shadowBias*2;
	shadowTexcoord[2].z -= shadowBias*3;
	shadowTexcoord[3].z -= shadowBias*4;
	
	shadow = GetPssm(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);
   	
	return shadow;
}

half4 maskStencilPS(float2 inTex : TEXCOORD0):COLOR
{
	clip( tex2D(shadowMaskSampler, inTex*0.125).r - 0.999999999);
	return 0;
}

technique sunShadowEdge
{
	/*
	pass pShadowHard
	{
		PixelShader = compile ps_3_0 hardShadowPS();
		alphablendenable = false;
	}
	*/
	
	pass pMaskStencil
	{
		PixelShader = compile ps_2_0 maskStencilPS();
		ColorWriteEnable = 0;
		
		//Write Stencil
		StencilEnable = true;
      StencilPass = REPLACE;
      StencilRef = 201;
	}
	
	pass pShadowSoft
	{
		ColorWriteEnable = RED | GREEN | BLUE | ALPHA;
		PixelShader = compile ps_3_0 softShadowPS();
		alphablendenable = false;
		//BlendOp = Add;
		//SrcBlend = DestColor;
		//DestBlend = Zero;
		
		// Here we want to process only marked pixels.
      StencilEnable = true;
      StencilPass = KEEP;
      StencilFunc = EQUAL;
      StencilRef = 201;
	}
	
}