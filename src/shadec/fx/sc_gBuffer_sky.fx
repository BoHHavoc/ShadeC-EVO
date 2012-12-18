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

texture entSkin1;
sampler entSkin1Sampler = sampler_state
{
	Texture = <entSkin1>;
	
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct vsOut
{
	float4 Pos : POSITION;
	float Pos2D : TEXCOORD0;
	half4 Tex : TEXCOORD1;
	half3 Normal : TEXCOORD2;
};

struct vsIn
{
	float4 Pos : POSITION;
	half2 Tex : TEXCOORD0;
	half3 Normal : NORMAL;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	Out.Pos = mul(In.Pos,matWorldViewProj);
	Out.Pos2D = mul(In.Pos,matWorldView).z;
	
	Out.Tex.xy = DoTexture(In.Tex.xy);
	//Out.Tex.zw = In.Shadow;
	Out.Normal = mul(In.Normal.xyz,matWorldView);

	return Out;	
}

struct PixelToFrame
{
    float4 normalsAndDepth : COLOR0;
    half4 albedoAndEmissiveMask : COLOR1;
    float4 materialData : COLOR2;
    //float4 lightmapAnd : COLOR3;
};


PixelToFrame mainPS(vsOut In)
{
	PixelToFrame PSOut = (PixelToFrame)0;
	
	half4 skin1 = tex2D(entSkin1Sampler,In.Tex);
	
	//initial w values
	PSOut.albedoAndEmissiveMask = 0;
	PSOut.normalsAndDepth = 0;
	PSOut.materialData = 0;
	
	//normals
	PSOut.normalsAndDepth.xy = PackNormals( normalize(In.Normal.rgb) ); //normals
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
