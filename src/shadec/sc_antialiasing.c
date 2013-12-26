void sc_antialiasing_materialEvent()
{
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL);
	switch(render_view)
	{
		case screen.views.antialiasing:
			screen.views.preAntialiasing.bmap = screen.renderTargets.full2;
			break;
			
		case screen.views.antialiasingBlendWeights:
			screen.views.antialiasingBlendWeights.bmap = screen.renderTargets.full1;
			//screen.views.dofBlurX.bmap = screen.renderTargets.quarter1;
			break;
			
		case screen.views.antialiasingEdgeDetect:
			screen.views.preAntialiasing.bmap = screen.renderTargets.full2;
			screen.views.antialiasingEdgeDetect.bmap = screen.renderTargets.full0;
			break;
		
		default:
			break;
	}
	//if(render_view == screen.views.dofDownsample) screen.views.deferred.bmap = screen.renderTargets.full0;
	//else screen.views.deferred.bmap = NULL;
}

void sc_antialiasing_init(SC_SCREEN* screen)
{
	/*
		//antialiasing
		screen.views.antialiasing.material = mtl_create();
		effect_load(screen.materials.dof, sc_dof_sMaterial);
		screen.materials.dof.skin1 = screen.renderTargets.full0;// this contains the current scene without dof
		screen.materials.dof.skin2 = screen.renderTargets.quarter0;// this contains the blurred scene
		screen.materials.dof.skin3 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.dof.skill1 = floatv(0.25); // inverted downsample factor
		*/
		
	//antialiasing
	screen.views.antialiasing = view_create(2);
	set(screen.views.antialiasing, PROCESS_TARGET);
	set(screen.views.antialiasing, UNTOUCHABLE);
	set(screen.views.antialiasing, NOSHADOW);
	//set(screen.views.antialiasing, NOSKY);
	reset(screen.views.antialiasing, AUDIBLE);
	set(screen.views.antialiasing, CHILD);
	screen.views.antialiasing.size_x = screen.views.main.size_x;
	screen.views.antialiasing.size_y = screen.views.main.size_y;
	//screen.views.antialiasing.bmap = screen.renderTargets.full0; //just assign it to an existing rendertarget so gamestudio does not automatically create a new one
	screen.views.antialiasing.material = mtl_create();
	effect_load(screen.views.antialiasing.material, sc_antialiasing_strMlaaFinal);
	screen.views.antialiasing.material.event = sc_antialiasing_materialEvent;
	screen.views.antialiasing.material.SC_SKILL = screen;
	set(screen.views.antialiasing.material, ENABLE_VIEW);
	screen.views.antialiasing.material.skin1 = screen.renderTargets.full2; //original scene
	screen.views.antialiasing.material.skin2 = screen.renderTargets.full1; //blend weights
		
	//antialiasing blend weights
	screen.views.antialiasingBlendWeights = view_create(2);
	set(screen.views.antialiasingBlendWeights, PROCESS_TARGET);
	set(screen.views.antialiasingBlendWeights, UNTOUCHABLE);
	set(screen.views.antialiasingBlendWeights, NOSHADOW);
	//set(screen.views.antialiasingBlendWeights, NOSKY);
	reset(screen.views.antialiasingBlendWeights, AUDIBLE);
	set(screen.views.antialiasingBlendWeights, CHILD);
	screen.views.antialiasingBlendWeights.size_x = screen.views.main.size_x;
	screen.views.antialiasingBlendWeights.size_y = screen.views.main.size_y;
	screen.views.antialiasingBlendWeights.bmap = screen.renderTargets.full1; //just assign it to an existing rendertarget so gamestudio does not automatically create a new one
	screen.views.antialiasingBlendWeights.material = mtl_create();
	effect_load(screen.views.antialiasingBlendWeights.material, sc_antialiasing_strMlaaBlendWeights);
	screen.views.antialiasingBlendWeights.material.event = sc_antialiasing_materialEvent;
	screen.views.antialiasingBlendWeights.material.SC_SKILL = screen;
	set(screen.views.antialiasingBlendWeights.material, ENABLE_VIEW);
	screen.views.antialiasingBlendWeights.stage = screen.views.antialiasing;
	screen.views.antialiasingBlendWeights.material.skin1 = screen.renderTargets.full0;
	screen.views.antialiasingBlendWeights.material.skin2 = sc_antialiasing_mlaaMapArea;
		
	//antialiasing edge detect
	screen.views.antialiasingEdgeDetect = view_create(2);
	set(screen.views.antialiasingEdgeDetect, PROCESS_TARGET);
	set(screen.views.antialiasingEdgeDetect, UNTOUCHABLE);
	set(screen.views.antialiasingEdgeDetect, NOSHADOW);
	reset(screen.views.antialiasingEdgeDetect, AUDIBLE);
	set(screen.views.antialiasingEdgeDetect, CHILD);
	screen.views.antialiasingEdgeDetect.size_x = screen.views.main.size_x;
	screen.views.antialiasingEdgeDetect.size_y = screen.views.main.size_y;
	screen.views.antialiasingEdgeDetect.bmap = screen.renderTargets.full0; //just assign it to an existing rendertarget so gamestudio does not automatically create a new one
	screen.views.antialiasingEdgeDetect.material = mtl_create();
	effect_load(screen.views.antialiasingEdgeDetect.material, sc_antialiasing_strMlaaEdgeDetect);
	screen.views.antialiasingEdgeDetect.material.event = sc_antialiasing_materialEvent;
	screen.views.antialiasingEdgeDetect.material.SC_SKILL = screen;
	set(screen.views.antialiasingEdgeDetect.material, ENABLE_VIEW);
	screen.views.antialiasingEdgeDetect.stage = screen.views.antialiasingBlendWeights;
	screen.views.antialiasingEdgeDetect.material.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
	screen.views.antialiasingEdgeDetect.material.skin2 = screen.renderTargets.full2; //original scene
		
	//apply to camera
	VIEW* view_last;
	view_last = screen.views.main;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.antialiasingEdgeDetect;
	screen.views.preAntialiasing = view_last;
}


