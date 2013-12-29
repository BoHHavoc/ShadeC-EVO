#include <scUnpackDepth>

float4 vecSkill1; // x = inverted downsample factor (2->0.5), y = clip_far; z = focal pos, w = focal width
float4 vecViewPort;

texture mtlSkin1; //current scene without dof
texture mtlSkin2; //blurred scene
texture mtlSkin3; //nomals and depth

sampler2D currentSceneSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};


sampler2D blurSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D normalsAndDepthSampler = sampler_state
{
	Texture = <mtlSkin3>;

	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};




float4 mainPS(float2 inTex:TEXCOORD0):COLOR0
{
	inTex *= vecSkill1.x;
	
	inTex.x += (0.5/vecViewPort.x); //half pixel fix
	inTex.y += (0.5/vecViewPort.y); //half pixel fix
	
	half3 color = tex2D(currentSceneSampler, inTex).xyz;
	half3 blur = tex2D(blurSampler, inTex).xyz;

	//get depth
	half depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex).zw);
	
	//full res focal plane
	half focalPlane = depth*vecSkill1.y;
	focalPlane = ((focalPlane-vecSkill1.z)/vecSkill1.w) * ((focalPlane-vecSkill1.z)/vecSkill1.w);
	focalPlane = saturate(focalPlane);
	
	/*
	//half res, blurred focal plane
	half blurredFocalPlane = tex2D(blurSampler, inTex).a;
	
	//foreground focal plane
	half foregroundPlane = max(focalPlane, blurredFocalPlane);
	
	//background plane
	half backgroundPlane = focalPlane;
	
	//calculate lerp factor for foreground and background
	half focalPlaneLerpFactor = saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	float CoCSize = 80;
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z, vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z, vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z, -vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z, -vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z, 0)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z, 0)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(0, vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	depth = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(0, -vecViewPort.w)*CoCSize ).zw);
	focalPlaneLerpFactor += saturate(( (depth*vecSkill1.y) -vecSkill1.z)/1);
	
	focalPlaneLerpFactor /= 9;
	
	focalPlane = lerp(foregroundPlane, backgroundPlane, focalPlaneLerpFactor);
	*/
	
	
	
	
	//focalPlane = lerp(focalPlane, 1, tex2D(blurSampler, inTex).w - focalPlane);
	//focalPlane = tex2D(blurSampler, inTex).w;
	/*
	vecViewPort *= 4;
	half blurFocus = tex2D(blurSampler, inTex + half2(vecViewPort.z,0)).w;
	blurFocus += tex2D(blurSampler, inTex + half2(-vecViewPort.z,0)).w;
	blurFocus += tex2D(blurSampler, inTex + half2(0, vecViewPort.w)).w;
	blurFocus += tex2D(blurSampler, inTex + half2(0, -vecViewPort.w)).w;
	*/
	
	/*
	half blurFocus = UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(vecViewPort.z,0)).zw);
	blurFocus += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(-vecViewPort.z,0)).zw);
	blurFocus += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(0, vecViewPort.w)).zw);
	blurFocus += UnpackDepth(tex2D(normalsAndDepthSampler, inTex + half2(0, -vecViewPort.w)).zw);
	blurFocus *= 0.25;
	half blurFocalPlane = blurFocus*vecSkill1.y;
	blurFocalPlane = ((blurFocalPlane-vecSkill1.z)/vecSkill1.w) * ((blurFocalPlane-vecSkill1.z)/vecSkill1.w);
	blurFocalPlane = saturate(blurFocalPlane);
	*/
	
	focalPlane = max(focalPlane, tex2D(blurSampler, inTex-vecViewPort.zw).w);//lerp(focalPlane, max(focalPlane, tex2D(blurSampler, inTex).w), focalPlanePos);
	
	color = lerp(color, blur, focalPlane);
	//color = focalPlanePos;
	
	
	return half4(color,1);
}

technique t1
{
	pass p0
	{
		PixelShader = compile ps_2_0 mainPS();
	}	
}