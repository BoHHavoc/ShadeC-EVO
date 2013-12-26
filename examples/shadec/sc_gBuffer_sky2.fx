//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_ALPHA (skin1.w) //alpha


//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

//bool AUTORELOAD;
bool PASS_SOLID;

#include <scPackNormals>
#include <scPackDepth>
#include <texture>
//#include <scPackSpecularData>

float4x4 matWorldViewProj;
float4x4 matWorld;
float4x4 matView;
float4x4 matWorldView;

float clipFar;
float alphaClip;
float materialID;

texture mtlSkin1;
sampler entSkin1Sampler = sampler_state
{
	Texture = <mtlSkin1>;
	
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct vsOut
{
	float4 Pos: POSITION;
	float3 eye: TEXCOORD1;
};

struct vsIn
{
	float4 Pos : POSITION;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	float4 pos = float4(1 * In.Pos.x, 1 * In.Pos.y, 1 * In.Pos.z, 1);
	float4 pPos = mul(float4(pos.xyz,1), matWorldViewProj);

	Out.Pos = pPos;

	Out.eye.x = 0.5 * (pPos.z + pPos.x);
	Out.eye.y = 0.5 * (pPos.z - pPos.y);
	Out.eye.z = pPos.z * 1;

	return Out;	
}

struct PixelToFrame
{
	float4 normalsAndDepth : COLOR0;
	half4 albedoAndEmissiveMask : COLOR1;
	float4 materialData : COLOR2;
	//float4 lightmapAnd : COLOR3;
	float depth : DEPTH;
};


PixelToFrame mainPS(vsOut In)
{
	PixelToFrame PSOut = (PixelToFrame)0;
	
	float2 mid = In.eye.xy / In.eye.z;
	half4 skin1 = tex2D(entSkin1Sampler,mid);
	
	//initial w values
	PSOut.albedoAndEmissiveMask = 0;
	PSOut.normalsAndDepth = 0;
	PSOut.materialData = 0;
	
	//normals
	//PSOut.normalsAndDepth.xy = PackNormals( normalize(In.Normal.rgb) ); //normals
	PSOut.normalsAndDepth.xy = PackNormals( normalize(float3(1.f,1.f,1.f)) );
	//depth
	PSOut.normalsAndDepth.zw = 1;//PackDepth(In.Pos2D/clipFar);
	
	//color
	PSOut.albedoAndEmissiveMask.xyz = skin1.xyz;	
	//alphablend (sky only!)
	PSOut.albedoAndEmissiveMask.a = skin1.a;

	//material data
	PSOut.materialData.x = 0; //material ID (255)
	PSOut.materialData.y = 0; //material Specular Power
	PSOut.materialData.z = 0;
	PSOut.materialData.w = 0; //environment map ID - not used yet
	
	PSOut.depth = 1;
	
	return PSOut;
}


PixelToFrame blackPS(vsOut In)
{
	PixelToFrame PSOut = (PixelToFrame)0;
	
	//initial values
	PSOut.albedoAndEmissiveMask = 0;
	PSOut.normalsAndDepth = 0;
	PSOut.materialData = 0;
	
	//depth
	PSOut.normalsAndDepth.zw = 1;//PackDepth(In.Pos2D/clipFar);
	
	//material data
	PSOut.materialData.x = 0; //material ID (255)
	PSOut.materialData.y = 0; //vecSkill17.z; //material Specular Power
	PSOut.materialData.z = 0;
	PSOut.materialData.w = 0; //environment map ID - not used yet
	
	PSOut.depth = 1;
	
	return PSOut;
}

technique t1
{
	pass p0
	{
		cullmode = CCW;
		
		
		//SrcBlend = 5;
		//DestBlend = 2;
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
		FogEnable = False;
		
		alphablendenable = true;
		//ColorWriteEnable = RED | GREEN | BLUE;
		
		/*
		//write stencil buffer value
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 100;
		*/
		
		//ZWRITEENABLE = TRUE;
		
		
		
	}
	/*
	pass p1
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 setAlpha();

		
		
		
		//write current pixel, if stencil buffer value from first pass is resident at the current pixel
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 100;
		
		
		//other stuff
		AlphaBlendEnable = true ;
		SEPARATEALPHABLENDENABLE = true;
		SrcBlend = zero ;
		DestBlend = one ;
		SrcBlendAlpha = one ;
		DestBlendAlpha = zero ;
		
		
		alphablendenable = true;
		fogEnable = False;
		
		ZENABLE = TRUE;
		ZFUNC = EQUAL;
		
	}
	*/
	
	
	pass p1
	{
		//ColorWriteEnable = ALPHA;
		AlphaBlendEnable = true ;
		SEPARATEALPHABLENDENABLE = true;
		SrcBlend = zero ;
		DestBlend = one ;
		SrcBlendAlpha = one ;
		DestBlendAlpha = zero ;
		
		
		alphablendenable = true;
		fogEnable = False;
		
		
		
		
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 blackPS();
	}
	
	
}
