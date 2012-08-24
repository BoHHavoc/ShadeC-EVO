
void sc_ssao_MaterialEvent()
{
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL);
	switch(render_view)
	{
		
		case screen.views.ssao:
		//	screen.views.preSSAO.bmap = screen.renderTargets.full0;
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
			if(pEffect != NULL)
			{
				pEffect->SetVectorArray("SAMPLE_KERNEL", screen.ssaoKernel, sc_ssao_kernelSize);
				pEffect->SetFloat("SAMPLE_KERNEL_SIZE", sc_ssao_kernelSize);
			}
			break;
			
		case screen.views.ssaoBlurX:
			screen.views.ssao.bmap = screen.renderTargets.half0;
			break;
			
		case screen.views.ssaoBlurY:
			screen.views.ssaoBlurX.bmap = screen.renderTargets.half1;
			break;
		
		case screen.views.ssaoFinalize:
			screen.views.ssao.bmap = screen.renderTargets.half0;
			//screen.views.ssaoBlurY.bmap = screen.renderTargets.half0;
			break;
		
		default:
			break;
	}
	//if(render_view == screen.views.dofDownsample) screen.views.deferred.bmap = screen.renderTargets.full0;
	//else screen.views.deferred.bmap = NULL;
}


void sc_ssao_generateSampleKernel(SC_SCREEN* screen)
{
	int kernel_size = sc_ssao_kernelSize;
	int i = 0;
	for (i = 0; i < kernel_size; ++i) {
		D3DXVec4Set(&(screen.ssaoKernel[i]), (float)(random(2)-1), (float)(random(2)-1), (float)random(1), 0);
		D3DXVec4Normalize(&(screen.ssaoKernel[i]), &(screen.ssaoKernel[i]));
		D3DXVec4Scale(&(screen.ssaoKernel[i]), &(screen.ssaoKernel[i]), (float)random(1));
		
		//non-linear placement
		float scale = (float)i / (float)kernel_size;
		//scale = lerp(0.1, 1.0, scale * scale);
		//scale -= (0.1 - 1.0) * (scale*scale); //wrong code
		VECTOR* scaleVec = vector(scale, scale,scale);
		vec_lerp(scaleVec, vector(0.1,0.1,0.1), vector(1,1,1), scale*scale);
		scale = scaleVec.x;
		D3DXVec4Scale(&(screen.ssaoKernel[i]), &(screen.ssaoKernel[i]), scale);
	}
}

void sc_ssao_generateNoiseTexture(SC_SCREEN* screen)
{
	int noise_size = 4; //generate a 4x4 texture
	screen.ssaoNoise = bmap_createblack(noise_size, noise_size, 32);
	int i,j = 0;
	for (i = 0; i < noise_size; ++i) {
		for(j = 0; j < noise_size; ++j) {
		VECTOR* noise = vector(random(2)-1, random(2)-1, 0); //create random noise
		vec_normalize(noise, 1); //normalize
		vec_scale(noise, 255); //put to rgb range
		
		//write to bmap
		var pixel = pixel_for_vec(noise,1,bmap_lock(screen.ssaoNoise,0));
		pixel_to_bmap(screen.ssaoNoise,i,j,pixel);
		bmap_unlock(screen.ssaoNoise);
			
		}
	}
}

