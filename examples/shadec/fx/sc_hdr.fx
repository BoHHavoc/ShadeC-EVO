float4 vecSkill1; // inverted downsample factor (2->0.5)

texture mtlSkin1; //current scene without bloom
texture mtlSkin2; //bloom

sampler2D bloomSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D currentSceneSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};




float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	inTex *= vecSkill1.x;
	half3 color = tex2D(currentSceneSampler, inTex).xyz;
	//inTex *= vecSkill1.x;
	color += tex2D(bloomSampler, inTex).xyz;
	
	return half4(color,1);
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}	
}