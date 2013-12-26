#include <scUnpackNormals>
#include <scUnpackDepth>
//#include <scUnpackSpecularData>

//#define STENCILMASK

bool AUTORELOAD;
bool PASS_SOLID;

float4x4 matProj;
float4x4 matWorldView;
float4x4 matView;

float4 vecViewPort;
float4 vecViewDir;

texture mtlSkin1; //normals (xy) depth (zw)
texture mtlSkin4; //material id (x), specular power (y), specular intensity (z), environment map id (w)
texture texBRDFLut; //brdf equations stored in volumetric texture
texture texMaterialLUT; //material data texture -> x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound

float4 vecSkill1; //lightpos (xyz), lightrange (w)
float4 vecSkill5; //light color (xyz), scene depth (w)
float4 vecSkill9; //light dir (xyz), stencil ref (w)
//float4 vecTime;

sampler normalsAndDepthSampler = sampler_state 
{ 
   Texture = <mtlSkin1>; 
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
};

sampler materialDataSampler = sampler_state 
{ 
   Texture = <mtlSkin4>; 
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
	AddressU = Border;
	AddressV = Border;
	//BorderColor = 0xFFFFFFFF;
	BorderColor = 0x00000000;
};

sampler1D materialLUTSampler = sampler_state 
{ 
   Texture = <texMaterialLUT>; 
   AddressU = WRAP; 
	AddressV = WRAP;
	AddressW = WRAP;
   MinFilter = NONE;
	MagFilter = NONE;
	MipFilter = NONE;
};

sampler3D brdfLUTSampler = sampler_state 
{
	Texture = <texBRDFLut>;
   AddressU = CLAMP; 
	AddressV = CLAMP;
	AddressW = WRAP;
	MIPFILTER = NONE;
	MINFILTER = LINEAR; //fade between brdfs
	MAGFILTER = LINEAR; //fade between brdfs
	//MINFILTER = NONE; // dont fade between brdfs
	//MAGFILTER = NONE; // dont fade between brdfs
};

struct vsOut
{
	float4 Pos : POSITION;
	float3 projCoord : TEXCOORD0;
	float4 posVS : TEXCOORD1;
	half2 texCoord : TEXCOORD2;
};

struct vsIn
{
	float4 Pos : POSITION;
	float2 texCoord : TEXCOORD0;
};

vsOut mainVS(vsIn In)
{
	vsOut Out = (vsOut)0;
	
	Out.posVS = mul(In.Pos, matWorldView);
	Out.Pos = mul(Out.posVS,matProj);
   Out.projCoord = Out.Pos.xyw;
   
   Out.texCoord = In.texCoord;
   
	
	return Out;
}

