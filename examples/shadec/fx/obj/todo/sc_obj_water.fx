bool AUTORELOAD;
bool PASS_SOLID;

//skin1 - normalmap
//skin2 - foammap

float maxDepth = 300; //maximum water depth
float3 waterColorDeep = {0.2, 0.5 , 0.6};
float3 waterColorShallow = {1.0, 1.0 , 1.0};
float foamTiling = 5;
float bumpTiling1 = 1;
float bumpTiling2 = 10;
float camShallowDist = 300;
float shoreHardness = 1;

//use waterdepth (for shoreline, waterfog, water depth)
#define WATERDEPTH

//waterfog (looks more realistic)
//#define WATERFOG

//foam on shoreline
#define FOAM

//if camera gets near to surface, switch to full shallow water
#define CAMSHALLOW

//soft shoreline without hard edges
#define SOFTSHORE

//dynamic lights affect water
//#define DYNLIGHTS

//sun affects water
//#define SUN

//-----------------------------------------------

#ifndef DYNLIGHTS
	#ifndef SUN
		#define NOLIGHTS
	#endif
#endif

#ifdef WATERFOG
	#define WATERDEPTH
#endif

#ifdef SUN
	#ifdef DYNLIGHTS
		#define PS_3_0
	#endif
#endif

float4x4 matWorld;
float4x4 matWorldViewProj;
//float4x4 sc_depth_matWorldViewProjInv_flt;
float4x4 matMtl;
float4x4 matTangent;

float4 vecTime;
float4 vecSkill1;
float4 vecSkill5;
float4 vecSkill9;
float4 vecSkill17;
float4 vecViewPort;
float4 vecViewPos;
float4 vecLightPos[8];
float4 vecLightColor[8];
float4 vecSunDir;
float4 vecSunColor;
float fPower;

texture entSkin1; //normalmap + alpha
texture entSkin2; //foam
texture TargetMap; //scene
texture mtlSkin1; //scene depth

