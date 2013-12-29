void sc_dof_MaterialEvent()
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
		case screen.views.dof:
			screen.views.preDOF.bmap = screen.renderTargets.full0;
			break;
			
		case screen.views.dofDownsample:
			screen.views.preDOF.bmap = screen.renderTargets.full0;
			screen.views.dofDownsample.bmap = screen.renderTargets.quarter0;
			break;
			
		case screen.views.dofBlurX:
			screen.views.dofBlurX.bmap = screen.renderTargets.quarter1;
			screen.views.dofBlurX.target1 = screen.renderTargets.quarter2;
			break;
		
		case screen.views.dofBlurY:
			screen.views.dofBlurY.bmap = screen.renderTargets.quarter0;
			break;
		
		default:
			break;
	}
	//if(render_view == screen.views.dofDownsample) screen.views.deferred.bmap = screen.renderTargets.full0;
	//else screen.views.deferred.bmap = NULL;
}

void sc_dof_init(SC_SCREEN* screen)
{
	//create materials
	
		//dof
		screen.materials.dof = mtl_create();
		effect_load(screen.materials.dof, sc_dof_sMaterial);
		screen.materials.dof.skin1 = screen.renderTargets.full0;// this contains the current scene without dof
		screen.materials.dof.skin2 = screen.renderTargets.quarter0;// this contains the blurred scene
		screen.materials.dof.skin3 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.dof.skill1 = floatv(0.25); // inverted downsample factor
		screen.materials.dof.event = sc_dof_MaterialEvent;
		screen.materials.dof.SC_SKILL = screen;
		set(screen.materials.dof, ENABLE_VIEW);
	
		//blur y
		screen.materials.dofBlurY = mtl_create();
		effect_load(screen.materials.dofBlurY, sc_dof_sMaterialBlurY);
		screen.materials.dofBlurY.skin1 = screen.renderTargets.quarter1;// this contains the x blurred scene, with unblurred focus
		screen.materials.dofBlurY.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.dofBlurY.skin3 = screen.renderTargets.quarter2;// this contains the downsampled scene, with blurred focus
		screen.materials.dofBlurY.skill1 = floatv(screen.settings.dof.blurY); //blur strength
		screen.materials.dofBlurY.event = sc_dof_MaterialEvent;
		screen.materials.dofBlurY.SC_SKILL = screen;
		set(screen.materials.dofBlurY, ENABLE_VIEW);
			
		//blur x
		screen.materials.dofBlurX = mtl_create();
		effect_load(screen.materials.dofBlurX, sc_dof_sMaterialBlurX);
		screen.materials.dofBlurX.skin1 = screen.renderTargets.quarter0;// this contains the downsampled scene
		screen.materials.dofBlurX.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.dofBlurX.skill1 = floatv(screen.settings.dof.blurX); //blur strength
		screen.materials.dofBlurX.event = sc_dof_MaterialEvent;
		screen.materials.dofBlurX.SC_SKILL = screen;
		set(screen.materials.dofBlurX, ENABLE_VIEW);
		
		//downsample
		screen.materials.dofDownsample = mtl_create();
		effect_load(screen.materials.dofDownsample, sc_dof_sMaterialDownsample);
		screen.materials.dofDownsample.skin1 = screen.renderTargets.full0;// this contains the current scene without dof
		screen.materials.dofDownsample.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.dofDownsample.skill1 = floatv(4); //downsample factor
		screen.materials.dofDownsample.event = sc_dof_MaterialEvent;
		screen.materials.dofDownsample.SC_SKILL = screen;
		set(screen.materials.dofDownsample, ENABLE_VIEW);
	
	
	//setup views
	
		//dof
		screen.views.dof = view_create(2);
		set(screen.views.dof, PROCESS_TARGET);
		set(screen.views.dof, UNTOUCHABLE);
		set(screen.views.dof, NOSHADOW);
		reset(screen.views.dof, AUDIBLE);
		set(screen.views.dof, CHILD);
		screen.views.dof.size_x = screen.views.main.size_x;
		screen.views.dof.size_y = screen.views.main.size_y;
		screen.views.dof.material = screen.materials.dof;
		//screen.views.dof.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
	
		//blur y
		screen.views.dofBlurY = view_create(2);
		set(screen.views.dofBlurY, PROCESS_TARGET);
		set(screen.views.dofBlurY, UNTOUCHABLE);
		set(screen.views.dofBlurY, NOSHADOW);
		reset(screen.views.dofBlurY, AUDIBLE);
		set(screen.views.dofBlurY, CHILD);
		screen.views.dofBlurY.size_x = screen.views.main.size_x/4;
		screen.views.dofBlurY.size_y = screen.views.main.size_y/4;
		screen.views.dofBlurY.material = screen.materials.dofBlurY;
		screen.views.dofBlurY.stage = screen.views.dof;
		screen.views.dofBlurY.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		//blur x
		screen.views.dofBlurX = view_create(2);
		set(screen.views.dofBlurX, PROCESS_TARGET);
		set(screen.views.dofBlurX, UNTOUCHABLE);
		set(screen.views.dofBlurX, NOSHADOW);
		reset(screen.views.dofBlurX, AUDIBLE);
		set(screen.views.dofBlurX, CHILD);
		screen.views.dofBlurX.size_x = screen.views.main.size_x/4;
		screen.views.dofBlurX.size_y = screen.views.main.size_y/4;
		screen.views.dofBlurX.material = screen.materials.dofBlurX;
		screen.views.dofBlurX.stage = screen.views.dofBlurY;
		screen.views.dofBlurX.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		screen.views.dofBlurX.target1 = screen.renderTargets.quarter2; //assign temp render target so Acknex does not automatically create a new one
		
		//downsample
		screen.views.dofDownsample = view_create(2);
		set(screen.views.dofDownsample, PROCESS_TARGET);
		set(screen.views.dofDownsample, UNTOUCHABLE);
		set(screen.views.dofDownsample, NOSHADOW);
		reset(screen.views.dofDownsample, AUDIBLE);
		set(screen.views.dofDownsample, CHILD);
		screen.views.dofDownsample.size_x = screen.views.main.size_x/4;
		screen.views.dofDownsample.size_y = screen.views.main.size_y/4;
		screen.views.dofDownsample.material = screen.materials.dofDownsample;
		screen.views.dofDownsample.stage = screen.views.dofBlurX;
		screen.views.dofDownsample.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		
		
	//apply to camera
	VIEW* view_last;
	view_last = screen.views.main;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.dofDownsample;
	screen.views.preDOF = view_last;
}

