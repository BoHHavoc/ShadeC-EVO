#include <scUnpackDepth>
#include <texture>
//#include <scUnpackNormals>

bool AUTORELOAD;
bool TRANSLUCENT;

float4x4 matProj;
float4x4 matWorldView;

float4 vecViewPort;
float clipFar; //main view clip_far
float4 data1; //x = camera fade distance, y = softness
float4 data2; //xyz = rgb noise tex scale factor, w = noise tex movement speed
float4 data3; //xyz = fog color
float fAlpha;
float4 vecTime;


texture entSkin1; //color + alpha
texture texNormalsAndDepth;

sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <texNormalsAndDepth>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

sampler2D spriteSkinSampler = sampler_state
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
	half3 Tex : TEXCOORD0;
	float4 projCoord : TEXCOORD1;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.projCoord = mul(In.Pos,matWorldView);
   Out.Pos = mul(Out.projCoord, matProj);
   Out.projCoord.xyw = Out.Pos.xyw;
   
   Out.Tex.xy = DoTexture(In.Tex.xy);
   Out.Tex.z = (vecTime.w/5000)*data2.w;

	return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	//PixelToFrame Out = (PixelToFrame)0;
	
	float2 projTex;
	projTex.x = In.projCoord.x/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.x);
   projTex.y = -In.projCoord.y/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.y);
	
	half4 gBuffer = tex2D(normalsAndDepthSampler,projTex.xy);
	half sceneDepth = UnpackDepth(gBuffer.zw);
	
	half4 color = half4(data3.xyz, tex2D(spriteSkinSampler, In.Tex.xy).a);
	color.a *= fAlpha * saturate(In.projCoord.z/data1.x) * saturate( ((sceneDepth*clipFar)/data1.y) - (In.projCoord.z)/data1.y );
	
	//Out.color.rgb = vecSkill1.xyz;
	
	half3 noise = 0;
	noise.r = tex2D(spriteSkinSampler,float2(In.Tex.x-In.Tex.z*2, In.Tex.y-In.Tex.z)*data2.x).r;
	noise.g = tex2D(spriteSkinSampler,float2(In.Tex.x-In.Tex.z*2, In.Tex.y+In.Tex.z)*data2.y).g;
	noise.b = tex2D(spriteSkinSampler,float2(In.Tex.x+In.Tex.z*4, In.Tex.y+In.Tex.z*4)*data2.z).b;
	
	color.a -= (noise.r*noise.g*noise.b);
	color.a = saturate(color.a);
	
	return color;
}


technique t1
{
	
	pass p0
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();

		//BlendOp = RevSubtract;
		ZWriteEnable = FALSE;
		ZEnable = true;
		ZFunc = LESSEQUAL;
		//ZFunc = ALWAYS;
		//StencilEnable = FALSE;
		AlphaBlendEnable = TRUE;
		
		//AlphaBlendEnable = True;
		//SrcBlend = 5;
		//DestBlend = 2;
	}

}