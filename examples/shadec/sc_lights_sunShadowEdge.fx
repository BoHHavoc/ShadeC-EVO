#include <scUnpackDepth>
#include <scCalculatePosVSQuad>
//#include <scGetPssm>

float4x4 matViewInv; //needed for PSSM, TEMP ONLY, remove this from shader!
float4x4 matTex[4]; // set up from the pssm script
float4 vecSkill1; //lightrange (w)
float4 vecSkill5; //clip_far (w)
float4 vecSkill13; // number of pssm splits (x)
int shadowmapSize; //512, 1024, 2048 ...
float shadowBias;
float4 vecViewPort;
float pssm_splitdist_var[5];

texture mtlSkin1; //normals (xy) depth (zw)
sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
	//BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
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

texture sc_map_random4x4_bmap;
sampler randSampler = sampler_state 
{ 
	Texture = <sc_map_random4x4_bmap>; 
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
	//BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};

half4 mainPS(in float2 inTex : TEXCOORD0):COLOR
{
	
	inTex *= 4;
	
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
	shadowTexcoord[2].z -= shadowBias*4;
	shadowTexcoord[3].z -= shadowBias*8;
	
	//half shadow = GetPssm(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);
	
	half2 rand = (tex2D(randSampler, inTex*(vecViewPort.xy*0.0625)).xy - 0.5);// * 8.0f/shadowmapSize;
	half2 blurAmt = (5.0f/shadowmapSize)*rand.xy;
	
	// sample shadow map (ReadDepth defined elsewhere) 
   float4 Depths;
   Depths.x = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(blurAmt.x,blurAmt.y)*0.25).r; 
   Depths.y = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(blurAmt.x,blurAmt.y)*0.5).r; 
   Depths.z = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(blurAmt.x,blurAmt.y)*0.75).r; 
   Depths.w = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(blurAmt.x,blurAmt.y)*1.25).r; 
   //Depths.y = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(0,blurAmt.y)).r; 
   //Depths.z = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(-blurAmt.x,0)).r; 
  	//Depths.w = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(0,-blurAmt.y)).r; 
   //Depths.y = tex2D( shadowDepth1Sampler, shadowTexcoord[0]).r; 
   /*
   Depths.x = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(blurAmt,0)).r; 
   Depths.y = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(0,blurAmt)).r; 
   Depths.z = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(-blurAmt,0)).r; 
   Depths.w = tex2D( shadowDepth1Sampler, shadowTexcoord[0] + half2(0,-blurAmt)).r;
   */
   
   // sum boolean results of the 4 samples 
   float4 Attenuation = step( shadowTexcoord[0].z, Depths ); 
   float fEdge = dot(Attenuation, 0.25);// + Attenuation.z;// + Attenuation.w; 
	/*
	//float fEdge = dot(Depths0,1);
   if( fEdge == 2.0f ) 
	   fEdge = 1.0f; 
	else if( fEdge > 0.0f ) 
		fEdge = 0.5f; 
		*/
	
	//2nd split	
	Depths.x = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,blurAmt.y)*0.25).r; 
   Depths.y = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,blurAmt.y)*0.5).r; 
   Depths.z = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,blurAmt.y)*0.75).r; 
   Depths.w = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,blurAmt.y)*1.25).r; 
	
	//Depths.x = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,blurAmt.y)).r; 
	//Depths.x = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(blurAmt.x,0)).r; 
   //Depths.y = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(0,blurAmt.y)).r; 
   //Depths.z = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(-blurAmt.x,0)).r; 
   //Depths.w = tex2D( shadowDepth2Sampler, shadowTexcoord[1] + half2(0,-blurAmt.y)).r; 
   Attenuation = step( shadowTexcoord[1].z, Depths ); 
   fEdge = lerp( fEdge, dot(Attenuation, 0.25), pow(saturate(posVS.z/pssm_splitdist_var[1]),50) );
   
   //3rd split	
   Depths.x = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,blurAmt.y)*0.5).r; 
   Depths.y = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,blurAmt.y)*0.75).r; 
   Depths.z = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,blurAmt.y)).r; 
   Depths.w = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,blurAmt.y)*2).r; 
   
   //Depths.x = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,blurAmt.y)).r; 
//	Depths.x = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(blurAmt.x,0)).r; 
// Depths.y = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(0,blurAmt.y)).r; 
// Depths.z = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(-blurAmt.x,0)).r; 
// Depths.w = tex2D( shadowDepth3Sampler, shadowTexcoord[2] + half2(0,-blurAmt.y)).r; 
   Attenuation = step( shadowTexcoord[2].z, Depths ); 
   fEdge = lerp( fEdge, dot(Attenuation, 0.25), pow(saturate(posVS.z/pssm_splitdist_var[2]),50) );
   
   //4th split
   Depths.x = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,blurAmt.y)*0.5).r; 
   Depths.y = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,blurAmt.y)).r; 
   Depths.z = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,blurAmt.y)*2).r; 
   Depths.w = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,blurAmt.y)*4).r; 
   
   
   //Depths.x = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,blurAmt.y)).r; 
	//Depths.x = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(blurAmt.x,0)).r; 
   //Depths.y = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(0,blurAmt.y)).r; 
   //Depths.z = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(-blurAmt.x,0)).r; 
   //Depths.w = tex2D( shadowDepth4Sampler, shadowTexcoord[3] + half2(0,-blurAmt.y)).r; 
   Attenuation = step( shadowTexcoord[3].z, Depths ); 
   fEdge = lerp( fEdge, dot(Attenuation, 0.25), pow(saturate(posVS.z/pssm_splitdist_var[3]),50) );
	

	return half4(fEdge,fEdge,fEdge,1);
}

technique sunShadowEdge
{
	pass p0
	{
		PixelShader = compile ps_3_0 mainPS();
		alphablendenable = false;
	}
}