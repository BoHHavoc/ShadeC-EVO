#define POINT
//#define SPECULAR
#define PROJECTION

#include <scLights>


/*
#include <scUnpackNormals>
#include <scUnpackDepth>
#include <scPackLighting>

bool AUTORELOAD;

float4x4 matProj;
float4x4 matWorldView;
float4x4 matView;
float4x4 matViewInv;
float4x4 matMtl; //LightMatrix (Cookie, Shadows)

float4 vecViewPort;
float4 vecViewPos;
float4 vecViewDir;

texture mtlSkin1; //gBuffer
texture mtlSkin2; //projection

float4 vecSkill1; //lightpos (xyz), lightrange (w)
float4 vecSkill5; //light color, xyz

sampler gBufferSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
};

sampler projSampler = sampler_state 
{ 
   Texture = <mtlSkin2>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

struct vsOut
{
	float4 Pos : POSITION;
	float3 projCoord : TEXCOORD0;
	float4 posVS : TEXCOORD1;
};

struct vsIn
{
	float4 Pos : POSITION;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.posVS = mul(In.Pos, matWorldView);
	Out.Pos = mul(Out.posVS,matProj);
   Out.projCoord = Out.Pos.xyw;
   
	
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
   half4 gBuffer = tex2D(gBufferSampler, projTex);
   gBuffer.z = UnpackDepth(gBuffer.zw);
   
   //clip pixel which can't be seen
   //float junk = ((In.posVS.z/vecSkill5.w))-(gBuffer.z);//length(gBuffer.z-(In.posVS.z/vecSkill5.w));
   clip(((In.posVS.z/vecSkill5.w))-(gBuffer.z));
   
   //decode normals
   half3 normal = UnpackNormals(gBuffer.xy);
      
   //get view pos
   float3 vFrustumRayVS = In.posVS.xyz * (vecSkill5.w/In.posVS.z);
   float3 posVS = gBuffer.z * vFrustumRayVS;
   
   
   //half3 Ln = mul(float3(vecSkill9.x,vecSkill9.z,vecSkill9.y)-vecViewPos.xyz,matView) - posVS.xyz;
   //half3 Ln = mul(vecSkill1.xzy,matView) - posVS.xyz;
   half3 Ln = mul(vecSkill1.xzy,matView) - posVS.xyz;
   half att = saturate(1-length(Ln)/vecSkill1.w);
   clip(att-0.0001);
   
   Ln = normalize(Ln);
      
   half diff = saturate(dot(Ln, normal));
   //half3 refl = normalize(2*diff*normal - Ln);
   //half spec = 0;//pow( saturate( dot(refl, Vn)), 2);
   
   //half2 light = lit(dot(Ln,normal), dot(Hn, normal),15).yz;
	
	diff = diff * att;
	color.rgb = diff;
   //color.rgb = diff * vecSkill5.xyz * texCUBE(projSampler, mul(mul(Ln, matViewInv),matMtl));//vecSkill5.xyz;
   
   //color.rgb /= 2;
   //color.a = light.y * length(color.rgb);
   color.a = 0;
   
   
   //Ln = mul(half4(Ln,0), matViewInv).rgb;
   Ln = mul(mul(half4(Ln,0), matViewInv),matMtl).rgb;
	color.rgb = texCUBE(projSampler, -Ln ).rgb;
 
   
   color = PackLighting(color.rgb, color.a);
   
   return color;
}

technique t1
{
	
	pass p0
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
	}
}
*/

