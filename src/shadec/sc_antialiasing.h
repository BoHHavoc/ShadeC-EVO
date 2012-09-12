void sc_antialiasing_init(SC_SCREEN* screen);
void sc_antialiasing_destroy(SC_SCREEN* screen);
void sc_antialiasing_frm(SC_SCREEN* screen);

STRING* sc_antialiasing_strMlaaEdgeDetect = "sc_mlaa_edgeDetect.fx";
STRING* sc_antialiasing_strMlaaBlendWeights = "sc_mlaa_blendWeight.fx";
STRING* sc_antialiasing_strMlaaFinal = "sc_mlaa_final.fx";

BMAP* sc_antialiasing_mlaaMapArea = "sc_mlaa_areaMap.dds";

