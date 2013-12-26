void sc_gBuffer_init(SC_SCREEN* screen, int inBufferType, int inBufferFormat) 
{
	if(!screen) return 0;
	
	//setup screen aligned quad
   sc_setupScreenquad(screen);
	
	//remove rendertarget textures if there are any
//	if(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]);
//	if(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]);
//	if(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]);
//	if(screen.renderTargets.gBuffer[3]) bmap_purge(screen.renderTargets.gBuffer[3]);
//	ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]);
//	ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]);
//	ptr_remove(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]);
//	ptr_remove(screen.renderTargets.gBuffer[3]);
		
	//create rendertarget textures
	screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH] = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, inBufferFormat);
	if(inBufferType == SC_GBUFFER_DEFERRED)
	{
		screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK] = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, inBufferFormat);
		screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA] = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, inBufferFormat);
		screen.renderTargets.gBuffer[3] = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, inBufferFormat);
	}
	
	/*
	//setup materials
	screen.materials.gBuffer = mtl_create();
	if(inBufferType == SC_GBUFFER_SIMPLE) effect_load(screen.materials.gBuffer, sc_gBuffer_sMaterialSimple);
	if(inBufferType == SC_GBUFFER_DEFERRED) effect_load(screen.materials.gBuffer, sc_gBuffer_sMaterialDeferred);
	set(screen.materials.gBuffer, TANGENT);
	set(screen.materials.gBuffer, ENABLE_RENDER);
	set(screen.materials.gBuffer, ENABLE_TREE);
	//set(screen.materials.gBuffer, ENABLE_VIEW);
	screen.materials.gBuffer.SC_SKILL = screen;
	screen.materials.gBuffer.event = sc_gBuffer_mtlGBufferEvent;
	*/
		
	//setup views
		//main view
		screen.views.gBuffer = view_create(0);
		screen.views.gBuffer.size_x = screen.views.main.size_x;
		screen.views.gBuffer.size_y = screen.views.main.size_y;
		set(screen.views.gBuffer,SHOW);
		set(screen.views.gBuffer,AUDIBLE);
		set(screen.views.gBuffer,NOPARTICLE);
		set(screen.views.gBuffer,NOSHADOW);
		reset(screen.views.gBuffer,UNTOUCHABLE);
		set(screen.views.gBuffer,NOFLAG1);
		//screen.views.gBuffer.material = screen.materials.gBuffer;
		//screen.views.gBuffer.stage = screen.views.main;
		
		//assign rendertargets
		screen.views.gBuffer.bmap = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		if(inBufferType == SC_GBUFFER_DEFERRED)
		{
			screen.views.gBuffer.target1 = screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK];
			screen.views.gBuffer.target2 = screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA];
			screen.views.gBuffer.target3 = screen.renderTargets.fogMap;
		}
		
}

/*
function eventTarget()
{
	if(!sc_screen_default) return(1);
	
	switch(render_view)
	{
		case sc_screen_default.views.gBuffer:
			bmap_rendertarget(sc_screen_default.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH],0,0);
			bmap_rendertarget(sc_screen_default.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK],1,0);
			bmap_rendertarget(sc_screen_default.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA],2,0);
			bmap_rendertarget(NULL,3,0);
			break;
		case sc_screen_default.views.deferredLighting:
			bmap_rendertarget(NULL,0,0);//bmap_rendertarget(sc_screen_default.renderTargets.deferredLighting,0,0);
			bmap_rendertarget(NULL,1,0);
			bmap_rendertarget(NULL,2,0);
			bmap_rendertarget(NULL,3,0);
			break;
		default:
			bmap_rendertarget(NULL,0,0);
			bmap_rendertarget(NULL,1,0);
			bmap_rendertarget(NULL,2,0);
			bmap_rendertarget(NULL,3,0);
	}
	
}

MATERIAL* mtl_viewevent = {
  event = eventTarget;
  flags = ENABLE_VIEW;
}
*/


void sc_gBuffer_destroy(SC_SCREEN* screen)
{
	if(screen.views.gBuffer != NULL){
		if(is(screen.views.gBuffer,NOSHADOW))
		{
			reset(screen.views.gBuffer,NOSHADOW);
			reset(screen.views.gBuffer,SHOW);
//			screen.views.gBuffer.bmap = NULL;
			screen.views.gBuffer.target1 = NULL;
			screen.views.gBuffer.target2 = NULL;
			screen.views.gBuffer.target3 = NULL;
			
//			if(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]);
//			if(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK]);
//			if(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]) bmap_purge(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]);
//			if(screen.renderTargets.gBuffer[3]) bmap_purge(screen.renderTargets.gBuffer[3]);
			
			/*
			//find view before shadows_viewShadows
			VIEW* view_last;
			view_last = screen.main;
			while(view_last.stage != screen.sc_depth_view)
			{
				view_last = view_last.stage;
			}
			//remove shadows_viewShadows from view chain
			if(screen.sc_depth_viewShowOrg.stage != NULL)
			{
				view_last.stage = screen.sc_depth_viewShowOrg.stage;
			}
			else
			{
				view_last.stage = NULL;
			}	
			*/
			
			screen.views.gBuffer.stage = NULL;
	
		}
	}
}

