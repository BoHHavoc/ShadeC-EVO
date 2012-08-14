bool AUTORELOAD;

float4x4 matWorldView;
float4x4 matProj;

float4 vecViewPort;

texture entSkin1; //normalmap + alpha
texture TargetMap; //scene
texture mtlSkin1; //scene depth

float4 vecSkill1; //yzw filled by SC_MYTEXMOVE
float4 vecSkill5; //xyz filled by SC_MYREFRCOL | w = view.clip_far
float4 vecSkill9; //xyz filled by entity position
float4 vecSkill17; // xy resize for sceneSampler

sampler2D sceneSampler = sampler_state
{
	Texture = <TargetMap>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

sampler depthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

sampler2D normalSampler = sampler_state
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
	float2 Tex : TEXCOORD0;
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
	
	Out.projCoord = mul(In.Pos, matWorldView); //linear depth
	Out.Pos = mul(Out.projCoord,matProj);
   Out.projCoord.xyw = Out.Pos.xyw; //projective texcoords
   
   Out.Tex = In.Tex;
	
	return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	
	float4 color = 1;
	color.a = tex2D(normalSampler,In.Tex.xy).a;
	
	//projective texcoords
	float2 projTex;
	projTex.x = In.projCoord.x/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.x);
   projTex.y = -In.projCoord.y/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.y);
   
   half2 gBuffer = tex2D(depthSampler,projTex.xy).xw;
   
   //clip non visible parts
   float texDepth = gBuffer.x+gBuffer.y/255;
	float realDepth = In.projCoord.z/vecSkill5.w;
	if(texDepth != 0) clip(texDepth - realDepth);
   
   //refract texcoords
   float refractStrength = 0.5;
   float3 normal = (tex2D(normalSampler,In.Tex.xy).rgb*2)-1;
	projTex = projTex.xy - (  normal.xy  * refractStrength);
   
   //project to object
   color.rgb = tex2D(sceneSampler,projTex.xy/vecSkill17.xy).rgb;
		
   return color;
}

technique t1
{
	pass p0
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
		alphablendenable = TRUE;
		zwriteenable = TRUE;
		cullmode = none;
	}
}

