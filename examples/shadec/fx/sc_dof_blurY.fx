#include <scUnpackDepth>

float4 vecViewPort;
float4 vecSkill1;

texture mtlSkin1; //blurred output, unblurred focus
sampler sceneSampler = sampler_state
{
	texture 		= mtlSkin1;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
   AddressV = Clamp;
};

texture mtlSkin3; //downsample output, blurred focus
sampler orgSceneSampler = sampler_state
{
	texture 		= mtlSkin3;
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

float4 mainPS(float2 inTex : TEXCOORD0) : COLOR
{
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
	//scene.a = tex2D(orgSceneSampler, inTex-vecViewPort.zw).w;
	//scene.a *= depth;
	half4 pixel = 0;
	for(int i = 0; i < g_c_PixelOffsetSize; i++)
	{
		half4 sample = tex2D(sceneSampler,(inTex) + PixelOffsets[i].yx * vecSkill1.x * depth);
		//sample.w = tex2D(orgSceneSampler,(inTex) + PixelOffsets[i].yx * vecSkill1.x * depth).w;
		//half sampleDepth = 1-UnpackDepth(tex2D(normalsAndDepthSampler,(inTex-vecViewPort.zw) + PixelOffsets[i].xy * vecSkill1.x).zw);
		//sample.a *= depthDepth;
		pixel += lerp(sample.rgba, scene.rgba, (scene.a - sample.a));

		//if(depth < sampleDepth) pixel += lerp(sample.rgb, scene.rgb, (scene.a - sample.a));
		//else pixel += scene.rgb;
		//if(depth > sampleDepth) pixel = lerp(pixel.rgb, scene.rgb, (-1)*(sample.a - scene.a));
	}
	
	//return scene;
	
	pixel /= g_c_PixelOffsetSize;
	pixel.a = (pixel.a + tex2D(orgSceneSampler, inTex-vecViewPort.zw).w) * 0.5;
		
	return pixel;
	
	//return scene;
	
	/*
	half depthpixel = 0;
	for(int i = 0; i < g_c_PixelOffsetSize; i++)
	{
		half sample = tex2D(sceneSampler,(inTex) + PixelOffsets[i].xy * vecSkill1.x * depth).w;
		//half sampleDepth = 1-UnpackDepth(tex2D(normalsAndDepthSampler,(inTex-vecViewPort.zw) + PixelOffsets[i].xy * vecSkill1.x).zw);
		//sample.a *= depthDepth;
		depthpixel += lerp(sample, scene.a, (scene.a - sample));

		//if(depth < sampleDepth) pixel += lerp(sample.rgb, scene.rgb, (scene.a - sample.a));
		//else pixel += scene.rgb;
		//if(depth > sampleDepth) pixel = lerp(pixel.rgb, scene.rgb, (-1)*(sample.a - scene.a));
	}
	
	depthpixel /= g_c_PixelOffsetSize;
	pixel.a = (pixel.a + depthpixel) * 0.5;
	*/
	
	
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

/*
Texture mtlSkin1; //x blurred scene

float4 vecViewPort;
float4 vecSkill1;

sampler currentScene = sampler_state
{
	texture 		= (mtlSkin1);
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
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

float4 dofHBlur_PS(float2 inTex : TEXCOORD0) : COLOR
{
	inTex.x += (0.5/vecViewPort.x); //half pixel fix
	inTex.y += (0.5/vecViewPort.y); //half pixel fix
	
	half4 scene = tex2D(currentScene, inTex-vecViewPort.zw);
	half3 pixel = 0;
	for(int i = 0; i < g_c_PixelOffsetSize; i++)
	{
		half4 sample = tex2D(currentScene,(inTex-vecViewPort.zw) + PixelOffsets[i].yx * vecSkill1.x * scene.a);	

		pixel += lerp(sample.rgb, scene.rgb, scene.a - sample.a);
	}

	
	return scene;
	return float4(pixel.rgb/g_c_PixelOffsetSize, scene.a);
}

technique t1
{
	pass p0
	{
		alphablendenable=false;
		Pixelshader = compile ps_3_0 dofHBlur_PS();
	}
}
*/