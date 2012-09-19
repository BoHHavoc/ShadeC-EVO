#include <scHeaderLightShadowmap>

#define CUSTOM_PS_EXTEND
#ifndef VECSKILL1
	#define VECSKILL1
	float4 vecSkill1;
#endif
#ifndef ENTSKIN1
#define ENTSKIN1
	texture entSkin1;
#endif
sampler colorSampler = sampler_state
{
	Texture = <entSkin1>;
	AddressU = WRAP;
	AddressV = WRAP;
};
psOut Custom_PS_Extend(vsOut InPs, psOut OutPs)
{
	half clipValue = (dot(tex2D(colorSampler, InPs.Tex).rgb,1)*vecSkill1.x)-1;
	clip(clipValue);

	return OutPs;
}

#include <scLightShadowmap>