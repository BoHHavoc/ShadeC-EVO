//prototypes
void sc_deferredLighting_init(SC_SCREEN* screen, int rtScale);
void sc_deferredLighting_destroy(SC_SCREEN* screen);
void sc_deferredLighting_frm(SC_SCREEN* screen);
//var sc_deferredLighting_mtlRenderEvent();


STRING* sc_deferredLighting_sBRDFLUT = "shadec/tex/sc_deferredLighting_LUT.dds";
LPDIRECT3DVOLUMETEXTURE9* sc_deferredLighting_texBRDFLUT;
