bool AUTORELOAD;
bool PASS_SOLID;

#include <scPackDepth>

//float4x4 matWorldViewProj;
float4x4 matWorld;
float4x4 matWorldView;
float4x4 matSplitViewProj;
//float4x4 matProj;

float4 vecSkill1; //depthmap stuff, x = | y = alpha clip | z = | w = maxDepth
float4 vecSkill5; //xyz = lightpos | w =
float fAlpha;

texture entSkin1;

sampler2D ColorSampler = sampler_state
{
	Texture = <entSkin1>;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct vsOut
{
	float4 Pos : POSITION;
	float2 Pos2D : TEXCOORD0;
	float2 Tex : TEXCOORD1;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.Pos = mul(In.Pos,matWorld);
	Out.Pos = mul(Out.Pos, matSplitViewProj);
	//Out.Pos = mul(In.Pos, matSplitViewProj);
	Out.Pos2D = Out.Pos.zw;
	Out.Tex = In.Tex;	
	
	return Out;
	
}

half4 CalculateShadowDepth(float2 Pos2D)
{
	half depth = (Pos2D.x/Pos2D.y);
	//half depth = (Pos2D.x/vecSkill1.w);
	depth += depth*vecSkill1.z;
	//half depth = 1-(( (In.Pos2D)/vecSkill1.w ) + vecSkill1.z);
	
	/*
	half4 outDepth = 0;
	outDepth.x=floor(depth*255)/255;
	outDepth.y=floor((depth-outDepth.x)*255*255)/255;
	*/
	
	
	return depth;//exp(2*depth);
	//half3 Ln = vecSkill5.xzy - In.PosW.xyz;
   //half att = saturate(1-length(Ln)/vecSkill1.w);
}

half4 mainPS(vsOut In):COLOR0
{
	//alpha clip
	clip(tex2D(ColorSampler,In.Tex).a-vecSkill1.y-(1-fAlpha));
	//return tex2D(ColorSampler,In.Tex);
	return CalculateShadowDepth(In.Pos2D);
}

half4 mainPS_lm(vsOut In):COLOR0
{
	//return tex2D(ColorSampler,In.Tex);
	return CalculateShadowDepth(In.Pos2D);
}

technique t1
{
	pass p0
	{
		//ColorWriteEnable = RED;
		cullmode = ccw;
		FogEnable = False;
		alphablendenable = false;
		zwriteenable = true;
		
		vertexshader = compile vs_2_0 mainVS();
		pixelshader = compile ps_2_0 mainPS();
		
	}
}

technique t1_lm
{
	pass p0
	{
		//ColorWriteEnable = RED;
		cullmode = ccw;
		FogEnable = False;
		alphablendenable = false;
		zwriteenable = true;
		vertexshader = compile vs_2_0 mainVS();
		pixelshader = compile ps_2_0 mainPS_lm();
	}
}