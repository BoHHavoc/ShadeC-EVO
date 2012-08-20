void sc_setup(SC_SCREEN* screen)
{
	/*
	//setup screen
	if(screen == 0 || screen == NULL)
	{
		camera.size_x = screen_size.x;
		camera.size_y = screen_size.y;
		if(sc_screen_default == NULL) sc_screen_default = sc_screen_create(camera);
		screen = sc_screen_default;
	}
	else 
	{
		if( screen.views.main.size_x == 0) screen.views.main.size_x = screen_size.x;
		if( screen.views.main.size_y == 0) screen.views.main.size_y = screen_size.y;
	}
	*/
	
	//deactivate stencil shadows
	shadow_stencil = 8;
	
	if( screen.views.main.size_x == 0) screen.views.main.size_x = screen_size.x;
	if( screen.views.main.size_y == 0) screen.views.main.size_y = screen_size.y;
	
	screen.draw = 0;
		
	//setup generic rendertargets
	if(screen.renderTargets.full0 != NULL) bmap_purge(screen.renderTargets.full0);
	screen.renderTargets.full0 = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
	if(screen.renderTargets.half0 != NULL) bmap_purge(screen.renderTargets.half0);
	screen.renderTargets.half0 = bmap_createblack(screen.views.main.size_x/2, screen.views.main.size_y/2, 32);
	if(screen.renderTargets.half1 != NULL) bmap_purge(screen.renderTargets.half1);
	screen.renderTargets.half1 = bmap_createblack(screen.views.main.size_x/2, screen.views.main.size_y/2, 32);
	if(screen.renderTargets.quarter0 != NULL) bmap_purge(screen.renderTargets.quarter0);
	screen.renderTargets.quarter0 = bmap_createblack(screen.views.main.size_x/4, screen.views.main.size_y/4, 32);
	if(screen.renderTargets.quarter1 != NULL) bmap_purge(screen.renderTargets.quarter1);
	screen.renderTargets.quarter1 = bmap_createblack(screen.views.main.size_x/4, screen.views.main.size_y/4, 32);
	if(screen.renderTargets.eighth0 != NULL) bmap_purge(screen.renderTargets.eighth0);
	screen.renderTargets.eighth0 = bmap_createblack(screen.views.main.size_x/8, screen.views.main.size_y/8, 32);
	if(screen.renderTargets.eighth1 != NULL) bmap_purge(screen.renderTargets.eighth1);
	screen.renderTargets.eighth1 = bmap_createblack(screen.views.main.size_x/8, screen.views.main.size_y/8, 32);
	
	//destroy previous effects
	sc_viewEvent_destroy(screen);
	//sc_gammaCorrection_destroy(screen); //not used yet...
	sc_hdr_destroy(screen);
	sc_dof_destroy(screen);
	sc_refract_destroy(screen);
	sc_forward_destroy(screen);
	sc_deferred_destroy(screen);
	sc_ssao_destroy(screen);
	sc_deferredLighting_destroy(screen);
	sc_lights_destroySun(screen);
	sc_gBuffer_destroy(screen);

	//setup effects
	sc_materials_init();
	sc_gBuffer_init(screen, SC_GBUFFER_DEFERRED, 32);
	sc_lights_initSun(screen);
	sc_deferredLighting_init(screen, 1);
	if(screen.settings.ssao.enabled == 1) sc_ssao_init(screen); //optional
	sc_deferred_init(screen);
	if(screen.settings.forward.enabled == 1) sc_forward_init(screen, SC_FORWARD_RENDER); //option 1
	else sc_forward_init(screen, SC_FORWARD_PASSTHROUGH); // option 2
	if(screen.settings.refract.enabled == 1) sc_refract_init(screen); //optional
	if(screen.settings.dof.enabled == 1) sc_dof_init(screen); //optional
	if(screen.settings.hdr.enabled == 1) sc_hdr_init(screen);
	//sc_gammaCorrection_init(screen); //not used yet...
	sc_viewEvent_init(screen);
	
	wait(2);
	
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