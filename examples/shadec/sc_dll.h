void sc_setupDLL(void);

//HRESULT sc_dll_renderGBuffer(void);
HRESULT sc_dll_renderGBuffer(BMAP* skin1, BMAP* skin2);


//CSSM Shadows http://free-zg.t-com.hr/cssm/
void sc_dll_getCSSMParams(
	float*				 outProjMatrixArray
	,float*              outCtrlMatrixArray
	,int*                outProjNumber
    // LIGHT INFO:
    ,const float*        inLightPos
    ,const float*        inLightDir
    ,float               inLightRange
    ,float               inLightAngle
    // CAMERA INFO:
    ,const float*        inViewMatrix
    ,const float*        inProjMatrix
    // CSSM INFO:
    ,float               inFocusRange
    //,bool                columnMajorMatrices=false // Used for OpenGL
);
