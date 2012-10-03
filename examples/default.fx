//////////////////////////////////////////////////////////////////////
// default fx functions for Gamestudio Materials
// (c) jcl/Conitec 2009  Version 1.3
// use: #include <transform>,<sun>, etc.
//////////////////////////////////////////////////////////////////////

#ifdef NIX // prevent that this file is included in C scripts
//////////////////////////////////////////////////////////////////////
// often used shader variables & functions

//////////////////////////////////////////////////////////////////////
//section: define - some common defines //////////////////////////////
#ifndef include_define
#define include_define

//enable: Mirror Fresnel Effect
//help: Water transparency depends on view angle
//id: 1
#define MIRROR_FRESNEL

//enable: Enviroment Fresnel Effect
//help: Water transparency depends on view angle
//id: 11
#define ENVIRO_FRESNEL

//enable: Blinn Shading
//help: Enable for Blinn (better), disable for Phong (faster)
//id: 15
#define BLINN

//enable: Bumpmapping Light Falloff
//help: Enable for light angle modulation at bumpmapped surfaces
//id: 16
#define BUMPFALLOFF

//enable: DX Lighting
//help: Enable for DirectX falloff, disable for 1/r lighting 
//id: 5
//#define DXLIGHTING

struct vertexIn
{
    float4 Pos		: POSITION;
    float4 Ambient: COLOR0;
    float3 Normal:  NORMAL; // expected to be normalized
    float2 Tex1:    TEXCOORD0;
    float2 Tex2:    TEXCOORD1;
    float3 Tangent: TEXCOORD2; // pre-normalized
};
#endif
//////////////////////////////////////////////////////////////////////
//section: transform - calculate vertex position /////////////////////
#ifndef include_transform
#define include_transform

float4x4 matWorldViewProj;
float4 DoTransform(float4 Pos)
{
	return mul(Pos,matWorldViewProj);
}
#endif

//////////////////////////////////////////////////////////////////////
//section: bones - calculate world position with bones transformation
#ifndef include_bones
#define include_bones

float4x3 matBones[72];
int iWeights;

float4 DoBones(float4 Pos,int4 BoneIndices,float4 BoneWeights)
{
	if(iWeights == 0) return Pos;
	float3 OutPos = 0;
	for(int i=0; i<iWeights; i++)
		OutPos += mul(Pos.xzyw,matBones[BoneIndices[i]])*BoneWeights[i];
	return float4(OutPos.xzy,1.0);
}

// only rotation and translation => inv(transpose(matWorld)) == matWorld
float3 DoBones(float3 Normal,int4 BoneIndices,float4 BoneWeights)
{
	if(iWeights == 0) return Normal;
	float3 OutNormal = 0;
	for(int i=0; i<iWeights; i++)
		OutNormal += mul(Normal.xzy,(float3x3)matBones[BoneIndices[i]])*BoneWeights[i];
	return normalize(OutNormal.xzy);
}

#endif

//////////////////////////////////////////////////////////////////////
//section: fog ///////////////////////////////////////////////////////
#ifndef include_fog
#define include_fog
#include <define>

float4 vecFog;
float4 vecViewPos;
#ifndef MATWORLDVIEW
float4x4 matWorldView;
#define MATWORLDVIEW
#endif
#ifndef MATWORLD
float4x4 matWorld;
#define MATWORLD
#endif

#ifdef DXFOG
float DoFog(float4 Pos)
{
	float3 P = mul(Pos,matWorldView).xyz; // convert vector to view space to get it's depth (.z)
   	return saturate((vecFog.y-P.z) * vecFog.z); // apply the linear fog formula
}
#else // distance based fog
float DoFog(float4 Pos)
{
	float3 P = mul(Pos,matWorld).xyz;
	return 1 - (distance(P,vecViewPos.xyz)-vecFog.x) * vecFog.z;
}
#endif
#endif
//////////////////////////////////////////////////////////////////////
//section: pos - transform vertex position to world space ////////////
#ifndef include_pos
#define include_pos

#ifndef MATWORLD
float4x4 matWorld;
#define MATWORLD
#endif
float4 DoPos(float4 Pos)
{
	return (mul(Pos,matWorld));
}
float3 DoPos(float3 Pos)
{
	return (mul(Pos,(float3x3)matWorld));
}
#endif
//////////////////////////////////////////////////////////////////////
//section: view - transform vertex position to view space ////////////
#ifndef include_view
#define include_view

#ifndef MATWORLDVIEW
float4x4 matWorldView;
#define MATWORLDVIEW
#endif
float4 DoView(float4 Pos)
{
	return (mul(Pos,matWorldView));
}
float3 DoView(float3 Pos)
{
	return (mul(Pos,(float3x3)matWorldView));
}
#endif

//////////////////////////////////////////////////////////////////////
//section: normal - transform vertex normal //////////////////////////
#ifndef include_normal
#define include_normal

#ifndef MATWORLD
float4x4 matWorld;
#define MATWORLD
#endif

// only rotation and translation => inv(transpose(matWorld)) == matWorld
float3 DoNormal(float3 inNormal)
{
	return normalize(mul(inNormal,(float3x3)matWorld));
}

// reconstruct a compressed normal
float3 CreateNormal(float2 inNormalXY)
{
	float3 n;
	n.xy = inNormalXY * 2 - 1;
	n.z  = sqrt(1.0 - dot(n.xy, n.xy));
	return n;
}
#endif
//////////////////////////////////////////////////////////////////////
//section: tangent - create tangent matrix ///////////////////////////
#ifndef include_tangent
#define include_tangent

float3x3 matTangent;	// hint for the engine to create tangents in TEXCOORD2

void CreateTangents(float3 inNormal,float3 inTangent)
{
	matTangent[0] = DoPos(inTangent);
	matTangent[1] = DoPos(cross(inTangent,inNormal));	// binormal
	matTangent[2] = DoPos(inNormal);
}

void CreateTangents(float3 inNormal,float4 inTangent)
{
	matTangent[0] = DoPos(inTangent.xyz);
	matTangent[1] = DoPos(cross(inTangent.xyz,inNormal)*inTangent.w);	// binormal with correct handedness
	matTangent[2] = DoPos(inNormal);
}

float3 DoTangent(float3 inVector)
{
	return normalize(mul(matTangent,inVector));
}
#endif

//////////////////////////////////////////////////////////////////////
//section: tangent_view - create view tangent matrix /////////////////
#ifndef include_tangent_view
#define include_tangent_view

float3x3 matTangent;	// hint for the engine to create tangents in TEXCOORD2

void CreateViewTangents(float3 inNormal,float3 inTangent)
{
// create matWorldView Rotation-only matrix
   float3x3 matViewRot;
   matViewRot[0] = matWorldView[0].xyz;
   matViewRot[1] = matWorldView[1].xyz;
   matViewRot[2] = matWorldView[2].xyz;

	matTangent[0] = mul(inTangent,matViewRot);
	matTangent[1] = mul(cross(inTangent,inNormal),matViewRot);	// binormal
	matTangent[2] = mul(inNormal,matViewRot);
}

void CreateViewTangents(float3 inNormal,float4 inTangent)
{
// create matWorldView Rotation-only matrix
   float3x3 matViewRot;
   matViewRot[0] = matWorldView[0].xyz;
   matViewRot[1] = matWorldView[1].xyz;
   matViewRot[2] = matWorldView[2].xyz;

	matTangent[0] = mul(inTangent.xyz,matViewRot);
	matTangent[1] = mul(cross(inTangent.xyz,inNormal)*inTangent.w,matViewRot);	// binormal
	matTangent[2] = mul(inNormal,matViewRot);
}

float3 DoTangent(float3 inVector)
{
	return normalize(mul(matTangent,inVector));
}
#endif

//////////////////////////////////////////////////////////////////////
//section: srctex - set up the source for postprocessing shaders
#ifndef include_srctex
#define include_srctex

float4 vecViewPort;
float4 vecSkill1;
Texture TargetMap;
sampler2D src = sampler_state { texture = <TargetMap>; };

#endif

//////////////////////////////////////////////////////////////////////
//section: texture - use the texture matrix
#ifndef include_texture
#define include_texture
float4x4 matTexture;

float2 DoTexture(float2 Tex)
{
   return mul(float4(Tex.x,Tex.y,1,1),matTexture).xy;
}
#endif

//////////////////////////////////////////////////////////////////////
//section: color - calculate final color from Diffuse, Ambient, Lightmap, etc.
#ifndef include_color
#define include_color
float4 vecLight;
float4 vecColor;
float4 vecAmbient;
float4 vecDiffuse;
float4 vecSpecular;
float4 vecEmissive;
float fPower;

float4 DoAmbient()
{
	return (vecAmbient * vecLight) + float4(vecEmissive.xyz*vecColor.xyz,vecLight.w);	
}

float DoSpecular()
{
	return (vecSpecular.x+vecSpecular.y+vecSpecular.z)*0.333;	
}

float4 DoLightmap(float3 Diffuse,float3 Lightmap,float4 Ambient)
{
   return float4(Diffuse+Lightmap*(Diffuse+Ambient.xyz),Ambient.w);
}

float4 DoColor(float3 Diffuse,float4 Ambient)
{
   return float4(Diffuse,Ambient.w) + Ambient;
}
#endif

//////////////////////////////////////////////////////////////////////
//section: phong - blinn and phong shading ///////////////////////////
#ifndef include_phong
#define include_phong

float DoShine(float3 LightDir,float3 Normal)
{
   return dot(normalize(LightDir),Normal);
}

float3 DoReflect(float3 inLightDir,float3 inNormal)
{
	//return normalize(2 * dot(inNormal, inLightDir) * inNormal - inLightDir);
	return -reflect(inLightDir,inNormal);
}

float3 DoPhong(float3 Diffuse, float fLight, float fHalf)
{
	return Diffuse * (saturate(fLight) * vecDiffuse.xyz + pow(saturate(fHalf),fPower) * vecSpecular.xyz);
}

float3 DoPhong(float3 Diffuse, float fLight, float fHalf, float fSpecular)
{
	return Diffuse * (saturate(fLight) * vecDiffuse.xyz + pow(saturate(fHalf),fPower) * fSpecular * vecSpecular.xyz);
}
#endif

//////////////////////////////////////////////////////////////////////
//section: tangent_vs - tangent creating vertex shader ///////////////
#include <define>
#include <transform>
#include <fog>
#include <pos>
#include <normal>
#include <tangent_view>
#include <view>
#include <lights>
#include <color>

float4x4 matView;

struct tangentOut
{
	float4 Pos: POSITION;
	float  Fog:	FOG;
	float4 Ambient:  COLOR0;
	float3 Diffuse1: COLOR1;
	float4 Tex12: 	  TEXCOORD0;
	float3 PosView:  TEXCOORD1;
	float3 Light1:	  TEXCOORD2;
	float3 Light2:	  TEXCOORD3;
	float3 Diffuse2: TEXCOORD4;	
	float3 Tangent0: TEXCOORD5;
	float3 Tangent1: TEXCOORD6;
	float3 Tangent2: TEXCOORD7;
};

