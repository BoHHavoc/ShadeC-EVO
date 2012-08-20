void sc_ssao_init(SC_SCREEN* screen);
void sc_ssao_destroy(SC_SCREEN* screen);
void sc_ssao_frm(SC_SCREEN* screen);

STRING* sc_ssao_sMaterialSSAOLow = "sc_ssao.fx";
STRING* sc_ssao_sMaterialBlurX = "sc_ssao_blurX.fx";
STRING* sc_ssao_sMaterialBlurY = "sc_ssao_blurY.fx";
STRING* sc_ssao_sMaterialFinalize = "sc_ssao_finalize.fx";

int sc_ssao_kernelSize = 16; //max = 32
//BMAP* sc_ssao_texNoise = "sc_ssao_noise.bmp";