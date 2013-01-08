//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

#ifndef SC_SKILL
	#define SC_SKILL skill99 //Gamestudio skill to map SC_SKILLs to. DO NOT USE THIS SKILL IN YOUR SCRIPTS!
#endif
#define SC_USE_NOFLAG1 //RECOMMENDED If defined, you should set FLAG1 for all non-shadow casting objects to additionally boost performance. DO NOT USE FLAG1 FOR ANY OTHER THINGS if this is defined!
//#define SC_CUSTOM_ZBUFFER //EXPERIMANTAL might fix bugs if the build in automatic zbuffer does not work. EXPERIMENTAL
#define SC_USEPVS //RECOMMENDED Use Acknex's intern BSP/PVS calculations for light/shadow culling.
//#define SC_A7 //If defined, Shade-C will compile under A7, however many features might be missing, like PSSM Shadows
//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#define SC_PI 3.14159265 //Pi
D3DXVECTOR4 sc_vec4Null;
//BMAP* sc_bmapNull = "#1#1#8";
BMAP* sc_map_random2x2 = "sc_random2x2.tga";
BMAP* sc_map_random4x4 = "sc_random4x4.tga";
BMAP* sc_map_random = "sc_random.png";

//SC_OBJECT
#define SC_OBJECT_LIGHT_POS 1
#define SC_OBJECT_LIGHT_DIR 2
#define SC_OBJECT_LIGHT_ARC 3
#define SC_OBJECT_LIGHT_RANGE 4
#define SC_OBJECT_LIGHT_PROJMAP 5
#define SC_OBJECT_LIGHT_SHADOWMAP 6
#define SC_OBJECT_LIGHT_MATERIAL 7
#define SC_OBJECT_LIGHT_MATRIX 8
#define SC_OBJECT_LIGHT_VIEW 9
#define SC_OBJECT_LIGHT_CLIPRANGE 10
#define SC_OBJECT_LIGHT_COLOR 11
#define SC_OBJECT_LIGHT_STENCILREF 12

#define SC_OBJECT_DEPTH 100
//#define SC_OBJECT_SHADOWBIAS 101
#define SC_OBJECT_CASTSHADOW 102
#define SC_OBJECT_PASS 103
#define SC_OBJECT_EMISSIVE 104
#define SC_OBJECT_COLOR 105
//#define SC_OBJECT_TERRAIN_ATLAS 106

#define SC_OBJECT_MATERIAL_ID 200
#define SC_OBJECT_MATERIAL_SHADOWMAP 201

#define SC_OBJECT_DATA_1_X 250
#define SC_OBJECT_DATA_1_Y 251
#define SC_OBJECT_DATA_1_Z 252
#define SC_OBJECT_DATA_1_W 253
#define SC_OBJECT_DATA_2_X 254
#define SC_OBJECT_DATA_2_Y 255
#define SC_OBJECT_DATA_2_Z 256
#define SC_OBJECT_DATA_2_W 257
#define SC_OBJECT_DATA_3_X 258
#define SC_OBJECT_DATA_3_Y 259
#define SC_OBJECT_DATA_3_Z 260
#define SC_OBJECT_DATA_3_W 261
#define SC_OBJECT_DATA_1 	262
#define SC_OBJECT_DATA_2 	263
#define SC_OBJECT_DATA_3 	264

//SC_PASS
#define SC_PASS_GBUFFER 0
#define SC_PASS_FORWARD 1
#define SC_PASS_REFRACT 2

//Quality Settings
#define SC_LOW 0
#define SC_MEDIUM 0
#define SC_HIGH 0
#define SC_ULTRA 0

//SC_MATERIAL
//#define SC_MATERIAL_LIGHT 0
//#define SC_MATERIAL_LIGHT_SHADOWMAP 1
//#define SC_MATERIAL_GBUFFER 2


//sc_getTexCaps() for r32f texture support check
#ifndef D3DFMT_X8R8G8B8
	#define D3DFMT_X8R8G8B8 22
