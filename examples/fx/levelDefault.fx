//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_ALPHA (skin1.w) //alpha
#define SKIN_NORMAL (skin2.xyz) //normalmap
#define SKIN_GLOSS (skin2.w) //glossmap
#define SKIN_EMISSIVEMASK (skin3.y) //emissive mask
#define SKIN_COLOR (skin3.w) //(team)color mask
//#define SKIN_EMVMAPMASK (skin3.x) //environment mapping mask
//#define SKIN_VELVETYMASK (skin3.z) //velvety lighting mask
//...

//#define MTL_SKIN1 //skin1 is a mtlSkin and not an entSkin?
//#define MTL_SKIN2 //skin2 is a mtlSkin and not an entSkin?
//#define MTL_SKIN3 //skin3 is a mtlSkin and not an entSkin?
//#define MTL_SKIN4 //skin4 is a mtlSkin and not an entSkin?

//#define NORMALMAPPING //do normalmapping?

//#define GLOSSMAP //entity has glossmap?
#define GLOSSSTRENGTH 0 //glossmap channel will be set to this value if GLOSSMAP is not defined

//#define EMISSIVEMASK //use emissive mask? (formula: emissive_color = SKIN_EMISSIVEMASK * SKIN_ALBEDO)
//#define EMISSIVE_A7 // (optional EMISSIVEMASK addon) use emissive_red/green/blue for as emissive color? (formula: emissive_color = SKIN_EMISSIVEMASK * vecEmissive)
//#define EMISSIVE_SHADEC // (optional EMISSIVEMASK addon) OR use SC_OBJECT_EMISSIVE as emissive color? (formula: emissive_color = SKIN_EMISSIVEMASK * SC_OBJECT_EMISSIVE)

//#define OBJECTCOLOR_A7 // use diffuse_red/green/blue as (team)color using the colormask?
//#define OBJECTCOLOR_SHADEC // OR use SC_OBJECT_COLOR as (team)color using the colormask?

//#define ALPHACLIP //do alphatesting/alphacutout?

//#define USE_VEC_DIFFUSE //use diffuse_red/green/blue? (note: don't use with OBJECTCOLOR_A7 at the same time)

//#define ZPREPASS //do an early zbuffer prepass? Only makes sense for heavy ALU




//PERFORMANCE
/*
Normalmapping matrix in VS erstellen und nur ein mul im pixelshader?
 float3x3 worldToTangentSpace;
    worldToTangentSpace[0] = mul(input.Tangent,world);
    worldToTangentSpace[1] = mul(cross(input.Tangent,input.Normal),world);
    worldToTangentSpace[2] = mul(input.Normal,world);
    
...
*/

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

//bool AUTORELOAD;
bool PASS_SOLID;

#include <scPackNormals>
#include <scPackDepth>
//#include <scPackSpecularData>

float4x4 matWorldViewProj;
float4x4 matWorld;
float4x4 matView;
float4x4 matWorldView;
#ifdef NORMALMAPPING
float3x3 matTangent; // hint for the engine to create tangents in TEXCOORD2
#endif

float3 vecDiffuse;

//emissive
#ifdef EMISSIVE_A7
	float3 vecEmissive;
#endif
#ifdef EMISSIVE_SHADEC
	float3 vecEmissive_SHADEC;
#endif

//(team)color
#ifdef OBJECTCOLOR_SHADEC
	float3 vecColor_SHADEC;
#endif

float fPower;
float clipFar;
float alphaClip;
float materialID;

#ifdef MTL_SKIN1
	texture mtlSkin1;
#else
	texture entSkin1;
#endif

#ifdef MTL_SKIN2
	texture mtlSkin2;
#else
	texture entSkin2;
#endif

#ifdef MTL_SKIN3
	texture mtlSkin3;
#else
	texture entSkin3;
#endif

#ifdef MTL_SKIN4
	texture mtlSkin4;
#else
	texture entSkin4;
#endif

