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




float4 mainPS(float2 inTex:TEXCOORD0):COLOR
{
	inTex *= vecSkill1.x;
	half3 color = tex2D(currentSceneSampler, inTex).xyz;
	//inTex *= vecSkill1.x;
	color += tex2D(bloomSampler, inTex).xyz;
	//color = pow(color.xyz, 1.0/2.2);
	return half4(color,1);
}

float4 scene(float2 inTex:TEXCOORD0):COLOR
{
	return tex2D(currentSceneSampler, inTex*vecSkill1.x);
}
float4 bloom(float2 inTex:TEXCOORD0):COLOR
{
	//half4 result = tex2D(bloomSampler, inTex*vecSkill1.x);
	//result.a = saturate(dot(result.xyz,1));
	//return result;
	return tex2D(bloomSampler, inTex*vecSkill1.x);
}

technique t1
{
	
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}
	
	
	
	/*
	pass scene
	{
		//PixelShader = compile ps_2_0 mainPS();
		PixelShader = compile ps_1_0 scene();
		//Texture[0] = <mtlSkin1>;
	}
	
	pass bloom
	{
		PixelShader = compile ps_1_0 bloom();
		alphablendenable = true;
		BlendOp = Add;
		DestBlend = ONE;
		SrcBlend = ONE;
	}
	*/
	
	
	/*
	pass scene
	{
		//PixelShader = compile ps_2_0 mainPS();
		PixelShader = compile ps_1_0 scene();
		//Texture[0] = <mtlSkin1>;
	}
	
	pass bloom
	{
		PixelShader = compile ps_1_0 bloom();
		alphablendenable = true;
		DestBlend = ONE;
		SrcBlend = SRCALPHA;
//		SrcBlend = ONE;
//		DestBlend = ONE;
//		BlendOp = Add;
		
	}
	*/
}