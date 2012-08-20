void sc_deferred_init(SC_SCREEN* screen)
{
	//create materials
	screen.materials.deferred = mtl_create();
	effect_load(screen.materials.deferred, sc_deferred_sMaterialFinalize);
	screen.materials.deferred.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK];
	screen.materials.deferred.skin2 = screen.renderTargets.deferredLighting;
	screen.materials.deferred.skin3 = screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA];
	screen.materials.deferred.skin4 = screen.renderTargets.ssao;
	
	//setup views
	screen.views.deferred = view_create(-997);
	set(screen.views.deferred, PROCESS_TARGET);
	set(screen.views.deferred, UNTOUCHABLE);
	set(screen.views.deferred, NOSHADOW);
	reset(screen.views.deferred, AUDIBLE);
	set(screen.views.deferred, NOPARTICLE);
	set(screen.views.deferred, CHILD);
	set(screen.views.deferred, NOSKY);
	screen.views.deferred.size_x = screen.views.main.size_x;
	screen.views.deferred.size_y = screen.views.main.size_y;
	screen.views.deferred.material = screen.materials.deferred;
	
	//apply dof to camera
	VIEW* view_last;
	view_last = screen.views.gBuffer;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.deferred;
	
}

void sc_deferred_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.deferred != NULL)
	{
		if(is(screen.views.deferred,NOSHADOW))
		{
			
			reset(screen.views.deferred,NOSHADOW);
			//purge render targets
			if(screen.views.deferred.bmap) bmap_purge(screen.views.deferred.bmap);
			screen.views.deferred.bmap = NULL;
		
			//remove dof from view chain
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.deferred)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.deferred.stage) view_last.stage = screen.views.deferred.stage;
			else view_last.stage = NULL;
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_hdr_mapOrgScene;
			//else view_last.bmap = NULL;
		}
	}
	return 1;
}

void sc_deferred_frm(SC_SCREEN* screen)
{
}