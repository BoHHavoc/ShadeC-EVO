void sc_forward_init(SC_SCREEN* screen, int mode)
{
	/*
	//setup material
	screen.materials.forward = mtl_create();
	effect_load(screen.materials.forward, sc_forward_sMaterial);
	set(screen.materials.forward, ENABLE_RENDER);
	screen.materials.forward.event = sc_forward_materialEvent;
	*/
	
	if(mode == SC_FORWARD_RENDER) //forward rendering
	{
		set(screen.views.main, UNTOUCHABLE);
		reset(screen.views.gBuffer,AUDIBLE);
		//setup view
		reset(screen.views.main, SHOW);
		set(screen.views.main, CHILD);
		
		set(screen.views.main, PROCESS_SCREEN); //keep zBuffer
		if(screen.settings.refract.enabled == 1) set(screen.views.main, NOPARTICLE);
		set(screen.views.main, NOSKY); //keep zBuffer
		set(screen.views.main,NOSHADOW);
		//screen.views.main.material = screen.materials.forward;
	}
	else if(mode == SC_FORWARD_PASSTHROUGH) //just pass through the deferred buffer
	{
		set(screen.views.main, UNTOUCHABLE);
		reset(screen.views.gBuffer,AUDIBLE);
		
		reset(screen.views.main, SHOW);
		set(screen.views.main, CHILD);
		set(screen.views.main, PROCESS_TARGET); //keep zBuffer
		set(screen.views.main, NOSKY); //keep zBuffer
		set(screen.views.main,NOSHADOW);
		//screen.views.main.bmap =  bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
	}
	
	//assign to render queue
	VIEW* view_last = screen.views.gBuffer;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.main;
	screen.views.preForward = view_last;
	screen.views.preForward.bmap = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
}

void sc_forward_destroy(SC_SCREEN* screen)
{
	if(screen.views.main != NULL){
		if(is(screen.views.main,NOSHADOW))
		{
			set(screen.views.main, SHOW);
			if(is(screen.views.main, PROCESS_SCREEN)) reset(screen.views.main, PROCESS_SCREEN);
			if(is(screen.views.main, PROCESS_TARGET)) reset(screen.views.main, PROCESS_TARGET);
			reset(screen.views.main, NOSKY);
			reset(screen.views.main, CHILD);
			reset(screen.views.main,NOSHADOW);
			
			if(screen.views.main.bmap != NULL) bmap_purge(screen.views.main.bmap);
			screen.views.main.bmap = NULL;
			
			if(screen.views.preForward.bmap != NULL) bmap_purge(screen.views.preForward.bmap);
			screen.views.preForward.bmap = NULL;
			
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.main && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.main.stage != NULL) view_last.stage = screen.views.main.stage;
			else view_last.stage = NULL;
			screen.views.main.stage = NULL;
		}
	}
}
void sc_forward_frm(SC_SCREEN* screen)
{
	//do nothing...
}
/*
var sc_forward_materialEvent()
{
	return(1);
}
*/