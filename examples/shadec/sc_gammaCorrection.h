void sc_gammaCorrection_init(SC_SCREEN* screen);
void sc_gammaCorrection_destroy(SC_SCREEN* screen);
void sc_gammaCorrection_frm(SC_SCREEN* screen);
void sc_gammaCorrection_MaterialEvent();

STRING* sc_gammaCorrection_sMaterial = "sc_gammaCorrection.fx";