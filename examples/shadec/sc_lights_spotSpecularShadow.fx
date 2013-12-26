#define SPOT
#define SPECULAR
#define SHADOW

#include <scLights>


/*
#include <scUnpackNormals>
#include <scUnpackDepth>
#include <scGetShadow>
#include <scPackLighting>
//#include <scUnpackSpecularData>

//#define STENCILMASK

bool AUTORELOAD;
bool PASS_SOLID;

float4x4 matProj;
float4x4 matWorldView;
float4x4 matView;
float4x4 matMtl; //LightMatrix (Cookie, Shadows, Dir)

float4 vecViewPort;
float4 vecViewDir;

texture mtlSkin1; //normals (xy) depth (zw)
texture mtlSkin2; //projectionmap
texture mtlSkin3; //shadowmap
texture mtlSkin4; //material id (x), specular power (y), specular intensity (z), environment map id (w)
texture texBRDFLut; //lighting equations stored in volumetric texture
texture texMaterialLUT; //material data texture -> x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound

float4 vecSkill1; //lightpos (xyz), lightrange (w)
float4 vecSkill5; //light color (xyz), scene depth (w)
float4 vecSkill9; //light dir (xyz), stencil ref (w)
//float4 vecTime;

//static half2 blurSize_softness = half2(0.001, 3000);

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

sampler1D materialLUTSampler = sampler_state 
{ 
   Texture = <texMaterialLUT>; 
   AddressU = WRAP; 
	AddressV = WRAP;
	AddressW = WRAP;
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
};

sampler3D brdfSampler = sampler_state 
{
	Texture = <texBRDFLut>;
   AddressU = CLAMP; 
	AddressV = CLAMP;
	AddressW = WRAP;
	MIPFILTER = NONE;
	MINFILTER = LINEAR; //fade between brdfs
	MAGFILTER = LINEAR; //fade between brdfs
	//MINFILTER = NONE; // dont fade between brdfs
	//MAGFILTER = NONE; // dont fade between brdfs
};

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

struct vsOut
{
	float4 Pos : POSITION;
	float3 projCoord : TEXCOORD0;
	float4 posVS : TEXCOORD1;
	half2 texCoord : TEXCOORD2;
	//nointerpolation float3 projCoord : TEXCOORD0;
	//nointerpolation float4 posVS : TEXCOORD1;
	//nointerpolation half2 texCoord : TEXCOORD2;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 texCoord : TEXCOORD0;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.posVS = mul(In.Pos, matWorldView);
	Out.Pos = mul(Out.posVS,matProj);
   Out.projCoord = Out.Pos.xyw;
   
   Out.texCoord = In.texCoord;
   
	
	return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	//je nach tiefe clippen...
	//discard;
	
	half4 color = 0;
	
	//projective texcoords
	float2 projTex;
	projTex.x = In.projCoord.x/In.projCoord.z/2.0f +0.5f + (0.5/vecViewPort.x);
   projTex.y = -In.projCoord.y/In.projCoord.z/2.0f +0.5f + (0.5/vecViewPort.y);
   
   //get gBuffer   
   float4 gBuffer = tex2D(normalsAndDepthSampler, projTex);
   gBuffer.w = UnpackDepth(gBuffer.zw);
   
   //get specular data
   //half2 glossAndPower = UnpackSpecularData(tex2D(emissiveAndSpecularSampler, projTex).w);
   
   
   //clip pixels which can't be seen
   //not really needed anymore due to correct zbuffer culling :)
   //float junk = ((In.posVS.z/vecSkill5.w))-(gBuffer.w);//length(gBuffer.w-(In.posVS.z/vecSkill5.w));
   //clip(((In.posVS.z/vecSkill5.w))-(gBuffer.w));
   
   
   //decode normals
   gBuffer.xyz = UnpackNormals(gBuffer.xy);
      
   //get view pos
   //float3 vFrustumRayVS = In.posVS.xyz * (vecSkill5.w/In.posVS.z);
   float3 posVS = gBuffer.w * In.posVS.xyz * (vecSkill5.w/In.posVS.z);
   
   //spotlight projection/cone
   //half4 lightProj = mul( half4(posVS,1), mul(matViewInv,matMtl) );
   half4 lightProj = mul( half4(posVS,1), matMtl );
   //half3 projection = tex2D(projSampler, lightProj.xy/lightProj.z).rgb;
   color.rgb = tex2D(projSampler, lightProj.xy/lightProj.z).rgb;
  	
   
   half3 Ln = mul(vecSkill1.xzy,matView).xyz - posVS.xyz;
   //half att = saturate(1-length(Ln)/vecSkill1.w);
   //clip(att*dot(color.rgb,1)-0.001);
   color.rgb *= saturate(1-length(Ln)/vecSkill1.w); //attenuation
   clip(dot(color.rgb,1)-0.001);
   Ln = normalize(Ln);
   //half backprojection = saturate(dot( mul(-vecSkill9.xzy,matView) , Ln));
   clip(saturate(dot( mul(-vecSkill9.xzy,matView) , Ln))-0.0001); //clip backprojection
   //half3 Vn = normalize(matView[0].xyz - posVS);//normalize(IN.WorldView);
   half3 Vn = normalize(vecViewDir.xyz - posVS); //same as above but less arithmetic instructions
   half3 Hn = normalize(Vn + Ln);
   
   //half4 brdfData = (tex2D(brdfDataSampler, projTex)); //get brdf gBuffer
   //half2 light = lit(dot(Ln,gBuffer.xyz), dot(Hn, gBuffer.xyz),brdfData.g*255).yz;
	//color.rgb = light.x * vecSkill5.xyz * att;//vecSkill5.xyz;
   //color.a = light.y;// * glossAndPower.x;
   //color.rgb = dot(Ln,gBuffer.xyz)*att*vecSkill5.xyz;
   
   
   //material data
   half2 materialData = (tex2D(materialDataSampler, projTex)).xy; //get brdf index and specular power
   //half4 brdfData1 = tex3D( matData1Sampler,half3(In.texCoord, materialData.r) ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
   half4 brdfData1 = tex1D( materialLUTSampler, materialData.r ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
   //brdfData.r = brdfData1.r;
     
   half2 OffsetUV;
   OffsetUV.x = (brdfData1.y-0.5)*2; //diffuse roughness
   OffsetUV.y = (brdfData1.z-0.5)*2; //diffuse wraparound/velvety
   //half2 nuv = float2((0.5+saturate(dot(Ln,gBuffer.xyz)+OffsetUV.x)/2.0),	saturate(1.0 - (0.5+dot(gBuffer.xyz,Vn)/2.0)) + OffsetUV.y); //diffuse brdf uv, no options
  	half2 lightFuncUV = half2( (dot(Vn, gBuffer.xyz)+OffsetUV.x) , ((dot(Ln, gBuffer.xyz) + 1) * 0.5)+OffsetUV.y ); //diffuse brdf uv. options (OffsetUV.x/V)
  	half4 lighting = tex3D( brdfSampler,half3(lightFuncUV , brdfData1.r) );
   color.rgb *= lighting.xyz * vecSkill5.xyz;
   
   //shadows
   //half shadowdepth = saturate(1-(lightProj.z/vecSkill1.w));
   //half2 noise = (tex2D(shadowNoiseSampler, (lightProj.xy/lightProj.z)*1000).xy*2-1);
   //lightProj.xy += noise*0.05;//*(1-shadowdepth);
   //lightProj.xy -= (1-noise)*0.05;//*(1-shadowdepth);
   //color.rgb *= GetShadow(shadowSampler, lightProj.xy/lightProj.z, ((lightProj.z/vecSkill1.w)));
   color.rgb *= GetShadow(shadowSampler, lightProj.xy/lightProj.z, lightProj.z/vecSkill1.w, vecSkill1.w);
   
   
   //additional clipping based on diffuse lighting. clip non-lit parts
   clip(dot(color.rgb,1)-0.003);
   
   //fps hungry....
   lightFuncUV = ( dot(Ln,Hn) , dot(gBuffer.xyz,Hn) ); //isotropic
   //anisotropic
   	//diffuseUV.x = 0.5+dot(Ln,gBuffer.xyz)/2.0;
   	//diffuseUV.y = 1-(0.5+dot(gBuffer.xyz,Hn)/2.0);
   lighting.w = tex3D( brdfSampler, half3(lightFuncUV, brdfData1.r) ).a;
   color.a = pow(lighting.w+0.005, materialData.g*255);
   //...
   //conventional specular
   //color.a = pow(dot(gBuffer.xyz,Hn),materialData.g*255);
   
    
   //color.rgb = pow(lighting.xyz,diffuseRoughness) * att * vecSkill5.xyz;
   //color.a = (saturate(pow(specular,materialData.g*255)));
      
	//pack
	//color.rgb /= 1.5;
	//color.rgb += brdfData1.rgb*color.rgb;
	//color.rgb=GetShadow(shadowSampler, lightProj.xy/lightProj.z, lightProj.z/vecSkill1.w, vecSkill1.w);
	
	color = PackLighting(color.rgb, color.a);
	
   return color;
}

technique outside
{
	#ifdef STENCILMASK
	//set stencil
	pass stencil
	{
		VertexShader = NULL;
		PixelShader = NULL;
		
		ColorWriteEnable = 0x0;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESS;
		StencilEnable = TRUE;
		StencilRef = vecSkill9.w;
		StencilFunc = ALWAYS;
		StencilPass = REPLACE;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilMask		= 0xFFFFFFFF;
      StencilWriteMask = 0xFFFFFFFF;
		CullMode = CCW;      
		
		// Disable writing to the frame buffer
      AlphaBlendEnable	= true;
      SrcBlend = Zero;
      DestBlend = One;
      
      
	}
	#endif
	
	pass lighting
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_a mainPS();
		
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
		
		#ifdef STENCILMASK
		//stencil test
		StencilFunc = EQUAL;
		StencilPass = KEEP;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilRef = vecSkill9.w;
		StencilEnable = TRUE;
		StencilMask		= 0xFFFFFFFF;
      StencilWriteMask = 0xFFFFFFFF;
      #endif
		
    	

	}
}
*/
