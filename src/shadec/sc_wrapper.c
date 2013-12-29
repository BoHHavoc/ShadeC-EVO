//resets shade-c, but keeps all settings stored in screen/sc_screen_default
void sc_reset(SC_SCREEN* screen)
{
	if(screen == NULL) return;
	screen.draw = 0;
	//sc_viewEvent_destroy(screen);
	//sc_gammaCorrection_destroy(screen); //not used yet...
	sc_hdr_destroy(screen);
	sc_dof_destroy(screen);
	sc_refract_destroy(screen);
	sc_forward_destroy(screen);
	sc_antialiasing_destroy(screen);
	sc_deferred_destroy(screen);
	sc_ssao_destroy(screen);
	sc_deferredLighting_destroy(screen);
	sc_lights_destroySun(screen);
	sc_gBuffer_destroy(screen);
	
	//Generic Rendertargets (GRTs)//////////////////////////////////////////
	if(screen.renderTargets.full0 != NULL){bmap_purge(screen.renderTargets.full0); ptr_remove(screen.renderTargets.full0); screen.renderTargets.full0=NULL; }
	if(screen.renderTargets.full1 != NULL){bmap_purge(screen.renderTargets.full1); ptr_remove(screen.renderTargets.full1); screen.renderTargets.full1=NULL; }
	if(screen.renderTargets.full2 != NULL){bmap_purge(screen.renderTargets.full2); ptr_remove(screen.renderTargets.full2); screen.renderTargets.full2=NULL; }
	if(screen.renderTargets.half0 != NULL){bmap_purge(screen.renderTargets.half0); ptr_remove(screen.renderTargets.half0); screen.renderTargets.half0=NULL; }
	if(screen.renderTargets.half1 != NULL){bmap_purge(screen.renderTargets.half1); ptr_remove(screen.renderTargets.half1); screen.renderTargets.half1=NULL; }
	if(screen.renderTargets.quarter0 != NULL){bmap_purge(screen.renderTargets.quarter0); ptr_remove(screen.renderTargets.quarter0); screen.renderTargets.quarter0=NULL; }
	if(screen.renderTargets.quarter1 != NULL){bmap_purge(screen.renderTargets.quarter1); ptr_remove(screen.renderTargets.quarter1); screen.renderTargets.quarter1=NULL; }
	if(screen.renderTargets.eighth0 != NULL){bmap_purge(screen.renderTargets.eighth0); ptr_remove(screen.renderTargets.eighth0); screen.renderTargets.eighth0=NULL; }
	if(screen.renderTargets.eighth1 != NULL){bmap_purge(screen.renderTargets.eighth1); ptr_remove(screen.renderTargets.eighth1); screen.renderTargets.eighth1=NULL; }
	/////////////////////////////////////////////////////////
	
	//screen.materials.viewEvent/////////////////////////////
	if(screen.materials.viewEvent!=NULL){ ptr_remove(screen.materials.viewEvent); screen.materials.viewEvent=NULL; }
	/////////////////////////////////////////////////////////
	
	//sc_materials_init()////////////////////////////////////
	if(sc_materials_mapData!=NULL){ bmap_purge(sc_materials_mapData); ptr_remove(sc_materials_mapData); sc_materials_mapData=NULL; }
	/////////////////////////////////////////////////////////
	
	//sc_gBuffer_init()//////////////////////////////////////
	if(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]!=NULL){ bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]); ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]); screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]=NULL; }
	if(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]!=NULL){ bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]); ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]); screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]=NULL; }
	if(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]!=NULL){ bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]); ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]); screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]=NULL; }
	if(screen.renderTargets.gBuffer[3]!=NULL){ bmap_purge(screen.renderTargets.gBuffer[3]); ptr_remove(screen.renderTargets.gBuffer[3]); screen.renderTargets.gBuffer[3]=NULL; }
	if(screen.views.gBuffer!=NULL){ ptr_remove(screen.views.gBuffer); screen.views.gBuffer=NULL; }
	/////////////////////////////////////////////////////////
	
	//sc_lights_initSun()////////////////////////////////////
	if(screen.materials.sun!=NULL){ ptr_remove(screen.materials.sun); screen.materials.sun=NULL; }
	if(screen.views.sun!=NULL)
	{ 
		if(screen.views.sun.bmap!=NULL){ bmap_purge(screen.views.sun.bmap); ptr_remove(screen.views.sun.bmap); screen.views.sun.bmap=NULL; }
		ptr_remove(screen.views.sun); screen.views.sun=NULL; 
	}
	#ifndef SC_A7
		int i; for(i=0; i<4; i++)
		{	
			if(screen.views.sunShadowDepth[i]!=NULL)
			{ 
				if(screen.views.sunShadowDepth[i].bmap!=NULL){ bmap_purge(screen.views.sunShadowDepth[i].bmap); ptr_remove(screen.views.sunShadowDepth[i].bmap); screen.views.sunShadowDepth[i].bmap=NULL; }
				if(screen.views.sunShadowDepth[i].material!=NULL){ ptr_remove(screen.views.sunShadowDepth[i].material); screen.views.sunShadowDepth[i].material=NULL; }
				ptr_remove(screen.views.sunShadowDepth[i]); screen.views.sunShadowDepth[i]=NULL; 
			}
			if(screen.renderTargets.sunShadowDepth[i]!=NULL){ bmap_purge(screen.renderTargets.sunShadowDepth[i]); ptr_remove(screen.renderTargets.sunShadowDepth[i]); screen.renderTargets.sunShadowDepth[i]=NULL; }
		}
		
		if(screen.views.sunEdge!=NULL)
		{ 
			if(screen.views.sunEdge.bmap!=NULL){ bmap_purge(screen.views.sunEdge.bmap); ptr_remove(screen.views.sunEdge.bmap); screen.views.sunEdge.bmap=NULL; }
			if(screen.views.sunEdge.material!=NULL){ ptr_remove(screen.views.sunEdge.material); screen.views.sunEdge.material=NULL; }
			ptr_remove(screen.views.sunEdge); screen.views.sunEdge=NULL; 
		}
		
		if(screen.views.sunExpand!=NULL)
		{ 
			if(screen.views.sunExpand.bmap!=NULL){ bmap_purge(screen.views.sunExpand.bmap); ptr_remove(screen.views.sunExpand.bmap); screen.views.sunExpand.bmap=NULL; }
			if(screen.views.sunExpand.material!=NULL){ ptr_remove(screen.views.sunExpand.material); screen.views.sunExpand.material=NULL; }
			ptr_remove(screen.views.sunExpand); screen.views.sunExpand=NULL; 
		}
		
		if(screen.views.sunShadow!=NULL)
		{ 
			if(screen.views.sunShadow.bmap!=NULL){ bmap_purge(screen.views.sunShadow.bmap); ptr_remove(screen.views.sunShadow.bmap); screen.views.sunShadow.bmap=NULL; }
			if(screen.views.sunShadow.material!=NULL){ ptr_remove(screen.views.sunShadow.material); screen.views.sunShadow.material=NULL; }
			ptr_remove(screen.views.sunShadow); screen.views.sunShadow=NULL; 
		}
		
	#endif
	/////////////////////////////////////////////////////////
	
	//sc_deferredLighting_init()/////////////////////////////
	if(screen.renderTargets.deferredLighting!=NULL){ bmap_purge(screen.renderTargets.deferredLighting); ptr_remove(screen.renderTargets.deferredLighting); screen.renderTargets.deferredLighting=NULL; }
	if(screen.views.deferredLighting!=NULL)
	{ 
		if(screen.views.deferredLighting.bmap!=NULL){ bmap_purge(screen.views.deferredLighting.bmap); ptr_remove(screen.views.deferredLighting.bmap); screen.views.deferredLighting.bmap=NULL; }
		ptr_remove(screen.views.deferredLighting); 
	}
	/////////////////////////////////////////////////////////
	
	//sc_ssao_init()/////////////////////////////////////////
	if(screen.renderTargets.ssao!=NULL){ bmap_purge(screen.renderTargets.ssao); ptr_remove(screen.renderTargets.ssao); screen.renderTargets.ssao=NULL; }
	if(screen.ssaoNoise!=NULL){ bmap_purge(screen.ssaoNoise); ptr_remove(screen.ssaoNoise); screen.ssaoNoise=NULL; }
	if(screen.materials.ssaoFinalize!=NULL){ ptr_remove(screen.materials.ssaoFinalize); screen.materials.ssaoFinalize=NULL; }
	if(screen.materials.ssao!=NULL){ ptr_remove(screen.materials.ssao); screen.materials.ssao=NULL; }
	if(screen.views.ssaoFinalize!=NULL){ ptr_remove(screen.views.ssaoFinalize); screen.views.ssaoFinalize=NULL; }
	if(screen.views.ssao!=NULL){ ptr_remove(screen.views.ssao); screen.views.ssao=NULL; }
	/////////////////////////////////////////////////////////
	
	//sc_deferred_init()/////////////////////////////////////
	if(screen.materials.deferred!=NULL){ ptr_remove(screen.materials.deferred); screen.materials.deferred=NULL; }
	if(screen.views.deferred!=NULL)
	{ 
		if(screen.views.deferred.bmap!=NULL){ bmap_purge(screen.views.deferred.bmap); ptr_remove(screen.views.deferred.bmap); screen.views.deferred.bmap=NULL; }
		ptr_remove(screen.views.deferred); screen.views.deferred=NULL; 
	}
	/////////////////////////////////////////////////////////
	
	//sc_antialiasing_init()/////////////////////////////////
	if(screen.views.antialiasing!=NULL)
	{ 
		if(screen.views.antialiasing.material!=NULL){ ptr_remove(screen.views.antialiasing.material); screen.views.antialiasing.material=NULL; }
		ptr_remove(screen.views.antialiasing); screen.views.antialiasing=NULL; 
	}
	if(screen.views.antialiasingBlendWeights!=NULL)
	{ 
		if(screen.views.antialiasingBlendWeights.material!=NULL){ ptr_remove(screen.views.antialiasingBlendWeights.material); screen.views.antialiasingBlendWeights.material=NULL; }
		ptr_remove(screen.views.antialiasingBlendWeights); screen.views.antialiasingBlendWeights=NULL; 
	}
	if(screen.views.antialiasingEdgeDetect!=NULL)
	{ 
		if(screen.views.antialiasingEdgeDetect.material!=NULL){ ptr_remove(screen.views.antialiasingEdgeDetect.material); screen.views.antialiasingEdgeDetect.material=NULL; }
		ptr_remove(screen.views.antialiasingEdgeDetect); screen.views.antialiasingEdgeDetect=NULL; 
	}
	/////////////////////////////////////////////////////////
	
	//sc_forward_init()//////////////////////////////////////
	if(screen.views.preForward!=NULL)
	{
		if(screen.views.preForward.bmap!=NULL){ bmap_purge(screen.views.preForward.bmap); ptr_remove(screen.views.preForward.bmap); screen.views.preForward.bmap=NULL; }
		ptr_remove(screen.views.preForward); screen.views.preForward=NULL; 
	}
	/////////////////////////////////////////////////////////
	
	//sc_refract_init()//////////////////////////////////////
	if(screen.views.refract!=NULL)
	{ 
		if(screen.views.refract.bmap!=NULL){ bmap_purge(screen.views.refract.bmap); ptr_remove(screen.views.refract.bmap); screen.views.refract.bmap=NULL; }
		ptr_remove(screen.views.refract); screen.views.refract=NULL; 
	}
	if(screen.views.preRefract!=NULL)
	{
		if(screen.views.preRefract.bmap!=NULL){ bmap_purge(screen.views.preRefract.bmap); ptr_remove(screen.views.preRefract.bmap); screen.views.preRefract.bmap=NULL; }
		ptr_remove(screen.views.preRefract); screen.views.preRefract=NULL; 
	}
	/////////////////////////////////////////////////////////
	
	//sc_dof_init()//////////////////////////////////////////
	if(screen.materials.dof!=NULL){ ptr_remove(screen.materials.dof); screen.materials.dof=NULL; }
	if(screen.materials.dofBlurY!=NULL){ ptr_remove(screen.materials.dofBlurY); screen.materials.dofBlurY=NULL; }
	if(screen.materials.dofBlurX!=NULL){ ptr_remove(screen.materials.dofBlurX); screen.materials.dofBlurX=NULL; }
	if(screen.materials.dofDownsample!=NULL){ ptr_remove(screen.materials.dofDownsample); screen.materials.dofDownsample=NULL; }
	if(screen.views.dof!=NULL){ ptr_remove(screen.views.dof); screen.views.dof=NULL; }
	if(screen.views.dofBlurY!=NULL){ ptr_remove(screen.views.dofBlurY); screen.views.dofBlurY=NULL; }
	if(screen.views.dofBlurX!=NULL){ ptr_remove(screen.views.dofBlurX); screen.views.dofBlurX=NULL; }
	if(screen.views.dofDownsample!=NULL){ ptr_remove(screen.views.dofDownsample); screen.views.dofDownsample=NULL; }
	/////////////////////////////////////////////////////////
	
	//sc_hdr_init()//////////////////////////////////////////
	if(screen.materials.hdr!=NULL){ ptr_remove(screen.materials.hdr); screen.materials.hdr=NULL; }
	if(screen.materials.hdrLensflareUpsample!=NULL){ ptr_remove(screen.materials.hdrLensflareUpsample); screen.materials.hdrLensflareUpsample=NULL; }
	if(screen.materials.hdrLensflareBlur!=NULL){ ptr_remove(screen.materials.hdrLensflareBlur); screen.materials.hdrLensflareBlur=NULL; }
	if(screen.materials.hdrLensflare!=NULL){ ptr_remove(screen.materials.hdrLensflare); screen.materials.hdrLensflare=NULL; }
	if(screen.materials.hdrLensflareDownsample!=NULL){ ptr_remove(screen.materials.hdrLensflareDownsample); screen.materials.hdrLensflareDownsample=NULL; }
	if(screen.materials.hdrBlurY!=NULL){ ptr_remove(screen.materials.hdrBlurY); screen.materials.hdrBlurY=NULL; }
	if(screen.materials.hdrBlurX!=NULL){ ptr_remove(screen.materials.hdrBlurX); screen.materials.hdrBlurX=NULL; }
	if(screen.materials.hdrScatter!=NULL){ ptr_remove(screen.materials.hdrScatter); screen.materials.hdrScatter=NULL; }
	if(screen.materials.hdrDownsample!=NULL){ ptr_remove(screen.materials.hdrDownsample); screen.materials.hdrDownsample=NULL; }
	
	if(screen.views.hdr!=NULL){ ptr_remove(screen.views.hdr); screen.views.hdr=NULL; }
	if(screen.views.hdrLensflareUpsample!=NULL){ ptr_remove(screen.views.hdrLensflareUpsample); screen.views.hdrLensflareUpsample=NULL; }
	if(screen.views.hdrLensflareBlur!=NULL){ ptr_remove(screen.views.hdrLensflareBlur); screen.views.hdrLensflareBlur=NULL; }
	if(screen.views.hdrLensflare!=NULL){ ptr_remove(screen.views.hdrLensflare); screen.views.hdrLensflare=NULL; }
	if(screen.views.hdrLensflareDownsample!=NULL){ ptr_remove(screen.views.hdrLensflareDownsample); screen.views.hdrLensflareDownsample=NULL; }
	if(screen.views.hdrBlurY!=NULL){ ptr_remove(screen.views.hdrBlurY); screen.views.hdrBlurY=NULL; }
	if(screen.views.hdrBlurX!=NULL){ ptr_remove(screen.views.hdrBlurX); screen.views.hdrBlurX=NULL; }
	if(screen.views.hdrScatter!=NULL){ ptr_remove(screen.views.hdrScatter); screen.views.hdrScatter=NULL; }
	if(screen.views.hdrDownsample!=NULL){ ptr_remove(screen.views.hdrDownsample); screen.views.hdrDownsample=NULL; }
	////////////////////////////////////////////////////	
	
	if(screen.views.main.bmap!=NULL){ bmap_purge(screen.views.main.bmap); ptr_remove(screen.views.main.bmap); screen.views.main.bmap=NULL; }
	screen.views.main.stage=NULL;
	
}

