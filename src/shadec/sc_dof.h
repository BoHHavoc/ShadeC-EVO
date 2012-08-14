void sc_dof_init(SC_SCREEN* screen);
void sc_dof_destroy(SC_SCREEN* screen);
void sc_dof_frm(SC_SCREEN* screen);

STRING* sc_dof_sMaterial = "sc_dof.fx";
STRING* sc_dof_sMaterialDownsample = "sc_dof_downsample.fx";
STRING* sc_dof_sMaterialBlurX = "sc_dof_blurX.fx";
STRING* sc_dof_sMaterialBlurY = "sc_dof_blurY.fx";
