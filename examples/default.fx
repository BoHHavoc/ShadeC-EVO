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
//section: sun - return the sun light on the surface /////////////////
#ifndef include_sun
#define include_sun

float4 vecSunDir;
float4 vecSunColor;
float4 DoSunLight(float3 N)
{
	return vecSunColor * dot(N,-vecSunDir); // modulate sunlight by the surface angle
}
#endif

//////////////////////////////////////////////////////////////////////
//section: lights - return the dynamic light on the surface //////////
#ifndef include_lights
#define include_lights
#include <define>

int iLights;
float4 vecLightPos[8];	 // light positions (xyz) and ranges (w)
float4 vecLightColor[8]; // light colors

// calculate the light attenuation factor
float DoLightFactor(float4 Light,float3 Pos)
{
   float fac = 0.f;
   if (Light.w > 0.f) {    
      float LD = length(Light.xyz-Pos)/Light.w;
#ifdef DXLIGHTING // DX falloff formula
		if (LD < 1.0f)
			fac = saturate(1.f/(0.f + 0.f*LD + 1.5f*LD*LD));	
#else  // Acknex formula, linear lighting
      if (LD < 1.f)
         fac = saturate(1.f - LD);
#endif  
   }
   return fac; // get the distance factor
}

// calculate the light attenuation factor on the front side
float DoLightFactorBump(float4 Light,float3 P,float3 N)
{
#ifdef BUMPFALLOFF
	float3 D = Light.xyz-P; // ray pointing from the light to the surface
	float NdotL = dot(N,normalize(D));   // angle between surface and light ray
	
	if (NdotL >= 0.f) 
	   return saturate(NdotL*8)*DoLightFactor(Light,P);
	else
	   return 0.f;
#else
     return DoLightFactor(Light,P);
#endif
}

float DoLightFactorN(float4 Light,float3 P,float3 N)
{
	float3 D = Light.xyz-P; // ray pointing from the light to the surface
	float NdotL = dot(N,normalize(D));   // angle between surface and light ray
	
	if (NdotL >= 0.f) 
	   return 2 * NdotL * DoLightFactor(Light,P);
	else
	   return 0.f;
}

float4 DoPointLight(float3 P, float3 N, float4 Light, float4 LightColor)
{
	return LightColor * DoLightFactorN(Light,P,N);
}

