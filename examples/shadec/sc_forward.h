void sc_forward_init(SC_SCREEN* screen, int mode);
void sc_forward_destroy(SC_SCREEN* screen);
void sc_forward_frm(SC_SCREEN* screen);

#define SC_FORWARD_RENDER 1
#define SC_FORWARD_PASSTHROUGH 2
//void sc_forward_materialEvent();

//STRING* sc_forward_sMaterial = "sc_forward.fx";