float4 mainPS(vsOut In):COLOR0
{
	//je nach tiefe clippen...
	//discard;
	
	half4 color = 0;
	
	//projective texcoords
	float2 projTex;
	projTex.x = In.projCoord.x/In.projCoord.z/2.0f +0.5f + (0.5/vecViewPort.x);
   projTex.y = -In.projCoord.y/In.projCoord.z/2.0f +0.5f + (0.5/vecViewPort.y);
   
   //get gBuffer   
   half4 gBuffer = tex2D(normalsAndDepthSampler, projTex);
   gBuffer.z = UnpackDepth(gBuffer.zw);
   
   //get specular data
   //half2 glossAndPower = UnpackSpecularData(tex2D(emissiveAndSpecularSampler, projTex).w);
   
   
   //clip pixels which can't be seen
   //not really needed anymore due to correct zbuffer culling :)
   //float junk = ((In.posVS.z/vecSkill5.w))-(gBuffer.z);//length(gBuffer.z-(In.posVS.z/vecSkill5.w));
   //clip(((In.posVS.z/vecSkill5.w))-(gBuffer.z));
   
   //decode normals
   half3 normal = UnpackNormals(gBuffer.xy);
      
   //get view pos
   float3 vFrustumRayVS = In.posVS.xyz * (vecSkill5.w/In.posVS.z);
   float3 posVS = gBuffer.z * vFrustumRayVS;
   
   
   //half3 Ln = mul(float3(vecSkill9.x,vecSkill9.z,vecSkill9.y)-vecViewPos.xyz,matView) - posVS.xyz;
   half3 Ln = mul(vecSkill1.xzy,matView) - posVS.xyz;
   half att = saturate(1-length(Ln)/vecSkill1.w);
   clip(att-0.001);
   Ln = normalize(Ln);
   //half3 Vn = normalize(matView[0].xyz - posVS);//normalize(IN.WorldView);
   half3 Vn = normalize(vecViewDir.xyz - posVS); //same as above but less arithmetic instructions
   half3 Hn = normalize(Vn + Ln);
   
   
   //half4 brdfData = (tex2D(materialDataSampler, projTex)); //get brdf gBuffer
   //half2 light = lit(dot(Ln,normal), dot(Hn, normal),brdfData.g*255).yz;
	//color.rgb = light.x * vecSkill5.xyz * att;//vecSkill5.xyz;
   //color.a = light.y;// * glossAndPower.x;
   //color.rgb = dot(Ln,normal)*att*vecSkill5.xyz;
   
   
    //material data
   half2 materialData = (tex2D(materialDataSampler, projTex)).xy; //get material ID and specular power
   //half4 brdfData1 = tex3D( matData1Sampler,half3(In.texCoord, materialData.r) ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
   half4 brdfData1 = tex1D( materialLUTSampler, materialData.r ); // x = lighting equation Lookup Texture index // y = diffuse roughness // z = diffuse wraparound
   //brdfData1.r = 0.0039;
   
   //materialData.r = brdfData1.r;
     
   half OffsetU = (brdfData1.y-0.5)*2; //diffuse roughness
   half OffsetV = (brdfData1.z-0.5)*2; //diffuse wraparound/velvety
   //half2 nuv = float2((0.5+saturate(dot(Ln,normal)+OffsetU)/2.0),	saturate(1.0 - (0.5+dot(normal,Vn)/2.0)) + OffsetV); //diffuse brdf uv, no options
  	half2 diffuseUV = half2( (dot(Vn, normal)+OffsetU) , ((dot(Ln, normal) + 1) * 0.5)+OffsetV ); //diffuse brdf uv. options (OffsetU/V)
  	half3 diffuse = tex3D( brdfLUTSampler,half3(diffuseUV , brdfData1.r) ).rgb;
   color.rgb = diffuse * att * vecSkill5.xyz;
   
   //additional clipping based on diffuse lighting. clip non-lit parts
   //half shaded = (color.r+color.g+color.b)/3;
   half shaded = (color.r+color.g+color.b);
	clip(shaded-0.001);
   
   //fps hungry....
   //half2 specularUV = ( dot(Ln,Hn) , dot(normal,Hn)-materialData.g ); //isotropic
   half2 specularUV = ( dot(Ln,Hn) , dot(normal,Hn)); //isotropic
   //anisotropic
   	//specularUV.x = 0.5+dot(Ln,normal)/2.0;
   	//specularUV.y = 1-(0.5+dot(normal,Hn)/2.0);
   half3 specular = tex3D( brdfLUTSampler, half3(specularUV, brdfData1.r) ).a;
   color.a = pow(specular+0.005, materialData.g*255);
   //...
   //conventional specular
   //color.a = pow(dot(normal,Hn),materialData.g*255);
   
    
   //color.rgb = pow(diffuse,diffuseRoughness) * att * vecSkill5.xyz;
   //color.a = (saturate(pow(specular,materialData.g*255)));
      
	//pack
	//color.rgb /= 1.5;
	//color.rgb += brdfData1.rgb*color.rgb;
		
	color.rgb *= 0.5;
	color.a *= length(color.rgb);
   return color;
}

technique t1
{
	#ifdef STENCILMASK
	//set stencil
	pass stencil
	{
		VertexShader = NULL;
		PixelShader = NULL;
		
		ColorWriteEnable = 0x0;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESS;
		StencilEnable = TRUE;
		StencilRef = vecSkill9.w;
		StencilFunc = ALWAYS;
		StencilPass = REPLACE;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilMask		= 0xFFFFFFFF;
      StencilWriteMask = 0xFFFFFFFF;
		CullMode = CCW;      
		
		// Disable writing to the frame buffer
      AlphaBlendEnable	= true;
      SrcBlend = Zero;
      DestBlend = One;
      
      
	}
	#endif
	
	pass lighting
	{
		VertexShader = compile vs_2_0 mainVS();
		PixelShader = compile ps_2_a mainPS();
		
		ColorWriteEnable = 0xFFFFFF;
		ZWriteEnable = FALSE;
		ZFunc = GREATEREQUAL;
		AlphablendEnable = TRUE;
		CullMode = CW;
    	Srcblend = One;
    	Destblend = One; 
    	FogEnable = FALSE;
    	ZEnable = true;
		
		#ifdef STENCILMASK
		//stencil test
		StencilFunc = EQUAL;
		StencilPass = KEEP;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilRef = vecSkill9.w;
		StencilEnable = TRUE;
		StencilMask		= 0xFFFFFFFF;
      StencilWriteMask = 0xFFFFFFFF;
      #endif
    	

	}
}

