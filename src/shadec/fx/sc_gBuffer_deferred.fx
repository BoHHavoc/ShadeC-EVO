//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_ALPHA (skin1.w) //alpha
#define SKIN_NORMAL (skin2.xyz) //normalmap
#define SKIN_GLOSS (skin2.w) //glossmap
//#define SKIN_EMISSIVEMASK (skin3.y) //emissive mask
//#define SKIN_COLOR (skin3.w) //(team)color mask
//...

//#define MTL_SKIN1 //skin1 is a mtlSkin and not an entSkin?
//#define MTL_SKIN2 //skin2 is a mtlSkin and not an entSkin?
//#define MTL_SKIN3 //skin3 is a mtlSkin and not an entSkin?
//#define MTL_SKIN4 //skin4 is a mtlSkin and not an entSkin?

//#define NORMALMAPPING //do normalmapping?

//#define GLOSSMAP //entity has glossmap?
//#define GLOSSSTRENGTH 0 //glossmap channel will be set to this value if GLOSSMAP is not defined

//#define EMISSIVEMASK //use emissive mask? (formula: emissive_color = SKIN_EMISSIVEMASK * SKIN_ALBEDO)
//#define EMISSIVE_A7 // (optional EMISSIVEMASK addon) use emissive_red/green/blue for as emissive color? (formula: emissive_color = SKIN_EMISSIVEMASK * vecEmissive)
//#define EMISSIVE_SHADEC // (optional EMISSIVEMASK addon) OR use SC_OBJECT_EMISSIVE as emissive color? (formula: emissive_color = SKIN_EMISSIVEMASK * SC_OBJECT_EMISSIVE)

//#define OBJECTCOLOR_A7 // use diffuse_red/green/blue as (team)color using the colormask?
//#define OBJECTCOLOR_SHADEC // OR use SC_OBJECT_COLOR as (team)color using the colormask?

//#define ALPHACLIP //do alphatesting/alphacutout?

//#define USE_VEC_DIFFUSE //use diffuse_red/green/blue? (note: don't use with OBJECTCOLOR_A7 at the same time)

//#define ZPREPASS //do an early zbuffer prepass? Only makes sense for heavy ALU




//PERFORMANCE
/*
Normalmapping matrix in VS erstellen und nur ein mul im pixelshader?
 float3x3 worldToTangentSpace;
    worldToTangentSpace[0] = mul(input.Tangent,world);
    worldToTangentSpace[1] = mul(cross(input.Tangent,input.Normal),world);
    worldToTangentSpace[2] = mul(input.Normal,world);
    
...
*/

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#include <scHeaderObject>
// <-
// insert custom code here
// ->
#include <scObject>