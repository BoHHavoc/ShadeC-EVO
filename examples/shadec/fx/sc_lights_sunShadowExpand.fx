float4 vecSkill1; //lightrange (w)
float4 vecSkill5; //clip_far (w)
float4 vecSkill13; // number of pssm splits (x)

float4 vecViewPort;

texture mtlSkin1; //shadow edge detect result
sampler shadowEdgeSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
	//BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};

texture sc_map_random2x2_bmap;
sampler randSampler = sampler_state 
{ 
	Texture = <sc_map_random2x2_bmap>; 
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
	//BorderColor = 0xFFFFFFFF;
	//BorderColor = 0x00000000;
};

half4 mainPS(in float2 inTex : TEXCOORD0):COLOR
{
	
	inTex *= 2;
	
	half2 rand = (tex2D(randSampler, inTex*(vecViewPort.xy*0.0625)).xy - 0.5);// * 8.0f/shadowmapSize;
	//vecViewPort.zw *= 8*rand;
	vecViewPort.zw *= 5;
	
	half expanded;
	expanded = tex2D(shadowEdgeSampler, inTex + half2(vecViewPort.z,0)).x;
	expanded += tex2D(shadowEdgeSampler, inTex + half2(0, vecViewPort.w)).x;
	expanded += tex2D(shadowEdgeSampler, inTex + half2(-vecViewPort.z,0)).x;
	expanded += tex2D(shadowEdgeSampler, inTex + half2(0, -vecViewPort.w)).x;
	expanded *= 0.25;
	
	half expandedOrg = expanded;
	if(expanded > 0 && expanded < 1)
		expanded = 1;
	if(expandedOrg == 1)
		expanded = 0.5;
	
	//expanded = tex2D(shadowEdgeSampler, inTex).r;
	
	return half4(expanded, expanded, expanded, 1);
	
	
	//return tex2D(shadowEdgeSampler, inTex);
}

technique sunShadowExpand
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
		alphablendenable = false;
	}
}