void sc_antialiasing_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.antialiasing != NULL)
	{
		
		if(is(screen.views.antialiasing,NOSHADOW))
		{
			
			reset(screen.views.antialiasing,NOSHADOW);
			
			//purge render targets
			//bmap_purge(screen.views.deferred.bmap);
			//screen.views.deferred.bmap = NULL;
						
			//remove from view chain
			VIEW* view_last;
			view_last = screen.views.main;
			while(view_last.stage != screen.views.antialiasingEdgeDetect && view_last.stage != NULL)
			{
				view_last = view_last.stage;
				error("ping pong");
			}
			
				
			if(screen.views.antialiasing.stage) view_last.stage = screen.views.antialiasing.stage;
			else view_last.stage = NULL;
			
			if(screen.views.antialiasingBlendWeights.material != NULL) ptr_remove(screen.views.antialiasingBlendWeights.material);
			if(screen.views.antialiasingEdgeDetect.material != NULL) ptr_remove(screen.views.antialiasingEdgeDetect.material);
			if(screen.views.antialiasing.material != NULL) ptr_remove(screen.views.antialiasing.material);
			
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_dof_mapOrgScene;
			//else view_last.bmap = NULL;
			
		}
		
	}
	return 1;
}












/*
var sc_mlaa_init(SC_SCREEN* screen)
{
	if(!screen) return 0;
	
	if(screen.sc_mlaa_mtlEdgeDetect != NULL)
	{
		if(screen.sc_mlaa_viewEdgeDetect.bmap) bmap_purge(screen.sc_mlaa_viewEdgeDetect.bmap);
		if(screen.sc_mlaa_viewBlendWeight.bmap) bmap_purge(screen.sc_mlaa_viewBlendWeight.bmap);
		if(screen.sc_mlaa_view.bmap) bmap_purge(screen.sc_mlaa_view.bmap);
		
		
		ptr_remove(screen.sc_mlaa_mtlEdgeDetect);
		ptr_remove(screen.sc_mlaa_mtlBlendWeight);
		ptr_remove(screen.sc_mlaa_mtl);
		ptr_remove(screen.sc_mlaa_viewEdgeDetect);
		ptr_remove(screen.sc_mlaa_viewBlendWeight);
		ptr_remove(screen.sc_mlaa_view);
	}
	
	//create materials
	screen.sc_mlaa_mtlEdgeDetect = mtl_create();
	screen.sc_mlaa_mtlBlendWeight = mtl_create();
	screen.sc_mlaa_mtl = mtl_create();
	
	//load materials
	effect_load(screen.sc_mlaa_mtlEdgeDetect, sc_mlaa_strEdgeDetect);
	effect_load(screen.sc_mlaa_mtlBlendWeight, sc_mlaa_strBlendWeight);
	effect_load(screen.sc_mlaa_mtl, sc_mlaa_strFinal);

	
	//create Edge Detect View
	screen.sc_mlaa_viewEdgeDetect = view_create(-10);
	set(screen.sc_mlaa_viewEdgeDetect,NOSHADOW);
	set(screen.sc_mlaa_viewEdgeDetect,PROCESS_TARGET);
	set(screen.sc_mlaa_viewEdgeDetect,CHILD);
	screen.sc_mlaa_viewEdgeDetect.material = screen.sc_mlaa_mtlEdgeDetect;
	screen.sc_mlaa_viewEdgeDetect.bmap = bmap_createblack(screen.main.size_x, screen.main.size_y, 12222);
	
	//create Blend Weigth View
	screen.sc_mlaa_viewBlendWeight = view_create(-10);
	set(screen.sc_mlaa_viewBlendWeight,PROCESS_TARGET);
	set(screen.sc_mlaa_viewBlendWeight,CHILD);
	screen.sc_mlaa_viewBlendWeight.material = screen.sc_mlaa_mtlBlendWeight;
	screen.sc_mlaa_viewEdgeDetect.stage = screen.sc_mlaa_viewBlendWeight;
	screen.sc_mlaa_viewBlendWeight.bmap = bmap_createblack(screen.main.size_x, screen.main.size_y, 12222);

	screen.sc_mlaa_mtlBlendWeight.skin1 = sc_mlaa_mapArea;
	
	
	//create MLAA View
	screen.sc_mlaa_view = view_create(-10);
	set(screen.sc_mlaa_view,PROCESS_TARGET);
	set(screen.sc_mlaa_view,CHILD);
	screen.sc_mlaa_view.material = screen.sc_mlaa_mtl;
	screen.sc_mlaa_viewBlendWeight.stage = screen.sc_mlaa_view;
	//screen.sc_mlaa_view.bmap = bmap_createblack(screen.main.size_x, screen.main.size_y, 32);
		
	//apply MLAA to camera
	VIEW* view_last;
	view_last = screen.main;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.sc_mlaa_viewEdgeDetect;
	
	//render original scene to map
	//screen.sc_mlaa_mapOrgScene = bmap_createblack(screen.main.size_x, screen.main.size_y, 32);
	//view_last.bmap = screen.sc_mlaa_mapOrgScene;
	screen.sc_mlaa_mtl.skin1 = bmap_createblack(screen.main.size_x, screen.main.size_y, 32);
	view_last.bmap = screen.sc_mlaa_mtl.skin1;
	
	//assign render targets to materials
	screen.sc_mlaa_mtlEdgeDetect.skin1 = screen.sc_depth_map; //this contains the depthmap (linear) and viewspace normals
	
	//return quality;
	
}

var sc_mlaa_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.sc_mlaa_mtlEdgeDetect != NULL)
	{
		if(is(screen.sc_mlaa_mtlEdgeDetect,NOSHADOW))
		{
			
			reset(screen.sc_mlaa_mtlEdgeDetect,NOSHADOW);
			
			//purge render targets
			if(screen.sc_mlaa_viewEdgeDetect.bmap) bmap_purge(screen.sc_mlaa_viewEdgeDetect.bmap);
			screen.sc_mlaa_viewEdgeDetect.bmap = NULL;
			
			if(screen.sc_mlaa_viewBlendWeight.bmap) bmap_purge(screen.sc_mlaa_viewBlendWeight.bmap);
			screen.sc_mlaa_viewBlendWeight.bmap = NULL;

			if(screen.sc_mlaa_view.bmap) bmap_purge(screen.sc_mlaa_view.bmap);
			screen.sc_mlaa_view.bmap = NULL;
			
			if(screen.sc_mlaa_mtl.skin1) bmap_purge(screen.sc_mlaa_mtl.skin1);
			screen.sc_mlaa_mtl.skin1 = NULL;
		
			
			//remove dof from view chain
			VIEW* view_last;
			view_last = screen.main;
			while(view_last.stage != screen.sc_mlaa_viewEdgeDetect)
			{
				view_last = view_last.stage;
			}
				
			if(screen.sc_mlaa_view.stage) view_last.stage = screen.sc_mlaa_view.stage;
			else view_last.stage = NULL;

		}
	}
	return 1;
}

void sc_mlaa_frm(SC_SCREEN* screen)
{
	if(screen.sc_mlaa_viewEdgeDetect != NULL)
	{
	
	}
	
}
*/