sampler2D sceneSampler = sampler_state
{
	Texture = <TargetMap>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

sampler depthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

sampler2D normalSampler = sampler_state
{
	Texture = <entSkin1>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D foamSampler = sampler_state
{
	Texture = <entSkin2>;

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct vsOut
{
	float4 Pos : POSITION;
	float4 Tex : TEXCOORD0;
	float4 projCoord : TEXCOORD1;
	float3 Normal  	: TEXCOORD2;
	float3 wPos : TEXCOORD3;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
	float3 Normal 		: NORMAL;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.Pos = mul(In.Pos,matWorldViewProj);
   Out.projCoord = Out.Pos;
   
   Out.Tex.xy = float2(In.Tex.x + vecTime.w * vecSkill1.x * 0.001, In.Tex.y + vecTime.w * vecSkill1.y * 0.001);
   Out.Tex.zw = float2(In.Tex.x + vecTime.w * vecSkill1.x * 0.002, In.Tex.y + vecTime.w * vecSkill1.y * -0.002);
   Out.Normal.xyz = mul(float4(In.Normal.xyz,0), matWorld);
   Out.wPos.xyz = mul(float4(In.Pos.xyz,1), matWorld);
   
   return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	float4 color = 1;
	
	//projective texcoords
	float2 projTex;
	projTex.x = In.projCoord.x/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.x);
   projTex.y = -In.projCoord.y/In.projCoord.w/2.0f +0.5f + (0.5/vecViewPort.y);
   float2 projTexOrg = projTex;
   
   //clip non visible parts
   float texDepth = tex2D(depthSampler,projTex.xy).r;
   if(texDepth == 0) texDepth = 1;
	
	float realDepth = In.projCoord.z/In.projCoord.w;
	float refrMask = 1;
	if(texDepth < realDepth && texDepth != 0)
	{
		clip(-1);
	} 
	
	//compute world position
	float4 vp = float4(projTex.xy * float2(2, -2) - float2(1, -1), texDepth, 1);
	float4 v = mul(vp, matMtl);
	float3 wp = v.xyz/v.w;
	
	float waterDepth = clamp(((1.0f-(wp.y-vecSkill9.z))/maxDepth),0,1);	
	
	if(vecViewPos.y < vecSkill9.z) waterDepth = 1-waterDepth;
	//refract texcoords
	float3 normal = (tex2D(normalSampler,In.Tex.zw*bumpTiling1).rgb*2)-1;
	float2 bump = normal.xy;
	projTex = projTex.xy - (  normal.xy  * vecSkill1.z * 0.025 * waterDepth);
	normal = (tex2D(normalSampler,In.Tex.xy*bumpTiling2).rgb*2)-1;
	bump += normal.xy;
	projTex -= (  normal.xy  * vecSkill1.z * 0.05 * waterDepth);

	//project to object
	color.rgb = tex2D(sceneSampler,projTex.xy/vecSkill17.xy).rgb;
	
	#ifdef WATERDEPTH
		//compute REFRACTED world position
		texDepth = tex2D(depthSampler,projTex.xy).r;
		vp = float4(projTex.xy * float2(2, -2) - float2(1, -1), texDepth, 1);
		v = mul(vp, matMtl);
		wp = v.xyz/v.w;
		float waterDepthRefr = clamp((1.0f-(wp.y-vecSkill9.z))/maxDepth,0,1);
	#else
		float waterDepthRefr = 0;
	#endif
	
	#ifdef FOAM
		half4 foam = tex2D(foamSampler, (In.Tex.xy*foamTiling) - (  normal.xy  * vecSkill1.z * 0.025 * waterDepth));
		foam.xyz *= foam.a;
		color.rgb += foam.xyz*(1-waterDepth);//lerp(color.rgb,foam.xyz,(1-waterDepth)*foam.a);
	#endif
	
	#ifdef CAMSHALLOW
		float fullShallow = saturate(1.0f - length(vecViewPos- In.wPos.xyz)/camShallowDist);
		fullShallow = refract(fullShallow, normal.y, 0.95);
		waterDepthRefr = lerp(waterDepthRefr,0,fullShallow);
	#endif
	
	
	
	#ifdef WATERFOG
		color.rgb =  lerp(color.rgb*waterColorShallow, waterColorDeep, waterDepthRefr);
	#else
		color.rgb =  lerp(color.rgb*waterColorShallow, color.rgb*waterColorDeep, waterDepthRefr);
	#endif
	
	//LIGHTING
	float3 Hn;
	float4 finalLight = 0;
	In.Normal.x += bump.x;
	In.Normal.y += bump.y;
	In.Normal.xyz = normalize(In.Normal.xyz);
	#ifdef DYNLIGHTS
	float3 Ln = 0;
	float att = 0;
	float3 lightDir = 0;
	float4 lightColor = 0;
	for (int i=0; i<3; i++)  // Add 8 dynamic lights
	{	
		if(vecLightPos[i].w < 100000 && vecLightPos[i].w > 0)
		{
			Ln = (vecLightPos[i].xyz - In.wPos.xyz);
			att = saturate(1.0f - length(Ln)/(vecLightPos[i].w));
			lightDir.xyz += (vecLightPos[i].xyz-In.wPos.xyz)*att;
			//Out.lightDir.xyz += lerp(min((vecLightPos[i].xyz-wPos.xyz)*att,Out.lightDir.xyz),max((vecLightPos[i].xyz-wPos.xyz)*att,Out.lightDir.xyz),0.5);
			//att = pow(att,2);//saturate(1.0f - length(Ln)/(vecLightPos[i].w));
			lightColor.xyz += vecLightColor[i].xyz*att;
			lightColor.w += att;
			
			//Out.lightDir.xyz = normalize(Out.lightDir.xyz);
		}
	}
	//lightDir /= 3;
	Hn = normalize((vecViewPos.xyz-In.wPos.xyz) + lightDir.xyz);
	float2 lighting = saturate(lit(dot(In.Normal.xyz, lightDir), dot(Hn.xyz, In.Normal.xyz), 25).yz) * lightColor.w;
	finalLight.xyz += lighting.x * lightColor.rgb;
	finalLight.w += lighting.y * lightColor.rgb;
	#endif
	
	
	
	#ifdef SUN
	Hn = normalize((vecViewPos.xyz-In.wPos.xyz) - vecSunDir.xyz);
	float2 sunLight = saturate(lit(dot(In.Normal.xyz, -vecSunDir.xyz), dot(Hn.xyz, In.Normal.xyz), 25).yz);
	finalLight.xyz += sunLight.x * vecSunColor.xyz;
	finalLight.w += sunLight.y * vecSunColor.xyz;
	#endif

	#ifndef NOLIGHTS
	//finalLight.xyz += 1-refract(finalLight.xyz, -normal.x-normal.y,1);
	//finalLight.y = refract(finalLight.y, normal.y,0.1);
	//finalLight.xyz += normal.x;
	color.rgb *= finalLight.xyz;
	color.rgb += finalLight.w;
	#endif
	
	#ifdef SOFTSHORE
		color.rgb = lerp(tex2D(sceneSampler, projTex/vecSkill17.xy).rgb, color.rgb,saturate(waterDepthRefr*shoreHardness));
	#endif
	
	/*
	color.rgb = tex2D(depthSampler, projTex).rgb;
	
	
	texDepth = tex2D(depthSampler, projTex).r;
	vp = float4(projTex.xy * float2(2, -2) - float2(1, -1), texDepth, 1);
	v = mul(vp, matMtl);
	wp = v.xyz/v.w;
	waterDepthRefr = clamp((1.0f-(wp.y-vecSkill9.z))/maxDepth,0,1);
	color.rgb = wp.xyz;
	*/
	
	//color.rgb = 1;
	//color.rgb = tex2D(sceneSampler, projTexOrg).rgb*;
	
	
	return color;
}

technique t1
{
	pass p0
	{
		VertexShader = compile vs_2_0 mainVS();
		#ifdef PS_3_0
			PixelShader = compile ps_3_0 mainPS();
		#else
			PixelShader = compile ps_2_a mainPS();
		#endif
		alphablendenable = TRUE;
		cullmode = none;
	}
}

