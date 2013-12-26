#include <scUnpackDepth>

float4 vecSkill1; //x = downsample factor, y = clip_far; z = focal pos, w = focal width
float4 vecViewPort;

texture mtlSkin1; //current scene
texture mtlSkin2; //normals and depth

sampler2D currentSceneSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D normalsAndDepthSampler = sampler_state
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
	inTex *= vecSkill1.x;
	
	inTex.x += (0.5/vecViewPort.x); //half pixel fix
	inTex.y += (0.5/vecViewPort.y); //half pixel fix
	
	half3 color = tex2D(currentSceneSampler, inTex);
	
	//generate focal plane depth
	half depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex).zw);
	depth *= vecSkill1.y;
	depth = ((depth-vecSkill1.z)/vecSkill1.w) * ((depth-vecSkill1.z)/vecSkill1.w);
	
	return half4(color,saturate(depth));

}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}
}