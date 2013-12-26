#include <scUnpackDepth>

bool AUTORELOAD;

//static float threshold = 0.1;
static float threshold = 0.085;

float4 vecViewPort;

texture mtlSkin1; //depthmap
sampler depthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = false;
};

texture mtlSkin2; //scene
sampler sceneSampler = sampler_state 
{ 
   Texture = <mtlSkin2>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	SRGBTexture = false;
};

void OffsetVS(inout float4 position : POSITION0,
              inout float2 texcoord : TEXCOORD0,
              out float4 offset[2] : TEXCOORD1)
{
	offset[0] = texcoord.xyxy;// + PIXEL_SIZE.xyxy * float4(-1.0, 0.0, 0.0, -1.0);
	offset[1] = texcoord.xyxy;// + PIXEL_SIZE.xyxy * float4( 1.0, 0.0, 0.0,  1.0);
}

float4 ColorEdgeDetectionPS(float2 texcoord : TEXCOORD0,
                            float4 offset[2]: TEXCOORD1) : COLOR0
{
	//texcoord.xy += 0.5/vecViewPort.zw;
	offset[0] = texcoord.xyxy + vecViewPort.zwzw * float4(-1.0, 0.0, 0.0, -1.0);
	offset[1] = texcoord.xyxy + vecViewPort.zwzw * float4( 1.0, 0.0, 0.0,  1.0);
    float3 weights = float3(0.2126,0.7152, 0.0722); // These ones are from the ITU-R Recommendation BT. 709

    /**
     * Luma calculation requires gamma-corrected colors (texture 'colorMapG').
     *
     * Note that there is a lot of overlapped luma calculations; performance
     * can be improved if this luma calculation is performed in the main pass,
     * which may give you an edge if used in conjunction with a z prepass.
     */
    float L = dot(tex2D(sceneSampler, texcoord).rgb, weights);
    float Lleft = dot(tex2D(sceneSampler, offset[0].xy).rgb, weights);
    float Ltop = dot(tex2D(sceneSampler, offset[0].zw).rgb, weights);  
    float Lright = dot(tex2D(sceneSampler, offset[1].xy).rgb, weights);
    float Lbottom = dot(tex2D(sceneSampler, offset[1].zw).rgb, weights);

    float4 delta = abs(L.xxxx - float4(Lleft, Ltop, Lright, Lbottom));
    float4 edges = step(threshold.xxxx, delta);

    //if (dot(edges, 1.0) == 0.0)
    //    discard;
	//clip(dot(edges, 1.0) - 0.00001);
	
    return edges;
}

float4 DepthEdgeDetectionPS(float2 inTex : TEXCOORD0, float4 offset[2]: TEXCOORD1) : COLOR0
{
	
	offset[0] = inTex.xyxy + vecViewPort.zwzw * float4(-1.0, 0.0, 0.0, -1.0);
	offset[1] = inTex.xyxy + vecViewPort.zwzw * float4( 1.0, 0.0, 0.0,  1.0);
	//half2 tempDepth = UnpackDepth(tex2D(depthSampler, inTex).zw);
	float D = UnpackDepth(tex2D(depthSampler, inTex).zw);//tempDepth.x + tempDepth.y/255;
	//tempDepth = UnpackDepth(tex2D(depthSampler, offset[0].xy).zw);
   float Dleft = UnpackDepth(tex2D(depthSampler, offset[0].xy).zw);//tempDepth.x + tempDepth.y/255;
   //tempDepth = UnpackDepth(tex2D(depthSampler, offset[0].zw).zw);
   float Dtop  = UnpackDepth(tex2D(depthSampler, offset[0].zw).zw);;//tempDepth.x + tempDepth.y/255;
   //tempDepth = UnpackDepth(tex2D(depthSampler, offset[1].xy).zw);
   float Dright = UnpackDepth(tex2D(depthSampler, offset[1].xy).zw);//tempDepth.x + tempDepth.y/255;
   //tempDepth = UnpackDepth(tex2D(depthSampler, offset[1].zw).zw);
   float Dbottom = UnpackDepth(tex2D(depthSampler, offset[1].zw).zw);//tempDepth.x + tempDepth.y/255;

   float4 delta = abs(D.xxxx - float4(Dleft, Dtop, Dright, Dbottom));
   float4 edges = step(threshold.xxxx * 0.1, delta); // Dividing by 10 give us results similar to the color-based detection.

   //if (dot(edges, 1.0) == 0.0)
	//	discard;

   return edges;
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 ColorEdgeDetectionPS();
		//PixelShader = compile ps_2_0 DepthEdgeDetectionPS();
		ZEnable = false;        
      SRGBWriteEnable = false;
      AlphaBlendEnable = false;

		/*
      // We will be creating the stencil buffer for later usage.
      StencilEnable = true;
      StencilPass = REPLACE;
      StencilRef = 101;
      */
      
	}
}