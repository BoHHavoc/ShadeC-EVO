void sc_deferred_init(SC_SCREEN* screen)
{
	//create materials
	screen.materials.deferred = mtl_create();
	effect_load(screen.materials.deferred, sc_deferred_sMaterialFinalize);
	//screen.materials.deferred.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK];
	//screen.materials.deferred.skin2 = screen.renderTargets.deferredLighting;
	//screen.materials.deferred.skin3 = screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA];
	screen.materials.deferred.skin4 = screen.renderTargets.ssao;
	
	//screen.materials.deferred.skin4 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
	
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
			while(view_last.stage != screen.views.deferred && view_last.stage != NULL)
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
	if(screen.views.deferred != NULL)
	{
		screen.materials.deferred.skill1 = floatv(ambient_color.red/255);
		screen.materials.deferred.skill2 = floatv(ambient_color.green/255);
		screen.materials.deferred.skill3 = floatv(ambient_color.blue/255);
		
		
		LPD3DXEFFECT fx = screen.materials.deferred->d3deffect;
		fx->SetFloat("clipFar", screen.views.main.clip_far);
		fx->SetTexture("texAlbedoAndEmissiveMask", (LPDIRECT3DTEXTURE9*)(screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK].d3dtex));
		fx->SetTexture("texNormalsAndDepth", (LPDIRECT3DTEXTURE9*)(screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH].d3dtex));
		fx->SetTexture("texMaterialData", (LPDIRECT3DTEXTURE9*)(screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA].d3dtex));
		fx->SetTexture("texDiffuseAndSpecular", (LPDIRECT3DTEXTURE9*)(screen.renderTargets.deferredLighting.d3dtex));
		
		//FOG
		screen.materials.deferred.skin1 = screen.settings.fogNoise;
		D3DXVECTOR4 heightFog;
		//heightFog.x = screen.views.main.clip_near + screen.settings.fogData.x;
		//heightFog.y = screen.views.main.clip_near + screen.settings.fogData.y;
		heightFog.x = screen.settings.fogData.y;//screen.settings.heightFog.x;
		heightFog.y = (float)(1) / (screen.settings.fogData.y - screen.settings.fogData.x);//screen.settings.fogData.y;
		//heightFog.z = (float)(1) / (screen.settings.fogData.y - screen.settings.fogData.x);
		
		//enable disable noise texture
		if(screen.settings.fogNoise == NULL)
			heightFog.z = 0;
		else
			heightFog.z = 1;
		
		//enable disable fog
		if(fog_color == 0)
			heightFog.w = 0;
		else
			heightFog.w = 1;
		fx->SetVector("vecFogHeight", heightFog);
		
		D3DXVECTOR4 fogData;
		fogData.x = screen.settings.fogNoiseScale*100;
		fogData.y = screen.settings.fogData.z/1000;
		fogData.z = screen.settings.fogData.w/1000;
		fx->SetVector("fogData", fogData);
		
		
	}
}