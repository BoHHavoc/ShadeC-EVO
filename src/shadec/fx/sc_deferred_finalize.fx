//#include <scUnpackSpecularData>

texture mtlSkin1; //albedo and emissive mask
texture mtlSkin2; //lighting, diffuse and specular
texture mtlSkin3; //brdf data
texture mtlSkin4; // ssao

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
	float2 Tex : TEXCOORD0;
};

float4 mainPS(psIn In):COLOR0
{
	half4 albedoAndEmissiveMask = tex2D(albedoAndEmissiveMaskSampler, In.Tex);
	half4 diffuseAndSpecular = tex2D(diffuseAndSpecularSampler, In.Tex); //get lighting
	half4 materialData = tex2D(materialDataSampler, In.Tex);
	diffuseAndSpecular.w = diffuseAndSpecular.a/length(diffuseAndSpecular.xyz) * 2; //unpack specular
	diffuseAndSpecular.xyz *= 2; //rescale
	//diffuseAndSpecular.w *= 2;
	
	//apply ssao
	half4 ssao = tex2D(ssaoSampler, In.Tex);
	diffuseAndSpecular.xyz *= ssao.w;
	diffuseAndSpecular.xyz += ssao.xyz;
	
	//albedoAndEmissiveMask.xyz = 1; //debug only
	
	//sky
	if(materialData.x == 0)
	{
		diffuseAndSpecular.xyz = 1;
		diffuseAndSpecular.w = 0;
	}
	
	
	half4 output = 1;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = albedoAndEmissiveMask.xyz * diffuseAndSpecular.xyz + diffuseAndSpecular.w*diffuseAndSpecular.xyz*specularMask;
	//output.xyz = pow(albedoAndEmissiveMask.xyz,2) //convert color to linear space for later gamma correction
	output.xyz = albedoAndEmissiveMask.xyz
					 * diffuseAndSpecular.xyz  + diffuseAndSpecular.w*diffuseAndSpecular.xyz*materialData.z;
	
	//emissive
	output.xyz += albedoAndEmissiveMask.xyz * albedoAndEmissiveMask.w;
	
	//output.xyz = albedoAndEmissiveMask.xyz;
	//output.xyz = diffuseAndSpecular.xyz;//*specularMask;
	//output.xyz = diffuseAndSpecular.a * diffuseAndSpecular.xyz;// *specularMask;
	
	//output.xyz = sqrt(output.xyz); //gamma correction
	//output.xyz = pow(output.xyz, (float)1.0/(float)2.2); //gamma correction
	
	//output.xyz = materialData.r;
	//output.xyz = diffuseAndSpecular.xyz;
	//output.xyz = albedoAndEmissiveMask.xyz;
	
	//output.xyz = diffuseAndSpecular.xyz;
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