//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_ALPHA (skin1.w) //alpha
#define SKIN_NORMAL (skin2.xyz) //normalmap
#define SKIN_GLOSS (skin2.w) //glossmap
//...

#define NORMALMAPPING //do normalmapping?

#define GLOSSMAP //entity has glossmap?
#define GLOSSSTRENGTH 0 //glossmap channel will be set to this value if GLOSSMAP is not defined

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#include <scHeaderObject>


#define CUSTOM_VS_TEX
#ifndef VECTIME
	#define VECTIME
	float4 vecTime;
#endif
#ifndef VECSKILL1
	#define VECSKILL1
	float4 vecSkill1;
#endif

float2 Custom_VS_Tex(vsIn In)
{
	return In.Tex.xy + vecTime.w*vecSkill1.xy*0.001;
}


#include <scObject>