#endif
#ifndef D3DFMT_R16F
	#define D3DFMT_R16F 111
#endif
#ifndef D3DFMT_A16B16G16R16F
	#define D3DFMT_A16B16G16R16F 113
#endif
#ifndef D3DFMT_R32F
	#define D3DFMT_R32F 114
#endif
#ifndef D3DFMT_A32B32G32R32F
	#define D3DFMT_A32B32G32R32F 116
#endif
#ifndef D3DRTYPE_TEXTURE
	#define D3DRTYPE_TEXTURE 3
#endif
#ifndef D3DUSAGE_RENDERTARGET
	#define D3DUSAGE_RENDERTARGET (0x00000001L)
#endif
#ifndef D3DUSAGE_QUERY_FILTER
	#define D3DUSAGE_QUERY_FILTER (0x00020000L)
#endif


//BLEND MODES
#ifndef D3DBLEND_ZERO
	#define D3DBLEND_ZERO               1
#endif
#ifndef D3DBLEND_ONE
	#define D3DBLEND_ONE                2
#endif
#ifndef D3DBLEND_SRCCOLOR
	#define D3DBLEND_SRCCOLOR           3
#endif
#ifndef D3DBLEND_INVSRCCOLOR
	#define D3DBLEND_INVSRCCOLOR        4
#endif
#ifndef D3DBLEND_SRCALPHA
	#define D3DBLEND_SRCALPHA           5
#endif
#ifndef D3DBLEND_INVSRCALPHA
	#define D3DBLEND_INVSRCALPHA        6
#endif
#ifndef D3DBLEND_DESTALPHA
	#define D3DBLEND_DESTALPHA          7
#endif
#ifndef D3DBLEND_INVDESTALPHA
	#define D3DBLEND_INVDESTALPHA       8
#endif
#ifndef D3DBLEND_DESTCOLOR
	#define D3DBLEND_DESTCOLOR          9
#endif
#ifndef D3DBLEND_INVDESTCOLOR
	#define D3DBLEND_INVDESTCOLOR       10
#endif
#ifndef D3DBLEND_SRCALPHASAT
	#define D3DBLEND_SRCALPHASAT        11
#endif
#ifndef D3DBLEND_BOTHSRCALPHA
	#define D3DBLEND_BOTHSRCALPHA       12
#endif
#ifndef D3DBLEND_BOTHINVSRCALPHA
	#define D3DBLEND_BOTHINVSRCALPHA    13
#endif
#ifndef D3DBLEND_BLENDFACTOR
	#define D3DBLEND_BLENDFACTOR        14
#endif
#ifndef D3DBLEND_INVBLENDFACTOR
	#define D3DBLEND_INVBLENDFACTOR     15
#endif
#ifndef D3DBLEND_SRCCOLOR2
	#define D3DBLEND_SRCCOLOR2          16
#endif
#ifndef D3DBLEND_INVSRCCOLOR2
	#define D3DBLEND_INVSRCCOLOR2       17
#endif


//STRUCTS
// simple vertex struct (will be used for screen aligned quad)
typedef struct SC_VERTEX_SCREENQUAD { 
	float x,y,z; 
	float rhw; 
	//D3DCOLOR color; 
	float u,v;
} SC_VERTEX_SCREENQUAD;
#define SC_D3DFVF_SCREENQUAD (D3DFVF_XYZRHW | D3DFVF_TEX1)
//#define SC_D3DFVF_SCREENQUAD (D3DFVF_XYZRHW | D3DFVF_DIFFUSE | D3DFVF_TEX1)



