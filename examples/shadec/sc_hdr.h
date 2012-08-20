void sc_hdr_init(SC_SCREEN* screen);
void sc_hdr_destroy(SC_SCREEN* screen);
void sc_hdr_frm(SC_SCREEN* screen);

STRING* sc_hdr_sMaterialHDR = "sc_hdr.fx";
STRING* sc_hdr_sMaterialHDRDownsample = "sc_hdr_downsample.fx";
STRING* sc_hdr_sMaterialHDRBlurX = "sc_hdr_blurX.fx";
STRING* sc_hdr_sMaterialHDRBlurY = "sc_hdr_blurY.fx";
STRING* sc_hdr_sMaterialHDRLensflareDownsample = "sc_hdr_lensflareDownsample.fx";
STRING* sc_hdr_sMaterialHDRLensflare = "sc_hdr_lensflare.fx";
STRING* sc_hdr_sMaterialHDRLensflareBlur = "sc_hdr_lensflareBlur.fx";
STRING* sc_hdr_sMaterialHDRLensflareUpsample = "sc_hdr_lensflareUpsample.fx";

BMAP* sc_hdr_mapLensdirt01 = "sc_hdr_lensdirt03.dds";
BMAP* sc_hdr_mapLensdirt02 = "sc_hdr_lensdirt04.dds";
