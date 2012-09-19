void sc_gammaCorrection_MaterialEvent()
{
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL);
	/*
	if(screen)
	{
		if(screen.views.gBuffer == NULL)
		{
			//free(screen);
			return(1);
		}
	}
	else
	{
		//free(screen);
		return(1);
	}
	*/
	switch(render_view)
	{
		case screen.views.gammaCorrection:
			screen.views.preGammaCorrection.bmap = screen.renderTargets.full0;
			break;
			
		default:
			break;
	}
}

void sc_gammaCorrection_init(SC_SCREEN* screen)
{
	//MATERIALs
	screen.materials.gammaCorrection = mtl_create();
	effect_load(screen.materials.gammaCorrection, sc_gammaCorrection_sMaterial);
	screen.materials.gammaCorrection.skin1 = screen.renderTargets.full0;// this contains the current scene without gamma correction
	screen.materials.gammaCorrection.event = sc_gammaCorrection_MaterialEvent;
	screen.materials.gammaCorrection.SC_SKILL = screen;
	set(screen.materials.gammaCorrection, ENABLE_VIEW);
	
	//VIEWs
	screen.views.gammaCorrection = view_create(2);
	set(screen.views.gammaCorrection, PROCESS_TARGET);
	set(screen.views.gammaCorrection, UNTOUCHABLE);
	set(screen.views.gammaCorrection, NOSHADOW);
	reset(screen.views.gammaCorrection, AUDIBLE);
	set(screen.views.gammaCorrection, CHILD);
	screen.views.gammaCorrection.size_x = screen.views.main.size_x;
	screen.views.gammaCorrection.size_y = screen.views.main.size_y;
	screen.views.gammaCorrection.material = screen.materials.gammaCorrection;
	
	//apply to camera
	VIEW* view_last;
	view_last = screen.views.main;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.gammaCorrection;
	screen.views.preGammaCorrection = view_last;
	
}

void sc_gammaCorrection_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.gammaCorrection != NULL)
	{
		if(is(screen.views.gammaCorrection,NOSHADOW))
		{
			reset(screen.views.gammaCorrection,NOSHADOW);
			//purge render targets
			//bmap_purge(screen.views.deferred.bmap);
			//screen.views.deferred.bmap = NULL;
						
			//remove from view chain
			VIEW* view_last;
			view_last = screen.views.main;
			while(view_last.stage != screen.views.gammaCorrection && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.gammaCorrection.stage) view_last.stage = screen.views.gammaCorrection.stage;
			else view_last.stage = NULL;
		}
	}
	return 1;
}

void sc_gammaCorrection_frm(SC_SCREEN* screen)
{
	//not much to do here...
}