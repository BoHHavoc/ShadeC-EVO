bool AUTORELOAD;

float4x4 matMtl;
float4x4 matViewProj;

Texture TargetMap;
sampler2D ssaoSampler = sampler_state {
	texture = <TargetMap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

Texture mtlSkin1;
sampler2D colorSampler = sampler_state {
	texture = <mtlSkin1>;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

Texture mtlSkin2;
sampler2D depthSampler = sampler_state {
	texture = <mtlSkin2>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

float4 vecViewPort; // contains viewport pixel size in zw components
float4 vecSkill1;

float2 taps[7] = {
   -0.00695914,  0.00457137,
   -0.00203345,  0.00620716,
    0.00962340, -0.00194983,
    0.00507431,  0.0064425,
    0.00896420,  0.00412458,
   -0.00321940, -0.00932615,
   -0.00791559, -0.00597705,
};

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
//	return tex2D(ssaoSampler, position);
	
	return half4(r.rgb , r.a);
}

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