//SC_SCREEN------------------------------------------------------------------------------------
typedef struct{
	VIEW* gBuffer;
	VIEW* sunShadowDepth[4];
	VIEW* sunEdge;
	VIEW* sunExpand;
	VIEW* sunShadow;
	VIEW* sun;
	VIEW* deferredLighting;
	//VIEW* shadowsDepth;
	//VIEW* shadows;
	VIEW* ssao;
	VIEW* ssaoBlurX;
	VIEW* ssaoBlurY;
	VIEW* ssaoFinalize;
	VIEW* deferred;
	VIEW* antialiasing;
	VIEW* antialiasingEdgeDetect;
	VIEW* antialiasingBlendWeights;
	VIEW* main;
	VIEW* refract;
	VIEW* hdr;
	VIEW* hdrDownsample;
	VIEW* hdrScatter;
	VIEW* hdrBlurX;
	VIEW* hdrBlurY;
	VIEW* hdrLensflareDownsample;
	VIEW* hdrLensflare;
	VIEW* hdrLensflareBlur;
	VIEW* hdrLensflareUpsample;
	VIEW* dof;
	VIEW* dofDownsample;
	VIEW* dofBlurX;
	VIEW* dofBlurY;
	VIEW* gammaCorrection;
	
	//pre views
	VIEW* preSSAO; //not needed...?
	VIEW* preForward;
	VIEW* preRefract;
	VIEW* preHDR;
	VIEW* preDOF;
	VIEW* preGammaCorrection;
	VIEW* preAntialiasing;
	
}SC_SCREEN_VIEWS;

typedef struct{
	BMAP* gBuffer[4]; //gBuffer
	BMAP* deferredLighting; //lighting data, diffuse (rgb) and specular (a)
	BMAP* ssao; //ssao buffer, color bleeding (rgb) and shadow (a)
	BMAP* sunShadowDepth[4];
	
	BMAP* full0; //generic rendertarget, full screen size
	BMAP* full1; //generic rendertarget, full screen size
	BMAP* full2; //generic rendertarget, full screen size
	BMAP* half0; //generic rendertarget, half screen size
	BMAP* half1; //generic rendertarget, half screen size
	BMAP* quarter0; //generic rendertarget, quarter screen size
	BMAP* quarter1; //generic rendertarget, quarter screen size
	BMAP* eighth0; //generic rendertarget, eighth screen size
	BMAP* eighth1; //generic rendertarget, eighth screen size
}SC_SCREEN_RENDERTARGETS;

typedef struct{
	//MATERIAL* shadowsDepth;
	//MATERIAL* shadows;
	MATERIAL* sun;
	MATERIAL* ssao;
	MATERIAL* ssaoBlurX;
	MATERIAL* ssaoBlurY;
	MATERIAL* ssaoFinalize;
	MATERIAL* deferred;
	MATERIAL* hdr;
	MATERIAL* hdrDownsample;
	MATERIAL* hdrScatter;
	MATERIAL* hdrBlurX;
	MATERIAL* hdrBlurY;
	MATERIAL* hdrLensflareDownsample;
	MATERIAL* hdrLensflare;
	MATERIAL* hdrLensflareBlur;
	MATERIAL* hdrLensflareUpsample;
	MATERIAL* dof;
	MATERIAL* dofDownsample;
	MATERIAL* dofBlurX;
	MATERIAL* dofBlurY;
	MATERIAL* gammaCorrection;
	
	MATERIAL* viewEvent;
}SC_SCREEN_MATERIALS;


//SC_SETTINGS
typedef struct{
	int enabled;
	float brightpass;
	float intensity;
}SC_SETTINGS_HDR_LENSFLARE;

typedef struct{
	int enabled;
	float blurX;
	float blurY;
	float brightpass;
	float intensity;
	float scatter;
	float emissiveIntensity;
	SC_SETTINGS_HDR_LENSFLARE lensflare;
}SC_SETTINGS_HDR;

typedef struct{
	int enabled;
	float blurX;
	float blurY;
	int focalPos;
	int focalWidth;
}SC_SETTINGS_DOF;

typedef struct{
	int enabled;
	float intensity;
	float radius;
	float selfOcclusion;
	float brightOcclusion;
	int quality;
	
}SC_SETTINGS_SSAO;

typedef struct{
	int enabled;
}SC_SETTINGS_REFRACT;

