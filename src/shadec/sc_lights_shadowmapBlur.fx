bool AUTORELOAD;

float4 vecSkill1; //x = blur factor
float4 vecViewPort;

texture TargetMap; //light depthmap
sampler2D blurSampler = sampler_state
{
	Texture = <TargetMap>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = MIRROR;
	AddressV = MIRROR;
	//AddressU = Border;
	//AddressV = Border;
	//BorderColor = 0x00000000;
};


half4 mainPS(float2 inTex : TEXCOORD0):COLOR
{
	//inTex += vecViewPort.zw * ((tex2D(noiseSampler, inTex*vecViewPort.xy)-0.5)*2);
	half4 result = tex2D(blurSampler, inTex).x;
	
	result.x += tex2D(blurSampler, inTex + half2(0, vecSkill1.x)).x;
	result.x += tex2D(blurSampler, inTex + half2(vecSkill1.x, 0)).x;
	result.x += tex2D(blurSampler, inTex + half2(0, -vecSkill1.x)).x;
	result.x += tex2D(blurSampler, inTex + half2(-vecSkill1.x, 0)).x;
	
	vecSkill1.x *= 0.75;
	result.x += tex2D(blurSampler, inTex + half2(vecSkill1.x, vecSkill1.x)).x;
	result.x += tex2D(blurSampler, inTex + half2(-vecSkill1.x, -vecSkill1.x)).x;
	result.x += tex2D(blurSampler, inTex + half2(vecSkill1.x, -vecSkill1.x)).x;
	result.x += tex2D(blurSampler, inTex + half2(-vecSkill1.x, vecSkill1.x)).x;
	
	result.x /= 9;
	
	
	return result;
}


/*
#define SAMPLE_COUNT 5
float2 Offsets[SAMPLE_COUNT] = {
	0,0,
	1,0,
	0,1,
	-1,0,
	0,-1
};


float log_conv ( float x0, float X, float y0, float Y )
{
    return (X + log(x0 + (y0 * exp(Y - X))));
}

float4 mainPS(float2 inTex : TEXCOORD0):COLOR
{
	float  sample[5];
   for (int i = 0; i < 5; i++)
   {
       sample[i] = tex2D( blurSampler, inTex + (Offsets[i]/vecViewPort.xy)vecSkill1.x ).x;
   }
 
   const float c = (1.f/5.f);    
   
   float accum;
   accum = log_conv( c, sample[0], c, sample[1] );
   for (int i = 2; i < 5; i++)
   {
       accum = log_conv( 1.f, accum, c, sample[i] );
   }    
        
   //float depth = accum;
   return accum;
}
*/

/*
//sampler TextureSampler : register(s0);
#define SAMPLE_COUNT 3
float2 Offsets[SAMPLE_COUNT] = {
	1,0,
	0,1,
	1,1
};

float log_space(float w0, float d1, float w1, float d2){
	return (d1 + log(w0 + (w1 * exp(d2 - d1))));
}

float4 mainPS(float2 texCoord : TEXCOORD0) : COLOR0
{
	float v, B, B2;
	float w = (1.0/SAMPLE_COUNT);

	B = tex2D(blurSampler, texCoord + Offsets[0]/256);
	B2 = tex2D(blurSampler, texCoord + Offsets[0]/256);
	v = log_conv(w, B, w, B2);

	for(int i = 2; i < SAMPLE_COUNT; i++)
	{
		B = tex2D(blurSampler, texCoord + Offsets[i]/256);
		v = log_conv(1.0, v, w, B);
	}

	return v;
}
*/

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