bool AUTORELOAD;

Texture TargetMap;
sampler2D ssaoSampler = sampler_state {
	texture = <TargetMap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

Texture mtlSkin2;
sampler2D depthSampler = sampler_state {
	texture = <mtlSkin2>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

float4 vecViewPort; // contains viewport pixel size in zw components
float4 vecViewPos;
float4 vecSkill1;
float4x4 matMtl;
float4x4 matViewProj;

#define b_iSampleInterpolantCount 6

float2 i_GaussianBlurSample[13] = {
   0.0, 0.0,
   0.0, 1.5,
   1.5, 0.0,
   1.0, 1.0,
   0.0,-1.5,
  -1.5, 0.0,
  -1.0,-1.0,
  -1.0, 1.0,
   1.0,-1.0,
   0.5, 0.5,
   0.5,-0.5,
  -0.5,-0.5,
  -0.5, 0.5

};

static const float p_fBlurWeights[13] =
{
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033,
	0.176033
};




float2 taps[7] = {
   -0.00695914,  0.00457137,
   -0.00203345,  0.00620716,
    0.00962340, -0.00194983,
    0.00507431,  0.0064425,
    0.00896420,  0.00412458,
   -0.00321940, -0.00932615,
   -0.00791559, -0.00597705,
};

//decode normals
half3 decodeNormals(half2 enc)
{
	
	/*
	//r12f
   half4 nn = half4(enc,0,0)*half4(2,2,0,0) + half4(-1,-1,1,-1);
   half l = dot(nn.xyz,-nn.xyw);
   nn.z = l;
   nn.xy *= sqrt(l);
   return nn.xyz * 2 + half3(0,0,-1);
   */ 
   
   
   //argb8
   //half3 n;
	//n.xy=enc.xy*2-1;
	//n.z=-sqrt(1-dot(n.xy,n.xy));
	//return n;
	
	//spheremap
	float3 n;
	n.xy = -enc*enc+enc;
	n.z = -1;
	float f = dot(n, float3(1,1,0.25));
	float m = sqrt(f);
	n.xy = (enc*8-4) * m;
	n.z = 1 - 8*f;
	return n;
	
	/*
	//Lambert Azimuthal
	half2 fenc = enc*4-2;
	half f = dot(fenc,fenc);
	half g = sqrt(1-f/4);
	half3 n;
	n.xy = fenc*g;
	n.z = 1-f/2;
	return n;
	*/
}

float4 ssaoBlurPS( float2 inTex : TEXCOORD0 ) : COLOR0 
{
	half ssao = 0;
	//half3 color = tex2D(colorSampler, inTex);
	
	ssao += tex2D(ssaoSampler, inTex + vecViewPort.zw);
	ssao += tex2D(ssaoSampler, inTex - vecViewPort.zw);
	ssao += tex2D(ssaoSampler, inTex + float2(-vecViewPort.z, vecViewPort.w));
	ssao += tex2D(ssaoSampler, inTex + float2(vecViewPort.z, -vecViewPort.w));
	

	ssao /= 4;
	half3 color;
	color = ssao;
	return float4(color,1);
}

float4 blur (float2 position : TEXCOORD0, uniform float blurStr) : COLOR
{
	position.x += (0.5/vecViewPort.x);
	position.y += (0.5/vecViewPort.y);
	
	float4 depthNormOrg = tex2D(depthSampler, position).xyzw;
	depthNormOrg.x = depthNormOrg.x + (depthNormOrg.w/255);
	depthNormOrg.yzw = decodeNormals(depthNormOrg.yz);
	
   float linDepth = pow(1-depthNormOrg.x,1);
	
	
	half4 ssaoOrg = tex2D(ssaoSampler, position).rgba;
	float4 blurDepthNorm = 0;
	half4 r = 0.0;
	
	for(int i = -2; i <= 1; i++)
	{
		blurDepthNorm = tex2D(depthSampler, position + (float)i * (vecSkill1.xy*blurStr) * vecViewPort.zw * linDepth).xyzw;
		blurDepthNorm.x = blurDepthNorm.x + (blurDepthNorm.w/255);
		blurDepthNorm.yzw = decodeNormals(blurDepthNorm.yz);
		
	  	if(
			abs( blurDepthNorm.x - depthNormOrg.x ) > 0.0001f
			|| dot( blurDepthNorm.yzw, depthNormOrg.yzw) < 0.99f
			) r += ssaoOrg;
		else r += tex2D(ssaoSampler, position + (float)i * (vecSkill1.xy*blurStr) * vecViewPort.zw * linDepth).rgba;
	}
		
	
	r *= 0.25f;
	//return tex2D(ssaoSampler, position);
	
	return half4(r.rgb , r.a);
}


/*

// i_UV : UV of center tap
// p_fBlurWeights Array of gaussian weights
// i_GaussianBlurSample: Array of interpolants, with each interpolants
// packing 2 gaussian sample positions.
float4 blur( float2 inTex:TEXCOORD0 ):COLOR0
{
	float2 vCenterTap = inTex.xy;
	float4 cValue = tex2D( ssaoSampler, vCenterTap.xy );
	float4 cResult = cValue * p_fBlurWeights[0];
	float fTotalWeight = p_fBlurWeights[0]; // Sample normal & depth for center tap
	float4 vNormalDepth = tex2D( depthSampler, vCenterTap.xy ).rgba;
	vNormalDepth.a = 1-vNormalDepth.r;
	vNormalDepth.rgb = SphericalToCartesian(vNormalDepth.gb);
	
	float4 vp = float4(inTex.xy * float2(2, -2) - float2(1, -1), vNormalDepth.a, 1);
   float4 v = mul(vp, matMtl);
   float3 wp = v.xyz/v.w;
   vNormalDepth.a = mul(float4(wp,1), matViewProj).z/50000;
	
	for ( int i = 0; i < b_iSampleInterpolantCount; i++ )
	{
		half4 cValue = tex2D( ssaoSampler, inTex.xy + i_GaussianBlurSample[i].xy*0.01*(1-vNormalDepth) );
		half fWeight = p_fBlurWeights[i * 2 + 1];
		float4 vSampleNormalDepth = tex2D( depthSampler, inTex.xy + i_GaussianBlurSample[i].xy*0.01*(1-vNormalDepth) );
		vSampleNormalDepth.a = 1-vSampleNormalDepth.r;
		vSampleNormalDepth.rgb = SphericalToCartesian(vSampleNormalDepth.gb);
		float4 vp = float4(inTex.xy * float2(2, -2) - float2(1, -1), vSampleNormalDepth.a, 1);
   	float4 v = mul(vp, matMtl);
   	float3 wp = v.xyz/v.w;
   	vSampleNormalDepth.a = mul(float4(wp,1), matViewProj).z/50000;
		
		if( dot( vSampleNormalDepth.rgb, vNormalDepth.rgb) < 0.9f || abs( vSampleNormalDepth.a - vNormalDepth.a ) > 0.01f ) fWeight = 0.0f;
		cResult += cValue * fWeight;
		fTotalWeight += fWeight;
		
		//cValue = tex2D( p_sSeparateBlurMap, INTERPOLANT_GaussianBlurSample[i].zw );
		//fWeight = p_fBlurWeights[i * 2 + 2];
		//vSampleNormalDepth = tex2D( ssaoSampler, INTERPOLANT_GaussianBlurSample[i].zw );
		//if( dot( vSampleNormalDepth.rgb, vNormalDepth .rgb < 0.9f ) || abs( vSampleNormalDepth.a - vNormalDepth.a ) > 0.01f ) fWeight = 0.0f;
		//cResult += cValue * fWeight; fTotalWeight += fWeight;
		
	}
	
	// Rescale result according to number of discarded samples.
	cResult *= 1.0f / fTotalWeight;
	//cResult.rgb = vNormalDepth.rgb;
	//cResult.rgb = tex2D( ssaoSampler, inTex.xy).rgb;
	return cResult;
}
*/


technique ssaoBlur
{
	
	pass p0
	{
		
		//alphablendenable=true;
   	//srcblend=one;
    	//destblend=one;
		PixelShader = compile ps_2_a blur(float(4));
	}

}
