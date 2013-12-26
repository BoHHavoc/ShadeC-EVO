
float4 mainPS():COLOR0
{
	
   return float4(1,0,0,1);
}

technique t1
{
	
	pass p0
	{
		//VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_0 mainPS();
			alphablendenable = true;
		
		
		stencilenable = false;
		zenable = true;
		zwriteenable = false;
		cullmode = cw;
		srcblend=2;
    	destblend=2; //2 , 4 , 6
    	ZFunc = LESSEQUAL;
    	FogEnable = FALSE;
	}
}

