/******************************************************************************************************
Shield-Shader by Wolfgang "BoH_Havoc" Reichardt

Entity Textures:
	Skin1 = Normalmap1
	Skin2 = Normalmap2
	Skin3 = Shield Spark Texture (8 stages)

Usage:
	Uncomment/Comment the #defines to add/remove an effect.
	
******************************************************************************************************/


/***************************************TWEAKABLES*****************************************************/
#include <scUnpackDepth>

bool AUTORELOAD;
float refractStrength = 8;

//Use Colormap (entSkin2) to color the entity
//#define USECOLOR

/***************************************SHADER*CODE****************************************************/

float4x4 matWorldView;
float4x4 matProj;
float4x4 matWorld;

float4 data1; // y= softness, z=, w = spark texture offset
float4 data3; //xyz = color
float clipFar;
float fAlpha;

float4 vecViewPos;
float4 vecViewPort;
float4 vecTime;

texture entSkin1;
texture entSkin2;
texture entSkin3;

sampler colorSampler = sampler_state
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

sampler normalmapSampler = sampler_state
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

sampler normalmap2Sampler = sampler_state
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

void heat_VS( in float4 inPos:POSITION, //input vertex position
					in float2 inTex:TEXCOORD0, //input texcoords
				   out float4 outPos:POSITION, //ouput transformed position
				   out float2 outTex:TEXCOORD0, //output texcoords
				   out float4 outProjectedTex:TEXCOORD1, //output projected texcoords
				   out float4 outWorld:TEXCOORD2 //output world position
				 )
{
	
	outProjectedTex = mul(inPos,matWorldView);
	outPos = mul(outProjectedTex, matProj);
	//save the vertex information for further projected texture coordinate computation
	outProjectedTex.xyw = outPos.xyw;
	//ouput texcoords
	outTex=inTex;
	//output worldPos
	outWorld = mul(inPos,matWorld);
}


float4 heat_PS(in float2 inTex:TEXCOORD0, //input texture coords
					  in float4 inProjectedTex:TEXCOORD1, //projectedTexcoords, needed to perform reflections,refractions
					  in float4 inWorld:TEXCOORD2 //world position, needed for refraction strength
					  ):COLOR0
{
	
	refractStrength /= distance(inWorld.xyz,vecViewPos.xyz)/4;
	
	data1.w *= 0.125;
	
	//inProjectedTex.xy/=inProjectedTex.w;
	//inProjectedTex.xy=inProjectedTex.xy*0.5f*float2(1,-1)+0.5f;
	
	inProjectedTex.x = inProjectedTex.x/inProjectedTex.w/2.0f + 0.5f + (0.5/vecViewPort.x);
   inProjectedTex.y = -inProjectedTex.y/inProjectedTex.w/2.0f + 0.5f + (0.5/vecViewPort.y);
	
	//clip non visible parts
   float texDepth = UnpackDepth(tex2D(normalsAndDepthSampler, inProjectedTex.xy).zw);
	//if(texDepth != 0) clip(texDepth - (inProjectedTex.z/vecSkill5.w));
	//else texDepth = 1;

	//soft intersection
	float difference = saturate( ((texDepth*clipFar)/data1.y) - (inProjectedTex.z)/data1.y );
	
	
	
	
	
	//get refract normals
	float4 pixelNormal= tex2D(normalmap2Sampler,(inTex)-(vecTime.w*0.00025*data1.z));
	pixelNormal.xy += tex2D(normalmap2Sampler,(inTex)+(vecTime.w*0.0005*data1.z)).xy;
	pixelNormal.xyz = normalize(pixelNormal.xyz);
   pixelNormal.xyz=(pixelNormal.xyz-0.5f)*2;
   
   //get refraction
   half4 refraction=tex2D(sceneSampler,(inProjectedTex.xy)-refractStrength*pixelNormal.xz);
 
	half4 color = tex2D(colorSampler, inTex + refractStrength*pixelNormal.xz);
	color.a = tex2D(colorSampler, inTex).a;
	color.a += pow(color.a*(pixelNormal.x+pixelNormal.y),2)*10;
	color.a *= difference*fAlpha;
	color.a = saturate(color.a);
	
	color.rgb *= data3.xyz; //colorize
	color.rgb += refraction*color.rgb;
	
   return color;
};

technique heat
{

	pass p0
	{
		CULLMODE = none;
		zwriteenable = false;
		alphablendenable = TRUE;
		VertexShader  = compile vs_2_0 heat_VS();
		PixelShader = compile ps_2_0 heat_PS();
		
		ZEnable = true;
		ZFunc = LESSEQUAL;	
	}
}