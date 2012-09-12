bool AUTORELOAD;

#define MAX_SEARCH_STEPS 8
#define MAX_DISTANCE 32

float4 vecViewPort;

texture mtlSkin1; //edges
sampler edgeSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = false;
};

sampler edgeLSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	SRGBTexture = false;
};

texture mtlSkin2; //mlaa area LUT
sampler areaSampler = sampler_state 
{ 
   Texture = <mtlSkin2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = false;
};

/**
 * This one just returns the first level of a mip map chain, which allow us to
 * avoid the nasty ddx/ddy warnings, even improving the performance a little 
 * bit.
 */

float4 tex2Dlevel0(sampler2D map, float2 texcoord) {
    return tex2Dlod(map, float4(texcoord, 0.0, 0.0));
}

/**
 * Same as above, this eases translation to assembly code;
 */
 
float4 tex2Doffset(sampler2D map, float2 texcoord, float2 offset) {
    #if defined(XBOX) && MAX_SEARCH_STEPS < 6
    float4 result;
    float x = offset.x;
    float y = offset.y;
    asm {
        tfetch2D result, texcoord, map, OffsetX = x, OffsetY = y
    };
    return result;
    #else
    //half2 pixelSize = half2(1.0/vecViewPort.x, 1.0/vecViewPort.y);
    return tex2Dlevel0(map, texcoord + vecViewPort.zw * offset);
    #endif
}

/** 
 * Ok, we have the distance and both crossing edges, can you please return 
 * the float2 blending weights?
 */

float2 Area(float2 distance, float e1, float e2) {
     // * By dividing by areaSize - 1.0 below we are implicitely offsetting to
     //   always fall inside of a pixel
     // * Rounding prevents bilinear access precision problems
    float areaSize = MAX_DISTANCE * 5.0;
    float2 pixcoord = MAX_DISTANCE * round(4.0 * float2(e1, e2)) + distance;
    float2 texcoord = pixcoord / (areaSize - 1.0);
    return tex2Dlevel0(areaSampler, texcoord).ra;
}

float SearchXLeft(float2 texcoord) {
    // We compare with 0.9 to prevent bilinear access precision problems.
    float i;
    float e = 0.0;
    for (i = -1.5; i > -2.0 * MAX_SEARCH_STEPS; i -= 2.0) {
        e = tex2Doffset(edgeLSampler, texcoord, float2(i, 0.0)).g;
        [flatten] if (e < 0.9) break;
    }
    return max(i + 1.5 - 2.0 * e, -2.0 * MAX_SEARCH_STEPS);
}

float SearchXRight(float2 texcoord) {
    float i;
    float e = 0.0;
    for (i = 1.5; i < 2.0 * MAX_SEARCH_STEPS; i += 2.0) {
        e = tex2Doffset(edgeLSampler, texcoord, float2(i, 0.0)).g;
        [flatten] if (e < 0.9) break;
    }
    return min(i - 1.5 + 2.0 * e, 2.0 * MAX_SEARCH_STEPS);
}

float SearchYUp(float2 texcoord) {
    float i;
    float e = 0.0;
    for (i = -1.5; i > -2.0 * MAX_SEARCH_STEPS; i -= 2.0) {
        e = tex2Doffset(edgeLSampler, texcoord, float2(i, 0.0).yx).r;
        [flatten] if (e < 0.9) break;
    }
    return max(i + 1.5 - 2.0 * e, -2.0 * MAX_SEARCH_STEPS);
}

float SearchYDown(float2 texcoord) {
    float i;
    float e = 0.0;
    for (i = 1.5; i < 2.0 * MAX_SEARCH_STEPS; i += 2.0) {
        e = tex2Doffset(edgeLSampler, texcoord, float2(i, 0.0).yx).r;
        [flatten] if (e < 0.9) break;
    }
    return min(i - 1.5 + 2.0 * e, 2.0 * MAX_SEARCH_STEPS);
}

float4 BlendWeightCalculationPS(float2 texcoord : TEXCOORD0) : COLOR0 {
    float4 areas = 0.0;

    float2 e = tex2D(edgeSampler, texcoord).rg;
    //return tex2D(edgeSampler, texcoord);

    [branch]
    if (e.g) { // Edge at north

        // Search distances to the left and to the right:
        float2 d = float2(SearchXLeft(texcoord), SearchXRight(texcoord));

        // Now fetch the crossing edges. Instead of sampling between edgels, we
        // sample at -0.25, to be able to discern what value has each edgel:
        float4 coords = mad(float4(d.x, -0.25, d.y + 1.0, -0.25),
                            vecViewPort.zwzw, texcoord.xyxy);
        float e1 = tex2Dlevel0(edgeLSampler, coords.xy).r;
        float e2 = tex2Dlevel0(edgeLSampler, coords.zw).r;

        // Ok, we know how this pattern looks like, now it is time for getting
        // the actual area:
        areas.rg = Area(abs(d), e1, e2);
    }

    [branch]
    if (e.r) { // Edge at west

        // Search distances to the top and to the bottom:
        float2 d = float2(SearchYUp(texcoord), SearchYDown(texcoord));

        // Now fetch the crossing edges (yet again):
        float4 coords = mad(float4(-0.25, d.x, -0.25, d.y + 1.0),
                            vecViewPort.zwzw, texcoord.xyxy);
        float e1 = tex2Dlevel0(edgeLSampler, coords.xy).g;
        float e2 = tex2Dlevel0(edgeLSampler, coords.zw).g;

        // Get the area for this direction:
        areas.ba = Area(abs(d), e1, e2);
    }

    return areas;
}

float4 mainPS(float2 inTex : TEXCOORD0):COLOR0
{
	return tex2D(edgeSampler, inTex);
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_3_0 BlendWeightCalculationPS();
		ZEnable = false;
      SRGBWriteEnable = false;
      AlphaBlendEnable = false;

      // Here we want to process only marked pixels.
      StencilEnable = true;
      StencilPass = KEEP;
      StencilFunc = EQUAL;
      StencilRef = 1;
     
	}
}