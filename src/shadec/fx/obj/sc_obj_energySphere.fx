/******************************************************************************************************
Energy Sphere Shader by Wolfgang "BoH_Havoc" Reichardt
******************************************************************************************************/


/***************************************TWEAKABLES*****************************************************/
//Refraction Strength
float refractStrength = 0.15;


/***************************************SHADER*CODE****************************************************/
#include <scUnpackDepth>
bool AUTORELOAD;
bool PASS_SOLID;

float4x4 matWorldView;
float4x4 matProj;
float4x4 matViewInv;
float4x4 matWorld;

float fAlpha;
float clipFar;
float4 data1; // y= softness, z=tex movement
float4 data3; // xyz = color
//float4 vecSkill1;
//float4 vecSkill5;
float4 vecTime;
float4 vecViewPort;

texture entSkin1;

sampler normalmapSampler = sampler_state
{
	Texture = <entSkin1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;   
	//MinFilter = POINT;
	//MagFilter = POINT;
	//MipFilter = POINT;   
	AddressU  = wrap;
	AddressV  = wrap;
	
};

texture entSkin2;

sampler colorSampler = sampler_state
{
	Texture = <entSkin2>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;   
	//MinFilter = POINT;
	//MagFilter = POINT;
	//MipFilter = POINT;   
	AddressU  = wrap;
	AddressV  = wrap;
	
};

texture entSkin3;

sampler lightningSampler = sampler_state
{
	Texture = <entSkin3>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;   
	//MinFilter = POINT;
	//MagFilter = POINT;
	//MipFilter = POINT;   
	AddressU  = wrap;
	AddressV  = wrap;
	
};

texture TargetMap;
sampler sceneSampler=sampler_state
{
	texture=<TargetMap>;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
   addressu=MIRROR;
   addressv=MIRROR;
};

texture texNormalsAndDepth;
sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <texNormalsAndDepth>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

void heat_VS( in float4 inPos : POSITION, //input vertex position
					in float2 inTex : TEXCOORD0, //input texcoords
					in float3 inNormal : NORMAL,
				   out float4 outPos : POSITION, //ouput transformed position
				   out float4 outTex : TEXCOORD0, //output texcoords
				   out float4 outProjectedTex : TEXCOORD1, //output projected texcoords
				   out float4 outWPos : TEXCOORD2, //output worldpos
				   out float4 outNormal : TEXCOORD3 //output normal
				   )
{
	
	outProjectedTex = mul(inPos,matWorldView);
	outPos = mul(outProjectedTex, matProj);
	//save the vertex information for further projected texture coordinate computation
	outProjectedTex.xyw = outPos.xyw;
	//ouput texcoords
	outTex.xy=inTex+(vecTime.w*0.001*data1.z);
	
	//Texture Rotation
	float a = radians(data1.z*vecTime.w);
   float ca = cos(a);
   float sa = sin(a);
   float2 off = float2(0.5,0.5);
   float2 nuv = inTex.xy - off;
   float2 ruv = float2(nuv.x*ca-nuv.y*sa,nuv.x*sa+nuv.y*ca);
   nuv = ruv + off;
	outTex.zw=nuv;
	
	outWPos = mul(inPos,matWorld);
	outNormal = mul(inNormal,matWorld);
}


float4 heat_PS(in float4 inTex:TEXCOORD0, //input texture coords
					in float4 inProjectedTex:TEXCOORD1, //projectedTexcoords, needed to perform reflections,refractions
					in float4 inWPos : TEXCOORD2,
					in float3 inNormal : TEXCOORD3
):COLOR0
{
   inProjectedTex.x = inProjectedTex.x/inProjectedTex.w/2.0f + 0.5f + (0.5/vecViewPort.x);
   inProjectedTex.y = -inProjectedTex.y/inProjectedTex.w/2.0f + 0.5f + (0.5/vecViewPort.y);
   
   half texDepth = UnpackDepth(tex2D(normalsAndDepthSampler,inProjectedTex.xy).zw);
   
   //clip non visible parts
   //float texDepth = gBuffer.x+gBuffer.y/255;
	//if(texDepth != 0) clip(texDepth - (inProjectedTex.z/vecSkill5.w));
	//else texDepth = 1;
	
	
	//soft intersection ------------------------------------------------------
	//half difference = saturate( ((texDepth*vecSkill5.w)/vecSkill1.y) - (inProjectedTex.z)/vecSkill1.y );
	float difference = saturate( ((texDepth*clipFar)/data1.y) - (inProjectedTex.z)/data1.y );
	//------------------------------------------------------------------------
   
	half3 pixelNormal=tex2D(normalmapSampler,inTex.xy).xyz;
	pixelNormal.yz=pixelNormal.zy;
   pixelNormal.xyz=(pixelNormal.xyz-0.5f)*2;
   
   half4 refraction=tex2D(sceneSampler,(inProjectedTex.xy)-refractStrength*pixelNormal.xz);
	half4 scene=tex2D(sceneSampler,inProjectedTex.xy);
	
	half4 color = 1;
	
	
	
	half3 Nn = normalize(inNormal);
	half3 Vn = normalize(matViewInv[3].xyz - inWPos.xyz);
	
	half velvBase = saturate(dot(Vn,Nn));
   half velvety1 = 1.5-velvBase;
   half velvety2 = 1.0-velvBase;
 
   //velvety2 = pow(velvety2,2);
   
   half4 alphaNoise = tex2D(colorSampler,inTex.zw-refractStrength*pixelNormal.xz);
   alphaNoise.r = pow(alphaNoise.r,2);
   
   
	color.a = 1;
	color.rgb = lerp(scene,refraction,alphaNoise.r);
	color.rgb -= (alphaNoise.g*velvety1);
	color.rgb += (alphaNoise.r-alphaNoise.g)*data3.xyz;
	//color.rgb += alphaNoise3*(1-velvety2);
	
	
	color.rgb += alphaNoise.b*float3(1,1,1);
	color.rgb = clamp(color.rgb,0,1);
	
	
	color.rgb += alphaNoise.b*data3.xyz*2;
	//color.rgb += alphaNoise.b*float3(1,1,2);
	color.rgb = clamp(color.rgb,0,1);
	
	//lightning
	half4 lightning = tex2D(lightningSampler,(inTex.zw*data1.z)+data1.zz-refractStrength*pixelNormal.xz);
	//float4 lightning = tex2D(lightningSampler,inTex.zw+float2(vecSkill17.x,vecSkill17.x));
	//lightning += tex2D(lightningSampler,(inTex.zw*vecSkill17.x)+float2(vecSkill17.x,vecSkill17.x));
	half4 lightningS = tex2D(lightningSampler,(inTex.zw*data1.z/2)+data1.zz-refractStrength*pixelNormal.xz);
	//lightning.a *= alphaNoise.g;
	lightning.a *= pow(alphaNoise.r,3.5);
	lightning.rgb *= lightning.a;
	//lightningS.a *= pow(1-alphaNoise.r,3.5)*velvety2*(1-velvety1)*(1-velvety2);
	lightningS.a *= (alphaNoise.r - alphaNoise.g);
	lightningS.rgb *= lightningS.a;
	color.rgb += lightning.rgb;
	//
	
	color.a = tex2D(colorSampler,inTex.zw).r*fAlpha*difference*(1-velvety2);


	return color;
};

technique heat
{

	pass p0
	{
		zwriteenable = false;
		alphablendenable = true;
		CULLMODE = CCW;
		VertexShader  = compile vs_2_0 heat_VS();
		PixelShader = compile ps_2_0 heat_PS();
	}
}