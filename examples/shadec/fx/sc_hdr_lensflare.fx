bool AUTORELOAD;

texture mtlSkin1; //bloomtexture
sampler2D bloomSampler = sampler_state
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

#define NSAMPLES 5
uniform float FLARE_DISPERSAL = 1.0;
uniform float FLARE_HALO_WIDTH = 0.5;
uniform float3 FLARE_CHROMA_DISTORTION = float3(0.15, 0.1, 0.05);


half3 textureDistorted(
	in sampler2D tex,
	in float2 sample_center, // where we'd normally sample
	in float2 sample_vector,
	in float3 distortion // per-channel distortion coeffs
) {
	return half3(
		tex2D(tex, sample_center + sample_vector * distortion.r).r,
		tex2D(tex, sample_center + sample_vector * distortion.g).g,
		tex2D(tex, sample_center + sample_vector * distortion.b).b
	);
}

half4 mainPS(float2 inTex : TEXCOORD0):COLOR0
{
	
	float2 image_center = float2(0.5, 0.5);
	float2 sample_vector = (image_center - inTex) * FLARE_DISPERSAL;
	float2 halo_vector = normalize(sample_vector) * FLARE_HALO_WIDTH;
	

	//float3 result = tex2D(bloomSampler, inTex + halo_vector).rgb;
	half3 result = textureDistorted(bloomSampler, inTex + halo_vector, halo_vector, FLARE_CHROMA_DISTORTION).rgb;
	
	for (int i = 0; i < NSAMPLES; ++i) {
		float2 offset = sample_vector * float(i);
		//result += tex2D(bloomSampler, inTex + offset).rgb;
		result += textureDistorted(bloomSampler, inTex + offset, offset, FLARE_CHROMA_DISTORTION).rgb;
	}
		
	return half4(result,0);
	
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