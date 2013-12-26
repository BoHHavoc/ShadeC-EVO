texture mtlSkin1; //final scene with post processing applied

sampler2D sceneSampler = sampler_state
{
	Texture = <mtlSkin1>;
	MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
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
	half4 output = tex2D(sceneSampler, In.Tex);

	output.xyz = sqrt(output.xyz); //gamma correction
	//output.xyz = pow(output.xyz, (float)1.0/(float)2.2); //gamma correction
	
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