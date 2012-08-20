#ifndef d3d9_h
	#include <d3d9.h>
#endif

#ifndef mtlFX
	//needed for default.fx shader #includes
	#define PRAGMA_PATH "%EXE_DIR%\\code"; // fx files
	#define PRAGMA_BIND "d3dcompiler_42.dll"; // DirectX 9.c shader compiler
	char* fx_needs = "default.fx"; 	// for the WED resource window
#endif

#ifndef SHADEC
	#define SHADEC
	
	#define PRAGMA_PATH "shadec\\fx"
	#define PRAGMA_PATH "shadec\\fx\\obj"
	#define PRAGMA_PATH "shadec\\fx\\pp"
	#define PRAGMA_PATH "shadec\\tex"
	#define PRAGMA_PATH "shadec\\mdl"
	#define PRAGMA_PATH "shadec\\plugins\\LiteXML"
	
	//include plugins
	//#include "LiteXML.h";
	
	//include Shade-C Headers
	#include "sc_dll.h"
	#include "sc_core.h"
	#include "sc_physics.h"
	#include "sc_volumeTexture.h"
	#include "sc_gBuffer.h"
	#include "sc_deferredLighting.h"
	#include "sc_lights.h"
	#include "sc_ssao.h"
	#include "sc_deferred.h"
	#include "sc_forward.h"
	#include "sc_refract.h"
	#include "sc_hdr.h"
	#include "sc_dof.h"
	#include "sc_gammaCorrection.h"
	#include "sc_entity.h"
	#include "sc_effects.h"
	#include "sc_materials.h"
	#include "sc_viewEvent.h"
	#include "sc_wrapper.h"
	
	//include Shade-C source
	#include "sc_core.c"
	#include "sc_physics.c"
	#include "sc_volumeTexture.c"
	#include "sc_gBuffer.c"
	#include "sc_deferredLighting.c"
	#include "sc_lights.c"
	#include "sc_ssao.c"
	#include "sc_deferred.c"
	#include "sc_forward.c"
	#include "sc_refract.c"
	#include "sc_hdr.c"
	#include "sc_dof.c"
	#include "sc_gammaCorrection.c"
	#include "sc_entity.c"
	#include "sc_effects.c"
	#include "sc_materials.c"
	#include "sc_viewEvent.c"
	#include "sc_wrapper.c"
#endif