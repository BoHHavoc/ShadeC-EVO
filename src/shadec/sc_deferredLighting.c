void sc_deferredLighting_init(SC_SCREEN* screen, int rtScale) 
{
	if(!screen) return 0;
	
	//remove rendertarget textures if there are any
	if(screen.renderTargets.deferredLighting) bmap_purge(screen.renderTargets.deferredLighting);
	ptr_remove(screen.renderTargets.deferredLighting);
	
	//create rendertarget textures
	screen.renderTargets.deferredLighting = bmap_createblack(screen.views.main.size_x/rtScale, screen.views.main.size_y/rtScale, 32);
	
	//create brdf LUT
	if(!sc_deferredLighting_texBRDFLUT) sc_deferredLighting_texBRDFLUT = sc_volumeTexture_create(sc_deferredLighting_sBRDFLUT);
			
	//setup views
		screen.views.deferredLighting = view_create(-998);
		screen.views.deferredLighting.size_x = screen.views.main.size_x/rtScale;
		screen.views.deferredLighting.size_y = screen.views.main.size_y/rtScale;
		reset(screen.views.deferredLighting, AUDIBLE);
		set(screen.views.deferredLighting, NOPARTICLE);
		set(screen.views.deferredLighting, NOSHADOW);
		set(screen.views.deferredLighting, UNTOUCHABLE);
		//set(screen.views.deferredLighting, PROCESS_SCREEN);
		set(screen.views.deferredLighting, NOSKY);
		set(screen.views.deferredLighting, CHILD);
		#ifdef SC_USE_NOFLAG1
			set(screen.views.deferredLighting, NOFLAG1);
		#endif
		//screen.views.deferredLighting.material = screen.materials.deferredLighting;
		screen.views.deferredLighting.bmap = screen.renderTargets.deferredLighting;
		
		//add to render chain
		VIEW* view_last;
		view_last = screen.views.gBuffer;
		//while(view_last.stage != screen.views.main)
		while(view_last.stage != NULL)
		{
			view_last = view_last.stage;
		}
		if(view_last.stage) screen.views.deferredLighting.stage = view_last.stage;
		view_last.stage = screen.views.deferredLighting;
		//
			
		
	
	
}

void sc_deferredLighting_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.deferredLighting != NULL)
	{
		if(is(screen.views.deferredLighting,NOSHADOW))
		{
			
			reset(screen.views.deferredLighting,NOSHADOW);
			//purge render targets
			bmap_purge(screen.views.deferredLighting.bmap);
			screen.views.deferredLighting.bmap = NULL;
					
			//remove deferredLighting from view chain
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.deferredLighting && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.deferredLighting.stage) view_last.stage = screen.views.deferredLighting.stage;
			else view_last.stage = NULL;
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_hdr_mapOrgScene;
			//else view_last.bmap = NULL;
		}
	}
}

void sc_deferredLighting_frm(SC_SCREEN* screen)
{
}

/*
var sc_deferredLighting_mtlRenderEvent()
{	
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL);
	//screen = (SC_SCREEN*)(mtl.SC_SKILL);
	if(screen)
	{
		if(screen.views.deferredLighting == NULL)
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
		
	if(my)
	{	
		if(my.SC_SKILL && render_view == screen.views.deferredLighting)
		{
			SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);
			if(ObjData == NULL) return(1); //don't render entity if it's not a Shade-C Object 
			if(ObjData.light.material != NULL)
			{
				ObjData.light.material.skin1 = mtl.skin1; //point to gBuffer: normals and depth
				ObjData.light.material.skin2 = ObjData.light.projMap; //projection map
				ObjData.light.material.skin3 = ObjData.light.shadowMap; //shadowmap
				ObjData.light.material.skin4 = mtl.skin4; //point to gBuffer: brdf data
				
				mtl.skill1 = floatv(my.x - screen.views.main.x); //light pos in camera space
				mtl.skill2 = floatv(my.y - screen.views.main.y); //light pos in camera space
				mtl.skill3 = floatv(my.z - screen.views.main.z); //light pos in camera space
				mtl.skill4 = floatv(ObjData.light.range);
				mtl.skill5 = floatv(ObjData.light.color.x);
				mtl.skill6 = floatv(ObjData.light.color.y);
				mtl.skill7 = floatv(ObjData.light.color.z);
				//mtl.skill8 = floatv(screen.views.main.clip_far);
				
				//spotlight
				mtl.skill9 = floatv(ObjData.light.dir.x);
				mtl.skill10 = floatv(ObjData.light.dir.y);
				mtl.skill11 = floatv(ObjData.light.dir.z);
				
				//stencil reference
				//mtl.skill12 = floatv(ObjData.light.stencilRef);
				
				//check if camera is in- or outside of lightvolume
				if( abs( vec_dist(my.x, screen.views.main.x) ) > ObjData.light.range + (50) ) //camera is outside of volume
				{
					mtl.skill12 = floatv(ObjData.light.stencilRef); //set stencil ref -> stenciling
				}
				else //camera is inside
				{
					mtl.skill12 = floatv(0); //set stencil ref to zero -> no stenciling...  HAVOC : doesn't work, gives visual bugs. Have to switch materials here
				}
				
				//Pass light-projection-matrix (shadows, projectionmap, etc)
				if(ObjData.light.matrix != NULL) mat_set(mtl.matrix, ObjData.light.matrix);
				//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
				//pd3dDevice->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), (float)1.0, 0);
				return(0);
	
			}
			
			
			
		}
		
		//free(screen);
	}
	
	mtl.skill1 = floatv(0);
	mtl.skill2 = floatv(0);
	mtl.skill3 = floatv(0);
	mtl.skill4 = floatv(0);
	mtl.skill5 = floatv(2);
	mtl.skill6 = floatv(2);
	mtl.skill7 = floatv(2);
	//mtl.skill8 = floatv(screen.views.main.clip_far);
	
	mtl.skill9 = floatv(0);
	mtl.skill10 = floatv(0);
	mtl.skill11 = floatv(0);
	mtl.skill12 = floatv(0);
	
	//clear the screen
	//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
	//pd3dDevice->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), (float)0.0, 0);
	return(1);	
	
	
	
}
*/