tangentOut tangent_VS(vertexIn In)
{
	tangentOut Out;

	Out.Pos = DoTransform(In.Pos);
	Out.Tex12 = float4(In.Tex1,In.Tex2);
	Out.Fog = DoFog(In.Pos);
	Out.Ambient = DoAmbient();	
	
// vertex position in world view space
  Out.PosView = DoView(In.Pos);
   
// tangent space vectors in world view space
	CreateViewTangents(In.Normal,In.Tangent);
	Out.Tangent0 = matTangent[0];
	Out.Tangent1 = matTangent[1];
	Out.Tangent2 = matTangent[2];

  Out.Light1 = mul(float4(vecLightPos[0].xyz,0),matView); // Light in view space
  Out.Light2 = mul(float4(vecLightPos[1].xyz,0),matView); 
   
  float3 PosWorld = DoPos(In.Pos);
  float3 Normal = DoNormal(In.Normal);
	Out.Diffuse1 = DoLightFactorBump(vecLightPos[0],PosWorld,Normal) * vecLightColor[0].xyz;
	Out.Diffuse2 = DoLightFactorBump(vecLightPos[1],PosWorld,Normal) * vecLightColor[1].xyz;
   
   return Out;
}

//////////////////////////////////////////////////////////////////////
//section: poisson - poisson filter //////////////////////////////////
#ifndef include_poisson
#define include_poisson

float4 vecViewPort; // contains viewport pixel size in zw components

static const int num_poisson_taps = 12;
static const float2 fTaps_Poisson[num_poisson_taps] = 
{
	{-.326,-.406},
	{-.840,-.074},
	{-.696, .457},
	{-.203, .621},
	{ .962,-.195},
	{ .473,-.480},
	{ .519, .767},
	{ .185,-.893},
	{ .507, .064},
	{ .896, .412},
	{-.322,-.933},
	{-.792,-.598}
};

float4 DoPoisson(sampler smp,float2 tex,float fDist)
{
   float4 Color = 0.;
   for (int i=0; i < num_poisson_taps; i++)
     Color += tex2D(smp,tex + vecViewPort.zw*fDist*fTaps_Poisson[i]);
   return Color/num_poisson_taps;
}

#endif

//////////////////////////////////////////////////////////////////////
//section: box - box filter //////////////////////////////////
#ifndef include_box
#define include_box

float4 vecViewPort; // contains viewport pixel size in zw components

#define NUM_BOX_TAPS 4
static const float2 fTaps_Box[NUM_BOX_TAPS] = {
	{-1.f,-1.f},
	{ 1.f,-1.f},
	{-1.f, 1.f},
	{ 1.f, 1.f},
};

float4 DoBox2x2(sampler smp,float2 tex,float fDist)
{
   float4 Color = 0.;
   for (int i=0; i < NUM_BOX_TAPS; i++)
     Color += tex2D(smp,tex + vecViewPort.zw*fDist*fTaps_Box[i]);
   return Color * (1.f/NUM_BOX_TAPS);
}

#endif

//////////////////////////////////////////////////////////////////////
//section: gauss - gauss filter //////////////////////////////////
#ifndef include_gauss
#define include_gauss

float4 vecViewPort; // contains viewport pixel size in zw components

#define NUM_GAUSS_TAPS 13
static const float fWeights_Gauss[NUM_GAUSS_TAPS] =
{
	0.002216,
	0.008764,
	0.026995,
	0.064759,
	0.120985,
	0.176033,
	0.199471,
	0.176033,
	0.120985,
	0.064759,
	0.026995,
	0.008764,
	0.002216,
};

float4 DoGauss(sampler smp,float2 tex,float2 fDist)
{
   float4 Color = 0.;
   for (int i=0; i < NUM_GAUSS_TAPS; i++)
     Color += fWeights_Gauss[i]*tex2D(smp,tex + vecViewPort.zw*fDist*(i-(NUM_GAUSS_TAPS/2)));
   return Color;
}

#endif




//////////////////////////////////////////////////////////////////////
//                 SHADE-C
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
//section: scPackNormals - packs normalized view space normals to 2x8bit //
#ifndef include_scPackNormals
#define include_scPackNormals

	half2 PackNormals(half3 n)
	{
		
		//argb r12f
		//half2 enc = normalize(n.xy) * (sqrt(-n.z*0.5+0.5));
	   //enc = enc*0.5+0.5;
	   //return enc;
		
		//argb8
		//return normalize(n.xyz).xy*0.5+0.5;
		//return normalize(n.xyz).xy*0.5+0.5;
		
		//Lambert Azimuthal
		//half f = sqrt(8*n.z + 8);
		//return n.xy / f + 0.5;
		
		
		
//		//spheremap
//		float f = -n.z*2+1;
//		float g = dot(n,n);
//		float p = sqrt(g+f);
//		float2 enc = n/p * 0.5 + 0.5;
//		return enc;
		
		//spheremap (optimized)
		half3 fgp;
		fgp.x = -n.z*2+1;
		fgp.y = dot(n,n);
		fgp.z = sqrt(dot(fgp.xy,1));
		fgp.xy = n/fgp.z * 0.5 + 0.5;
		return fgp.xy;
		
		
		/*
		//float2 enc = normalize(n.xy) * sqrt(n.z*0.5f + 0.5f);
		float2 enc = (n.xy) * sqrt(n.z*0.5f + 0.5f);
	   enc = enc*0.5 + 0.5f;
	   return enc;
	   */
		
		
		/*
		//best fit normals
		//just normalize for decode ... ?
		n = normalize(n);
		half3 vNormalUns = abs(n);
		half maxNAbs = max(vNormalUns.z, max(vNormalUns.x, vNormalUns.y) );
		float2 vTexCoord = vNormalUns.z<maxNAbs?(vNormalUns.y<maxNAbs?vNormalUns.yz:vNormalUns.xz):vNormalUns.xy;
		vTexCoord = vTexCoord.x < vTexCoord.y ? vTexCoord.yx : vTexCoord.xy;
		vTexCoord.y /= vTexCoord.x;
		n.rgb /= maxNAbs;
		float fFittingScale = tex2D(normalEncodeSampler, vTexCoord).a;
		n *= fFittingScale;
		n = n*0.5+0.5;
		*/
	}
	
#endif

//////////////////////////////////////////////////////////////////////
//section: scUnpackNormals - unpacks normals //
#ifndef include_scUnpackNormals
#define include_scUnpackNormals

	half3 UnpackNormals(half2 enc)
	{
		
		/*
		//r12f
	   half4 nn = half4(enc,0,0)*half4(2,2,0,0) + half4(-1,-1,1,-1);
	   half l = dot(nn.xyz,-nn.xyw);
	   nn.z = l;
	   nn.xy *= sqrt(l);
	   return nn.xyz * 2 + half3(0,0,-1);
	   */ 
	   
	   
	   //argb8
	   //half3 n;
		//n.xy=enc.xy*2-1;
		//n.z=-sqrt(1-dot(n.xy,n.xy));
		//return n;
		
		/*
		//spheremap
		float3 n;
		n.xy = -enc*enc+enc;
		n.z = -1;
		float f = dot(n, float3(1,1,0.25));
		float m = sqrt(f);
		n.xy = (enc*8-4) * m;
		n.z = 1 - 8*f;
		return n;
		*/

		//spheremap (optimized)
		half3 n;
		n.xy = -enc*enc+enc;
		n.z = -1;
		half2 fm;
		fm.x = dot(n, half3(1,1,0.25));
		fm.y = sqrt(fm.x);
		n.xy = (enc*8-4) * fm.y;
		n.z = 1 - 8*fm.x;
		return n;
		

		
		/*
		//Lambert Azimuthal
		half2 fenc = enc*4-2;
		half f = dot(fenc,fenc);
		half g = sqrt(1-f/4);
		half3 n;
		n.xy = fenc*g;
		n.z = 1-f/2;
		return n;
		*/
	}
	
#endif

//////////////////////////////////////////////////////////////////////
//section: scNormalsFromPosition - creates flat normals from position//
#ifndef include_scNormalsFromPosition
#define include_scNormalsFromPosition

	//#include <scUnpackDepth>
	//#include <scCalculatePosVSQuad>
	//half3 NormalsFromPosition(half2 inTex, half2 screenSize, sampler depthSampler)
	half3 NormalsFromPosition(half3 inPos)
	{
		//float3 p1 = tex2D(g_buffer_pos, uv+float2(1.0/g_screen_size.x*0.25,0)).xyz;
		//float3 p2 = tex2D(g_buffer_pos, uv+float2(0,1.0/g_screen_size.y*0.25)).xyz;
		//float3 p = CalculatePosVSQuad(inTex, UnpackDepth(tex2D(depthSampler, inTex).zw));
		//float3 dx = p1-p;
		//float3 dy = p2-p;
		//return normalize(cross( dx , dy  ));  
	
		return normalize(cross(ddx(inPos.xyz),ddy(inPos.xyz)));
	}
	
#endif

