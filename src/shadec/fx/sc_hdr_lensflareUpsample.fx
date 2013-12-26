bool AUTORELOAD;

float4 vecSkill1; //x = upsample factor

texture mtlSkin1; //lensflaretexture
sampler2D lensSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
	
};

texture mtlSkin2; //bloom
sampler2D bloomSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
	
};

texture mtlSkin3; //lensdirt
sampler2D lensDirt1Sampler = sampler_state
{
	Texture = <mtlSkin3>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
	
};

texture mtlSkin4; //lensdirt
sampler2D lensDirt2Sampler = sampler_state
{
	Texture = <mtlSkin4>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
	
};

half4 mainPS(float2 inTex : TEXCOORD0):COLOR0
{
	inTex *= vecSkill1.x;
	return tex2D(lensSampler, inTex)*tex2D(lensDirt2Sampler,inTex) + tex2D(bloomSampler, inTex);
	//return tex2D(lensSampler, inTex);
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}
}

/*
const static float4 vPurple = float4(0.7f, 0.2f, 0.9f, 1.0f);
const static float4 vOrange = float4(0.7f, 0.4f, 0.2f, 1.0f);
const static float4 vWhite = float4(1.0f, 1.0f, 1.0f, 1.0f);
const static float fThreshold = 0.1f;
float4 vecViewPort;

texture mtlSkin1; //bloomtexture
sampler2D bloomSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};


float4 lensflare(
	float2 inTex:TEXCOORD0,
	uniform int NumSamples,
	uniform float4 vTint,
	uniform float fTexScale,
	uniform float fBlurScale
):COLOR0
{
	//screen space lensflare
	//inTex *= vecSkill1.x;
  	
	float2 vMirrorCoord = float2(1.0f, 1.0f) - inTex;
	float2 vNormalizedCoord = vMirrorCoord * 2.0f - 1.0f;
	vNormalizedCoord *= fTexScale;
	
	// We'll blur towards the center of screen, and also away from it.
	float2 vTowardCenter = normalize(-vNormalizedCoord);
	float2 fBlurDist = fBlurScale * NumSamples;
	float2 vStartPoint = vNormalizedCoord + ((vTowardCenter / vecViewPort.xy) * fBlurDist);
	float2 vStep = -(vTowardCenter / vecViewPort.xy) * 2 * fBlurDist;
	
	// Do the blur and sum the samples
	float4 vSum = 0;
	float2 vSamplePos = vStartPoint;
	for (int i = 0; i < NumSamples; i++)
	{
		float2 vSampleTexCoord = vSamplePos * 0.5f + 0.5f;
		// Don't add in samples past texture border
		if (vSampleTexCoord.x >= 0 && vSampleTexCoord.x <= 1.0f
		&& vSampleTexCoord.y >=0 && vSampleTexCoord.y <= 1.0f)
		{
			float4 vSample = tex2D(bloomSampler, vSampleTexCoord);
			vSum +=  max(0, vSample - fThreshold) * vTint;
		}
		vSamplePos += vStep;
	}
	//return vSum / NumSamples;
	half4 color = vSum / NumSamples;
	
	color += tex2D(bloomSampler, inTex);
	return color;
}


technique t1
{
	pass t1
	{
		//PixelShader = compile ps_3_0 lensflare(12, vOrange, 2.00f, 0.3f);
		PixelShader = compile ps_3_0 lensflare(12, vOrange, 2.00f, 1.3f);
	}
}
*/