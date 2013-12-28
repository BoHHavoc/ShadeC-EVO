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
//section: scPackNormals - packs normalized view space normals to 2x8bit //
#ifndef include_scPackNormals
#define include_scPackNormals
	
	/*
	texture sc_map_BFNormals_bmap;
	sampler2D BFNSampler = sampler_state
	{
		Texture = <sc_map_BFNormals_bmap>;
		MinFilter = NONE;
		MagFilter = NONE;
		MipFilter = NONE;
		AddressU = WRAP;
		AddressV = WRAP;
		AddressW = WRAP;
	};
	
	#ifndef BFN_BIAS
	#define BFN_BIAS float3(127.5 / 255.0, 127.5 / 255.0, 8.0 / 255.0)
	#endif
	*/
	
	half2 PackNormals(half3 n)
	{
		
		//argb r12f
		//half2 enc = normalize(n.xy) * (sqrt(-n.z*0.5+0.5));
	   //enc = enc*0.5+0.5;
	   //return enc;
		
		//argb8
		//return n.xy*0.5+0.5;
		
		//Lambert Azimuthal
		//half f = sqrt(8*n.z + 8);
		//return n.xy / f + 0.5;
		
		
		/*
		//spheremap
		float f = -n.z*2+1;
		float g = dot(n,n);
		float p = sqrt(g+f);
		float2 enc = n/p * 0.5 + 0.5;
		return enc;
		*/
		
		
		
		//spheremap (optimized) <--
		half3 fgp;
		fgp.x = -n.z*2+1;
		fgp.y = dot(n,n);
		fgp.z = sqrt(dot(fgp.xy,1));
		fgp.xy = n/fgp.z * 0.5 + 0.5;
		return fgp.xy;
		
		
		
		
		
		/*
		//BFN Best Fit Normals (cube lookup texture)
		float3 an = abs(n);
		float bestfit = tex3D(BFNSampler, n).a;
		float maxabs = max(max(an.x, an.y), an.z);
		
		const float3 c3 = 1.0 - BFN_BIAS;
		const float3 c4 = BFN_BIAS;
		
		return n * (bestfit / maxabs) * c3 + c4;
		*/

		
		
		
		
		/*
		//BFN Best Fit Normals (2d lookup)
		half3 vNormalUns = abs(n);
		//get axis for cubemap lookup
		half maxNAbs = max(max(vNormalUns.x, vNormalUns.y), vNormalUns.z);	
		//get coords of collapsed cubemap
		float2 vTexCoord = vNormalUns.z<maxNAbs?(vNormalUns.y<maxNAbs?vNormalUns.yz:vNormalUns.xz):vNormalUns.xy;
		vTexCoord = vTexCoord.x < vTexCoord.y ? vTexCoord.yx : vTexCoord.xy;
		vTexCoord.y /= vTexCoord.x;
		//fit normal into edge of unit cube
		n /= maxNAbs;
		//look-up fitting length
		float fFittingScale = tex2D(BFNSampler, vTexCoord).a;
		//scale the normal to get the best fit
		n *= fFittingScale;
		//squeeze back to unsigned
		n = n*0.5+0.5; //normalizing here guves "some" result, although not quite right
		//return n;
		return n.xy; //return only xy as we only have 2 gBuffer slots available
		*/
		
		
		
		
		
		/*
		// Renormalize (needed if any blending or interpolation happened before)
   	//n.rgb = normalize(n.rgb);
   	// Get unsigned normal for cubemap lookup (note the full float presision is required)
   	half3 vNormalUns = abs(n.rgb);
   	// Get the main axis for cubemap lookup
   	half maxNAbs = max(vNormalUns.z, max(vNormalUns.x, vNormalUns.y));
   	// Get texture coordinates in a collapsed cubemap
   	float2 vTexCoord = vNormalUns.z < maxNAbs ? (vNormalUns.y < maxNAbs ? vNormalUns.yz : vNormalUns.xz) : vNormalUns.xy;
   	vTexCoord = vTexCoord.x < vTexCoord.y ? vTexCoord.yx : vTexCoord.xy;
   	vTexCoord.y /= vTexCoord.x;
   	// Fit normal into the edge of unit cube
   	n.rgb /= maxNAbs;
   	// Look-up fitting length and scale the normal to get the best fit
   	float fFittingScale = tex2D(BFNSampler, vTexCoord).a;
   	// Scale the normal to get the best fit
   	n.rgb *= fFittingScale;
		// Squeeze to unsigned.
		n.rgb = n.rgb * .5h + .5h;
		//return n;
    	return n.xy;
    	*/
    	
    	
		
		
		

		
		
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
	
	/*
	#ifndef BFN_BIAS
	#define BFN_BIAS float3(127.5 / 255.0, 127.5 / 255.0, 8.0 / 255.0)
	#endif
	*/
	
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
	    
	   
	   /*
	   //argb8
	 	half3 n;
		n.xy=enc.xy*2-1;
		n.z=-sqrt(1-dot(n.xy,n.xy));
		return (n);
		*/
		
		
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
		
		
		
		//spheremap (optimized) <--
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
		//Best Fit Normals (3d lookup)
		const float3 c1 = 1.0 / (1.0 - BFN_BIAS);
		const float3 c2 = 1.0 - c1;
		//return normalize( n * c1 + c2 );
		half3 n;
		n.xy = normalize(enc * c1.xy + c2.xy);
		//n.xy=enc.xy*2-1;
		n.z=-sqrt(1-dot(n.xy,n.xy));
		return n;
		*/
		
		
		/*
		//Best Fit Normals (2d lookup)
		//enc.xyz = normalize(enc.xyz*2-1); //this is it if you are using 3 components...doesnt work with 2 though >.<
		
		half3 n = normalize(half3(enc.xy*2-1,-1));
		n.z=sqrt(1-dot(n.xy,n.xy));
		return (n);
		
//		half3 n;
//		n.xy= enc.xy*2-1;//normalize( half3(enc,-1) * c1.xyz + c2.xyz ).xy;
//		n.z=-sqrt(1-dot(n.xy,n.xy));
//		return normalize(n);
		*/
		
		
		

		

		
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
		return normalize(float3(ddx(inDepth), ddy(inDepth), 1.0f));// * 0.5 + 0.5;
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
		//viewRay.x = lerp(-1, 1, inTex.x);
		viewRay.x = inTex.x*2-1;
		//viewRay.y = lerp(1, -1, inTex.y);
		viewRay.y = (1-inTex.y)*2-1;
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
	
	static half2 shadow_softness = 0.075;
	half GetShadow(sampler2D shadowSampler, float2 inTex, half inDepth, half maxDepth)
	{
	   //inDepth -=  0.00025;
	   half shadowDepth = tex2D(shadowSampler, inTex).x;//UnpackDepth(tex2D(shadowSampler, inTex).xy);
	   return saturate( exp( (exp(shadowDepth)-exp(inDepth))*shadow_softness * maxDepth) );
	}
#endif

//////////////////////////////////////////////////////////////////////
//section: scGetShadowPCF - Calculates the shadow term using PCF with edge tap smoothing //
#ifndef include_scGetShadowPCF
#define include_scGetShadowPCF


// Calculates the shadow term using PCF with edge tap smoothing
float scGetShadowPCF(half3 vTexCoord, sampler inDepthSampler, int inShadowMapSize, int iSqrtSamples)
{
    float fShadowTerm = 0.0f;  
    
    iSqrtSamples -= 1;
    //float fRadius = (iSqrtSamples - 1.0f) / 2;        
    float fRadius = (iSqrtSamples) / 2;
    for (float y = -fRadius; y <= fRadius; y++)
    {
        for (float x = -fRadius; x <= fRadius; x++)
        {
            float2 vOffset = 0;
            vOffset = float2(x, y);                
            vOffset /= inShadowMapSize;
            float4 vSamplePoint = 0;//
            vSamplePoint.xy = vTexCoord + vOffset;
            float fDepth = tex2Dlod(inDepthSampler, vSamplePoint).x;
            float fSample = (vTexCoord.z <= fDepth);
            
            // Edge tap smoothing
            float xWeight = 1;
            float yWeight = 1;
            
            if (x == -fRadius)
                xWeight = 1 - frac(vTexCoord.x * inShadowMapSize);
            else if (x == fRadius)
                xWeight = frac(vTexCoord.x * inShadowMapSize);
                
            if (y == -fRadius)
                yWeight = 1 - frac(vTexCoord.y * inShadowMapSize);
            else if (y == fRadius)
                yWeight = frac(vTexCoord.y * inShadowMapSize);
                
            fShadowTerm += fSample * xWeight * yWeight;
        }                                            
    }        
    //iSqrtSamples -= 1;
    fShadowTerm /= (iSqrtSamples * iSqrtSamples );
    //fShadowTerm /= ((iSqrtSamples - 1) * (iSqrtSamples - 1));
    
    return fShadowTerm;
}

// Calculates the shadow occlusion using bilinear PCF
float scGetShadowPCFBilinear(half3 vTexCoord, sampler inDepthSampler, int inShadowMapSize)
{
    float fShadowTerm = 0.0f;

    // transform to texel space
    float2 vShadowMapCoord = inShadowMapSize * vTexCoord.xy;
    
    // Determine the lerp amounts           
    float2 vLerps = frac(vShadowMapCoord);

    //optimized
    float4 fSamples;
    fSamples.x = tex2Dlod(inDepthSampler, half4(vTexCoord.xy,0,0) ).x; 
    fSamples.y = tex2Dlod(inDepthSampler, half4(vTexCoord.xy + float2(1.0f/inShadowMapSize, 0),0,0) ).x;
    fSamples.z = tex2Dlod(inDepthSampler, half4(vTexCoord.xy + float2(0, 1.0f/inShadowMapSize),0,0) ).x;
    fSamples.w = tex2Dlod(inDepthSampler, half4(vTexCoord.xy + float2(1.0f/inShadowMapSize, 1.0/inShadowMapSize),0,0) ).x;
    
    fSamples -= vTexCoord.z;
    //fSamples = fSamples*990000;
    fSamples = fSamples*10000;
    fSamples = clamp(fSamples, 0, 1);//saturate(fSamples);//clamp(fSamples, 0, 1);
    
    // lerp between the shadow values to calculate our light amount
    fShadowTerm = lerp( lerp( fSamples.x, fSamples.y, vLerps.x ),
                        lerp( fSamples.z, fSamples.w, vLerps.x ),
                        vLerps.y );     
                                
    return fShadowTerm;                                 
    
}

#endif

//////////////////////////////////////////////////////////////////////
//section: scGetPssm - calculates PSSM shadows //
#ifndef include_scGetPssm
#define include_scGetPssm

	//#include <scGetShadowPCFBilinear>
	#include <scGetShadowPCF>
	
	
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
	
	half GetPssm(half4 shadowTexcoord[4], half fDistance, half maxDepth, half numberOfSplits, sampler sDepth1, sampler sDepth2, sampler sDepth3, sampler sDepth4, int inMapSize)
	{
		half4 shadows = 0;
		/*
		//optimized
	 	half4 realDepth;
	 	//half4 realDepth;  //= half4(shadowTexcoord[0].z, shadowTexcoord[1].z, shadowTexcoord[2].z, shadowTexcoord[3].z);
	 	realDepth.x = shadowTexcoord[0].z;
	 	realDepth.y = shadowTexcoord[1].z;
	 	realDepth.z = shadowTexcoord[2].z;
	 	realDepth.w = shadowTexcoord[3].z;
	 	realDepth -=  0.00025;
	 	
	 	//ESM SHADOWS
	 	shadows.x = tex2D(sDepth1, shadowTexcoord[0].xy ).r;
	 	shadows.y = tex2D(sDepth2, shadowTexcoord[1].xy ).r;
	 	shadows.z = tex2D(sDepth3, shadowTexcoord[2].xy ).r;
	 	shadows.w = tex2D(sDepth4, shadowTexcoord[3].xy ).r;
	 	shadows = saturate( exp( (exp(2*shadows)-exp(2*realDepth))*shadow_softness * maxDepth) );
	 	*/
	 	
	 	/*
	 	//PCF SHADOWS
	 	//Variable Kernel
	 	shadows.x = scGetShadowPCF(shadowTexcoord[0].xyz, sDepth1, inMapSize, 5);
	 	shadows.y = scGetShadowPCF(shadowTexcoord[1].xyz, sDepth2, inMapSize, 3);
	 	shadows.z = scGetShadowPCF(shadowTexcoord[2].xyz, sDepth3, inMapSize, 2);
	 	//shadows.w = scGetShadowPCF(shadowTexcoord[3].xyz, sDepth4, inMapSize, 3);
	 	
	 	//Bilinear
	 
	 	//shadows.x = scGetShadowPCFBilinear(shadowTexcoord[0].xyz, sDepth1, inMapSize);
	 	//shadows.y = scGetShadowPCFBilinear(shadowTexcoord[1].xyz, sDepth2, inMapSize);
	 	//shadows.z = scGetShadowPCFBilinear(shadowTexcoord[2].xyz, sDepth3, inMapSize);
	 	shadows.w = scGetShadowPCFBilinear(shadowTexcoord[3].xyz, sDepth4, inMapSize);
	 	*/
	 	
	 	/*
	 	[BRANCH]
	 	if(fDistance < pssm_splitdist_var[1] || numberOfSplits < 2)
	 		shadows.x = scGetShadowPCF(shadowTexcoord[0].xyz, sDepth1, inMapSize, 5);
	  	else if(fDistance < pssm_splitdist_var[2] || numberOfSplits < 3)
	 		shadows.y = scGetShadowPCF(shadowTexcoord[1].xyz, sDepth2, inMapSize, 3);
	  	else if(fDistance < pssm_splitdist_var[3] || numberOfSplits < 4)
	 		shadows.z = scGetShadowPCFBilinear(shadowTexcoord[2].xyz, sDepth3, inMapSize);
		else
	 		shadows.w = scGetShadowPCFBilinear(shadowTexcoord[3].xyz, sDepth4, inMapSize);
	 	
	 	//Put Splits together
	 	half fShadow;
	 	fShadow = lerp( shadows.x, shadows.y, pow(saturate(fDistance/pssm_splitdist_var[1]),50) );
	 	fShadow = lerp( fShadow, shadows.z, pow(saturate(fDistance/pssm_splitdist_var[2]),50) );
	 	fShadow = lerp( fShadow, shadows.w, pow(saturate(fDistance/pssm_splitdist_var[3]),50) );
	 	*/
	 	
	 	half fShadow = 1;
	 	[BRANCH]
	 	if(fDistance < pssm_splitdist_var[1] || numberOfSplits < 2)
	 		fShadow = scGetShadowPCF(shadowTexcoord[0].xyz, sDepth1, inMapSize, 5);
	  	else if(fDistance < pssm_splitdist_var[2] || numberOfSplits < 3)
	 		fShadow = scGetShadowPCF(shadowTexcoord[1].xyz, sDepth2, inMapSize, 3);
	  	else if(fDistance < pssm_splitdist_var[3] || numberOfSplits < 4)
	 		fShadow = scGetShadowPCFBilinear(shadowTexcoord[2].xyz, sDepth3, inMapSize);
		else
	 		fShadow = scGetShadowPCFBilinear(shadowTexcoord[3].xyz, sDepth4, inMapSize); //fShadow = saturate( exp( (exp(2*tex2Dlod(sDepth4, half4(shadowTexcoord[3].xy,0,0) ).r)-exp(2*shadowTexcoord[3].z)) * maxDepth * 0.004) );
	 	
	 	
	 	
	 	return fShadow;
	}
	
	half GetPssmHard(half4 shadowTexcoord[4], half fDistance, half maxDepth, half numberOfSplits, sampler sDepth1, sampler sDepth2, sampler sDepth3, sampler sDepth4, int inMapSize)
	{
		half4 shadows = 0;
		/*
	 	//ESM SHADOWS
	 	half4 realDepth;
	 	realDepth.x = shadowTexcoord[0].z;
	 	realDepth.y = shadowTexcoord[1].z;
	 	realDepth.z = shadowTexcoord[2].z;
	 	realDepth.w = shadowTexcoord[3].z;
	 	
	 	
	 	shadows.x = tex2Dlod(sDepth1, half4(shadowTexcoord[0].xy,0,0) ).r;
	 	shadows.y = tex2Dlod(sDepth2, half4(shadowTexcoord[1].xy,0,0) ).r;
	 	shadows.z = tex2Dlod(sDepth3, half4(shadowTexcoord[2].xy,0,0) ).r;
	 	shadows.w = tex2Dlod(sDepth4, half4(shadowTexcoord[3].xy,0,0) ).r;
	 	
	 	shadows = clamp((shadows-realDepth)*100000,0,1);
	 	
	 	 	
	 	//Put Splits together
	 	half fShadow;
	 	shadows.x = lerp( shadows.x, shadows.y, pow(saturate(fDistance/pssm_splitdist_var[1]),10) );
	 	shadows.x = lerp( shadows.x, shadows.z, pow(saturate(fDistance/pssm_splitdist_var[2]),10) );
	 	shadows.x = lerp( shadows.x, shadows.w, pow(saturate(fDistance/pssm_splitdist_var[3]),10) );
	 	*/
	 	//fShadow = 1;
	 	
	 	
	 	
	 	half fShadow;
	 	[BRANCH]
	 	if(fDistance < pssm_splitdist_var[1] || numberOfSplits < 2)
	 		fShadow = (tex2Dlod(sDepth1, half4(shadowTexcoord[0].xy,0,0) ).r < shadowTexcoord[0].z) ? 0.0 : 1.0;
	  	else if(fDistance < pssm_splitdist_var[2] || numberOfSplits < 3)
	 		fShadow = (tex2Dlod(sDepth2, half4(shadowTexcoord[1].xy,0,0) ).r < shadowTexcoord[1].z) ? 0.0 : 1.0;
	  	else if(fDistance < pssm_splitdist_var[3] || numberOfSplits < 4)
	 		fShadow = (tex2Dlod(sDepth3, half4(shadowTexcoord[2].xy,0,0) ).r < shadowTexcoord[2].z) ? 0.0 : 1.0;
		else
	 		fShadow = (tex2Dlod(sDepth4, half4(shadowTexcoord[3].xy,0,0) ).r < shadowTexcoord[3].z) ? 0.0 : 1.0;
	 	
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
		#ifndef MATPROJ
		#define MATPROJ
			float4x4 matProj;
		#endif
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
	
	#ifdef SHADOW
		#include <scNormalsFromDepth>
		#include <scNormalsFromPosition>
	#endif
	
	#ifdef SUN
		#include <scCalculatePosVSQuad>
	#endif
	#ifdef SHADOW //((SUN) && (SHADOW))
		
		#ifdef SUN
			#ifndef MATVIEWINV
			#define MATVIEWINV
				float4x4 matViewInv; //needed for PSSM, TEMP ONLY, remove this from shader!
			#endif
			float4x4 matTex[4]; // set up from the pssm script
			#include <scGetPssm>
		#endif
		
		#ifdef SPOT
			#include <scGetShadow>
		#endif
		float shadowBias = 0.0005;
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
	int shadowmapSize; //512, 1024 or 2048
	
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
			
			texture texShadowMask;
			sampler2D shadowMaskSampler = sampler_state
			{
				Texture = <texShadowMask>; 
			   MinFilter = POINT;
				MagFilter = POINT;
				MipFilter = NONE;
				AddressU = MIRROR;
				AddressV = MIRROR;
			};
			
			texture texShadowSun;
			sampler2D shadowSunSampler = sampler_state
			{
				Texture = <texShadowSun>; 
			   MinFilter = LINEAR;
				MagFilter = LINEAR;
				MipFilter = NONE;
				AddressU = MIRROR;
				AddressV = MIRROR;
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
	
	texture sc_map_brdf_bmap;
	sampler2D brdfSampler = sampler_state 
	{ 
	   Texture = <sc_map_brdf_bmap>; 
	   AddressU = CLAMP; 
	   AddressV = CLAMP;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
	/*
	#ifdef SUN
	float4 vecViewPort;
	texture sc_lights_mapShadowScatter64_bmap;
	sampler sc_lights_scatterTex = sampler_state 
	{ 
	   Texture = <sc_lights_mapShadowScatter64_bmap>; 
	   MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = WRAP;
		AddressV = WRAP;
		//BorderColor = 0xFFFFFFFF;
		//BorderColor = 0x00000000;
	};
	#endif
	*/
	
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
		//upsample from edge and expand phase
		#ifdef SUN
			#ifdef SHADOW
				//In.Tex.xy /= 8;
			#endif
		#endif
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
		
		#ifdef SUN
			//clip sky for better performance
			clip((1-gBuffer.w)-0.000001);
		#endif
	   
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
	   
	   
	   #ifdef SUN
	   	half3 Ln = mul(float4(vecSkill1.xzy,1),matView).xyz - posVS.xyz; //SUN
	   #else
	   	half3 Ln = mul(vecSkill1.xzy,matView).xyz - posVS.xyz;
	   #endif
	   //half3 Ln = 0 - posVS.xyz;
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
	   //#ifdef SUN
	   //	clip(dot(color.rgb,1)-0.001);
	   //#endif
	   
	   #ifdef SPECULAR
		   //fps hungry....
		   //half2 specularUV = half2( dot(Ln,Hn) , dot(gBuffer.xyz,Hn)-materialData.g ); //isotropic
		   //isotropic
		   //lightingUV = half2( dot(Ln,Hn) , dot(gBuffer.xyz,Hn)); //isotropic WHY IS THIS WRONG?
		   //lightingUV = half2( dot(gBuffer.xyz,Hn) , dot(Ln,Hn)); //isotropic WHY IS THIS WRONG?
		   //lightingUV.x = dot(Ln,Hn);
		   //lightingUV.y = dot(gBuffer.xyz, Hn);
		   //lightingUV.x = saturate( dot(Hn,gBuffer.xyz) );//pow(saturate( dot(Hn,gBuffer.xyz) ),materialData.g*255);
		   lightingUV.x = max(pow( ( dot(gBuffer.xyz,Hn) ),materialData.g*128)-0.02, 0);
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
		   color.a *= color.a;
		   //color.a = min(pow(color.a, 4),1);
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
			half shadowMask = tex2D(shadowMaskSampler, In.Tex.xy).r;
			[BRANCH]
			if(shadowMask == 0)
			{
				//PSSM---------------------
				//half4 posWorld = mul(float4(posVS,1), matViewInv);
				
				//gBuffer.xyz = NormalsFromPosition(posVS.xyz).xyz;
				//gBuffer.xyz = normalize(pow(gBuffer.xyz, 4));
				//gBuffer.z = -gBuffer.z;
				//gBuffer.xyz = normalize(gBuffer.xyz);
				
				half4 posWorld = mul(float4(posVS,1), matViewInv);
				//posWorld += ShadowOffset;
				//half4 posWorld = mul(float4(posVS + ShadowOffset,1), matViewInv);
				//posWorld.xyz += mul(float4(gBuffer.xyz,1), matViewInv).xyz * 0.01 * (1.0f/max((1-gBuffer.w),0.00001));
				//posWorld.xyz += ShadowOffset.xyz;
				
				//Generate PSSM Projection Coordinates
				half4 shadowTexcoord[4];
				shadowTexcoord[0] = shadowTexcoord[1] = shadowTexcoord[2] = shadowTexcoord[3] = half4(0,0,0,0);
				for(int i=0;i<vecSkill13.x;i++)
					shadowTexcoord[i] = mul(posWorld,matTex[i]);
				
//				posWorld = mul(float4(posVS + ShadowOffset ,1), matViewInv);
//				for(int i=0;i<vecSkill13.x;i++)
//					shadowTexcoord[i].z = mul(posWorld,matTex[i]).z;
				
				
				
				//gBuffer.xyz += NormalsFromPosition( posVS.xyz );
				//gBuffer.xyz = normalize(gBuffer.xyz);
//				half cosLightAngle = saturate(1- dot(Ln, gBuffer.xyz ));
//				float sinLightAngle = sqrt( 1.0 - cosLightAngle*cosLightAngle);
//		   		half slope = sinLightAngle / max(cosLightAngle,0.00001);
		   		
		 		
		 		
		 		//half bias =  0.0006f;// + (slope*0.0001f);
		 		
				shadowTexcoord[0].z -= shadowBias;
				shadowTexcoord[1].z -= shadowBias*2;
				shadowTexcoord[2].z -= shadowBias*3;
				shadowTexcoord[3].z -= shadowBias*4;
				
				//shadowTexcoord[1] = Plp;
				
//				half2 shadowScatter = tex2D(sc_lights_scatterTex, In.Tex.xy * (vecViewPort.xy/256) ).xy*2-1;
//				shadowScatter += tex2D(sc_lights_scatterTex, In.Tex.xy * (vecViewPort.xy/128) ).xy*2-1;
//				shadowScatter += tex2D(sc_lights_scatterTex, In.Tex.xy * (vecViewPort.xy/64) ).xy*2-1;
//				shadowScatter += tex2D(sc_lights_scatterTex, In.Tex.xy * (vecViewPort.xy/32) ).xy*2-1;
//				shadowScatter = normalize(shadowScatter);
//				
//				shadowTexcoord[0].xy += shadowScatter*0.00025;
//				shadowTexcoord[1].xy += shadowScatter*0.000125;
//				shadowTexcoord[2].xy += shadowScatter*0.0000625;
//				shadowTexcoord[3].xy += shadowScatter*0.0000625;
				
				
				//tex2D(shadowMaskSampler, In.Tex.xy).rgb;
				//half shadowMask = tex2D(shadowMaskSampler, In.Tex.xy).r;
				//if(shadowMask > 0 && shadowMask < 1)
				//	shadowMask = 0.5;
				
				
				//USE STENCIL MASKING INSTEAD! DYNAMIC BRANCHING DOESN'T WORK ON ALL MACHINES!
				//[BRANCH]
				//if(shadowMask == 1)
				//	color.rgb *= GetPssm(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);
				//[BRANCH]
				//if(shadowMask == 0)
					color.rgb *= GetPssmHard(shadowTexcoord, posVS.z, vecSkill1.w, vecSkill13.x,  shadowDepth1Sampler, shadowDepth2Sampler, shadowDepth3Sampler, shadowDepth4Sampler, shadowmapSize);
				//else
				//	color.rgb *= 1;
				
				//-------------------------
			}
			else if(shadowMask == 1)
				color.rgb *= tex2Dlod(shadowSunSampler, half4(In.Tex.xy,0,0) ).rgb;
			#endif
		#endif
		
		
		#ifdef SUN
			color.rgb *= sun_light_var*0.01; //brightness based on sun_light
		#endif
		
		
		/*
		//BRDF test
		//lightingUV = half2( (dot(Vn, gBuffer.xyz)+OffsetUV.x) , ((dot(Ln, gBuffer.xyz) + 1) * 0.5)+OffsetUV.y );
		half2 lightingUV;
		lightingUV.x = saturate(dot(Vn, gBuffer.xyz));
		lightingUV.y = saturate(dot(Ln, gBuffer.xyz) * 0.5 + 0.5);
		color.rgb = tex2D(brdfSampler, lightingUV).rgb;
		//color.rgb = lightingUV.x;
		//color.rgb = pow(color.xyz, 2.2);
		*/
		
		
		
		color = PackLighting(color.rgb, color.a);
		
	
	   return color;
	}
	
	#ifdef SUN
	half4 sunBackdrop():COLOR
	{
		return PackLighting(half3(1,1,1), 0);
	}
	#endif
		
	technique t1
	{
		
		#ifdef SUN
		pass pSunBackdrop
		{
			PixelShader = compile ps_2_0 sunBackdrop();
			AlphablendEnable = False;
			ZWriteEnable = FALSE;
			
//			StencilEnable = true;
//      	StencilPass = REPLACE;
//      	StencilRef = 201;
		}
		#endif
		
		
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
				ZEnable = FALSE;
				//StencilEnable = true;
      		//StencilPass = REPLACE;
      		//StencilRef = 202;
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
		    	#ifndef SUN
		    		ZEnable = true;
		    	#else
		    		ZEnable = false;
		    	#endif
			#endif
			
			//SRGBWriteEnable = true;
			
			
		
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
	
	#ifdef TRANSPARENT
		#define PROJCOORDS
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
	#ifdef BONES
		#include <bones>
	#endif
	
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
	
	#ifndef FALPHA
	#define FALPHA
		float fAlpha;
	#endif
	
	#ifndef MATERIALID
	#define MATERIALID
		float materialID;
	#endif
	
	#ifdef PROJCOORDS
		#ifndef VECVIEWPORT
		#define VECVIEWPORT
			float4 vecViewPort;
		#endif
	#endif
	

	
	texture SKIN1;
	texture SKIN2;
	texture SKIN3;
	texture SKIN4;
	
	#ifdef TRANSPARENT
		#ifndef ALPHACLIP
			#define ALPHACLIP 0.001
		#endif
		texture sc_map_stipplingMask_bmap;
		sampler2D stipplingMaskSampler = sampler_state
		{
			Texture = <sc_map_stipplingMask_bmap>;
			MinFilter = POINT;
			MagFilter = POINT;
			MipFilter = NONE;
			AddressU = WRAP;
			AddressV = WRAP;
		};
	#endif
	
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
	
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = WRAP;
		AddressV = WRAP;
		
		//SRGBTexture = true;
		
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
		#ifdef BONES
			int4 BoneIndices: BLENDINDICES;
			float4 BoneWeights: BLENDWEIGHT;
		#endif
		#ifdef CUSTOM_VS_INPUT_EXTEND
			CUSTOM_VS_INPUT_EXTEND
		#endif
	};
	
	struct vsOut
	{
		float4 Pos : POSITION;
		#ifdef PROJCOORDS
			float4 Pos2D: TEXCOORD0;
		#else
			float Pos2D : TEXCOORD0;
		#endif
		float4 Tex : TEXCOORD1;
		float3 Normal : TEXCOORD2;
		#ifdef NORMALMAPPING
			float3 Tangent : TEXCOORD3;
			float3 Binormal : TEXCOORD4;
		#endif
		#ifdef CUSTOM_VS_OUTPUT_EXTEND
			CUSTOM_VS_OUTPUT_EXTEND
		#endif
	};
	
	struct psOut
	{
	    float4 NormalsAndDepth : COLOR0;
	    half4 AlbedoAndEmissiveMask : COLOR1;
	    float4 MaterialData : COLOR2;
	    //float4 lightmapAnd : COLOR3;
	    
	    #ifdef CUSTOM_PS_OUTPUT_EXTEND
			CUSTOM_PS_OUTPUT_EXTEND
		 #endif
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
			#ifdef BONES
				Out.Pos = DoBones(In.Pos,In.BoneIndices,In.BoneWeights);
				Out.Pos = mul( Out.Pos , matWorldViewProj);
			#else
				Out.Pos = mul(In.Pos,matWorldViewProj);
			#endif
		#else
			Out.Pos = Custom_VS_Position(In);
		#endif
		//Z Depth and optional Projective Texcoords
		#ifdef PROJCOORDS
			Out.Pos2D.x = mul(In.Pos,matWorldView).z; //HAVOC: CHANGE BACK IF YOU GET DEPTHMAP ERRORS OR POSITION ERRORS!
			Out.Pos2D.yzw = Out.Pos.xyw;	
		#else
			Out.Pos2D = mul(In.Pos,matWorldView).z; //HAVOC: CHANGE BACK IF YOU GET DEPTHMAP ERRORS OR POSITION ERRORS!
		#endif
		
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
	
	
	/*
	texture sc_map_litSphere_bmap;
	sampler2D litSphereSampler = sampler_state 
	{ 
	   Texture = <sc_map_litSphere_bmap>; 
	   AddressU = CLAMP; 
	   AddressV = CLAMP;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	*/
	
	
	psOut mainPS(vsOut In)
	{
		psOut PSOut = (psOut)0;
		
		#ifdef CUSTOM_PS_TEX
			In.Tex = Custom_PS_Tex(In);
		#endif
		
		#ifdef PROJCOORDS
			half2 projCoord;
			projCoord.x = In.Pos2D.y/In.Pos2D.w/2.0f +0.5f + (0.5/vecViewPort.x);
   		projCoord.y = -In.Pos2D.z/In.Pos2D.w/2.0f +0.5f + (0.5/vecViewPort.y);
		#endif
		
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
		
		/*
		//alphatest
		#ifndef CUSTOM_PS_ALPHA
			#ifdef ALPHA
				clip(SKIN_ALPHA-fAlpha);
			#endif
		#else
			//CUSTOM CODE
			clip( Custom_PS_Alpha(In, SKIN_ALPHA) );
		#endif
		
		//alpha stippling
		#ifndef CUSTOM_PS_TRANSPARENT
			#ifdef TRANSPARENT
				clip(SKIN_ALPHA-fAlpha);
			#endif
		#else
			//CUSTOM CODE
			clip( Custom_PS_Transparent(In, SKIN_ALPHA) );
		#endif
		*/
		
		#ifdef ALPHA
			#ifdef TRANSPARENT
				
				SKIN_ALPHA *= tex2D(stipplingMaskSampler, projCoord*vecViewPort.xy*0.5).g * fAlpha;
				#ifdef TRANSPARENTALPHACLIP
					clip(SKIN_ALPHA - fAlpha);
				#else
					clip(SKIN_ALPHA - ALPHACLIP);
				#endif
			#else
				#ifdef CUSTOM_PS_ALPHA
					clip(Custom_PS_Alpha(In, SKIN_ALPHA));
				#else
					clip(SKIN_ALPHA-(1-fAlpha));
				#endif
			#endif
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
			PSOut.NormalsAndDepth.w = (In.Pos2D.x/clipFar);
		#else
			//CUSTOM CODE
			PSOut.NormalsAndDepth.w = Custom_PS_Depth(In);
		#endif
		
		//albedo
		#ifndef CUSTOM_PS_DIFFUSE
			#ifdef USE_VEC_DIFFUSE
				#ifndef OBJECTCOLOR_A7
					PSOut.AlbedoAndEmissiveMask.xyz = SKIN_ALBEDO * vecDiffuse;
				#else
					PSOut.AlbedoAndEmissiveMask.xyz = SKIN_ALBEDO;
				#endif
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
		
		#ifdef ALPHA
			#ifdef TRANSPARENT
				PSOut.MaterialData.w = SKIN_ALPHA; //alpha value //environment map ID - not used yet
			#endif
		#endif
		
		//Extend Pixelshader
		#ifdef CUSTOM_PS_EXTEND
			PSOut = Custom_PS_Extend(In, PSOut);
		#endif
		
		
		/*
		//litpshere test
		PSOut.NormalsAndDepth.xyz = normalize(PSOut.NormalsAndDepth.xyz)*0.5+0.5;
		PSOut.NormalsAndDepth.y = 1-PSOut.NormalsAndDepth.y;
		PSOut.AlbedoAndEmissiveMask.xyz = tex2D(litSphereSampler, PSOut.NormalsAndDepth.xy).rgb;
		*/
		
		//Packing---------------------
		//PSOut.normalsAndDepth.xy = PackNormals( mul((In.Normal.rgb) ,matView) ); //normals
		PSOut.NormalsAndDepth.xy = PackNormals(normalize(PSOut.NormalsAndDepth.xyz)); //normals
		//depth
		PSOut.NormalsAndDepth.zw = PackDepth(PSOut.NormalsAndDepth.w);
		
		//PSOut.AlbedoAndEmissiveMask.xyz = pow(PSOut.AlbedoAndEmissiveMask.xyz, 2.2);
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
		
		#ifndef TARGET_VS
			#define TARGET_VS vs_2_0
		#endif
		#ifndef TARGET_PS
			#define TARGET_PS ps_2_a
		#endif
		
		
		pass p0
		{
			cullmode = ccw;
			alphablendenable = false;
			VertexShader = compile TARGET_VS mainVS();
			PixelShader = compile TARGET_PS mainPS();
			FogEnable = False;
			
			#ifdef ZPREPASS
				ColorWriteEnable = RED | GREEN | BLUE | ALPHA;
				zenable = true;
				zwriteenable = false;
		    	ZFunc = LESSEQUAL;
		   #else
		   	zwriteenable = true;
			#endif
			
			/*
			#ifdef TRANSPARENT
				alphablendenable = true;
				BlendOp = Add;
				//SrcBlend = InvDestColor;
				//DestBlend = One;
				//SrcBlendAlpha = InvDestAlpha;//InvDestAlpha;
				//DestBlendAlpha = One;
			#endif
			*/
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
	#ifdef BONES
		#include <bones>
	#endif
	
	#ifndef MATWORLD
	#define MATWORLD
		float4x4 matWorld;
	#endif
	#ifndef MATVIEWPROJ
	#define MATVIEWPROJ
		float4x4 matViewProj;
	#endif
	#ifndef MATSPLITVIEWPROJ
	#define MATSPLITVIEWPROJ
		float4x4 matSplitViewProj;
	#endif
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
	#ifndef FALPHA
	#define FALPHA
		float fAlpha;
	#endif
	#ifndef SHADOWMAPMODE
	#define SHADOWMAPMODE
		float shadowmapMode = 1; //0 = sun | 1 = local lights | auto-set by code
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
		#ifdef BONES
			int4 BoneIndices: BLENDINDICES;
			float4 BoneWeights: BLENDWEIGHT;
		#endif
	};
	
	struct vsOut
	{
		float4 Pos : POSITION;
		float2 Pos2D : TEXCOORD0;
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
	//float4x4 _matViewProj; //set by code |we can't use the default matViewProj here as we need to support both sun and local lights
	
	vsOut mainVS(vsIn In)
	{
		vsOut Out = (vsOut)0;	
		
		/*
		float4 pos = mul(In.Pos,matWorldViewProj);
		Out.Pos2D = pos.z;
		Out.Pos = pos;//mul(pos,matProj);
		Out.Tex = In.Tex;	
		*/
		
		//dead ugly...but we have to serve both sun and local shadowmaps...
		matWorldViewProj = lerp( mul(matWorld, matSplitViewProj), matWorldViewProj, shadowmapMode );
		matViewProj = lerp(matSplitViewProj, matViewProj, shadowmapMode);
		
		#ifndef CUSTOM_VS_POSITION
			#ifdef BONES
				Out.Pos = DoBones(In.Pos, In.BoneIndices, In.BoneWeights);
				Out.Pos = mul( Out.Pos , matWorldViewProj);
			#else
				Out.Pos = mul(In.Pos,matWorldViewProj);
			#endif
		#else
			Out.Pos = Custom_VS_Position(In);
		#endif
		
		//support both local and sun shadows (sun shadowmap needs Out.Pos.w whereas local lights need clipFar)
		Out.Pos2D = float2(Out.Pos.z, lerp(Out.Pos.w, clipFar, shadowmapMode)); 
		Out.Tex = In.Tex;	
		
		#ifdef CUSTOM_VS_Extend
			Out = Custom_VS_Extend(In, Out);
		#endif
		
		return Out;
		
	}
	
	half4 CalculateShadowDepth(float2 Pos2D_Z)
	{
		//half depth = ((Pos2D_Z)/vecSkill1.w);
		//half depth = ((Pos2D_Z)/clipFar);
		half depth = Pos2D_Z.x/Pos2D_Z.y;
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
				clip(tex2D(sc_skin1Sampler,In.Tex).a-(1-fAlpha));
			#endif
		#else
			#ifdef ALPHA
				clip( Custom_PS_Alpha(In, tex2D(sc_skin1Sampler,In.Tex).a) );
			#else
				clip( Custom_PS_Alpha(In, 1) );
			#endif
		#endif
		
		Out.Color = CalculateShadowDepth(In.Pos2D.xy);
		
		#ifdef CUSTOM_PS_EXTEND
			Out = Custom_PS_Extend(In, Out);
		#endif
		
		return Out;
	}
	
	psOut mainPS_lm(vsOut In)
	{
		psOut Out = (psOut)0;
		
		Out.Color = CalculateShadowDepth(In.Pos2D.xy);
		
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
//section: end
#endif
