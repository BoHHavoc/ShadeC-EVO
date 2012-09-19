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
#define GLOSSSTRENGTH 0 //glossmap channel will be set to this value if GLOSSMAP is not defined

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#include <scHeaderObject>


#define CUSTOM_VS_POSITION
#ifndef MATWORLD
#define MATWORLD
	float4x4 matWorld;
#endif
#ifndef MATWORLDVIEWPROJ
#define MATWORLDVIEWPROJ
	float4x4 matWorldViewProj;
#endif
#ifndef VECTIME
#define VECTIME
	float4 vecTime;
#endif
#ifndef VECSKILL1
#define VECSKILL1
	float4 vecSkill1;
#endif
float4 Custom_VS_Position(vsIn In)
{
	float3 P = mul(In.Pos, matWorld);
	float force_x = vecSkill1.x; 
	float force_y = vecSkill1.y;
	float speed = sin((vecTime.w+0.2*(P.x+P.y+P.z)) * vecSkill1.z);
	
	if (In.Pos.y > 0 ) // move only upper part of tree
	{
		In.Pos.x += speed * force_x * In.Pos.y;
		In.Pos.z += speed * force_y * In.Pos.y;
		In.Pos.y -= 0.1*abs(speed*(force_x+force_y)) * In.Pos.y;
	}
	
	return mul(In.Pos,matWorldViewProj);
}

#define CUSTOM_PS_EMISSIVEMASK
float Custom_PS_EmissiveMask(vsOut In, float emissive)
{
	return vecSkill1.w;
}


#include <scObject>


