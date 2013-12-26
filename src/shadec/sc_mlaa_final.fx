bool AUTORELOAD;

//#define BILINEAR_FILTER_TRICK

float4 vecViewPort;

texture mtlSkin1; //scene

#ifdef BILINEAR_FILTER_TRICK
sampler colorLSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	SRGBTexture = true;
};
#else
sampler colorSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = true;
};
#endif



texture mtlSkin2; //blend weights
sampler weightSampler = sampler_state 
{ 
   Texture = <mtlSkin2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = false;
};


float4 NeighborhoodBlendingPS(float2 texcoord : TEXCOORD0,
                              float4 offset[2]: TEXCOORD1) : COLOR0
{
	offset[0] = texcoord.xyxy + vecViewPort.zwzw * float4(-1.0, 0.0, 0.0, -1.0);
	offset[1] = texcoord.xyxy + vecViewPort.zwzw * float4( 1.0, 0.0, 0.0,  1.0);
    // Fetch the blending weights for current pixel:
    float4 topLeft = tex2D(weightSampler, texcoord);
    float bottom = tex2D(weightSampler, offset[1].zw).g;
    float right = tex2D(weightSampler, offset[1].xy).a;
    float4 a = float4(topLeft.r, bottom, topLeft.b, right);

    // Up to 4 lines can be crossing a pixel (one in each edge). So, we perform
    // a weighted average, where the weight of each line is 'a' cubed, which
    // favors blending and works well in practice.
    float4 w = a * a * a;

    // There is some blending weight with a value greater than 0.0?
    float sum = dot(w, 1.0);
    //if (sum < 1e-5)
    //		discard;
    //clip(sum-0.00001);
    

    float4 color = 0.0;

    // Add the contributions of the possible 4 lines that can cross this pixel:
    #ifdef BILINEAR_FILTER_TRICK
        float4 coords = mad(float4( 0.0, -a.r, 0.0,  a.g), vecViewPort.wwww, texcoord.xyxy);
        color = mad(tex2D(colorLSampler, coords.xy), w.r, color);
        color = mad(tex2D(colorLSampler, coords.zw), w.g, color);

        coords = mad(float4(-a.b,  0.0, a.a,  0.0), vecViewPort.zzzz, texcoord.xyxy);
        color = mad(tex2D(colorLSampler, coords.xy), w.b, color);
        color = mad(tex2D(colorLSampler, coords.zw), w.a, color);
    #else
        float4 C = tex2D(colorSampler, texcoord);
        float4 Cleft = tex2D(colorSampler, offset[0].xy);
        float4 Ctop = tex2D(colorSampler, offset[0].zw);
        float4 Cright = tex2D(colorSampler, offset[1].xy);
        float4 Cbottom = tex2D(colorSampler, offset[1].zw);
        color = mad(lerp(C, Ctop, a.r), w.r, color);
        color = mad(lerp(C, Cbottom, a.g), w.g, color);
        color = mad(lerp(C, Cleft, a.b), w.b, color);
        color = mad(lerp(C, Cright, a.a), w.a, color);
    #endif


	//return tex2D(weightSampler, texcoord);

    // Normalize the resulting color and we are finished!
    //return (color / sum); 
    float4 result = color / sum;
    return float4(lerp(tex2D(colorSampler, texcoord).rgb, result.rgb, result.a), 1);
    //return tex2D(colorSampler, texcoord);// + (color/sum)*100;
    
}

technique t1
{
	pass p1
	{
		PixelShader = compile ps_2_0 NeighborhoodBlendingPS();
		ZEnable = false;
      SRGBWriteEnable = true;
      AlphaBlendEnable = false;

		/*
      // Here we want to process only marked pixels.
      StencilEnable = true;
      StencilPass = KEEP;
      StencilFunc = EQUAL;
      StencilRef = 101;
      */
	}
}