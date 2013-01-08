//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_NORMAL (skin2.xyz) //normalmap
#define SKIN_GLOSS (skin2.w) //glossmap
//...

#define NORMALMAPPING //do normalmapping?

#define GLOSSMAP //entity has glossmap?

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#include <scHeaderObject>


#define CUSTOM_PS_EXTEND
#ifndef VECSKILL1
	#define VECSKILL1
	float4 vecSkill1;
#endif
psOut Custom_PS_Extend(vsOut InPs, psOut OutPs)
{
	//fetch output color and calculate clip value from it
	half clipValue = (dot(OutPs.AlbedoAndEmissiveMask.xyz,1)*vecSkill1.x)-1;
	//apply clipping
	clip(clipValue);
	
	//output clipvalue to emissive buffer for some nice glow on edges where clipping will occur in the near future
	OutPs.AlbedoAndEmissiveMask.w = (1-saturate(clipValue))*0.5;
	//set emissive color
	OutPs.AlbedoAndEmissiveMask.xyz = lerp(OutPs.AlbedoAndEmissiveMask.xyz, vecSkill1.yzw, pow(1-saturate(clipValue),2));
	
	return OutPs;
}

#include <scObject>


