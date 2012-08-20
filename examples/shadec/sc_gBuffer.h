void sc_gBuffer_init(SC_SCREEN* screen, int inBufferType);
void sc_gBuffer_destroy(SC_SCREEN* screen);
void sc_gBuffer_frm(SC_SCREEN* screen);
void sc_gBuffer_passFrustumPoints(SC_SCREEN* screen);
//var sc_gBuffer_mtlGBufferEvent();

#define SC_GBUFFER_DEFERRED 1
//#define SC_GBUFFER_SIMPLE 2 //not implemented

#define SC_GBUFFER_NORMALS_AND_DEPTH 0
#define SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK 1
#define SC_GBUFFER_MATERIAL_DATA 2

//STRING* sc_gBuffer_sMaterialSimple = "";
//STRING* sc_gBuffer_sMaterialDeferred = "sc_gBuffer_deferred.fx";
