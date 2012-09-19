void sc_refract_init(SC_SCREEN* screen)
{
	/*
	//setup material
	screen.materials.forward = mtl_create();
	effect_load(screen.materials.forward, sc_forward_sMaterial);
	set(screen.materials.forward, ENABLE_RENDER);
	screen.materials.forward.event = sc_forward_materialEvent;
	*/
	
	//setup view
	screen.views.refract = view_create(10);
	screen.views.refract.size_x = screen.views.main.size_x;
	screen.views.refract.size_y = screen.views.main.size_y;
	reset(screen.views.refract, SHOW);
	reset(screen.views.refract, AUDIBLE);
	set(screen.views.refract, PROCESS_SCREEN); //keep zBuffer
	set(screen.views.refract, NOSKY); //keep zBuffer
	set(screen.views.refract, CHILD);
	set(screen.views.refract,NOSHADOW);
	//set(screen.views.refract,NOPARTICLE);
	set(screen.views.refract,UNTOUCHABLE);
	//screen.views.refract.bmap =  bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
	//screen.views.main.material = screen.materials.forward;
		
	//assign to render queue
	VIEW* view_last = screen.views.gBuffer;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.refract;
	screen.views.preRefract = view_last;
	screen.views.preRefract.bmap = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
}

void sc_refract_destroy(SC_SCREEN* screen)
{
	if(screen.views.refract != NULL){
		if(is(screen.views.refract,NOSHADOW))
		{
			reset(screen.views.refract,NOSHADOW);
			if(screen.views.refract.bmap) bmap_purge(screen.views.refract.bmap);
			screen.views.refract.bmap = NULL;
			
			if(screen.views.preRefract.bmap) bmap_purge(screen.views.preRefract.bmap);
			screen.views.preRefract.bmap = NULL;
			
			
			//find view before
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.refract && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
			//remove view from view chain
			if(screen.views.refract.stage != NULL)	view_last.stage = screen.views.refract.stage;
			else view_last.stage = NULL;	
			screen.views.refract.stage = NULL;
	
		}
	}
}
void sc_refract_frm(SC_SCREEN* screen)
{
	//do nothing...
}
/*
var sc_forward_materialEvent()
{
	return(1);
}
*/