void sc_gBuffer_frm(SC_SCREEN* screen)
{
	//if(!screen) return 0;
	
	proc_mode = PROC_LATE;
	if(screen.views.gBuffer != NULL)
	{
		
		screen.views.gBuffer.clip_near = screen.views.main.clip_near;
		screen.views.gBuffer.clip_far = screen.views.main.clip_far;
		
		vec_set(screen.views.gBuffer.x, screen.views.main.x);
		vec_set(screen.views.gBuffer.pan, screen.views.main.pan);
		vec_set(screen.views.gBuffer.arc, screen.views.main.arc);
		
		screen.views.gBuffer.lod = screen.views.main.lod;
		screen.views.gBuffer.size_x = screen.views.main.size_x;
		screen.views.gBuffer.size_y = screen.views.main.size_y;
		screen.views.gBuffer.genius = screen.views.main.genius;
		
		screen.views.gBuffer.fog_start = screen.views.main.fog_start;
		screen.views.gBuffer.fog_end = screen.views.main.fog_end;
		
	}
}

/*
void sc_gBuffer_passFrustumPoints(SC_SCREEN* screen)
{
	if(!screen) return 0;
	
	VECTOR tl;
	VECTOR tr;
	VECTOR bl;
		
	D3DXVECTOR3 tr_;
	D3DXVECTOR3 tl_;
	D3DXVECTOR3 bl_;
		
	tl.x = 0;
	tl.y = 0;
	tl.z = -screen.views.main.clip_far;
	vec_for_screen(tl,screen.views.main);
	vec_set(tl, vector(tl.x, tl.z, tl.y) );	
		
	tr.x = screen.views.main.size_x;
	tr.y = 0;
	tr.z = -screen.views.main.clip_far;
	vec_for_screen(tr,screen.views.main);
	vec_set(tr, vector(tr.x, tr.z, tr.y) );
			
	bl.x = 0;
	bl.y = screen.views.main.size_y;
	bl.z = -screen.views.main.clip_far;
	vec_for_screen(bl,screen.views.main);
	vec_set(bl, vector(bl.x, bl.z, bl.y) );
			
	tr_.x = tr.x;
	tr_.y = tr.y;
	tr_.z = tr.z;
			
	tl_.x = tl.x;
	tl_.y = tl.y;
	tl_.z = tl.z;
		
	bl_.x = bl.x;
	bl_.y = bl.y;
	bl_.z = bl.z;
			
	D3DXMATRIX _matView;
	D3DXMATRIX _matProj;
	view_to_matrix(screen.views.main, _matView, _matProj);
	D3DXVec3Transform(tr_, tr_, _matView);
	D3DXVec3Transform(tl_, tl_, _matView);
	D3DXVec3Transform(bl_, bl_, _matView);
			

	tr.x = tr_.x;
	tr.y = tr_.y;
	tr.z = tr_.z;
		
	tl.x = tl_.x;
	tl.y = tl_.y;
	tl.z = tl_.z;
		
	bl.x = bl_.x;
	bl.y = bl_.y;
	bl.z = bl_.z;
}
*/

/*
var sc_gBuffer_mtlGBufferEvent()
{
	
	//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
	//pd3dDevice->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), (float)0.0, 0);
	
	if(my)
	{
		//if(my.skill2 == 1) mtl.skill1 = floatv(1);
		if(my.SC_SKILL)
		{
			SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);
			
			if(ObjData.depth == -1) return(1); //clip from gBuffer
			
			//if(ObjData.materials.gBuffer != NULL)
			if(my.material)
			{
				my.material.skill17 = mtl.skill17;
				
				//mtl = ObjData.materials.gBuffer;
				mtl = my.material;
				mtl.skill1 = floatv(1-(my.alpha/100));
				//mtl.skill17 = floatv(screen.views.main.clip_far); //max depth
				mtl.skill18 = floatv(ObjData.brdf.index); //brdf Index
				mtl.skill19 = floatv(ObjData.brdf.power); //brdf Power
			}
			//mtl.skill2 = floatv(ObjData.depth);
			//ptr_remove(ObjData);
			return (0);
		}
		else
		{
			if(my.material)
			{
				my.material.skill17 = mtl.skill17;
				mtl = my.material;
				mtl.skill1 = floatv(1-(my.alpha/100)); //alpha cutout
			}
		}
	}
	

	mtl.skill1 = floatv(0.5); //alpha cutout
	//mtl.skill17 = floatv(screen.views.main.clip_far); //max depth
	mtl.skill18 = floatv(0.0039); //brdf index (0 and 0.0039 = blinn-phong (special case as blinn-phong is on tex-sheet 1 and 128!)
	mtl.skill19 = floatv(0.35); //brdf power
	
	//ptr_remove(screen);
	return(0);
	
	
	
	//get device
	//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
	
	//load effect
	//LPD3DXEFFECT anEffect;
	//D3DXCreateEffectFromFileA(pd3dDevice,"sc_gBuffer_deferred.fx",NULL,NULL,0,NULL,&anEffect,NULL)
	
	
	
}
*/