void sc_ssao_init(SC_SCREEN* screen)
{
	//create maps
	if(screen.renderTargets.ssao == NULL) screen.renderTargets.ssao = bmap_createblack(screen.views.main.size_x, screen.views.main.size_y, 32);
	
	//generate sample kernel
	sc_ssao_generateSampleKernel(screen);
	
	//generate noise texture
	sc_ssao_generateNoiseTexture(screen);
	
	//create materials
		//ssao finalize
		screen.materials.ssaoFinalize = mtl_create();
		effect_load(screen.materials.ssaoFinalize, sc_ssao_sMaterialFinalize);
		screen.materials.ssaoFinalize.skin1 = screen.renderTargets.half0;// this contains the (blurred) ssao
		screen.materials.ssaoFinalize.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.ssaoFinalize.event = sc_ssao_MaterialEvent;
		screen.materials.ssaoFinalize.SC_SKILL = screen;
		set(screen.materials.ssaoFinalize, ENABLE_VIEW);
		/*
		//blur y
		screen.materials.ssaoBlurY = mtl_create();
		effect_load(screen.materials.ssaoBlurY, sc_ssao_sMaterialBlurY);
		screen.materials.ssaoBlurY.skin1 = screen.renderTargets.half1;// this contains the x blurred ssao
		screen.materials.ssaoBlurY.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.ssaoBlurY.event = sc_ssao_MaterialEvent;
		screen.materials.ssaoBlurY.SC_SKILL = screen;
		set(screen.materials.ssaoBlurY, ENABLE_VIEW);
			
		//blur x
		screen.materials.ssaoBlurX = mtl_create();
		effect_load(screen.materials.ssaoBlurX, sc_ssao_sMaterialBlurX);
		screen.materials.ssaoBlurX.skin1 = screen.renderTargets.half0;// this contains the unblurred ssao
		screen.materials.ssaoBlurX.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.ssaoBlurX.event = sc_ssao_MaterialEvent;
		screen.materials.ssaoBlurX.SC_SKILL = screen;
		set(screen.materials.ssaoBlurX, ENABLE_VIEW);
		*/
		//ssao
		screen.materials.ssao = mtl_create();
		effect_load(screen.materials.ssao, sc_ssao_sMaterialSSAOLow);
		screen.materials.ssao.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH];
		screen.materials.ssao.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK];
		screen.materials.ssao.skin3 = screen.renderTargets.deferredLighting;
		screen.materials.ssao.skin4 = screen.ssaoNoise;//sc_ssao_texNoise;
		screen.materials.ssao.event = sc_ssao_MaterialEvent;
		screen.materials.ssao.SC_SKILL = screen;
		set(screen.materials.ssao, ENABLE_VIEW);
	
	
	//setup views
		//ssao finalize
		screen.views.ssaoFinalize = view_create(2);
		set(screen.views.ssaoFinalize, PROCESS_TARGET);
		set(screen.views.ssaoFinalize, UNTOUCHABLE);
		set(screen.views.ssaoFinalize, NOSHADOW);
		reset(screen.views.ssaoFinalize, AUDIBLE);
		set(screen.views.ssaoFinalize, CHILD);
		screen.views.ssaoFinalize.size_x = screen.views.main.size_x;
		screen.views.ssaoFinalize.size_y = screen.views.main.size_y;
		screen.views.ssaoFinalize.material = screen.materials.ssaoFinalize;
		screen.views.ssaoFinalize.bmap = screen.renderTargets.ssao;
		/*
		//blur y
		screen.views.ssaoBlurY = view_create(2);
		set(screen.views.ssaoBlurY, PROCESS_TARGET);
		set(screen.views.ssaoBlurY, UNTOUCHABLE);
		set(screen.views.ssaoBlurY, NOSHADOW);
		reset(screen.views.ssaoBlurY, AUDIBLE);
		set(screen.views.ssaoBlurY, CHILD);
		screen.views.ssaoBlurY.size_x = screen.views.main.size_x/2;
		screen.views.ssaoBlurY.size_y = screen.views.main.size_y/2;
		screen.views.ssaoBlurY.material = screen.materials.ssaoBlurY;
		screen.views.ssaoBlurY.stage = screen.views.ssaoFinalize;
		screen.views.ssaoBlurY.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		//blur x
		screen.views.ssaoBlurX = view_create(2);
		set(screen.views.ssaoBlurX, PROCESS_TARGET);
		set(screen.views.ssaoBlurX, UNTOUCHABLE);
		set(screen.views.ssaoBlurX, NOSHADOW);
		reset(screen.views.ssaoBlurX, AUDIBLE);
		set(screen.views.ssaoBlurX, CHILD);
		screen.views.ssaoBlurX.size_x = screen.views.main.size_x/2;
		screen.views.ssaoBlurX.size_y = screen.views.main.size_y/2;
		screen.views.ssaoBlurX.material = screen.materials.ssaoBlurX;
		screen.views.ssaoBlurX.stage = screen.views.ssaoBlurY;
		screen.views.ssaoBlurX.bmap = screen.renderTargets.quarter0;  //assign temp render target so Acknex does not automatically create a new one
		*/
		//ssao
		screen.views.ssao = view_create(2);
		set(screen.views.ssao, PROCESS_TARGET);
		set(screen.views.ssao, UNTOUCHABLE);
		set(screen.views.ssao, NOSHADOW);
		reset(screen.views.ssao, AUDIBLE);
		set(screen.views.ssao, CHILD);
		screen.views.ssao.size_x = screen.views.main.size_x/2;
		screen.views.ssao.size_y = screen.views.main.size_y/2;
		screen.views.ssao.material = screen.materials.ssao;
		//screen.views.ssao.stage = screen.views.ssaoBlurX;
		screen.views.ssao.stage = screen.views.ssaoFinalize;
		screen.views.ssao.bmap = screen.renderTargets.quarter0;  //assign temp render target so Acknex does not automatically create a new one
		
		
		
	//apply to camera
	VIEW* view_last;
	view_last = screen.views.gBuffer;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.ssao;
	screen.views.preSSAO = view_last;
	
}

void sc_ssao_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.ssao != NULL)
	{
		if(is(screen.views.ssao,NOSHADOW))
		{
			
			reset(screen.views.ssao,NOSHADOW);
			//purge render targets
			if(screen.renderTargets.ssao) bmap_purge(screen.renderTargets.ssao);
			screen.views.ssaoFinalize.bmap = NULL;
						
			//remove from view chain
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.ssao)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.ssaoFinalize.stage) view_last.stage = screen.views.ssaoFinalize.stage;
			else view_last.stage = NULL;
			
			//if(screen.views.ssaoFinalize.bmap) view_last.bmap = screen.sc_dof_mapOrgScene;
			//else view_last.bmap = NULL;
		}
	}
	return 1;
}

void sc_ssao_frm(SC_SCREEN* screen)
{
	if(screen.views.ssao != NULL)
	{
		/*
		screen.materials.ssao.skill1 = floatv(280); //intensity
		screen.materials.ssao.skill2 = floatv(16); //ssao radius
		screen.materials.ssao.skill3 = floatv(0.99); //distance
		screen.materials.ssao.skill4 = floatv(0.5); //bias
		*/
		
		screen.materials.ssao.skill1 = floatv(screen.settings.ssao.intensity); //intensity
		screen.materials.ssao.skill2 = floatv(screen.settings.ssao.radius); //ssao radius
		screen.materials.ssao.skill3 = floatv(screen.settings.ssao.selfOcclusion); //anti self occlusion
		
		//pass frustum far plane points to shader
		screen.materials.ssao.skill5 = floatv(screen.frustumPoints.x);
		screen.materials.ssao.skill6 = floatv(screen.frustumPoints.y);
		screen.materials.ssao.skill7 = floatv(screen.frustumPoints.z);
		screen.materials.ssao.skill8 = floatv(screen.frustumPoints.w);
		
		//pass clip far to shader
		screen.materials.ssao.skill9 = floatv(screen.views.main.clip_far);
	}
}