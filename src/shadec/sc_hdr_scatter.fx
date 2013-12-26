#include <scUnpackDepth>

float4 vecSkill1; //x = scatter strength
float4 vecViewPort;

texture mtlSkin1; //contains the scene
sampler2D sceneSampler = sampler_state
{
	Texture=<mtlSkin1>;
};

texture mtlSkin2; //contains the scene's Normals and Depth
sampler2D gBufferSampler = sampler_state
{
	Texture=<mtlSkin2>;
};

float4 mainPS(float2 inTex:TEXCOORD0, uniform half strength):COLOR
{
	float4 color = 0;
	float depth = 1-UnpackDepth(tex2D(gBufferSampler, inTex).zw);
	vecSkill1.x *= strength;
	
	//color = tex2D(sceneSampler, inTex);
	
	color += tex2D(sceneSampler, inTex + half2(vecViewPort.z*vecSkill1.x, 0));
	color += tex2D(sceneSampler, inTex + half2(-vecViewPort.z*vecSkill1.x, 0));
	color += tex2D(sceneSampler, inTex + half2(0, vecViewPort.w*vecSkill1.x));
	color += tex2D(sceneSampler, inTex + half2(0, -vecViewPort.w*vecSkill1.x));
	
	vecSkill1.x *= 0.75;
	
	color += tex2D(sceneSampler, inTex + half2(vecViewPort.z*vecSkill1.x, vecViewPort.w*vecSkill1.x));
	color += tex2D(sceneSampler, inTex + half2(-vecViewPort.z*vecSkill1.x, -vecViewPort.w*vecSkill1.x));
	color += tex2D(sceneSampler, inTex + half2(vecViewPort.z*vecSkill1.x, -vecViewPort.w*vecSkill1.x));
	color += tex2D(sceneSampler, inTex + half2(-vecViewPort.z*vecSkill1.x, vecViewPort.w*vecSkill1.x));
	
	return color;//color*0.125;
	//return tex2D(sceneSampler, inTex)*1000;
}

technique t1
{
	pass p0
	{
		Texture[0] = <mtlSkin1>;
	}
	
	pass p1
	{
		PixelShader = compile ps_2_0 mainPS(1);
		AlphaBlendEnable = True;
		BlendOp = ADD;
		SrcBlend = ONE;
		DestBlend = ONE;
	}
	
	pass p2
	{
		PixelShader = compile ps_2_0 mainPS(2);
		AlphaBlendEnable = True;
		BlendOp = ADD;
		SrcBlend = ONE;
		DestBlend = ONE;
	}
	
	pass p3
	{
		PixelShader = compile ps_2_0 mainPS(3);
		AlphaBlendEnable = True;
		BlendOp = ADD;
		SrcBlend = ONE;
		DestBlend = ONE;
	}
}