Texture mtlSkin1; //brightpass output

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

static const float BlurWeights[g_c_PixelOffsetSize] =
{
	0.002216,
	0.008764,
	0.026995,
	0.064759,
	0.120985,
	0.176033,
	0.199471,
	0.176033,
	0.120985,
	0.064759,
	0.026995,
	0.008764,
	0.002216,
};

float4 dofHBlur_PS(float2 texcoord0 : TEXCOORD0) : COLOR
{
	float3 pixel = 0;
	for(int i = 0; i < g_c_PixelOffsetSize; i++)
	{
		pixel += tex2D(currentScene,(texcoord0-vecViewPort.zw+PixelOffset_fix) + PixelOffsets[i] * vecSkill1.x).rgb * BlurWeights[i];	
	}
	//pixel = tex2D(currentScene, texcoord0).xyz;
	//pixel /= g_c_PixelOffsetSize;
	return float4(pixel,1);
	
}

technique t1
{
	pass p0
	{
		alphablendenable=false;
		Pixelshader = compile ps_2_0 dofHBlur_PS();
	}
}