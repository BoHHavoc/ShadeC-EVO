//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

int sc_lights_defaultClipRange = 5000; //If not set otherwise, lights will be clipped at this range

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#define SC_LIGHT_POINT          0x0001
#define SC_LIGHT_SPOT           0x0002
#define SC_LIGHT_SPECULAR       0x0004
#define SC_LIGHT_PROJECTION     0x0008
#define SC_LIGHT_SHADOW         0x0010

/*
2^2  4
2^3  8
2^4  10 
2^5  20
2^6  40
2^7  80
etc 
*/

//pointlight
#define SC_LIGHT_P 0
#define SC_LIGHT_P_SPEC 1
#define SC_LIGHT_P_SPEC_PROJ 2
#define SC_LIGHT_P_PROJ 3

//spotlight
#define SC_LIGHT_S 10
#define SC_LIGHT_S_SPEC 11
#define SC_LIGHT_S_SPEC_SHADOW 12
#define SC_LIGHT_S_SHADOW 13

//
int sc_lights_stencilRefCurrent = 1; //current Stencil Reference for lights. Will be set to 0 again once > 254

//textures
BMAP* sc_lights_map_defaultProjTex = "sc_lights_defaultProjTex.bmp";

//material Strings
STRING* sc_lights_sMaterialShadowmapLocal = "sc_lights_shadowmapLocal.fx";
STRING* sc_lights_sMaterialShadowmapBlur = "sc_lights_shadowmapBlur.fx";

//model files
STRING* sc_lights_mdlPointLight = "sc_lights_pointLight.mdl";
//STRING* sc_lights_mdlDirectionalLight = "sc_lights_directional.mdl";
/*
MATERIAL* sc_lights_mtlPoint = { effect = "sc_lights_point.fx"; }
MATERIAL* sc_lights_mtlPointSpec = { effect = "sc_lights_pointSpec.fx"; }
MATERIAL* sc_lights_mtlPointSpecProj = { effect = "sc_lights_pointSpecProj.fx"; }
MATERIAL* sc_lights_mtlPointProj = { effect = "sc_lights_pointProj.fx"; }
*/

MATERIAL* sc_lights_mtlPoint = {effect = "sc_lights_point.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlPointSpec = { effect = "sc_lights_pointSpecular.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlPointSpecProj = { effect = "sc_lights_pointSpecularProjection.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlPointProj = { effect = "sc_lights_pointProjection.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }

MATERIAL* sc_lights_mtlSpot = { effect = "sc_lights_spot.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlSpotSpec = { effect = "sc_lights_spotSpecular.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlSpotSpecShadow = { effect = "sc_lights_spotSpecularShadow.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }
MATERIAL* sc_lights_mtlSpotShadow = { effect = "sc_lights_spotShadow.fx"; flags = ENABLE_RENDER; event = sc_materials_event; }


//prototypes
var sc_lights_mtlShadowmapLocalRenderEvent();




//--------------------------------------------------------------------------
// SUN
//--------------------------------------------------------------------------

void sc_lights_initSun(SC_SCREEN* screen);
void sc_lights_destroySun(SC_SCREEN* screen);
void sc_lights_frmSun(SC_SCREEN* screen);

STRING* sc_lights_sMaterialSun = "sc_lights_sun.fx";
STRING* sc_lights_sMaterialSunShadow = "sc_lights_sunShadow.fx";
//STRING* sc_lights_sMaterialShadowmap = "sc_lights_shadowmap.fx";
STRING* sc_lights_sMaterialShadowmapSplit1 = "sc_lights_shadowmap.fx";
STRING* sc_lights_sMaterialShadowmapSplit2 = "sc_lights_shadowmap.fx";
STRING* sc_lights_sMaterialShadowmapSplit3 = "sc_lights_shadowmap.fx";
STRING* sc_lights_sMaterialShadowmapSplit4 = "sc_lights_shadowmap.fx";