//////////////////////////////////////////////////////////////////////
//section: scNormalsFromDepth - creates flat normals from linear depth//
#ifndef include_scNormalsFromDepth
#define include_scNormalsFromDepth
	half3 NormalsFromDepth(float inDepth)
	{
		//return normalize(float3(ddx(inDepth) * 5000.0, ddy(inDepth) * 5000.0, 1.0));// * 0.5 + 0.5;
		//return normalize(float3(ddx(inDepth) * clipFar, ddy(inDepth) * clipFar, 1.0));// * 0.5 + 0.5;
		return normalize(float3(ddx(inDepth), ddy(inDepth), 1.0));// * 0.5 + 0.5;
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scPackDepth - packs linear depth to 2x8bit //
#ifndef include_scPackDepth
#define include_scPackDepth

	//const float4 bitSh	= float4(   256*256*256, 256*256,   256,         1);
	//const float4 bitMsk = float4(   0,      1.0/256.0,    1.0/256.0,    1.0/256.0);

	float2 PackDepth(float inDepth)
	{
		
//		half2 enc;
//		enc.x = floor(inDepth*255)/255;
//		enc.y = floor((inDepth-enc.x)*255*255)/255;
//		return enc;
		
		//optimized
		//half2 enc;
		//enc.x = floor(inDepth*255)/255;
		//enc.y = floor((inDepth-enc.x)*65025)/255;
		//return enc;
		
		
		//return half2( floor(inDepth * 255.f)/255.f, frac(inDepth * 255.f) );
		//inDepth = 1-inDepth;
		inDepth *= 255.f;
		return half2( floor(inDepth)/255.f, frac(inDepth) );
		//return half2( floor(inDepth * 65536.f)/65536.f, frac(inDepth * 65536.f) );
		
	}
	
#endif

//////////////////////////////////////////////////////////////////////
//section: scUnpackDepth - unpacks depth //
#ifndef include_scUnpackDepth
#define include_scUnpackDepth
	
	//static float4 extract = { 1.0, 0.00390625, 0.0000152587890625, 0.000000059604644775390625 };
	//const float4 bitShifts = float4(1.0/(256.0*256.0*256.0), 1.0/(256.0*256.0), 1.0/256.0, 1);

	float UnpackDepth(float2 enc)
	{
		//return enc.x + (enc.y/255);
		
		//optimized
		enc.y /= 255.f;
		return dot(enc,1);
		
		//return dot(enc,extract.xy);
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scRGBtoLogLUV - RGB to LUV //
#ifndef include_scRGBtoLogLUV
#define include_scRGBtoLogLUV
	// M matrix, for encoding
	const static float3x3 M = float3x3(
	    0.2209, 0.3390, 0.4184,
	    0.1138, 0.6780, 0.7319,
	    0.0102, 0.1130, 0.2969);

	float4 RGBtoLogLUV(in float3 vRGB) 
	{		 
	    float4 vResult; 
	    float3 Xp_Y_XYZp = mul(vRGB, M);
	    Xp_Y_XYZp = max(Xp_Y_XYZp, float3(1e-6, 1e-6, 1e-6));
	    vResult.xy = Xp_Y_XYZp.xy / Xp_Y_XYZp.z;
	    float Le = 2 * log2(Xp_Y_XYZp.y) + 127;
	    vResult.w = frac(Le);
	    vResult.z = (Le - (floor(vResult.w*255.0f))/255.0f)/255.0f;
	    return vResult;
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scLogLUVtoRGB - LUV to RGB //
#ifndef include_scLogLUVtoRGB
#define include_scLogLUVtoRGB
	// Inverse M matrix, for decoding
	const static float3x3 InverseM = float3x3(
		6.0013,	-2.700,	-1.7995,
		-1.332,	3.1029,	-5.7720,
		.3007,	-1.088,	5.6268);	
	
	float3 LogLUVtoRGB(in float4 vLogLuv)
	{	
		float Le = vLogLuv.z * 255 + vLogLuv.w;
		float3 Xp_Y_XYZp;
		Xp_Y_XYZp.y = exp2((Le - 127) / 2);
		Xp_Y_XYZp.z = Xp_Y_XYZp.y / vLogLuv.y;
		Xp_Y_XYZp.x = vLogLuv.x * Xp_Y_XYZp.z;
		float3 vRGB = mul(Xp_Y_XYZp, InverseM);
		return max(vRGB, 0);
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scPackLighting - packs lighting (diffuse + specular)
#ifndef include_scPackLighting
#define include_scPackLighting
	float4 PackLighting(in float3 vRGB, in float Specular) 
	{	
		//return float4(vRGB, Specular);
		//return float4(vRGB*0.5, Specular);
		return float4(exp2(-vRGB), exp2(-Specular*length(vRGB)));//Specular);
	    
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scUnpackLighting - unpacks lighting (diffuse + specular)
#ifndef include_scUnpackLighting
#define include_scUnpackLighting
	float4 UnpackLighting(in float4 inPackage) 
	{
		//return inPackage;
		//return float4(inPackage.xyz*2, inPackage.w);
		//return float4(-log2(inPackage.xyz), -log2(inPackage.w));
		float4 output;
		output.xyz = -log2(inPackage.xyz);
		output.w = (-log2(inPackage.w))/length(output.xyz);
		return output;
		
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scPackSpecularData - packs specular data //
#ifndef include_scPackSpecularData
#define include_scPackSpecularData
	
	half PackSpecularData(half gloss, half power)
	{
		
		//float n_s = (0.43 + sqrt(0.1849 + 3.44*power)) * 1.1627907;
      //float integer_part = floor(n_s + 0.5);
      //float float_part = frac(gloss * 0.5);
      //return ((integer_part + float_part) * 0.03125);
      
      //optimized
      half3 ns_integerpart_floatpart;
      ns_integerpart_floatpart.x = 0.43;//(0.43 + sqrt(0.1849 + 3.44*power)) * 1.1627907;
      ns_integerpart_floatpart.y = 0.1849;
      ns_integerpart_floatpart.z = 3.44*power;
      ns_integerpart_floatpart.y = sqrt(dot(ns_integerpart_floatpart.yz,1));
      ns_integerpart_floatpart.x = dot(ns_integerpart_floatpart.xy,1) * 1.1627907;
      
      ns_integerpart_floatpart.y = floor(ns_integerpart_floatpart.x + 0.5);
      ns_integerpart_floatpart.z = frac(gloss * 0.5);
      return (dot(ns_integerpart_floatpart.yz,1) * 0.03125);
      //
      
      /*
      gloss *= 255;
      power /= 255;
      float n_s = (0.43 + sqrt(0.1849 + 3.44*gloss)) * 1.1627907;
      float integer_part = floor(n_s + 0.5);
      float float_part = frac(power * 0.5);
      return ((integer_part + float_part) * 0.03125);
      */
      
		/*
		float integer_part = clamp( (floor(power*0.5)/256)+0.5, 0.5, 1)*255;
		float float_part = clamp(frac(gloss * 0.5), 0, 0.5)*255;
		return (float_part + integer_part)/255;//(integer_part + float_part)/255;
		*/
		
		/*
		power /= 255;
		return (gloss*0.5) + ((power*0.5)+0.5);
		*/
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scUnpackSpecularData - unpacks depth //
#ifndef include_scUnpackSpecularData
#define include_scUnpackSpecularData
	half2 UnpackSpecularData(half data)
	{
		
		
		
		//float scaleBackValue = data * 32.0 + 0.004;
		//float integer_part = floor(scaleBackValue);
      //float float_part = frac(scaleBackValue);
  
      //float spcPower = (integer_part*integer_part*0.43 - integer_part*0.43) * 0.5;
      //float spcScale = float_part * 2.0;
      
      //return half2(spcScale,spcPower);
      
      //optimized
      half3 scaleBackValue_integerpart_floatpart;
      scaleBackValue_integerpart_floatpart.x = 32.0;
      scaleBackValue_integerpart_floatpart.y = 0.004;
      scaleBackValue_integerpart_floatpart.x = data * dot(scaleBackValue_integerpart_floatpart.xy,1);
		scaleBackValue_integerpart_floatpart.y = floor(scaleBackValue_integerpart_floatpart.x);
      scaleBackValue_integerpart_floatpart.z = frac(scaleBackValue_integerpart_floatpart.x);
  
      half2 spcScale_Power;// = (pow(scaleBackValue_integerpart_floatpart.y,2)*0.43 - scaleBackValue_integerpart_floatpart.y*0.43) * 0.5;
      spcScale_Power.x = (pow(scaleBackValue_integerpart_floatpart.y,2)*0.43 - scaleBackValue_integerpart_floatpart.y*0.43) * 0.5;
      spcScale_Power.y = scaleBackValue_integerpart_floatpart.z * 2.0;
      
      return spcScale_Power;
      //
      
      
      /*
		float scaleBackValue = data * 32.0 + 0.004;
      float integer_part = floor(scaleBackValue);
      float float_part = frac(scaleBackValue);
  
      float spcPower = (integer_part*integer_part*0.43 - integer_part*0.43) * 0.5;
      float spcScale = float_part * 2.0;
      
      return half2(spcPower/255,spcScale*255);
      */
      
     /*
      float gloss = clamp(data-0.5, 0, 0.5);
      gloss = pow(gloss*2, 2);
      float power = (clamp(data, 0.5, 1) -0.5)*2;
      return half2(gloss, power*255);
      */
      
      /*
      float gloss = clamp(data-0.5, 0, 0.5);
      gloss = pow(gloss*2, 2);
      float power = clamp(data, 0.5, 1)-0.5;
      power = pow(power*2, 2);
      return half2(gloss, power*255);
      */
	} 
#endif

//////////////////////////////////////////////////////////////////////
//section: scTriplanarProjection - returns tri planar mapping //
#ifndef include_scTriplanarProjection
#define include_scTriplanarProjection
	//float4 TriplanarProjection(sampler inTexSampler, float3 inPos, float3 inNormal, float inScale)
	half4 TriplanarProjection(sampler2D inSampler, float3 inPos, half3 inNormal, half inScale, half inBlendSmoothnes)
	{
		half4 col = 0;
		
		inPos /= inScale;
		half4 col_z = tex2D(inSampler,inPos.xy);
		half4 col_y = tex2D(inSampler,inPos.xz);	
		half4 col_x = tex2D(inSampler,inPos.yz);	
		
		half3 BlendF=pow(abs(inNormal), inBlendSmoothnes);//inBlendSmoothnes);   
      BlendF /= dot(BlendF.xyz,1.f);
      
		col = col_x * BlendF.x
				+ col_y * BlendF.y
				+ col_z * BlendF.z;
		
		return col;
		
		
		/*
		float4 col = 0;
		
		inPos /= inScale;
		float4 col_y = tex2D(inSampler,inPos.xz);
		float4 col_x = tex2D(inSampler,inPos.yz);
		float4 col_z = tex2D(inSampler,inPos.xy);
		
		//Blendweights
		//float3 BlendF=pow(abs(inNormal), inBlendSmoothnes);//inBlendSmoothnes);   
      //BlendF /= dot(BlendF.xyz,1.f);
      float3 blend_weights = abs( inNormal.xyz );   // Tighten up the blending zone:
		blend_weights = (blend_weights - 0.2) * 7;
		blend_weights = max(blend_weights, 0);      // Force weights to sum to 1.0 (very important!)
		blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z ).xxx; 
      
      
		col = col_x * blend_weights.x
				+ col_y * blend_weights.y
				+ col_z * blend_weights.z;
		
		return col;
		*/
		
		/*
		// Calculate blending weights
		float3 BlendWeights = abs(inNormal);
		BlendWeights = (BlendWeights - 0.2f) * 7;
		BlendWeights = max(BlendWeights, 0);
		BlendWeights /= (BlendWeights.x + BlendWeights.y + BlendWeights.z);
		
		// Triplanar sample coords
		float2 coord1 = float2(inPos.z, -inPos.y) / inScale; // ZY: Left and Right
		float2 coord2 = float2(inPos.x, -inPos.z) / inScale; // XZ: Top and Bottom
		float2 coord3 = float2(inPos.x, -inPos.y) / inScale; // XY: Front and Back
		
		float3 flip = sign(inNormal);
		coord1.x *= flip.x;
		coord2.x *= flip.y;
		coord3.x *= -flip.z;
		
		//color
		float4 col1 = tex2D(inSampler, coord1);
		float4 col2 = tex2D(inSampler, coord2);
		float4 col3 = tex2D(inSampler, coord3);
		
		col = col1 * BlendWeights.x +
				col2 * BlendWeights.y +
				col3 * BlendWeights.z;
		*/
		
		/*
		float3 ds=sign(inNormal);
        
      float2 Tex1=inPos.zy*float2(ds.x,-1.f);
      float2 Tex2=inPos.xz*float2(1.f,-ds.y);
      float2 Tex3=inPos.xy*float2(-ds.z,-1.f);
      Tex1 /= inScale;
      Tex2 /= inScale;
      Tex3 /= inScale;
      
      float3 BlendF=pow(abs(inNormal), 60.f);   
      BlendF/=dot(BlendF.xyz,1.f);
      
      float3 NM1=tex2D(inSampler,Tex1.xy)*2.f-1.f;
      float3 NM2=tex2D(inSampler,Tex2.xy)*2.f-1.f;
      float3 NM3=tex2D(inSampler,Tex3.xy)*2.f-1.f;
        
      NM1=float3(0,-NM1.y,NM1.x*ds.x);
      NM2=float3(NM2.x,0,-NM2.y*ds.y);
      NM3=float3(-NM3.x*ds.z,-NM3.y,0);
        
      //return normalize(Normal+(NM1*BlendF.x + NM2*BlendF.y + NM3*BlendF.z));
      return normalize((NM1*BlendF.x + NM2*BlendF.y + NM3*BlendF.z));
		*/
		
		//return col;
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scTriplanarProjectionNM - returns tri planar mapping //
#ifndef include_scTriplanarProjectionNM
#define include_scTriplanarProjectionNM
	half3 TriplanarProjectionNM(sampler2D inSampler, float3 inPos, half3 inNormal, half inScale)
	{
		half3 outNormal = 0;
		inNormal = normalize(inNormal);
		
		inPos /= inScale;
		half2 bumpFetch1 = tex2D(inSampler,inPos.yz).xy*2-1; //X
		half2 bumpFetch2 = tex2D(inSampler,inPos.zx).xy*2-1; //Y
		half2 bumpFetch3 = tex2D(inSampler,inPos.xy).xy*2-1; //Z
		
		//Blendweights
		//float3 BlendF=pow(abs(inNormal), inBlendSmoothnes);//inBlendSmoothnes);   
      //BlendF /= dot(BlendF.xyz,1.f);
      half3 blend_weights = abs( inNormal.xyz );   // Tighten up the blending zone:
		blend_weights = (blend_weights - 0.2) * 7;
		blend_weights = max(blend_weights, 0);      // Force weights to sum to 1.0 (very important!)
		blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z ).xxx;
		
		//oversimplified tangent basis
		half3 bump1 = half3(0, bumpFetch1.x, bumpFetch1.y);
 		half3 bump2 = half3(bumpFetch2.y, 0, bumpFetch2.x);
 		half3 bump3 = half3(bumpFetch3.x, bumpFetch3.y, 0);
      
      
		outNormal = bump1 * blend_weights.x
				+ bump2 * blend_weights.y
				+ bump3 * blend_weights.z;
		
		return (inNormal + outNormal);
		
		//return col;
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scCalculatePosVSQuad - returns the viewspace position for a screenspace quad. Needs screenspace texcoords and linear depth * clip_far //
#ifndef include_scCalculatePosVSQuad
#define include_scCalculatePosVSQuad

	#ifndef MATPROJINV
	#define MATPROJINV
		float4x4 matProjInv;
	#endif
	float3 CalculatePosVSQuad(float2 inTex, float inDepth)
	{
		float4 viewRay;
		viewRay.x = lerp(-1, 1, inTex.x);
		viewRay.y = lerp(1, -1, inTex.y);
		viewRay.z = 1;
		viewRay.w = 1;
			
		viewRay.xyz = mul(viewRay, matProjInv).xyz;
		return (viewRay.xyz * inDepth);
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scGetShadow - Calculate Shadows. Needs projective texcoords and original light->receiver depth//
#ifndef include_scGetShadow
#define include_scGetShadow
	#include <scUnpackDepth>
	
	/*
	float g_MinVariance = 0.0001;
	
	float linstep(float min, float max, float v)  
	{  
	  return clamp((v - min) / (max - min), 0, 1);  
	}  
	float ReduceLightBleeding(float p_max, float Amount)  
	{  
	  // Remove the [0, Amount] tail and linearly rescale (Amount, 1].  
	   return linstep(Amount, 1, p_max);  
	}
	*/
	
	//static half2 shadow_blurSize_softness = half2(0.0025, 0.015);
	//static half2 shadow_blurSize_softness = half2(0.0075, 0.02);
	static half2 shadow_softness = 0.075;
	half GetShadow(sampler2D shadowSampler, float2 inTex, half inDepth, half maxDepth)
	{
		
		
		//fix shadow bias
	   //inDepth -= (1/maxDepth);
	   //inDepth -= 0.001;
		
		/*
		shadow_blurSize_softness.x = 0.0003125;
		shadow_blurSize_softness.y = 0.95;
		inTex += ((tex2D(shadowRandomSampler, inTex*2048).xy-0.5)*2)*0.001;	
		half shadow = 0;
		shadow += saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
		shadow += saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex +float2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
		shadow += saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex +float2(-shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
		shadow += saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex +float2(shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
		shadow += saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex +float2(-shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
		shadow /= 5;
		return shadow;
		*/
		
		/*
		float depth = UnpackDepth(tex2D(shadowSampler, inTex).xy);
		half shadow =  (depth > inDepth) ? 	1 : 0;
		depth = UnpackDepth(tex2D(shadowSampler, inTex +float2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
		shadow +=  (depth > inDepth) ? 	1 : 0;
		depth = UnpackDepth(tex2D(shadowSampler, inTex +float2(shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
		shadow +=  (depth > inDepth) ? 	1 : 0;
		depth = UnpackDepth(tex2D(shadowSampler, inTex +float2(-shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
		shadow +=  (depth > inDepth) ? 	1 : 0;
		depth = UnpackDepth(tex2D(shadowSampler, inTex +float2(-shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
		shadow +=  (depth > inDepth) ? 	1 : 0;
		shadow /= 5;
		return shadow;
		*/
		
		
		
		
		/*
		half4 shadowDepth[2];
	   shadowDepth[0].x = UnpackDepth(tex2D(shadowSampler, inTex + float2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth[0].y = UnpackDepth(tex2D(shadowSampler, inTex + float2(-shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth[0].z = UnpackDepth(tex2D(shadowSampler, inTex + float2(shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   shadowDepth[0].w = UnpackDepth(tex2D(shadowSampler, inTex + float2(-shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   
	   shadowDepth[1].x = UnpackDepth(tex2D(shadowSampler, inTex + float2(shadow_blurSize_softness.x,0) ).xy);
	   shadowDepth[1].y = UnpackDepth(tex2D(shadowSampler, inTex + float2(-shadow_blurSize_softness.x,0) ).xy);
	   shadowDepth[1].z = UnpackDepth(tex2D(shadowSampler, inTex + float2(0,shadow_blurSize_softness.x) ).xy);
	   shadowDepth[1].w = UnpackDepth(tex2D(shadowSampler, inTex + float2(0,-shadow_blurSize_softness.x) ).xy);
	   //shadowDepth = (shadowDepth > inDepth) ? 	1 : 0;
	   
	   //kinda works....
	   shadowDepth[0] = saturate( exp( (shadowDepth[0]-inDepth)*shadow_blurSize_softness.y * maxDepth) );
	   shadowDepth[1] = saturate( exp( (shadowDepth[1]-inDepth)*shadow_blurSize_softness.y * maxDepth) );
	   return (dot(shadowDepth[0],1) + dot(shadowDepth[1],1)) * 0.125;	   
	   //
	   */
	   
	   
	   //half lerpFactor = saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*maxDepth) );
	   //lerpFactor = saturate( (UnpackDepth(tex2D(shadowSampler, inTex).xy) - inDepth)*10000 );
	   //return sqrt(ShadowContribution(shadowSampler, inTex, inDepth));
	   
	   /*
	   shadowDepth.x = UnpackDepth(tex2D(shadowSampler, inTex).xy);
	   float temp = (shadowDepth.x-inDepth);
	   temp *= (temp)*30;
	   //temp = saturate(pow(1-temp,300));
	   //inDepth *= 1200;
	   //shadowDepth.x *= 1200;
	   //temp *= (inDepth - shadowDepth.x);
	   return temp;
	   */
	   
	   /*
	   //ESM
	   float occluder= UnpackDepth(tex2D(shadowSampler, inTex).xy)-0.05f;
		float overdark =30.05f;
		float    lit = exp(overdark* (occluder - inDepth));
		lit = saturate(lit);
	   return lit;
	   */
	   
	   
	   /*
	   //create filter taps
	   half4 shadowDepth;
	   shadowDepth.x = UnpackDepth(tex2D(shadowSampler, inTex + half2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);// + float2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth.y = UnpackDepth(tex2D(shadowSampler, inTex + half2(-shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth.z = UnpackDepth(tex2D(shadowSampler, inTex + half2(shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   shadowDepth.w = UnpackDepth(tex2D(shadowSampler, inTex + half2(-shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   //half falloff = saturate((inDepth-min(min(shadowDepth.x,shadowDepth.y), min(shadowDepth.z,shadowDepth.w)) )*5);
	   half falloff = saturate((inDepth-min(min(shadowDepth.x,shadowDepth.y), min(shadowDepth.z,shadowDepth.w)) )* (6*(maxDepth*0.001)) );
	   //shadowDepth = 1-saturate( (shadowDepth-inDepth) * shadow_blurSize_softness.y * maxDepth ); //cullmode of depthmap: CW
	   //shadowDepth = saturate( ( (inDepth-shadowDepth)*shadow_blurSize_softness.y * maxDepth)  //cullmode of depthmap: CCW
	   //					* max(1 , saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) ) *5 )   );
	   shadowDepth = saturate( ( (inDepth-shadowDepth)*shadow_blurSize_softness.y * maxDepth) );  //cullmode of depthmap: CCW
	   					//* max(1 , saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) ) *6 )   );
	   
	   //create filter
	   half filter = shadowDepth.x*shadowDepth.y*shadowDepth.z*shadowDepth.w; //cullmode of depthmap: CCW
	   
	   //create softshadow
	   shadowDepth.x = saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-(inDepth-0.0012))*shadow_blurSize_softness.y * maxDepth) );
	   
	   
	   //finalize filter
	   filter *= shadowDepth.x;
	   filter = max(filter, 1-falloff);
	      
	   //return ReduceLightBleeding( shadowDepth.x, filter );
	   //return smoothstep(filter, 1, shadowDepth.x);
	      
	   //create shadow mask to get rid of surface acne
	   shadowDepth.w = saturate((1-shadowDepth.x)*17);
	   shadowDepth.w =  1-pow(shadowDepth.w,14);
	   
	   //final shadow
	   //return max(smoothstep( 1-pow(1-filter,2), 1, shadowDepth.x ),shadowDepth.w);
	   //return smoothstep( filter, 1, shadowDepth.x );
	   return max(smoothstep( filter, 1, shadowDepth.x ),shadowDepth.w);
	   */
	   
	   //inDepth -=  0.00025;
	   half shadowDepth = tex2D(shadowSampler, inTex).x;//UnpackDepth(tex2D(shadowSampler, inTex).xy);
	   return saturate( exp( (exp(shadowDepth)-exp(inDepth))*shadow_softness * maxDepth) );
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scGetPssm - calculates PSSM shadows //
#ifndef include_scGetPssm
#define include_scGetPssm

	//#include <scGetShadow>
	float pssm_splitdist_var[5];
	//float pssm_numsplits_var = 3;
	//static half2 shadow_blurSize_softness = half2(0.0025, 0.025);
	static half shadow_softness = 0.025;
	//static half2 shadow_blurSize_softness = half2(0.00125, 0.01);
	
	/*
	float linstep(float min, float max, float v)  
	{  
	  return clamp((v - min) / (max - min), 0, 1);  
	}  
	float ReduceLightBleeding(float p_max, float Amount)  
	{  
	  // Remove the [0, Amount] tail and linearly rescale (Amount, 1].  
	   return linstep(Amount, 1, p_max);  
	}
	*/
	
	half GetPssm(half4 shadowTexcoord[4], half fDistance, half maxDepth, half numberOfSplits, sampler sDepth1, sampler sDepth2, sampler sDepth3, sampler sDepth4)
	{
		/*
		half fShadow = 0;
		if(fDistance < pssm_splitdist_var[1] || pssm_numsplits_var < 2)
		{
			//fShadow = (tex2Dlod(sDepth1, half4(shadowTexcoord[0].xy,0,0) ).r + pssm_fbias_flt  < shadowTexcoord[0].z) ? 0.0f: 1.0f;
			shadowTexcoord[0].z = exp(2*shadowTexcoord[0].z);
	 		fShadow = saturate( exp( (exp(2*tex2Dlod(sDepth1, half4(shadowTexcoord[0].xy,0,0) ).r)-(shadowTexcoord[0].z))*shadow_blurSize_softness.y * maxDepth) );
	 		//fShadow *= 1-saturate(fDistance/pssm_splitdist_var[1]);
 		}
		else if(fDistance < pssm_splitdist_var[2] || pssm_numsplits_var < 3)
		{
			//fShadow = (tex2Dlod(sDepth2, half4(shadowTexcoord[1].xy,0,0) ).r + 2*pssm_fbias_flt  < shadowTexcoord[1].z) ? 0.0f: 1.0f;
			shadowTexcoord[1].z = exp(2*shadowTexcoord[1].z);
	 		fShadow = saturate( exp( (exp(2*tex2Dlod(sDepth2, half4(shadowTexcoord[1].xy,0,0) ).r)-(shadowTexcoord[1].z))*shadow_blurSize_softness.y * maxDepth) );
		}
		else if(fDistance < pssm_splitdist_var[3] || pssm_numsplits_var < 4)
		{
	 		//fShadow = (tex2Dlod(sDepth3, half4(shadowTexcoord[2].xy,0,0) ).r + 4*pssm_fbias_flt  < shadowTexcoord[2].z) ? 0.0f: 1.0f;
	 		shadowTexcoord[2].z = exp(2*shadowTexcoord[2].z);
	 		fShadow = saturate( exp( (exp(2*tex2Dlod(sDepth3, half4(shadowTexcoord[2].xy,0,0) ).r)-(shadowTexcoord[2].z))*shadow_blurSize_softness.y * maxDepth) );
 		}
		else
		{
	 		//fShadow = (tex2Dlod(sDepth4, half4(shadowTexcoord[3].xy,0,0) ).r + 8*pssm_fbias_flt  < shadowTexcoord[3].z) ? 0.0f: 1.0f;
	 		fShadow = saturate( exp( (tex2Dlod(sDepth4, half4(shadowTexcoord[3].xy,0,0) ).r-(shadowTexcoord[3].z)) * shadow_blurSize_softness.y * 16 * maxDepth) );
 		}
	 		//fShadow = saturate(((fDistance+pssm_splitdist_var[1])/pssm_splitdist_var[2]));
	 		//fShadow = saturate(fDistance/pssm_splitdist_var[2]) * saturate(fDistance/pssm_splitdist_var[1]);
	 	*/
	 	
	 	
	 	
	 	
	 	//optimize this!!!
	 	/*
	 	half4 shadows = 0;
	 	shadowTexcoord[0].z = exp(2*shadowTexcoord[0].z);
	 	shadows.x = saturate( exp( (exp(2*tex2D(sDepth1, shadowTexcoord[0].xy ).r)-(shadowTexcoord[0].z))*shadow_softness * maxDepth) );
	 	shadowTexcoord[1].z = exp(2*shadowTexcoord[1].z);
	 	shadows.y = saturate( exp( (exp(2*tex2D(sDepth2, shadowTexcoord[1].xy ).r)-(shadowTexcoord[1].z))*shadow_softness * maxDepth) );
	 	shadowTexcoord[2].z = exp(2*shadowTexcoord[2].z);
	 	shadows.z = saturate( exp( (exp(2*tex2D(sDepth3, shadowTexcoord[2].xy ).r)-(shadowTexcoord[2].z))*shadow_softness * maxDepth) );
	 	shadowTexcoord[3].z = exp(2*shadowTexcoord[3].z);
	 	shadows.w = saturate( exp( (exp(2*tex2D(sDepth4, shadowTexcoord[3].xy ).r)-(shadowTexcoord[3].z))*shadow_softness * maxDepth) );
	 	*/
	 	
	 	//optimized
	 	half4 shadows, realDepth;
	 	//half4 realDepth;  //= half4(shadowTexcoord[0].z, shadowTexcoord[1].z, shadowTexcoord[2].z, shadowTexcoord[3].z);
	 	realDepth.x = shadowTexcoord[0].z;
	 	realDepth.y = shadowTexcoord[1].z;
	 	realDepth.z = shadowTexcoord[2].z;
	 	realDepth.w = shadowTexcoord[3].z;
	 	realDepth -=  0.00025;
	 	shadows.x = tex2D(sDepth1, shadowTexcoord[0].xy ).r;
	 	shadows.y = tex2D(sDepth2, shadowTexcoord[1].xy ).r;
	 	shadows.z = tex2D(sDepth3, shadowTexcoord[2].xy ).r;
	 	shadows.w = tex2D(sDepth4, shadowTexcoord[3].xy ).r;
	 	shadows = saturate( exp( (exp(2*shadows)-exp(2*realDepth))*shadow_softness * maxDepth) );
	 	//
	 	
	 	half fShadow;
	 	fShadow = lerp( shadows.x, shadows.y, pow(saturate(fDistance/pssm_splitdist_var[1]),10) );
	 	fShadow = lerp( fShadow, shadows.z, pow(saturate(fDistance/pssm_splitdist_var[2]),10) );
	 	fShadow = lerp( fShadow, shadows.w, pow(saturate(fDistance/pssm_splitdist_var[3]),10) );
	 	//fShadow = lerp( fShadow, 1, pow(saturate((fDistance/pssm_splitdist_var[numberOfSplits])*1.5),20) );
	 	 	
	 	return fShadow;
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scLights - contains all needed stuff to compute deferred lighting  //
#ifndef include_scLights
#define include_scLights
	
	#ifdef SPOT
		#ifndef PROJECTION
			#define PROJECTION
		#endif
	#endif
	
	#ifndef SUN
		bool PASS_SOLID;
	#endif
	
	float4x4 matView;
	#ifndef SUN
		float4x4 matWorldView;
		float4x4 matProj;
	#endif
	#ifdef PROJECTION
		float4x4 matMtl; //LightMatrix (Cookie, Shadows)
		#ifdef POINT
			float4x4 matViewInv;
		#endif
	#endif
	
	#include <scUnpackNormals>
	#include <scUnpackDepth>
	#include <scPackLighting>
	
	#ifdef SUN
		#include <scCalculatePosVSQuad>
	#endif
	#ifdef SHADOW //((SUN) && (SHADOW))
		#ifdef SUN
			float4x4 matViewInv; //needed for PSSM, TEMP ONLY, remove this from shader!
			float4x4 matTex[4]; // set up from the pssm script
			#include <scGetPssm>
		#endif
		#ifdef SPOT
			#include <scGetShadow>
		#endif
	#endif
	
	
	float4 vecSkill1; //lightpos (xyz), lightrange (w)
	float4 vecSkill5; //light color (xyz), scene depth (w)
	float4 vecSkill9; //light dir (xyz), stencil ref (w)
	#ifdef SHADOW //((SUN) && (SHADOW))
		#ifdef SUN
			float4 vecSkill13; // number of pssm splits (x)
		#endif
	#endif
	#ifdef SUN
		float sun_light_var;
	#endif
	//float4 frustumPoints;
	
	#ifndef VECVIEWDIR
	#define VECVIEWDIR
		float4 vecViewDir;
	#endif
	#ifndef SUN
		#ifndef VECVIEWPORT
		#define VECVIEWPORT
			float4 vecViewPort;
		#endif
	#endif
	
	texture mtlSkin1; //normals (xy) depth (zw)
	#ifdef PROJECTION
		texture mtlSkin2; //projection map
		#ifdef SHADOW
			texture mtlSkin3; //shadow depthmap
		#endif
	#endif
	texture mtlSkin4; //material id (x), specular power (y), specular intensity (z), environment map id (w)
	texture texBRDFLut; //brdf equations stored in volumetric texture
	texture texMaterialLUT; //material data texture -> x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
	
	#ifdef PROJECTION
		sampler projSampler = sampler_state 
		{ 
		   Texture = <mtlSkin2>; 
		   MinFilter = LINEAR;
			MagFilter = LINEAR;
			MipFilter = LINEAR;
			AddressU = Border;
			AddressV = Border;
			//BorderColor = 0xFFFFFFFF;
			BorderColor = 0x00000000;
		};
	#endif
	
	sampler normalsAndDepthSampler = sampler_state 
	{ 
	   Texture = <mtlSkin1>; 
	   MinFilter = NONE;
		MagFilter = NONE;
		MipFilter = NONE;
		AddressU = Border;
		AddressV = Border;
		//BorderColor = 0xFFFFFFFF;
		BorderColor = 0x00000000;
	};
	
	sampler materialDataSampler = sampler_state 
	{ 
	   Texture = <mtlSkin4>; 
	   MinFilter = NONE;
		MagFilter = NONE;
		MipFilter = NONE;
		AddressU = Border;
		AddressV = Border;
		//BorderColor = 0xFFFFFFFF;
		BorderColor = 0x00000000;
	};
	
	#ifdef SHADOW //((SUN) && (SHADOW))
		#ifdef SUN
			texture shadowTex1;
			texture shadowTex2;
			texture shadowTex3;
			texture shadowTex4;
			
			sampler shadowDepth1Sampler = sampler_state 
			{ 
			   Texture = <shadowTex1>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = LINEAR;
				AddressU = Border;
				AddressV = Border;
				//BorderColor = 0xFFFFFFFF;
				BorderColor = 0x00000000;
			};
			sampler shadowDepth2Sampler = sampler_state 
			{ 
			   Texture = <shadowTex2>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = LINEAR;
				AddressU = Border;
				AddressV = Border;
				//BorderColor = 0xFFFFFFFF;
				BorderColor = 0x00000000;
			};
			sampler shadowDepth3Sampler = sampler_state 
			{ 
			   Texture = <shadowTex3>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = LINEAR;
				AddressU = Border;
				AddressV = Border;
				//BorderColor = 0xFFFFFFFF;
				BorderColor = 0x00000000;
			};
			sampler shadowDepth4Sampler = sampler_state 
			{ 
			   Texture = <shadowTex4>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = LINEAR;
				AddressU = Border;
				AddressV = Border;
				//BorderColor = 0xFFFFFFFF;
				BorderColor = 0x00000000;
			};
		#endif
		
		#ifdef SPOT
			sampler2D shadowSampler = sampler_state 
			{ 
			   Texture = <mtlSkin3>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = LINEAR;
				AddressU = Border;
				AddressV = Border;
				//BorderColor = 0xFFFFFFFF;
				BorderColor = 0x00000000;
			};
		#endif
	#endif
	
	sampler1D materialLUTSampler = sampler_state 
	{ 
	   Texture = <texMaterialLUT>; 
	   AddressU = CLAMP; 
	   AddressV = CLAMP;
		MinFilter = NONE;
		MagFilter = NONE;
		MipFilter = NONE;
	};
	
	sampler3D brdfLUTSampler = sampler_state 
	{
		Texture = <texBRDFLut>;
	   AddressU = CLAMP; 
		AddressV = CLAMP;
		//AddressU = Border;
		//AddressV = Border;
		//BorderColor = 0xFFFFFFFF;
		//BorderColor = 0x00000000;
		//AddressW = WRAP;
		AddressW = CLAMP;
		MIPFILTER = NONE;
		MINFILTER = LINEAR; //fade between brdfs
		MAGFILTER = LINEAR; //fade between brdfs
		//MINFILTER = NONE; // dont fade between brdfs
		//MAGFILTER = NONE; // dont fade between brdfs
	};
	
	struct vsOut
	{
		float4 Pos : POSITION;
		#ifdef SUN
			half2 Tex : TEXCOORD0;
		#else
			float3 Tex : TEXCOORD0;
			float4 posVS : TEXCOORD1;
		#endif
	};
	
	#ifndef SUN
		struct vsIn
		{
			float4 Pos : POSITION;
			float2 Tex : TEXCOORD0;
		};
		
		vsOut mainVS(vsIn In)
		{
			vsOut Out = (vsOut)0;
			
			Out.posVS = mul(In.Pos, matWorldView);
			Out.Pos = mul(Out.posVS,matProj);
		   Out.Tex = Out.Pos.xyw;
		
			return Out;
		}
	#endif
	
	
	//float4 mainPS(in float2 inTex:TEXCOORD0):COLOR0
	float4 mainPS(vsOut In):COLOR
	{
		//je nach tiefe clippen...
		//discard;
		
		half4 color = 1;
		
		//projective texcoords
		#ifndef SUN
			//float2 projTex;
			In.Tex.x = In.Tex.x/In.Tex.z/2.0f +0.5f + (0.5/vecViewPort.x);
	   	In.Tex.y = -In.Tex.y/In.Tex.z/2.0f +0.5f + (0.5/vecViewPort.y);
	   #endif
	   
	   //clip sky
	   //clip( (1-materialData.r)-0.1 );
	   
	   
	   //get gBuffer
	   half4 gBuffer = tex2D(normalsAndDepthSampler, In.Tex.xy);
		gBuffer.w = UnpackDepth(gBuffer.zw);
	   
	   //get specular data
	   //half2 glossAndPower = UnpackSpecularData(tex2D(emissiveAndSpecularSampler, inTex).w);
	   
	   
	   //clip pixels which can't be seen
	   //not really needed anymore due to correct zbuffer culling :)
	   //float junk = ((In.posVS.z/vecSkill5.w))-(gBuffer.w);//length(gBuffer.w-(In.posVS.z/vecSkill5.w));
	   //clip(((In.posVS.z/vecSkill5.w))-(gBuffer.w));
	   
	   //decode normals
	   gBuffer.xyz = UnpackNormals(gBuffer.xy);
	   
	   //get view pos
	   #ifndef SUN
	   	float3 posVS = gBuffer.w * In.posVS.xyz * (vecSkill5.w/In.posVS.z);
	   #else
	   	float3 posVS = CalculatePosVSQuad(In.Tex.xy, gBuffer.w*vecSkill5.w);
	   #endif
	   
	   
	   #ifdef PROJECTION
	   	#ifdef SPOT
		   	half4 lightProj = mul( half4(posVS,1), matMtl );
			   color.rgb *= tex2D(projSampler, lightProj.xy/lightProj.z).rgb;
			#endif
		#endif
	   
	   
	   //half3 Ln = mul(float4(vecSkill1.xzy,1),matView).xyz - posVS.xyz; //SUN
	   half3 Ln = mul(vecSkill1.xzy,matView).xyz - posVS.xyz;
	   #ifndef SUN
	   	color.rgb *= saturate(1-length(Ln)/vecSkill1.w); //attenuation
   		//clip(dot(color.rgb,1)-0.001);
   	#endif
	   //return PackLighting(color.rgb,0);
	   
	   Ln = normalize(Ln);
	   #ifdef PROJECTION
	   	#ifdef POINT
				//color.rgb = texCUBE(projSampler, mul(mul(half4(Ln,0), matViewInv),matMtl)).rgb;
				color.rgb *= texCUBE(projSampler, -mul(half4(Ln,0), matViewInv).rgb).rgb;
				//return PackLighting(color.rgb, 0);
			#endif
		#endif
	   #ifdef SPOT
	   	clip(saturate(dot( mul(-vecSkill9.xzy,matView) , Ln))-0.0001); //clip backprojection
		#endif
	   //half3 Vn = normalize(matView[0].xyz - posVS);//normalize(IN.WorldView);
	   half3 Vn = normalize(vecViewDir.xyz - posVS); //same as above but less arithmetic instructions
	   half3 Hn = normalize(Vn + Ln);
	   
	   //half4 brdfData = (tex2D(materialDataSampler, inTex)); //get brdf gBuffer
	   //half2 light = lit(dot(Ln,gBuffer.xyz), dot(Hn, gBuffer.xyz),brdfData.g*255).yz;
		//color.rgb = light.x * vecSkill5.xyz * att;//vecSkill5.xyz;
	   //color.a = light.y;// * glossAndPower.x;
	   //color.rgb = dot(Ln,gBuffer.xyz)*att*vecSkill5.xyz;
	   
	   
	   //material data
	   half2 materialData = (tex2D(materialDataSampler, In.Tex.xy)).xy; //get material ID and specular power
	   //half4 brdfData1 = tex3D( matData1Sampler,half3(In.texCoord, materialData.r) ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
	   half4 brdfData1 = tex1D( materialLUTSampler, materialData.x ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
	   //brdfData1.r = 0.0039;
	   
	   //materialData.r = brdfData1.r;
	     
	   half2 OffsetUV;
	   OffsetUV.x = (brdfData1.y-0.5)*2;//+brdfTest1; //diffuse roughness
	   OffsetUV.y = (brdfData1.z-0.5)*2;//+brdfTest2; //diffuse wraparound/velvety
	   //half2 nuv = float2((0.5+saturate(dot(Ln,gBuffer.xyz)+OffsetUV.x)/2.0),	saturate(1.0 - (0.5+dot(gBuffer.xyz,Vn)/2.0)) + OffsetUV.y); //diffuse brdf uv, no options
	  	half2 lightingUV = half2( (dot(Vn, gBuffer.xyz)+OffsetUV.x) , ((dot(Ln, gBuffer.xyz) + 1) * 0.5)+OffsetUV.y ); //diffuse brdf uv. options (OffsetUV.x/V)
	  	color.rgb *= tex3D( brdfLUTSampler,half3(lightingUV , brdfData1.r) ).rgb * vecSkill5.xyz;
	   
	   #ifdef SPOT
	   	#ifdef SHADOW
	   		color.rgb *= GetShadow(shadowSampler, lightProj.xy/lightProj.z, lightProj.z/vecSkill1.w, vecSkill1.w);
	   	#endif
	   #endif
	   
	   //additional clipping based on diffuse lighting. clip non-lit parts
	   #ifdef SPOT
	   	clip(dot(color.rgb,1)-0.003);
	   #endif
	   
	   #ifdef SPECULAR
		   //fps hungry....
		   //half2 specularUV = half2( dot(Ln,Hn) , dot(gBuffer.xyz,Hn)-materialData.g ); //isotropic
		   //isotropic
		   //lightingUV = half2( dot(Ln,Hn) , dot(gBuffer.xyz,Hn)); //isotropic WHY IS THIS WRONG?
		   //lightingUV = half2( dot(gBuffer.xyz,Hn) , dot(Ln,Hn)); //isotropic WHY IS THIS WRONG?
		   //lightingUV.x = dot(Ln,Hn);
		   //lightingUV.y = dot(gBuffer.xyz, Hn);
		   //lightingUV.x = saturate( dot(Hn,gBuffer.xyz) );//pow(saturate( dot(Hn,gBuffer.xyz) ),materialData.g*255);
		   lightingUV.x = pow( ( dot(Hn,gBuffer.xyz) ),materialData.g*255);
		   //lightingUV.x = pow( dot(Hn,gBuffer.xyz)*2-1 ,materialData.g*32)*0.5+0.5;
		   lightingUV.y = dot(Ln,Hn);//dot(Ln, gBuffer.xyz);
		   //lightingUV = ( dot(Ln,Hn) , dot(gBuffer.xyz,Hn)); //isotropic WHY IS THIS NOT WRONG?
		   //anisotropic
		   	//lightingUV.x = saturate(color.xyz);
		   	//lightingUV.y = dot(Hn, gBuffer.xyz);
		   	//lightingUV = half2( dot(Ln,gBuffer.xyz) , dot(Hn,gBuffer.xyz));
		   	//specularUV.x = 0.5+dot(Ln,gBuffer.xyz)/2.0;
		   	//specularUV.y = 1-(0.5+dot(gBuffer.xyz,Hn)/2.0);
		   //color.a = tex3D( brdfLUTSampler, half3(lightingUV, brdfData1.r) ).a;
		   color.a = tex3D( brdfLUTSampler, half3(lightingUV, brdfData1.r) ).a;
		   //color.a = pow(color.a+0.001, materialData.g*255);
		   //...
		   //conventional specular
		   //color.a = pow(dot(gBuffer.xyz,Hn),materialData.g*255);
		   //color.xyz = color.a;
		   
		#else
			color.a = 0;
		#endif
	   
	    
	   //color.rgb = pow(diffuse,diffuseRoughness) * att * vecSkill5.xyz;
	   //color.a = (saturate(pow(specular,materialData.g*255)));
	      
		//pack
		//color.rgb /= 1.5;
		//color.rgb += brdfData1.rgb*color.rgb;
		
		
		
		
		#ifdef SHADOW //((SUN) && (SHADOW))
			#ifdef SUN
				//PSSM---------------------
				half4 posWorld = mul(float4(posVS,1), matViewInv);
				//half pssm_numsplits = 3;
				half4 shadowTexcoord[4];
				shadowTexcoord[0] = shadowTexcoord[1] = shadowTexcoord[2] = shadowTexcoord[3] = float4(0,0,0,0);
				for(int i=0;i<vecSkill13.x;i++)
					shadowTexcoord[i] = mul(posWorld,matTex[i]);
			
				color.rgb *= GetPssm(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler);
				//-------------------------
			#endif
		#endif
		
		#ifdef SUN
			color.rgb *= sun_light_var*0.01; //brightness based on sun_light
		#endif
		

		color = PackLighting(color.rgb, color.a);
		
	
	   return color;
	}
	
	technique t1
	{
		pass p0
		{
			#ifndef SUN
				VertexShader = compile vs_2_0 mainVS();
				PixelShader = compile ps_2_a mainPS();
			#else
				PixelShader = compile ps_3_0 mainPS();
			#endif
			
			#ifdef SUN
				AlphablendEnable = False;
			#else
				ColorWriteEnable = 0xFFFFFF;
				ZWriteEnable = FALSE;
				ZFunc = GREATEREQUAL;
				AlphablendEnable = TRUE;
				CullMode = CW;
		    	//Srcblend = One;
		    	//Destblend = One; 
		    	Srcblend = DestColor;
		    	Destblend = Zero; 
		    	FogEnable = FALSE;
		    	ZEnable = true;
			#endif	
		}
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scHeaderObject - Shade-C object ubershader2 //
#ifndef include_scHeaderObject
#define include_scHeaderObject
	
	/*
	#ifndef SKIN_ALBEDO
		#define SKIN_ALBEDO (skin1.xyz) //diffusemap
	#endif
	#ifndef SKIN_ALPHA
		#define SKIN_ALPHA (skin1.w) //alpha
	#endif
	#ifndef SKIN_NORMAL
		#define SKIN_NORMAL (skin2.xyz) //normalmap
	#endif
	#ifndef SKIN_GLOSS
		#define SKIN_GLOSS (skin2.w) //glossmap
	#endif
	#ifndef SKIN_EMISSIVEMASK
		#define SKIN_EMISSIVEMASK (skin3.x) //emissive mask
	#endif
	#ifndef SKIN_COLOR
		#define SKIN_COLOR (skin3.y) //(team)color mask
	#endif
	*/
	
	#ifndef PASSSOLID
	#define PASSSOLID
		bool PASS_SOLID;
	#endif
	
	#ifndef SKIN_ALBEDO
		#define SKIN_ALBEDO half3(0.5, 0.5, 0.5)
	#endif
	#ifndef SKIN_ALPHA
		#define SKIN_ALPHA 1;
	#endif
	#ifndef SKIN_NORMAL
		#define SKIN_NORMAL half3(0.5, 0.5, 1)
	#endif
	#ifndef SKIN_GLOSS
		#define SKIN_GLOSS 0
	#endif
	#ifndef SKIN_EMISSIVEMASK
		#define SKIN_EMISSIVEMASK 0
	#endif
	#ifndef SKIN_COLOR
		#define SKIN_COLOR 0
	#endif
	//#define SKIN_EMVMAPMASK (skin3.x) //environment mapping mask
	//#define SKIN_VELVETYMASK (skin3.z) //velvety lighting mask
	
	#ifndef GLOSSSTRENGTH
		#define GLOSSSTRENGTH 0
	#endif
		
	
	#ifndef SKIN1
		#define SKIN1 entSkin1
	#endif
	#ifndef SKIN2
		#define SKIN2 entSkin2
	#endif
	#ifndef SKIN3
		#define SKIN3 entSkin3
	#endif
	#ifndef SKIN4
		#define SKIN4 entSkin4
	#endif
	
	#include <scPackNormals>
	#include <scPackDepth>
	
	
	#ifndef MATWORLDVIEWPROJ
	#define MATWORLDVIEWPROJ
		float4x4 matWorldViewProj;
	#endif
	#ifndef MATWORLD
	#define MATWORLD
		float4x4 matWorld;
	#endif
	#ifndef MATVIEW
	#define MATVIEW
		float4x4 matView;
	#endif
	#ifndef MATWORLDVIEW
	#define MATWORLDVIEW
		float4x4 matWorldView;
	#endif
	
	#ifdef NORMALMAPPING
		#ifndef MATTANGENT
		#define MATTANGENT
			float3x3 matTangent; // hint for the engine to create tangents in TEXCOORD2
		#endif
	#endif
	
	#ifndef VECDIFFUSE
	#define VECDIFFUSE
		float3 vecDiffuse;
	#endif
	
	//emissive
	#ifdef EMISSIVE_A7
		#ifndef VECEMISSIVE
		#define VECEMISSIVE
			float3 vecEmissive;
		#endif
	#endif
	#ifdef EMISSIVE_SHADEC
		float3 vecEmissive_SHADEC;
	#endif
	
	//(team)color
	#ifdef OBJECTCOLOR_SHADEC
		float3 vecColor_SHADEC;
	#endif
	
	#ifndef FPOWER
	#define FPOWER
		float fPower;
	#endif
	#ifndef CLIPFAR
	#define CLIPFAR
		float clipFar;
	#endif
	#ifndef ALPHACLIP
	#define ALPHACLIP
		float alphaClip;
	#endif
	#ifndef MATERIALID
	#define MATERIALID
		float materialID;
	#endif
	
	texture SKIN1;
	texture SKIN2;
	texture SKIN3;
	texture SKIN4;
	
	/*
	#ifdef MTL_SKIN1
		#ifndef MTLSKIN1
		#define MTLSKIN1
			texture mtlSkin1;
		#endif
	#else
		#ifndef ENTSKIN1
		#define ENTSKIN1
			texture entSkin1;
		#endif
	#endif
	*/
	
	sampler2D sc_skin1Sampler = sampler_state
	{
		Texture = <SKIN1>;
		/*
		#ifdef MTL_SKIN1
			Texture = <mtlSkin1>;
		#else
			Texture = <entSkin1>;
		#endif
		*/
	
		MinFilter = Linear;
		MagFilter = Linear;
		MipFilter = Linear;
		AddressU = WRAP;
		AddressV = WRAP;
	};
	
	sampler2D sc_skin2Sampler = sampler_state
	{
		Texture = <SKIN2>;
	
		MinFilter = Linear;
		MagFilter = Linear;
		MipFilter = Linear;
		AddressU = WRAP;
		AddressV = WRAP;
	};
	
	sampler2D sc_skin3Sampler = sampler_state
	{
		Texture = <SKIN3>;
	
		MinFilter = Linear;
		MagFilter = Linear;
		MipFilter = Linear;
		AddressU = WRAP;
		AddressV = WRAP;
	};
	
	sampler2D sc_skin4Sampler = sampler_state
	{
		Texture = <SKIN4>;
			
		MinFilter = Linear;
		MagFilter = Linear;
		MipFilter = Linear;
		AddressU = WRAP;
		AddressV = WRAP;
	};
	
	
	struct vsIn
	{
		float4 Pos : POSITION;
		half2 Tex : TEXCOORD0;
		half2 TexShadow : TEXCOORD1;
		half3 Normal : NORMAL;
		#ifdef NORMALMAPPING
			half4 Tangent: TEXCOORD2;
		#endif
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
	
	struct psOut
	{
	    float4 NormalsAndDepth : COLOR0;
	    half4 AlbedoAndEmissiveMask : COLOR1;
	    float4 MaterialData : COLOR2;
	    //float4 lightmapAnd : COLOR3;
	};
#endif

//////////////////////////////////////////////////////////////////////
//section: scObject - Shade-C object ubershader //
#ifndef include_scObject
#define include_scObject	
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
		
		#ifndef CUSTOM_VS_POSITION
			Out.Pos = mul(In.Pos,matWorldViewProj);
		#else
			Out.Pos = Custom_VS_Position(In);
		#endif
		Out.Pos2D = mul(In.Pos,matWorldView).z;
		
		#ifndef CUSTOM_VS_TEX
			Out.Tex.xy = In.Tex;
		#else
			Out.Tex.xy = Custom_VS_Tex(In);
		#endif
		
		#ifndef CUSTOM_VS_TEXSHADOW
			Out.Tex.zw = In.TexShadow;
		#else
			Out.Tex.zw = Custom_VS_TexShadow(In);
		#endif
		
		#ifndef CUSTOM_VS_NORMAL
			Out.Normal = mul(In.Normal.xyz,matWorldView);
		#else
			Out.Normal = Custom_VS_Normal(In);
		#endif
		
		#ifdef NORMALMAPPING
			#ifndef CUSTOM_VS_TANGENT
				Out.Tangent = mul(In.Tangent.xyz, matWorldView); 
			#else
				Out.Tangent = Custom_VS_Tangent(In);
			#endif
			
			#ifndef CUSTOM_VS_BINORMAL
	   		Out.Binormal = mul(cross(In.Tangent.xyz, In.Normal.xyz), matWorldView); 
	   	#else
	   		Out.Binormal = Custom_VS_Binormal(In);
	   	#endif
	   	//Out.Tangent = normalize(Out.Tangent);
	   	//Out.Binormal = normalize(Out.Binormal);
	   #endif
	   //Out.Normal = normalize(Out.Normal);
		
		#ifdef CUSTOM_VS_EXTEND
			Out = Custom_VS_Extend(In, Out);
		#endif
		
		return Out;	
	}
	
	/*
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
	
	
	
	
	psOut mainPS(vsOut In)
	{
		psOut PSOut = (psOut)0;
		
		//get skins
		#ifndef CUSTOM_PS_SKIN1
			#ifndef NO_SKIN1
				half4 skin1 = tex2D(sc_skin1Sampler,In.Tex);
			#else
				half4 skin1 = 0;
			#endif
		#else
			//CUSTOM CODE
			half4 skin1 = Custom_PS_Skin1(In);
		#endif
		#ifndef CUSTOM_PS_SKIN2
			#ifndef NO_SKIN2
				half4 skin2 = tex2D(sc_skin2Sampler,In.Tex);
			#else
				half4 skin2 = 0;
			#endif
		#else
			//CUSTOM CODE
			half4 skin2 = Custom_PS_Skin2(In);
		#endif
		#ifndef CUSTOM_PS_SKIN3
			#ifndef NO_SKIN3
				half4 skin3 = tex2D(sc_skin3Sampler,In.Tex);
			#else
				half4 skin3 = 0;
			#endif
		#else
			//CUSTOM CODE
			half4 skin3 = Custom_PS_Skin3(In);
		#endif
		#ifndef CUSTOM_PS_SKIN4
			#ifndef NO_SKIN4
				half4 skin4 = tex2D(sc_skin4Sampler,In.Tex);
			#else
				half4 skin4 = 0;
			#endif
		#else
			//CUSTOM CODE
			half4 skin4 = Custom_PS_Skin4(In);
		#endif
		
		
		//alphatest
		#ifndef CUSTOM_PS_ALPHA
			#ifdef ALPHA
				clip(SKIN_ALPHA-alphaClip);
			#endif
		#else
			//CUSTOM CODE
			clip( Custom_PS_Alpha(In, SKIN_ALPHA) );
		#endif
		
		//initial w values
		PSOut.AlbedoAndEmissiveMask.w = 0;
		
		//normals
		#ifndef CUSTOM_PS_NORMALMAPPING
			#ifdef NORMALMAPPING
				half3 bump = SKIN_NORMAL*2-1;
				In.Normal.rgb += (bump.x * In.Tangent.xyz + bump.y * In.Binormal.xyz);
			#endif
		#else
			//CUSTOM CODE
			In.Normal.rgb = Custom_PS_Normalmapping(In, SKIN_NORMAL);
		#endif
		//PSOut.normalsAndDepth.xy = PackNormals( normalize(In.Normal.rgb) ); //normals
		PSOut.NormalsAndDepth.xyz = (In.Normal.rgb); //normals
			
		//depth
		#ifndef CUSTOM_PS_DEPTH
			PSOut.NormalsAndDepth.w = (In.Pos2D/clipFar);
		#else
			//CUSTOM CODE
			PSOut.NormalsAndDepth.w = Custom_PS_Depth(In);
		#endif
		
		//albedo
		#ifndef CUSTOM_PS_DIFFUSE
			#ifdef USE_VEC_DIFFUSE
				PSOut.AlbedoAndEmissiveMask.xyz = SKIN_ALBEDO * vecDiffuse;
			#else
				PSOut.AlbedoAndEmissiveMask.xyz = SKIN_ALBEDO;
			#endif
		#else
			//CUSTOM CODE
			PSOut.AlbedoAndEmissiveMask.xyz = Custom_PS_Diffuse(In, SKIN_ALBEDO);
		#endif
		
		//(team)color
		#ifndef CUSTOM_PS_COLOR
			#ifdef OBJECTCOLOR_A7
				PSOut.AlbedoAndEmissiveMask.xyz += SKIN_COLOR * vecDiffuse;
			#endif
			#ifdef OBJECTCOLOR_SHADEC
				PSOut.AlbedoAndEmissiveMask.xyz += SKIN_COLOR * vecColor_SHADEC;
			#endif
		#else
			//CUSTOM CODE
			PSOut.AlbedoAndEmissiveMask.xyz += Custom_PS_Color(In, SKIN_COLOR);
		#endif
				
		//emissiveMask
		#ifndef CUSTOM_PS_EMISSIVEMASK
			#ifdef EMISSIVEMASK
				//Set EmissiveMask
				PSOut.AlbedoAndEmissiveMask.w = SKIN_EMISSIVEMASK;
				#ifdef EMISSIVE_A7
					PSOut.AlbedoAndEmissiveMask.xyz =  clamp(PSOut.AlbedoAndEmissiveMask.xyz - PSOut.AlbedoAndEmissiveMask.w,0,1);
					PSOut.AlbedoAndEmissiveMask.xyz =  clamp(PSOut.AlbedoAndEmissiveMask.xyz + (PSOut.AlbedoAndEmissiveMask.w * vecEmissive.xyz ),0,1);
				#endif
				#ifdef EMISSIVE_SHADEC
					PSOut.AlbedoAndEmissiveMask.xyz =  clamp(PSOut.AlbedoAndEmissiveMask.xyz - PSOut.AlbedoAndEmissiveMask.w,0,1);
					PSOut.AlbedoAndEmissiveMask.xyz =  clamp(PSOut.AlbedoAndEmissiveMask.xyz + (PSOut.AlbedoAndEmissiveMask.w * vecEmissive_SHADEC.xyz ),0,1);
				#endif
			#endif
		#else
			//CUSTOM CODE
			PSOut.AlbedoAndEmissiveMask.w = Custom_PS_EmissiveMask(In, SKIN_EMISSIVEMASK);
		#endif
		
		//material ID
		#ifndef CUSTOM_PS_MATERIALID
			PSOut.MaterialData.x = materialID; //material ID
		#else
			//CUSTOM CODE
			PSOut.MaterialData.x = Custom_PS_MaterialID(In);
		#endif
		
		//Specular Power
		#ifndef CUSTOM_PS_SPECULARPOWER
			PSOut.MaterialData.y = fPower/(float)255;//vecSkill17.z; //material Specular Power
		#else
			//CUSTOM CODE
			PSOut.MaterialData.y = Custom_PS_SpecularPower(In);
		#endif
		
		//Specular Gloss
		#ifndef CUSTOM_PS_GLOSS
			#ifdef GLOSSMAP
				PSOut.MaterialData.z = SKIN_GLOSS; //material Specular Intensity
			#else
				PSOut.MaterialData.z = GLOSSSTRENGTH;
			#endif
		#else
			//CUSTOM CODE
			PSOut.MaterialData.z = Custom_PS_Gloss(In, SKIN_GLOSS);
		#endif
		PSOut.MaterialData.w = 0; //environment map ID - not used yet
		
		//Extend Pixelshader
		#ifdef CUSTOM_PS_EXTEND
			PSOut = Custom_PS_Extend(In, PSOut);
		#endif
		
		
		//Packing---------------------
		//PSOut.normalsAndDepth.xy = PackNormals( mul((In.Normal.rgb) ,matView) ); //normals
		PSOut.NormalsAndDepth.xy = PackNormals(normalize(PSOut.NormalsAndDepth.xyz)); //normals
		//depth
		PSOut.NormalsAndDepth.zw = PackDepth(PSOut.NormalsAndDepth.w);
		
		
		return PSOut;
	}
	
	technique Object
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
			PixelShader = compile ps_2_a mainPS();
			FogEnable = False;
			
			#ifdef ZPREPASS
				ColorWriteEnable = RED | GREEN | BLUE | ALPHA;
				zenable = true;
				zwriteenable = false;
		    	ZFunc = LESSEQUAL;
			#endif
		}
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scHeaderLightShadowmap - shadowmap calculation //
#ifndef include_scHeaderLightShadowmap
#define include_scHeaderLightShadowmap
	
	#ifndef PASSSOLID
	#define PASSSOLID
		bool PASS_SOLID;
	#endif
	
	#include <scPackDepth>
	
	#ifndef MATWORLDVIEWPROJ
		#define MATWORLDVIEWPROJ
		float4x4 matWorldViewProj;
	#endif
	//float4x4 matProj;
	
	/*
	#ifndef VECSKILL1
	#define VECSKILL1
		float4 vecSkill1; //depthmap stuff, x = | y = alpha clip | z = bias | w = maxDepth
	#endif
	*/
	
	#ifndef CLIPFAR
	#define CLIPFAR
		float clipFar;
	#endif
	#ifndef ALPHACLIP
	#define ALPHACLIP
		float alphaClip;
	#endif
	
	#ifdef ALPHA
		#ifndef ENTSKIN1
		#define ENTSKIN1
			texture entSkin1;
		#endif
		
		sampler2D sc_skin1Sampler = sampler_state
		{
			Texture = <entSkin1>;
			AddressU = WRAP;
			AddressV = WRAP;
		};
	#endif
	
	struct vsIn
	{
		float4 Pos : POSITION;
		float2 Tex : TEXCOORD0;
	};
	
	struct vsOut
	{
		float4 Pos : POSITION;
		float Pos2D : TEXCOORD0;
		float2 Tex : TEXCOORD1;
	};
	
	struct psOut
	{
		float4 Color : COLOR;
	};
	
#endif

//////////////////////////////////////////////////////////////////////
//section: scLightShadowmap - shadowmap calculation //
#ifndef include_scLightShadowmap
#define include_scLightShadowmap
	vsOut mainVS(vsIn In)
	{
		vsOut Out = (vsOut)0;	
		
		/*
		float4 pos = mul(In.Pos,matWorldViewProj);
		Out.Pos2D = pos.z;
		Out.Pos = pos;//mul(pos,matProj);
		Out.Tex = In.Tex;	
		*/
		
		#ifndef CUSTOM_VS_POSITION
			Out.Pos = mul(In.Pos,matWorldViewProj);
		#else
			Out.Pos = Custom_VS_Position(In);
		#endif
		Out.Pos2D = Out.Pos.z;
		Out.Tex = In.Tex;	
		
		#ifdef CUSTOM_VS_Extend
			Out = Custom_VS_Extend(In, Out);
		#endif
		
		return Out;
		
	}
	
	half4 CalculateShadowDepth(float Pos2D_Z)
	{
		//half depth = ((Pos2D_Z)/vecSkill1.w);
		half depth = ((Pos2D_Z)/clipFar);
		//depth += depth*vecSkill1.z;
		
		//return half4(PackDepth(depth),0,0);
		return half4(depth,0,0,0);
	}
	
	psOut mainPS(vsOut In)
	{
		psOut Out = (psOut)0;
		
		//alpha clip
		#ifndef CUSTOM_PS_ALPHA
			#ifdef ALPHA
				//clip(tex2D(skin1Sampler,In.Tex).a-vecSkill1.y);
				clip(tex2D(sc_skin1Sampler,In.Tex).a-alphaClip);
			#endif
		#else
			#ifdef ALPHA
				clip( Custom_PS_Alpha(In, tex2D(sc_skin1Sampler,In.Tex).a) );
			#else
				clip( Custom_PS_Alpha(In, 1) );
			#endif
		#endif
		
		Out.Color = CalculateShadowDepth(In.Pos2D);
		
		#ifdef CUSTOM_PS_EXTEND
			Out = Custom_PS_Extend(In, Out);
		#endif
		
		return Out;
	}
	
	psOut mainPS_lm(vsOut In)
	{
		psOut Out = (psOut)0;
		
		Out.Color = CalculateShadowDepth(In.Pos2D);
		
		#ifdef CUSTOM_PS_EXTEND
			Out = Custom_PS_Extend(In, Out);
		#endif
		
		return Out;
	}
	
	technique LightShadowmap
	{
		pass p0
		{
			cullmode = ccw;
			FogEnable = False;
			alphablendenable = false;
			zwriteenable = true;
			vertexshader = compile vs_2_0 mainVS();
			pixelshader = compile ps_2_0 mainPS();
		}
	}
	
	technique LightShadowmap_lm
	{
		pass p0
		{
			cullmode = ccw;
			FogEnable = False;
			alphablendenable = false;
			zwriteenable = true;
			vertexshader = compile vs_2_0 mainVS();
			pixelshader = compile ps_2_0 mainPS_lm();
		}
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scDummy - calculates PSSM shadows //
#ifndef include_scDummy
#define include_scDummy
	half2 test()
	{
		return half2(1,1);
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: end
#endif
