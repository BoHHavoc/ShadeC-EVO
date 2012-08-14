//float BRIGHT_PASS_THRESHOLD = 0.65f;
const float3 blackAndWhite = float3(0.2125f,0.7154f,0.0721f); // Reinhard Luminance weights
float4 vecSkill1; //x = downsample factor, y = brightpass threshold, z = brightpass rescale

texture mtlSkin1; //current scene
texture mtlSkin2; //albedo and emissive mask

sampler2D currentSceneSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D albedoAndEmissiveMaskSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	
	half3 color = tex2D(currentSceneSampler, inTex*vecSkill1.x);
	float result = dot(color.xyz,blackAndWhite);
	result -= vecSkill1.y;	
	result = max(result,0.f); 
	
	half4 emissive = tex2D(albedoAndEmissiveMaskSampler, inTex*vecSkill1.x);
	emissive.xyz *= emissive.w;
	
	//output brightpass and emissive	
	return half4( (result*color.xyz*vecSkill1.z)+emissive.xyz ,0);
	
//	half3 color = tex2D(currentSceneSampler, inTex*vecSkill1.x).xyz;
//	return half4(color,1);
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}
}