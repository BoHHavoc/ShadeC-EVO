//#include <scUnpackSpecularData>
#include <scUnpackLighting>

float4 vecSkill1; //xyz = ambient_color

texture mtlSkin1; //albedo and emissive mask
texture mtlSkin2; //lighting, diffuse and specular
texture mtlSkin3; //brdf data
texture mtlSkin4; //ssao

sampler2D albedoAndEmissiveMaskSampler = sampler_state
{
	Texture = <mtlSkin1>;

	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D diffuseAndSpecularSampler = sampler_state
{
	Texture = <mtlSkin2>;

	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler2D materialDataSampler = sampler_state
{
	Texture = <mtlSkin3>;

	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
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

float4 mainPS(psIn In):COLOR
{
	half4 albedoAndEmissiveMask = tex2D(albedoAndEmissiveMaskSampler, In.Tex);
	half4 diffuseAndSpecular = UnpackLighting(tex2D(diffuseAndSpecularSampler, In.Tex));
	half4 materialData = tex2D(materialDataSampler, In.Tex);
	//diffuseAndSpecular.w = diffuseAndSpecular.a/length(diffuseAndSpecular.xyz) * 2; //unpack specular
	//diffuseAndSpecular.xyz *= 2; //rescale
	//diffuseAndSpecular.w *= 2;
	//get ssao
	half4 ssao = tex2D(ssaoSampler, In.Tex);
	diffuseAndSpecular.xyz *= ssao.w;
	diffuseAndSpecular.xyz += ssao.xyz;
	
	//albedoAndEmissiveMask.xyz = 1; //debug only
	
	//sky
	if(materialData.x == 0)
	{
		diffuseAndSpecular.xyz = 1;
		diffuseAndSpecular.w = 0;
		//ssao.w = 1;
		//ssao.xyz = 0;
	}
	
	//gamme correction
	//diffuseAndSpecular.xyz = pow(diffuseAndSpecular.xyz, 1.f/2.2f);
	//albedoAndEmissiveMask.xyz = pow(albedoAndEmissiveMask.xyz, 1.f/2.2f);
	albedoAndEmissiveMask.xyz = pow(albedoAndEmissiveMask.xyz, 2.2);
	
	//diffuseAndSpecular.xyz = (diffuseAndSpecular.xyz*(6.2*diffuseAndSpecular.xyz+0.5))/(diffuseAndSpecular.xyz*(6.2*diffuseAndSpecular.xyz+1.7)+0.06);
	half4 output;// = 1;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = pow(albedoAndEmissiveMask.xyz,2) //convert color to linear space for later gamma correction
	output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz //pow(albedoAndEmissiveMask.xyz,2.2f) * diffuseAndSpecular.xyz
					 + diffuseAndSpecular.w*diffuseAndSpecular.xyz*materialData.z;
					 //* (((diffuseAndSpecular.xyz+vecSkill1.xyz)*ssao.w)+ssao.xyz)  + diffuseAndSpecular.w*diffuseAndSpecular.xyz*materialData.z*ssao.w;
	
	output.xyz = pow(output.xyz, 1.0/2.2);
	
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
	//output.xyz = diffuseAndSpecular.w;
	output.w = 1;
	
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
	}
}