sampler2D entSkin1Sampler = sampler_state
{
	#ifdef MTL_SKIN1
		Texture = <mtlSkin1>;
	#else
		Texture = <entSkin1>;
	#endif

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D entSkin2Sampler = sampler_state
{
	#ifdef MTL_SKIN2
		Texture = <mtlSkin2>;
	#else
		Texture = <entSkin2>;
	#endif

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D entSkin3Sampler = sampler_state
{
	#ifdef MTL_SKIN3
		Texture = <mtlSkin3>;
	#else
		Texture = <entSkin3>;
	#endif

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D entSkin4Sampler = sampler_state
{
	#ifdef MTL_SKIN4
		Texture = <mtlSkin4>;
	#else
		Texture = <entSkin4>;
	#endif

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
	float4 Tex : TEXCOORD1;
	float3 Normal : TEXCOORD2;
	#ifdef NORMALMAPPING
		float3 Tangent : TEXCOORD3;
		float3 Binormal : TEXCOORD4;
	#endif
};

struct vsIn
{
	float4 Pos : POSITION;
	half2 Tex : TEXCOORD0;
	half2 Shadow : TEXCOORD1;
	half3 Normal : NORMAL;
	#ifdef NORMALMAPPING
		half4 Tangent: TEXCOORD2;
	#endif
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	/*
	//WIND ANIMATION
	if(vecSkill1.w == 1)
	{
		float3 P = mul(In.Pos, matWorld);
		float force_x = DoDefault(vecSkill41.x*(0.1/50),0.1); 
		float force_y = DoDefault(vecSkill41.y*(0.1/50),0.1);
		float speed = sin((vecTime.w+0.2*(P.x+P.y+P.z)) * DoDefault(vecSkill41.z*(0.05/50),0.05));
		
		if (In.Pos.y > 0 ) // move only upper part of tree
		{
			In.Pos.x += speed * force_x * In.Pos.y;
			In.Pos.z += speed * force_y * In.Pos.y;
			In.Pos.y -= 0.1*abs(speed*(force_x+force_y)) * In.Pos.y;
		}
	}
	*/
	
	Out.Pos = mul(In.Pos,matWorldViewProj);
	Out.Pos2D = mul(In.Pos,matWorldView).z;
	
	Out.Tex.xy = In.Tex;
	//Out.Tex.zw = In.Shadow;
	Out.Normal = mul(In.Normal.xyz,matWorldView);
	#ifdef NORMALMAPPING
		Out.Tangent = mul(In.Tangent.xyz, matWorldView); 
   	Out.Binormal = mul(cross(In.Tangent.xyz, In.Normal.xyz), matWorldView); 
   	//Out.Tangent = normalize(Out.Tangent);
   	//Out.Binormal = normalize(Out.Binormal);
   #endif
   //Out.Normal = normalize(Out.Normal);
		
	return Out;	
}

/*
float4 encode(float fDist)
{
	const float4 bitSh	= float4(   256*256*256, 256*256,   256,         1);
	const float4 bitMsk = float4(   0,      1.0/256.0,    1.0/256.0,    1.0/256.0);

	float4 comp;
	comp	= fDist * bitSh;
	comp	= frac(comp);
	comp	-= comp.xxyz * bitMsk;
	return comp;
}

float4 EncodeFloatRGBA( float v ) {
  float4 enc = float4(1.0, 255.0, 65025.0, 160581375.0) * v;
  enc = frac(enc);
  enc -= enc.yzww * float4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
  return enc;
}
float DecodeFloatRGBA( float4 rgba ) {
  return dot( rgba, float4(1.0, 1/255.0, 1/65025.0, 1/160581375.0) );
}
*/

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
	half4 skin2 = tex2D(entSkin2Sampler,In.Tex);
	half4 skin3 = tex2D(entSkin3Sampler,In.Tex);
	
	//initial w values
	PSOut.albedoAndEmissiveMask.w = 0;
	
	//normals
	#ifdef NORMALMAPPING
		half3 bump = SKIN_NORMAL*2-1;
		In.Normal.rgb += (bump.x * In.Tangent.xyz + bump.y * In.Binormal.xyz);
	#endif
	//PSOut.normalsAndDepth.xy = PackNormals( mul((In.Normal.rgb) ,matView) ); //normals
	PSOut.normalsAndDepth.xy = PackNormals( normalize(In.Normal.rgb) ); //normals
	//depth
	
	PSOut.normalsAndDepth.zw = PackDepth(In.Pos2D/clipFar);
	
	//albedo
	#ifdef USE_VEC_DIFFUSE
		PSOut.albedoAndEmissiveMask.xyz = SKIN_ALBEDO * vecDiffuse;
	#else
		PSOut.albedoAndEmissiveMask.xyz = SKIN_ALBEDO;
	#endif
	//(team)color
	#ifdef OBJECTCOLOR_A7
		PSOut.albedoAndEmissiveMask.xyz += SKIN_COLOR * vecDiffuse;
	#endif
	#ifdef OBJECTCOLOR_SHADEC
		PSOut.albedoAndEmissiveMask.xyz += SKIN_COLOR * vecColor_SHADEC;
	#endif
		
	//alphatest
	#ifdef ALPHACLIP
		clip(SKIN_ALPHA-alphaClip);
	#endif
	
	//emissiveMask
	#ifdef EMISSIVEMASK
		PSOut.albedoAndEmissiveMask.w = SKIN_EMISSIVEMASK;
		#ifdef EMISSIVE_A7
			PSOut.albedoAndEmissiveMask.xyz =  clamp(PSOut.albedoAndEmissiveMask.xyz - PSOut.albedoAndEmissiveMask.w,0,1);
			PSOut.albedoAndEmissiveMask.xyz =  clamp(PSOut.albedoAndEmissiveMask.xyz + (PSOut.albedoAndEmissiveMask.w * vecEmissive.xyz ),0,1);
		#endif
		#ifdef EMISSIVE_SHADEC
			PSOut.albedoAndEmissiveMask.xyz =  clamp(PSOut.albedoAndEmissiveMask.xyz - PSOut.albedoAndEmissiveMask.w,0,1);
			PSOut.albedoAndEmissiveMask.xyz =  clamp(PSOut.albedoAndEmissiveMask.xyz + (PSOut.albedoAndEmissiveMask.w * vecEmissive_SHADEC.xyz ),0,1);
		#endif
	#endif
	
	//material data
	PSOut.materialData.x = materialID; //material ID
	PSOut.materialData.y = fPower/(float)255;//vecSkill17.z; //material Specular Power
	#ifdef GLOSSMAP
		PSOut.materialData.z = SKIN_GLOSS; //material Specular Intensity
	#else
		PSOut.materialData.z = GLOSSSTRENGTH;
	#endif
	PSOut.materialData.w = 0; //environment map ID - not used yet
	
	//Specular
	//Pack Gloss and Power in 8bit
	//PSOut.emissiveAndSpecular.w = PackSpecularData(SKIN_GLOSS,50);
	
	//debugging
	//PSOut.normalsAndDepth.w = 1;
	//PSOut.albedoAndEmissiveMask.w = 1;
	//PSOut.emissiveAndSpecular.w = 1;
	
	return PSOut;
}

technique t1
{
	#ifdef ZPREPASS
	pass zPrePass
	{
		ColorWriteEnable = 0;
		cullmode = ccw;
		zwriteenable = true;	
		alphablendenable = false;
		stencilenable = false;
	}
	#endif
	
	pass p0
	{
		cullmode = ccw;
		#ifndef ZPREPASS
			zwriteenable = true;
		#endif
		alphablendenable = false;
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
		FogEnable = False;
		
		#ifdef ZPREPASS
			ColorWriteEnable = RED | GREEN | BLUE | ALPHA;
			zenable = true;
			zwriteenable = false;
	    	ZFunc = LESSEQUAL;
		#endif
	}
}
