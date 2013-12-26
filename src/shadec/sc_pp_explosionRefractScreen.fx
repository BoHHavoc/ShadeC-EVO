float4 vecSkill1;

texture TargetMap;
sampler sceneSampler = sampler_state 
{ 
   Texture = <TargetMap>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

texture mtlSkin1;
sampler normalSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

float4 mainPS(float2 inTex : TEXCOORD0):COLOR0
{
	half3 color = tex2D(sceneSampler,inTex.xy).rgb;
	//float3 normal = tex2D(normalSampler,(inTex.xy*4)+float2(-1.5,-1.5)).xyw;
	float3 normal = tex2D(normalSampler,(inTex.xy)+float2(vecSkill1.y,vecSkill1.z)).xyw;
	
	normal.xy = normalize((normal.xy-0.5)*2);
	inTex.xy += (normal.xy * vecSkill1.x * 0.1) * normal.z;
	
	color = tex2D(sceneSampler,inTex.xy).rgb;//lerp(tex2D(sceneSampler,inTex.xy).rgb,color.rgb, 1-normal.z);
	
	return half4(color,1);
}

technique t1
{
	pass p0
	{
		Pixelshader = compile ps_2_0 mainPS();
	}
}