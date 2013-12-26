//#include <scUnpackSpecularData>
#include <scUnpackLighting>

/*
float3 vecViewDir;
#include <scUnpackNormals>
#include <scUnpackDepth>
#include <scCalculatePosVSQuad>
*/

float4 vecSkill1; //xyz = ambient_color

texture mtlSkin1; //albedo and emissive mask
texture mtlSkin2; //lighting, diffuse and specular
texture mtlSkin3; //brdf data
texture mtlSkin4; //ssao

sampler2D albedoAndEmissiveMaskSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
	
	SRGBTexture = true;
};

sampler2D diffuseAndSpecularSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D materialDataSampler = sampler_state
{
	Texture = <mtlSkin3>;

	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D ssaoSampler = sampler_state
{
	Texture = <mtlSkin4>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct psIn
{
	float4 Pos : POSITION;
	half2 Tex : TEXCOORD0;
};


float4 OffsetMapping (float NdotL, float NdotV, sampler2D tex)
{
   //float fNdotL = dot(vecNormal, vecLight);
   //float fNdotE = saturate(dot(vecNormal, vecView));
   float4 texBrdf = tex2D(tex, float2((NdotL * .5 + .5), NdotV));

   return texBrdf;
}

float4 vecViewPort;
half4 DoTransparency(half2 inAlphaMask, half alpha, sampler2D inSampler, half2 inTex)
{
	half4 opague;
	half4 translucent;
	
	half4 buffer[2];
	buffer[0] = tex2D(inSampler, inTex);
	buffer[1] = tex2D(inSampler, inTex+half2(vecViewPort.z, 0));
	
	opague = lerp(buffer[0], buffer[1], inAlphaMask.r);
	translucent = lerp(buffer[0], buffer[1], inAlphaMask.g); //  1-inAlphaMask.r is also valid of course...
	
	return lerp(opague, translucent, alpha);
}

float4 mainPS(psIn In):COLOR
{
	half4 albedoAndEmissiveMask;// = tex2D(albedoAndEmissiveMaskSampler, In.Tex);
	half4 diffuseAndSpecular;// = UnpackLighting(tex2D(diffuseAndSpecularSampler, In.Tex));
	half4 materialData = tex2D(materialDataSampler, In.Tex);
	
	
	
	//return half4(materialData.xyz, 1);
	//Do Transparency
	half2 alphaMask;
	alphaMask.x = materialData.w;
	alphaMask.y = tex2D(materialDataSampler, In.Tex+half2(vecViewPort.z,0)).w;
	//alphaMask.z = tex2D(materialDataSampler, In.Tex+half2(0,vecViewPort.w)).w;
	//alphaMask.w = tex2D(materialDataSampler, In.Tex+vecViewPort.zw).w;
	half alpha = dot(alphaMask,1);//max(max(alphaMask.r, alphaMask.g),max(alphaMask.b, alphaMask.a));
	alphaMask = clamp(alphaMask*256,0,1);
	albedoAndEmissiveMask = DoTransparency(alphaMask, alpha, albedoAndEmissiveMaskSampler, In.Tex);
	diffuseAndSpecular = UnpackLighting(DoTransparency(alphaMask, alpha, diffuseAndSpecularSampler, In.Tex));
	materialData = DoTransparency(alphaMask, alpha, materialDataSampler, In.Tex);
	//return diffuseAndSpecular.a;
	//diffuseAndSpecular.w = diffuseAndSpecular.a/length(diffuseAndSpecular.xyz) * 2; //unpack specular
	//diffuseAndSpecular.xyz *= 2; //rescale
	//diffuseAndSpecular.w *= 2;
	//get ssao
	half4 ssao = tex2D(ssaoSampler, In.Tex);
	//return half4(ssao.xyz,1);
	//transparency has no ssao
	ssao.w = clamp(ssao.w+alphaMask.r+alphaMask.g, 0,1);
	//only needed for ssdo...
	//ssao.xyz *= 1-(alphaMask.r+alphaMask.g);
	
	//return half4(ssao.xyz*pow(ssao.w,2),1);
	//
	diffuseAndSpecular.xyz *= ssao.w;
	//only needed for ssdo...
	//diffuseAndSpecular.xyz += ssao.xyz;
	//return half4(diffuseAndSpecular.xyz, 1);
	//albedoAndEmissiveMask.xyz = 1; //debug only

	
	
	/*
	//sky
	//...this is now handled in the sun shader :)
	if(materialData.x == 0)
	{
		diffuseAndSpecular.xyz = 1;
		diffuseAndSpecular.w = 0;
		//ssao.w = 1;
		//ssao.xyz = 0;
	}
	*/
	
	//gamme correction
	//albedoAndEmissiveMask.xyz = pow(albedoAndEmissiveMask.xyz, 2.2);
	//return half4(diffuseAndSpecular.xyz*diffuseAndSpecular.w, 1);
	//diffuseAndSpecular.xyz = (diffuseAndSpecular.xyz*(6.2*diffuseAndSpecular.xyz+0.5))/(diffuseAndSpecular.xyz*(6.2*diffuseAndSpecular.xyz+1.7)+0.06);
	half4 output;// = 1;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = pow(albedoAndEmissiveMask.xyz,2) //convert color to linear space for later gamma correction
	output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz //pow(albedoAndEmissiveMask.xyz,2.2f) * diffuseAndSpecular.xyz
					 + diffuseAndSpecular.w*diffuseAndSpecular.xyz*materialData.z;
					 //* (((diffuseAndSpecular.xyz+vecSkill1.xyz)*ssao.w)+ssao.xyz)  + diffuseAndSpecular.w*diffuseAndSpecular.xyz*materialData.z*ssao.w;
	
	//gamma correction...we used sRGB when we created the gBuffer
	//output.xyz = pow(output.xyz, 1.0/2.2);
	
	/*				 
	//gamma correction
	//output.xyz = pow(output.xyz,1.f/2.2f);
	//output.xyz = (output.xyz*(6.2*output.xyz+0.5))/(output.xyz*(6.2*output.xyz+1.7)+0.06);
	half Brightness = -0.2;
	half Contrast = 1;
	// Adjust the brightness
   output.xyz = output.xyz + Brightness;
   // Adjust the contrast
   output.xyz = (output.xyz - 0.5) * Contrast + 0.5;
   output.xyz = clamp(output.xyz,0,1);
   //gamma correction
	output.xyz = pow(output.xyz, 1.f/2.2f);
	*/
	
	//emissive
	output.xyz += albedoAndEmissiveMask.xyz * albedoAndEmissiveMask.w;
	
	//output.xyz = albedoAndEmissiveMask.xyz;
	//output.xyz = diffuseAndSpecular.xyz;//*specularMask;
	//output.xyz = diffuseAndSpecular.a * diffuseAndSpecular.xyz;// *specularMask;
	
	//output.xyz = sqrt(output.xyz); //gamma correction
	//output.xyz = pow(output.xyz, (float)1.0/(float)2.2); //gamma correction
	
	//output.xyz = materialData.r;
	//output.xyz = diffuseAndSpecular.xyz + diffuseAndSpecular.xyz * diffuseAndSpecular.a;
	//output.xyz = albedoAndEmissiveMask.xyz;
	
	//output.xyz = diffuseAndSpecular.xyz;
	//output.xyz = ssao.w;
	//output.xyz = UnpackLighting(tex2D(diffuseAndSpecularSampler, In.Tex)).xyz * tex2D(albedoAndEmissiveMaskSampler, In.Tex).xyz;
	//if(dot(output.xyz,1) > 3) output.xyz = 0;
	//output.xyz = diffuseAndSpecular.xyz;// + diffuseAndSpecular.w * diffuseAndSpecular.xyz;
	//output.xyz = diffuseAndSpecular.xyz + diffuseAndSpecular.w * diffuseAndSpecular.xyz;
	output.w = 1;
	
	/*
	//Offset Mapping
	float4 gBuffer = tex2D(ssaoSampler, In.Tex);
	gBuffer.w = UnpackDepth(gBuffer.zw);
	gBuffer.xyz = UnpackNormals(gBuffer.xy);
	float3 posVS = CalculatePosVSQuad(In.Tex, gBuffer.w*5000);
	float3 vecView = normalize(vecViewDir.xyz - posVS);
	float NdotV = saturate(dot(gBuffer.xyz, vecView));
	
	
	vecView.y = -vecView.y;
	half2 offset = half2(gBuffer.x, gBuffer.y)*0.02*(1-gBuffer.w) * vecView.xy*NdotV;
	output.xyz = tex2D(albedoAndEmissiveMaskSampler, In.Tex + offset).xyz;
	output.xyz *= UnpackLighting(tex2D(diffuseAndSpecularSampler, In.Tex + offset)).xyz;
	//output.xyz = OffsetMapping(saturate(diffuseAndSpecular.xyz), NdotV, albedoAndEmissiveMaskSampler).xyz;
	//output.xyz = gBuffer.w;
	//output.xyz = NdotV;
	*/
	
	//output.xyz = ssao.w;
	//output.xyz = diffuseAndSpecular.xyz * albedoAndEmissiveMask.xyz;
	
	
	//gamma correction
	//output = float4( sqrt(output.xyz), output.w);
	
	return output;
}

technique t1
{
	pass p0
	{
		//cullmode = ccw;
		//zwriteenable = false;
		alphablendenable = false;
		//VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
		//FogEnable = False;
		
		SRGBWriteEnable = true;
	}
}