//completely destroys/removes shade-c
void sc_destroy(SC_SCREEN* screen)
{
	sc_reset(screen);
	
	if(sc_screen_default != NULL)
	{
		//free memory	
		sys_free(sc_screen_default);
		
		//pointer to NULL
		sc_screen_default=NULL;
	}
}

void sc_setup(SC_SCREEN* screen)
{
	//deactivate stencil shadows
	//...this wont work here, you have to do this before loading a level
	//shadow_stencil = 8;
	//shadow_stencil = -1;
	
	
	//destroy previous effects
	sc_reset(screen);
	
	if( screen.views.main.size_x == 0) screen.views.main.size_x = screen_size.x;
	if( screen.views.main.size_y == 0) screen.views.main.size_y = screen_size.y;
	
	screen.draw = 0;
	
	//setup generic rendertargets (GRTs)
	screen.renderTargets.full0 = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, screen.settings.bitdepthGRTs);
	screen.renderTargets.full1 = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, screen.settings.bitdepthGRTs);
	screen.renderTargets.full2 = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, screen.settings.bitdepthGRTs);
	screen.renderTargets.half0 = bmap_createblack(screen.views.main.size_x/2, screen.views.main.size_y/2, screen.settings.bitdepthGRTs);
	screen.renderTargets.half1 = bmap_createblack(screen.views.main.size_x/2, screen.views.main.size_y/2, screen.settings.bitdepthGRTs);
	screen.renderTargets.quarter0 = bmap_createblack(screen.views.main.size_x/4, screen.views.main.size_y/4, screen.settings.bitdepthGRTs);
	screen.renderTargets.quarter1 = bmap_createblack(screen.views.main.size_x/4, screen.views.main.size_y/4, screen.settings.bitdepthGRTs);
	screen.renderTargets.eighth0 = bmap_createblack(screen.views.main.size_x/8, screen.views.main.size_y/8, screen.settings.bitdepthGRTs);
	screen.renderTargets.eighth1 = bmap_createblack(screen.views.main.size_x/8, screen.views.main.size_y/8, screen.settings.bitdepthGRTs);
	
	//setup effects
	sc_materials_init();
	sc_gBuffer_init(screen, SC_GBUFFER_DEFERRED, screen.settings.bitdepthGBuffer); //change 32 (8bit) to 12222 (16bit) or 14444 (32bit) to get a floating point g-buffer.
	sc_lights_initSun(screen);
	sc_deferredLighting_init(screen, 1, screen.settings.bitdepthLBuffer); //change 32 (8bit) to 12222 (16bit) or 14444 (32bit) to get a floating point light buffer
	if(screen.settings.ssao.enabled == 1) sc_ssao_init(screen); //optional
	sc_deferred_init(screen);
	if(screen.settings.antialiasing.enabled == 1) sc_antialiasing_init(screen);
	if(screen.settings.forward.enabled == 1) sc_forward_init(screen, SC_FORWARD_RENDER); //option 1
	else sc_forward_init(screen, SC_FORWARD_PASSTHROUGH); // option 2
	if(screen.settings.refract.enabled == 1) sc_refract_init(screen); //optional
	if(screen.settings.dof.enabled == 1) sc_dof_init(screen); //optional
	if(screen.settings.hdr.enabled == 1) sc_hdr_init(screen);
	//sc_gammaCorrection_init(screen); //not used yet...
	sc_viewEvent_init(screen);

	
	screen.draw = 1;
	
	//main loop
	while(screen.draw == 1)
	{
		//sc_getFrustumPoints(screen); //not needed, moved to shader
		
		sc_gBuffer_frm(screen);
		sc_lights_frmSun(screen);
		sc_deferredLighting_frm(screen);
		sc_ssao_frm(screen);
		sc_deferred_frm(screen);
		sc_forward_frm(screen);
		sc_dof_frm(screen);
		sc_hdr_frm(screen);
		//sc_gammaCorrection_frm(screen);
		
		wait(1);
	}
}


//overwrite default F5 video switch
void def_video() 
{
	var mode = video_mode;
	while(1) {
		if (!key_shift) 
			mode++; 
		else 
			mode--;
		mode = cycle(mode,6,12); 
		if (video_switch(mode,0,0)) 
			break;
   }
   
   sc_screen_default.views.main.size_x = screen_size.x;
   sc_screen_default.views.main.size_y = screen_size.y;
   sc_setup(sc_screen_default);
}

var sc_video_switch(var mode, var depth, var screen, SC_SCREEN* screen)
{
	var out = video_switch(mode, depth, screen);
	
	sc_screen_default.views.main.size_x = screen_size.x;
   sc_screen_default.views.main.size_y = screen_size.y;
	sc_setup(sc_screen_default);
	
	return out;
}

var sc_video_set(var width, var height, var depth, var screen, SC_SCREEN* screen)
{
	var out = video_set(width, height, depth, screen);

	sc_screen_default.views.main.size_x = screen_size.x;
   sc_screen_default.views.main.size_y = screen_size.y;
	sc_setup(sc_screen_default);
	
	return out;
}