typedef struct{
	int enabled;
}SC_SETTINGS_FORWARD;

typedef struct{
	VECTOR sunPos;
	int sunShadows;
	int sunShadowResolution;
	int sunPssmSplits;
	var sunPssmSplitWeight;
	int sunPssmBlurSplits;
	int sunShadowRange;
	float sunShadowBias;
}SC_SETTINGS_LIGHTS;

typedef struct{
	int enabled;
}SC_SETTINGS_ANTIALIASING;

typedef struct{
	SC_SETTINGS_HDR hdr;
	SC_SETTINGS_DOF dof;
	SC_SETTINGS_REFRACT forward;
	SC_SETTINGS_REFRACT refract;
	SC_SETTINGS_SSAO ssao;
	SC_SETTINGS_LIGHTS lights;
	SC_SETTINGS_ANTIALIASING antialiasing;
}SC_SETTINGS;
//


typedef struct{
	SC_SCREEN_VIEWS views;
	SC_SCREEN_RENDERTARGETS renderTargets;
	SC_SCREEN_MATERIALS materials;
	SC_SETTINGS settings;
	
	int draw;
	SC_VERTEX_SCREENQUAD vertexScreenquad[4];
	D3DXVECTOR4 frustumPoints;
	D3DXVECTOR4 ssaoKernel[32];
	BMAP* ssaoNoise;
}SC_SCREEN;

SC_SCREEN* sc_screen_default;




//SC_OBJECT--------------------------------------------------------------------------------------
typedef struct{
	VECTOR color;
	VECTOR pos;
	VECTOR dir;
	int arc;
	int range;
	int clipRange;
	int stencilRef;
	BMAP* projMap;
	BMAP* shadowMap;
	//MATERIAL* mtlShadowmap;
   D3DXMATRIX* matrix;   
   VIEW* view;
}SC_OBJECT_LIGHT;

typedef struct{
	float id;
	MATERIAL* shadowmap;
}SC_OBJECT_MATERIAL;

typedef struct{
	D3DXVECTOR4 data1;
	D3DXVECTOR4 data2;
	D3DXVECTOR4 data3;
}SC_OBJECT_DATA;

typedef struct{
	SC_OBJECT_LIGHT* light;
	//SC_OBJECT_BRDF* brdf;
	SC_OBJECT_MATERIAL material;
	SC_OBJECT_DATA* data;
	int depth;
	int castShadow;
	//float shadowBias;
	int pass;
	D3DXVECTOR4 emissive;
	D3DXVECTOR4 color;
}SC_OBJECT;


//PROTOTYPES
var sc_getTexCaps(var tex);
VIEW* sc_ppAdd(MATERIAL* Material,VIEW* View,BMAP* bmap);
int sc_ppRemove(MATERIAL* Material,VIEW* View,VIEW* StageView);
SC_SCREEN* sc_screen_create(VIEW* inView);

void sc_skill_(ENTITY* ent,int objMode, var objVar);
void sc_skill(ENTITY* ent, int objMode, VECTOR* objVec)
{
	sc_skill_(ent, objMode, objVec);
}
void sc_skill(ENTITY* ent, int objMode, BMAP* objMap)
{
	sc_skill_(ent, objMode, objMap);
}
void sc_skill(ENTITY* ent, int objMode, D3DXMATRIX* objMtx)
{
	sc_skill_(ent, objMode, objMtx);
}
void sc_skill(ENTITY* ent, int objMode, VIEW* objView)
{
	sc_skill_(ent, objMode, objView);
}
void sc_skill(ENTITY* ent,int objMode, var objVar)
{
	sc_skill_(ent, objMode, objVar);
}

void sc_material(ENTITY* ent,int objMode, MATERIAL* mat);
/*void sc_material(ENTITY* ent,var objMode, STRING* matString)
{
	MATERIAL* tempMtl = mtl_create();
	tempMtl = effect_load(tempMtl, matString);
	sc_material(ent, objMode, tempMtl);
}
*/