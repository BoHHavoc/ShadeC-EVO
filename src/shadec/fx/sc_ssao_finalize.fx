bool AUTORELOAD;

float4 vecSkill1;
float4 vecSkill5;
float4 vecSkill9;
float4 vecSkill13;
float4 vecSkill17;

float4x4 matWorld;
float4x4 matView;
float4x4 matProj;
float4x4 matWorldView;
float4x4 matViewProj;
float4x4 matViewInv;
float4x4 matWorldViewProj;
float4x4 matMtl;
float4 vecViewPort;
float4 vecViewDir;
float4 vecViewPos;

//Texture TargetMap;
texture mtlSkin1;
sampler2D ssaoSampler = sampler_state {
	//texture = <TargetMap>;
	texture = <mtlSkin1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = MIRROR;
	AddressV = MIRROR;
};
/*
//Texture mtlSkin1;
sampler2D colorSampler = sampler_state {
	texture = <mtlSkin1>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
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

Texture mtlSkin3;
sampler2D depthHalfSampler = sampler_state {
	texture = <mtlSkin3>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};
*/

float4 mainPS(in float2 inTex:TEXCOORD0, in float2 inPos:VPOS):COLOR0
{
	//inTex.xy /=2;	
	
	
	
	/*
	float4 result = 0.0;
	for (int i = 0; i < 4; ++i) {
		for (int j = 0; j < 4; ++j) {
			float2 offset = float2(vecViewPort.z * float(j), vecViewPort.w * float(i));
			result += tex2D(ssaoSampler, (inTex/2) + offset);
		}
	}
	
	return (result * 0.0625);
	*/
	
	
	vecViewPort.x *= 2;
	vecViewPort.y *= 2;
	vecViewPort.z = 1.0f/(vecViewPort.x);
	vecViewPort.w = 1.0f/(vecViewPort.y);
	
	/*
	//dilate / convolute filter to get rid of 1 pixel halo
	half4 output = 0;//tex2D(ssaoSampler, inTex/2);
	output = tex2D(ssaoSampler, (inTex/2) + float2(vecViewPort.z, vecViewPort.w)*2 );
	output = min(output, tex2D(ssaoSampler, (inTex/2) + float2(-vecViewPort.z, vecViewPort.w)*2 ));
	output = min(output, tex2D(ssaoSampler, (inTex/2) + float2(vecViewPort.z, -vecViewPort.w)*2 ));
	output = min(output, tex2D(ssaoSampler, (inTex/2) + float2(-vecViewPort.z, -vecViewPort.w)*2 ));
	return output;///4;
	*/
	
	
	//cheap blur to get rid of noise dots
	//also: slight convolute filter
	half4 output = 0;//tex2D(ssaoSampler, inTex/2);
	output += tex2D(ssaoSampler, (inTex/2) + float2(vecViewPort.z, vecViewPort.w)*2 );
	output += tex2D(ssaoSampler, (inTex/2) + float2(-vecViewPort.z, vecViewPort.w)*2 );
	output += tex2D(ssaoSampler, (inTex/2) + float2(vecViewPort.z, -vecViewPort.w)*2 );
	output += tex2D(ssaoSampler, (inTex/2) + float2(-vecViewPort.z, -vecViewPort.w)*2 );
	return output/4;
	
	
	/*
	//below: bilateral upsampling with correct edge reconstruction etc. yadda yadda
	half4 ssaoOrg = tex2D(ssaoSampler, inTex/2);
	half4 ssao = 0;//ssaoOrg;
  
  	float fDepthHiRes;
	float fDepthsCoarse[4];
	float3 vNormalHiRes;
	float3 vNormalsCoarse[4];
	float4 vShadingCoarse[4];
	
	vShadingCoarse[0] = tex2D(ssaoSampler, inTex/2 + float2(vecViewPort.z, vecViewPort.w) );
	vShadingCoarse[1] = tex2D(ssaoSampler, inTex/2 + float2(-vecViewPort.z, -vecViewPort.w) );
	vShadingCoarse[2] = tex2D(ssaoSampler, inTex/2 + float2(vecViewPort.z, -vecViewPort.w) );
	vShadingCoarse[3] = tex2D(ssaoSampler, inTex/2 + float2(-vecViewPort.z, vecViewPort.w) );
	
	float4 depthNorm = 0;
	depthNorm = tex2D(depthHalfSampler, inTex/2 + float2(vecViewPort.z, vecViewPort.w) ).xyzw;
	fDepthsCoarse[0] = depthNorm.x + depthNorm.w/255;
	vNormalsCoarse[0] = decodeNormals(depthNorm.yz);
	
	depthNorm = tex2D(depthHalfSampler, inTex/2 + float2(-vecViewPort.z, -vecViewPort.w) ).xyzw;
	fDepthsCoarse[1] = depthNorm.x + depthNorm.w/255;
	vNormalsCoarse[1] = decodeNormals(depthNorm.yz);
	
	depthNorm = tex2D(depthHalfSampler, inTex/2 + float2(vecViewPort.z, -vecViewPort.w) ).xyzw;
	fDepthsCoarse[2] = depthNorm.x + depthNorm.w/255;
	vNormalsCoarse[2] = decodeNormals(depthNorm.yz);
	
	depthNorm = tex2D(depthHalfSampler, inTex/2 + float2(-vecViewPort.z, vecViewPort.w) ).xyzw;
	fDepthsCoarse[3] = depthNorm.x + depthNorm.w/255;
	vNormalsCoarse[3] = decodeNormals(depthNorm.yz);
	
	depthNorm = tex2D(depthSampler, inTex/2).xyzw;
	fDepthHiRes = depthNorm.x + depthNorm.w/255;
	vNormalHiRes = decodeNormals(depthNorm.yz); 
  
	
	float vNormalWeights[4];
	for(int i=0;i<4;i++)
	{
		vNormalWeights[i] = dot( vNormalsCoarse[i],vNormalHiRes);
		//vNormalWeights[i] = pow(vNormalWeights[i] , 32 );
		//vNormalWeights[i] = pow(vNormalWeights[i] , 2 );
		vNormalWeights[i] = pow(vNormalWeights[i] , 32 );
	}
	
	float vDepthWeights[4];
	//float EPSILON = 0.001;
	//float EPSILON = 0.00001;
	float EPSILON = 0.001;
	for(int i=0;i<4;i++)
	{
		float fDepthDiff= fDepthHiRes - fDepthsCoarse[i];
		vDepthWeights[i] = 1.0/( EPSILON + abs(fDepthDiff));
	}
	
	float fTotalWeight = 0;
	for(int nSample=0; nSample<4; nSample++)
	{
		float fWeight= vNormalWeights[nSample] *vDepthWeights[nSample];// *vBilinearWeights[nSample];
		fTotalWeight+= fWeight;
		ssao+= vShadingCoarse[nSample]*fWeight;
	}
	ssao/= fTotalWeight;
	
	
	ssao = saturate(ssao);
	ssao = lerp(ssao, ssaoOrg, saturate(1-fTotalWeight+10) );
	
	
	
	half3 color = tex2D(colorSampler, inTex/2 ).rgb;
	
	
	//float vignette  = 1-saturate(dot(inTex-1, inTex-1));//1 - pow(saturate(dot(inTex-1, inTex-1)-0.5),2);
	//vignette += (1-vignette)*0.5;
	
	//ok
	//return half4( (ssao.rgb * saturate(color.r+color.g+color.b)) + (ssao.w*color.rgb),0);
	
	//better ?
	ssao.rgb *= ssao.w;
	ssao.rgb = saturate(ssao.rgb*3);
	ssao.rgba = pow(ssao.rgba, 2);
	//ssao = lerp(ssao, half4(0,0,0,1), saturate(fDepthHiRes*2));
	
	//return half4( (ssao.rgb * length(color.rgb)) + (ssao.w*color.rgb),0);
	return half4(ssao.rgb,ssao.w);
	//return half4(ssao.www, 1);
	//return tex2D(ssaoSampler, inTex);
			
	//return ssao.rgba+ssao.w;
	//return half4(color.rgb, 1);
	//return half4( (ssao.rgb * saturate(color.r+color.g+color.b)) + (ssao.w*color.rgb),0);
	//return half4( (ssao.rgb * length(color.rgb)+ssao.w),0);
	*/
	
	
	
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_a mainPS();
	}
}