float4 DoLight(float3 P, float3 N, int i)
{
	return DoPointLight(P,N,vecLightPos[i],vecLightColor[i]);
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
//section: vecskill - set vecSkill41 to default values ///////////////
#ifndef include_vecskill
#define include_vecskill

float4 vecSkill41;

float DoDefault(float vecSkill,float defVal)
{
   if (0 == vecSkill) 
      return defVal;
   else
      return vecSkill;
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
//section: bump_vs - bumpmapping vertex shader //////////////////////////
#include <define>
#include <transform>
#include <fog>
#include <pos>
#include <normal>
#include <tangent>
#include <lights>
#include <color>

struct bumpOut
{
	float4 Pos: POSITION;
	float  Fog:	FOG;
	float4 Ambient:  COLOR0;
	float4 Tex12:    TEXCOORD0;	
	float3 ViewDir:  TEXCOORD1;
	float3 LightDir1:	 TEXCOORD2;	
	float3 LightDir2:	 TEXCOORD3;
	float3 LightDir3:	 TEXCOORD4;	
	float3 Diffuse1: TEXCOORD5;		
	float3 Diffuse2: TEXCOORD6;		
	float3 Diffuse3: TEXCOORD7;		
};

bumpOut bump_VS(vertexIn In)
{
	bumpOut Out;

	Out.Pos	= DoTransform(In.Pos);
	Out.Tex12 = float4(In.Tex1,In.Tex2);
	Out.Fog	= DoFog(In.Pos);
	Out.Ambient = DoAmbient();	

	CreateTangents(In.Normal,In.Tangent);
  float3 PosWorld = DoPos(In.Pos);
	Out.ViewDir = DoTangent(vecViewPos-PosWorld);
	Out.LightDir1 = DoTangent(vecLightPos[0].xyz-PosWorld);
	Out.LightDir2 = DoTangent(vecLightPos[1].xyz-PosWorld);
	Out.LightDir3 = DoTangent(vecLightPos[2].xyz-PosWorld);
	
  float3 Normal = DoNormal(In.Normal);
	Out.Diffuse1 = DoLightFactorBump(vecLightPos[0],PosWorld,Normal) * vecLightColor[0];
	Out.Diffuse2 = DoLightFactorBump(vecLightPos[1],PosWorld,Normal) * vecLightColor[1];
	Out.Diffuse3 = DoLightFactorBump(vecLightPos[2],PosWorld,Normal) * vecLightColor[2];
	
	return Out;		
}

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

//section: scPackDepth - packs linear depth to 2x8bit //
#ifndef include_scPackDepth
#define include_scPackDepth

	half2 PackDepth(half inDepth)
	{
		
//		half2 enc;
//		enc.x = floor(inDepth*255)/255;
//		enc.y = floor((inDepth-enc.x)*255*255)/255;
		
		//optimized
		half2 enc;
		enc.x = floor(inDepth*255)/255;
		enc.y = floor((inDepth-enc.x)*65025)/255;
		
		return enc;
	}
	
#endif

//section: scUnpackDepth - unpacks depth //
#ifndef include_scUnpackDepth
#define include_scUnpackDepth

	half UnpackDepth(half2 enc)
	{
		//return enc.x + (enc.y/255);
		
		//optimized
		enc.y /= 255;
		return dot(enc,1);
	}
#endif


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

//section: scCalculatePosVSQuad - returns the viewspace position for a screenspace quad. Needs screenspace texcoords and linear depth * clip_far //
#ifndef include_scCalculatePosVSQuad
#define include_scCalculatePosVSQuad
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


//section: scGetShadow - Calculate Shadows. Needs projective texcoords and original light->receiver depth//
#ifndef include_scGetShadow
#define include_scGetShadow
	#include <scUnpackDepth>
	
	#ifdef RANDOMIZE_SHADOW
	texture sc_map_random2x2_bmap;
	sampler2D shadowRandomSampler = sampler_state 
	{ 
	   Texture = <sc_map_random2x2_bmap>; 
	   AddressU = WRAP; 
		AddressV = WRAP;
		AddressW = WRAP;
	   MinFilter = NONE;
		MagFilter = NONE;
		MipFilter = NONE;
	};
	#endif
	
	
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
	/*
	float ChebyshevUpperBound(float2 Moments, float t)  
	{  
	  // One-tailed inequality valid if t > Moments.x  
	   float p = (t <= Moments.x);  
	  // Compute variance.  
	   float Variance = Moments.y - (Moments.x*Moments.x);  
	  Variance = max(Variance, g_MinVariance);  
	  // Compute probabilistic upper bound.  
	   float d = t - Moments.x;  
	  float p_max = Variance / (Variance + d*d);  
	  return max(p, p_max);  
	}
	float ShadowContribution(sampler2D shadowSampler, float2 lightTexCoord, float distanceToLight)  
	{  
	  // Read the moments from the variance shadow map.  
	   float depth = UnpackDepth(tex2D(shadowSampler, lightTexCoord).xy);  
	   float2 moments;
	   moments.x = depth;  
	   float dx = ddx(depth);  
		float dy = ddy(depth);  
		// Compute second moment over the pixel extents.  
		moments.y = depth*depth + 0.25*(dx*dx + dy*dy);  
	   
	  // Compute the Chebyshev upper bound.  
	   return ChebyshevUpperBound(moments, distanceToLight);  
	}
	
	float ESM(sampler2D shadowSampler, half2 inTex, half receiver)
	{
		float occluder= UnpackDepth(tex2D(shadowSampler, inTex).xy);
		float overdark = 1000;
		float    lit = exp(overdark* ( occluder - receiver ));
		lit = saturate(lit);
		return lit;
	}
	*/
	
	//static half2 shadow_blurSize_softness = half2(0.0025, 0.015);
	static half2 shadow_blurSize_softness = half2(0.0025, 0.02);
	half GetShadow(sampler2D shadowSampler, float2 inTex, half inDepth, half maxDepth)
	{
		
		//fix shadow bias
	   //inDepth -= (1/maxDepth);
		
		#ifdef RANDOMIZE_SHADOW
			inTex += ((tex2D(shadowRandomSampler, inTex*64).xy-0.5)*2)*shadow_blurSize_softness.x;
			inTex += ((tex2D(shadowRandomSampler, inTex*128).xy-0.5)*8)*shadow_blurSize_softness.x;
			inTex += ((tex2D(shadowRandomSampler, inTex*256).xy-0.5)*10)*shadow_blurSize_softness.x;
		#endif
		
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
	   
	   
	   
	   //create filter taps
	   half4 shadowDepth;
	   shadowDepth.x = UnpackDepth(tex2D(shadowSampler, inTex + float2(shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth.y = UnpackDepth(tex2D(shadowSampler, inTex + float2(-shadow_blurSize_softness.x,shadow_blurSize_softness.x) ).xy);
	   shadowDepth.z = UnpackDepth(tex2D(shadowSampler, inTex + float2(shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   shadowDepth.w = UnpackDepth(tex2D(shadowSampler, inTex + float2(-shadow_blurSize_softness.x,-shadow_blurSize_softness.x) ).xy);
	   //shadowDepth = 1-saturate( (shadowDepth-inDepth) * shadow_blurSize_softness.y * maxDepth ); //cullmode of depthmap: CW
	   shadowDepth = saturate( ( (inDepth-shadowDepth)*shadow_blurSize_softness.y * maxDepth)  //cullmode of depthmap: CCW
	   					* max(1 , saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) ) *6 )   );
	   //shadowDepth = saturate( ( (inDepth-shadowDepth)*shadow_blurSize_softness.y * maxDepth) );  //cullmode of depthmap: CCW
	   					//* max(1 , saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) ) *6 )   );
	   
	   //create filter
	   half filter = shadowDepth.x*shadowDepth.y*shadowDepth.z*shadowDepth.w; //cullmode of depthmap: CW
	   
	   //create softshadow
	   shadowDepth.x = saturate( exp( (UnpackDepth(tex2D(shadowSampler, inTex).xy)-inDepth)*shadow_blurSize_softness.y * maxDepth) );
	   
	   //return shadowDepth.x;
	   //finalize filter
	   filter *= shadowDepth.x;
	   
	   
	   //return ReduceLightBleeding( shadowDepth.x, filter );
	   return smoothstep( filter, 1, shadowDepth.x );
	   /*
	   shadowDepth.y = 1-saturate(((UnpackDepth(tex2D(shadowSampler, inTex).xy) - (inDepth-(3/maxDepth))) * 3000));
	   shadowDepth.y *= 1-filter;//saturate(exp((UnpackDepth(tex2D(shadowSampler, inTex).xy) - (inDepth-(3/maxDepth))) * 60));
	   
	   //return shadowDepth.y;
	   return half3(shadowDepth.y, 1-pow(smoothstep( filter, 1, shadowDepth.x ),100) ,0);
	   */
	}
#endif




//////////////////////////////////////////////////////////////////////
//section: end
#endif
