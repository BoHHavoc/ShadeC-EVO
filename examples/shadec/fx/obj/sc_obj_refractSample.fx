#include <scUnpackDepth>

bool AUTORELOAD;

float4x4 matWorldView;
float4x4 matWorld;
float4x4 matProj;

float4 vecViewPort;
float4 vecViewPos;

float softIntersectionSmoothness = 10;
float refractStrength = 1;
float clipFar;
//float4 data1; //y = soft intersection smoothness

texture entSkin1;
sampler skin1Sampler=sampler_state
{
	texture=<entSkin1>;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
   addressu=WRAP;
   addressv=WRAP;
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

struct vsOut
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
	float4 projCoord : TEXCOORD1;
	float3 worldPos : TEXCOORD2;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.projCoord = mul(In.Pos, matWorldView); //linear depth
	Out.Pos = mul(Out.projCoord,matProj);
   Out.projCoord.xyw = Out.Pos.xyw; //projective texcoords
   Out.worldPos = mul(In.Pos, matWorld).xyz;
   
   Out.Tex = In.Tex;
	
	return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	float refractStrength = refractStrength / distance(In.worldPos.xyz,vecViewPos.xyz);
	
	//projective texcoords
	In.projCoord.x = In.projCoord.x/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.x);
   In.projCoord.y = -In.projCoord.y/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.y);
   
   //get depth from gBuffer
   float texDepth = UnpackDepth(tex2D(normalsAndDepthSampler, In.projCoord.xy).zw);
   
	//soft intersection
	float softIntersection = saturate( ((texDepth*clipFar)/softIntersectionSmoothness) - (In.projCoord.z)/softIntersectionSmoothness );
	
	//get normalmap
	float2 normal = ( tex2D(skin1Sampler,In.Tex).xy-0.5f ) * 2;
   
   //get refraction
   float3 refraction=tex2D(sceneSampler,(In.projCoord.xy)-refractStrength*normal.xy).xyz;
   
   //finish up
   half4 result = 0;
   result.xyz = refraction;
   result.a = softIntersection;
	
   return result;
}

technique t1
{
	pass p0
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
		alphablendenable = TRUE;
		cullmode = none;
		
		ZEnable = true;
		ZFunc = LESSEQUAL;
	}
}

