void sc_materials_init();
var sc_materials_event();
var sc_material_loadDataFromXML(STRING* inFilename);

int sc_materials_initialized = 0; //will be set to 1 once all materials are ready
BMAP* sc_materials_mapData;// = "#2x1x32";  //contains material data (brdf lookup index, diffuse roughness & wrap, etc)
BMAP* sc_materials_zbuffer=NULL;
BMAP* sc_materials_fogMap=NULL;

//struct that holds material data when reading from/writing to XML 
typedef struct SC_MATERIAL_DATA{
	int materialID;
	int lightFunction; //lightfunction 3D texture index
	int diffuseWrap; //diffuse lighting wrap
	int diffuseSmoothness; //diffuse lighting smoothness
} SC_MATERIAL_DATA;

//sky cube
MATERIAL* sc_material_sky =
{
	effect = "sc_gBuffer_sky.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
}

//atmospheric scattering sky
MATERIAL* sc_material_sky2 =
{
	effect = "sc_gBuffer_sky2.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
}

//STRING* sc_materials_sMatData1 = "sc_materials_matData1.dds";
//LPDIRECT3DVOLUMETEXTURE9* sc_materials_texMatData1;

//#define SC_MATERIALS_BRDF_SIZE 128

/*
typedef struct{
	float LUTIndex;
	float diffuseRoughness;
	float diffuseWrap;
	float specularStrength;
} SC_MATERIALS_BRDF;
SC_MATERIALS_BRDF sc_materials_brdf[SC_MATERIALS_BRDF_SIZE];
*/

// x = BRDF Lookup Texture index
// y = diffuse roughness
// z = diffuse wraparound
// w = specular strength
//D3DXVECTOR4 sc_material_brdfData1[SC_MATERIALS_BRDF_SIZE];

