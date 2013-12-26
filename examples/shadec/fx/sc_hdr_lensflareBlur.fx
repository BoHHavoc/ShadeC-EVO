bool AUTORELOAD;

float4 vecSkill1; //x = blur factor

texture mtlSkin1; //bloomtexture
sampler2D bloomSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = MIRROR;
	AddressV = MIRROR;
	//AddressU = Border;
	//AddressV = Border;
	//BorderColor = 0x00000000;
};

half4 mainPS(float2 inTex : TEXCOORD0):COLOR0
{
	half3 result = tex2D(bloomSampler, inTex);
	
	result += tex2D(bloomSampler, inTex + half2(0, vecSkill1.x)).xyz;
	result += tex2D(bloomSampler, inTex + half2(vecSkill1.x, 0));
	result += tex2D(bloomSampler, inTex + half2(0, -vecSkill1.x));
	result += tex2D(bloomSampler, inTex + half2(-vecSkill1.x, 0));
	
	vecSkill1.x *= 0.75;
	result += tex2D(bloomSampler, inTex + half2(vecSkill1.x, vecSkill1.x)).xyz;
	result += tex2D(bloomSampler, inTex + half2(-vecSkill1.x, -vecSkill1.x));
	result += tex2D(bloomSampler, inTex + half2(vecSkill1.x, -vecSkill1.x));
	result += tex2D(bloomSampler, inTex + half2(-vecSkill1.x, vecSkill1.x));
	
	result /= 9;
	
	return half4(result, 0);
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
	//float2 vMirrorCoord = inTex;
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
	half4 color = vSum / NumSamples;
	
	color += tex2D(bloomSampler, inTex);
	return color;
}


technique t1
{
	pass t1
	{
		//PixelShader = compile ps_3_0 lensflare(12, vPurple, 0.50f, 0.15f);
		PixelShader = compile ps_3_0 lensflare(12, vPurple, 1.0f, 0.8f);
	}
}
*/