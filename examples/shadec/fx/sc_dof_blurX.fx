#include <scUnpackDepth>

float4 vecViewPort;
float4 vecSkill1;

texture mtlSkin1; //downsample output
sampler sceneSampler = sampler_state
{
	texture 		= mtlSkin1;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
   AddressV = Clamp;
};

texture mtlSkin2; //normals and depth
sampler normalsAndDepthSampler = sampler_state
{
	texture 		= mtlSkin2;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = Clamp;
   AddressV = Clamp;
};

static const int g_c_PixelOffsetSize = 13;

float2 PixelOffsets[g_c_PixelOffsetSize] =
{
	{ -0.006, 0.0 },
	{ -0.005, 0.0 },
	{ -0.004, 0.0 },
	{ -0.003, 0.0 },
	{ -0.002, 0.0 },
	{ -0.001, 0.0 },
	{  0.000, 0.0 },
	{  0.001, 0.0 },
	{  0.002, 0.0 },	
	{  0.003, 0.0 },
	{  0.004, 0.0 },
	{  0.005, 0.0 },
	{  0.006, 0.0 },
};


float2 PixelOffset_fix = {0.0, 0.002};


struct psOut
{
	half4 blurred : COLOR0;
	half4 downsampled : COLOR1;
};


psOut mainPS(float2 inTex : TEXCOORD0)
{
	psOut PSOut = (psOut)0;
	
	inTex.x += (0.5/vecViewPort.x); //half pixel fix
	inTex.y += (0.5/vecViewPort.y); //half pixel fix
	
	half depth = 1-UnpackDepth(tex2D(normalsAndDepthSampler, inTex).zw);
	/*
	half depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z, vecViewPort.w)).zw);
	depth += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z, vecViewPort.w)).zw);
	depth += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z, -vecViewPort.w)).zw);
	depth += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z, -vecViewPort.w)).zw);
	depth = 1-(depth*0.25);
	*/
	
	
	half4 scene = tex2D(sceneSampler, inTex-vecViewPort.zw);
	half4 pixel = 0;
	for(int i = 0; i < g_c_PixelOffsetSize; i++)
	{
		half4 sample = tex2D(sceneSampler,(inTex) + PixelOffsets[i].xy * vecSkill1.x * depth);
		pixel += lerp(sample.rgba, scene.rgba, (scene.a - sample.a));
	}

	pixel /= g_c_PixelOffsetSize;
	//pixel.a = scene.a;
	
	PSOut.blurred = pixel; //blurred scene
	PSOut.blurred.a = scene.a; //unblurred focus
	
	PSOut.downsampled = scene; //unblurred scene
	PSOut.downsampled.a = pixel.a; //blurred focus
	
	return PSOut;
	//return float4(pixel.rgb, scene.a);
}

technique t1
{
	pass p0
	{
		alphablendenable=false;
		Pixelshader = compile ps_3_0 mainPS();
	}
}