void sc_dof_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.dof != NULL)
	{
		if(is(screen.views.dof,NOSHADOW))
		{
			
			reset(screen.views.dof,NOSHADOW);
			//purge render targets
			//bmap_purge(screen.views.deferred.bmap);
			//screen.views.deferred.bmap = NULL;
						
			//remove from view chain
			VIEW* view_last;
			view_last = screen.views.main;
			while(view_last.stage != screen.views.dofDownsample && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.dof.stage) view_last.stage = screen.views.dof.stage;
			else view_last.stage = NULL;
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_dof_mapOrgScene;
			//else view_last.bmap = NULL;
		}
	}
	return 1;
}

void sc_dof_frm(SC_SCREEN* screen)
{
	if(screen.views.dof != NULL)
	{
		screen.materials.dofDownsample.skill2 = floatv(screen.views.main.clip_far);
		screen.materials.dofDownsample.skill3 = floatv(screen.settings.dof.focalPos); //focal plane pos
		screen.materials.dofDownsample.skill4 = floatv(screen.settings.dof.focalWidth); //focal plane width
		
		screen.materials.dof.skill2 = floatv(screen.views.main.clip_far);
		screen.materials.dof.skill3 = floatv(screen.settings.dof.focalPos); //focal plane pos
		screen.materials.dof.skill4 = floatv(screen.settings.dof.focalWidth); //focal plane width
		
		screen.materials.dofBlurX.skill1 = floatv(screen.settings.dof.blurX); //blur strength
		screen.materials.dofBlurY.skill1 = floatv(screen.settings.dof.blurY); //blur strength
	}
}