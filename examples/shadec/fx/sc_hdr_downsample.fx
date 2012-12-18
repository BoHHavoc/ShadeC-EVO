//#include <scUnpackLighting>

//float BRIGHT_PASS_THRESHOLD = 0.65f;
const float3 blackAndWhite = float3(0.2125f,0.7154f,0.0721f); // Reinhard Luminance weights
float4 vecSkill1; //x = downsample factor, y = brightpass threshold, z = brightpass rescale

texture mtlSkin1; //current scene
texture mtlSkin2; //albedo and emissive mask
texture mtlSkin3; //lightingbuffer

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

/*
sampler2D lightingSampler = sampler_state
{
	Texture = <mtlSkin3>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};
*/

float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	inTex *= vecSkill1.x;
	half3 color = tex2D(currentSceneSampler, inTex);
	float result = dot(color.xyz,blackAndWhite);
	result -= vecSkill1.y;	
	result = max(result,0.f); 
	
	half4 emissive = tex2D(albedoAndEmissiveMaskSampler, inTex);
	emissive.xyz *= emissive.w;
	
	/*
	//add specular lighting to emissive buffer
	half4 lighting = UnpackLighting(tex2D(lightingSampler, inTex));
	emissive.xyz += lighting.xyz*lighting.w*0.04;
	*/
	
	//output brightpass and emissive	
	//return half4( (result*color.xyz*vecSkill1.z)+emissive.xyz*vecSkill1.w ,0);
	return half4( max((result*color.xyz*vecSkill1.z),emissive.xyz*vecSkill1.w) ,0);
	
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