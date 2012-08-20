void sc_hdr_MaterialEventHDR()
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
		case screen.views.hdr:
			screen.views.preHDR.bmap = screen.renderTargets.full0;
			break;
			
		case screen.views.hdrDownsample:
			screen.views.preHDR.bmap = screen.renderTargets.full0;
			screen.views.hdrDownsample.bmap = screen.renderTargets.quarter0;
			break;
			
		case screen.views.hdrBlurX:
			screen.views.hdrBlurX.bmap = screen.renderTargets.quarter1;
			break;
		
		case screen.views.hdrBlurY:
			screen.views.hdrBlurY.bmap = screen.renderTargets.quarter0;
			break;
		
		case screen.views.hdrLensflareDownsample:
			screen.views.hdrLensflareDownsample.bmap = screen.renderTargets.eighth0;
			break;
		
		case screen.views.hdrLensflare:
			screen.views.hdrLensflare.bmap = screen.renderTargets.eighth1;
			break;
			
		case screen.views.hdrLensflareBlur:
			screen.views.hdrLensflareBlur.bmap = screen.renderTargets.eighth0;
			break;
			
		case screen.views.hdrLensflareUpsample:
			screen.views.hdrLensflareUpsample.bmap = screen.renderTargets.quarter1;
			break;
		
		default:
			break;
	}
	//if(render_view == screen.views.hdrDownsample) screen.views.deferred.bmap = screen.renderTargets.full0;
	//else screen.views.deferred.bmap = NULL;
}

void sc_hdr_init(SC_SCREEN* screen)
{
	//create materials
	
		//hdr
		screen.materials.hdr = mtl_create();
		effect_load(screen.materials.hdr, sc_hdr_sMaterialHDR);
		screen.materials.hdr.skin1 = screen.renderTargets.full0;// this contains the current scene without hdr
		if(screen.settings.hdr.lensflare.enabled == 1) screen.materials.hdr.skin2 = screen.renderTargets.quarter1;// this contains the bloom and lensflare
		else screen.materials.hdr.skin2 = screen.renderTargets.quarter0;// this contains the bloom
		screen.materials.hdr.skill1 = floatv(0.25); // inverted downsample factor
		
		//lensflare activated?
		if(screen.settings.hdr.lensflare.enabled == 1)
		{
			//lensflare upsample
			screen.materials.hdrLensflareUpsample = mtl_create();
			effect_load(screen.materials.hdrLensflareUpsample, sc_hdr_sMaterialHDRLensflareUpsample);
			screen.materials.hdrLensflareUpsample.skin1 = screen.renderTargets.eighth0;// this contains the blurred lensflare
			screen.materials.hdrLensflareUpsample.skin2 = screen.renderTargets.quarter0;// this contains the bloom
			screen.materials.hdrLensflareUpsample.skin3 = sc_hdr_mapLensdirt01;
			screen.materials.hdrLensflareUpsample.skin4 = sc_hdr_mapLensdirt02;
			screen.materials.hdrLensflareUpsample.skill1 = floatv(0.5); //upsample factor
			
			//lensflare blur
			screen.materials.hdrLensflareBlur = mtl_create();
			effect_load(screen.materials.hdrLensflareBlur, sc_hdr_sMaterialHDRLensflareBlur);
			screen.materials.hdrLensflareBlur.skin1 = screen.renderTargets.eighth1;// this contains the lensflare
			screen.materials.hdrLensflareBlur.skill1 = floatv(0.022); //blur strength
			
			//lensflare pass 1
			screen.materials.hdrLensflare = mtl_create();
			effect_load(screen.materials.hdrLensflare, sc_hdr_sMaterialHDRLensflare);
			screen.materials.hdrLensflare.skin1 = screen.renderTargets.eighth0;// this contains the downsampled lensflare data
			//screen.materials.hdrLensflare1.skill1 = floatv(16); //blur strength
			
			//lensflare downsample
			screen.materials.hdrLensflareDownsample = mtl_create();
			effect_load(screen.materials.hdrLensflareDownsample, sc_hdr_sMaterialHDRLensflareDownsample);
			screen.materials.hdrLensflareDownsample.skin1 = screen.renderTargets.quarter0;// this contains the bloom
			screen.materials.hdrLensflareDownsample.skill1 = floatv(2); //downsample factor
		}
		
		//blur y
		screen.materials.hdrBlurY = mtl_create();
		effect_load(screen.materials.hdrBlurY, sc_hdr_sMaterialHDRBlurY);
		screen.materials.hdrBlurY.skin1 = screen.renderTargets.quarter1;// this contains the x blurred bloom
		screen.materials.hdrBlurY.skill1 = floatv(screen.settings.hdr.blurY); //blur strength
			
		//blur x
		screen.materials.hdrBlurX = mtl_create();
		effect_load(screen.materials.hdrBlurX, sc_hdr_sMaterialHDRBlurX);
		screen.materials.hdrBlurX.skin1 = screen.renderTargets.quarter0;// this contains the brightpass
		screen.materials.hdrBlurX.skill1 = floatv(screen.settings.hdr.blurX); //blur strength
		
		//downsample and highpass
		screen.materials.hdrDownsample = mtl_create();
		effect_load(screen.materials.hdrDownsample, sc_hdr_sMaterialHDRDownsample);
		screen.materials.hdrDownsample.skin1 = screen.renderTargets.full0;// this contains the current scene without hdr
		screen.materials.hdrDownsample.skin2 = screen.renderTargets.gBuffer[SC_GBUFFER_ALBEDO_AND_EMISSIVE_MASK];
		screen.materials.hdrDownsample.skill1 = floatv(4); //downsample factor
		screen.materials.hdrDownsample.skill2 = floatv(screen.settings.hdr.brightpass); //brightpass threshold
		screen.materials.hdrDownsample.skill3 = floatv(screen.settings.hdr.intensity); //brightpass rescale/strength
		
		

			
	
	//setup views
	
		//hdr
		screen.views.hdr = view_create(2);
		set(screen.views.hdr, PROCESS_TARGET);
		set(screen.views.hdr, UNTOUCHABLE);
		set(screen.views.hdr, NOSHADOW);
		reset(screen.views.hdr, AUDIBLE);
		set(screen.views.hdr, CHILD);
		screen.views.hdr.size_x = screen.views.main.size_x;
		screen.views.hdr.size_y = screen.views.main.size_y;
		screen.materials.hdr.event = sc_hdr_MaterialEventHDR;
		screen.materials.hdr.SC_SKILL = screen;
		set(screen.materials.hdr, ENABLE_VIEW);
		screen.views.hdr.material = screen.materials.hdr;
		//screen.views.hdr.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		if(screen.settings.hdr.lensflare.enabled == 1)
		{
			//lensflare upsample
			screen.views.hdrLensflareUpsample = view_create(2);
			set(screen.views.hdrLensflareUpsample, PROCESS_TARGET);
			set(screen.views.hdrLensflareUpsample, UNTOUCHABLE);
			set(screen.views.hdrLensflareUpsample, NOSHADOW);
			set(screen.views.hdrLensflareUpsample, NOPARTICLE);
			reset(screen.views.hdrLensflareUpsample, AUDIBLE);
			set(screen.views.hdrLensflareUpsample, CHILD);
			screen.views.hdrLensflareUpsample.size_x = screen.views.main.size_x/4;
			screen.views.hdrLensflareUpsample.size_y = screen.views.main.size_y/4;
			screen.materials.hdrLensflareUpsample.event = sc_hdr_MaterialEventHDR;
			screen.materials.hdrLensflareUpsample.SC_SKILL = screen;
			set(screen.materials.hdrLensflareUpsample, ENABLE_VIEW);
			screen.views.hdrLensflareUpsample.material = screen.materials.hdrLensflareUpsample;
			screen.views.hdrLensflareUpsample.stage = screen.views.hdr;
			screen.views.hdrLensflareUpsample.bmap = screen.renderTargets.quarter1; //assign temp render target so Acknex does not automatically create a new one
			
			//lensflare2
			screen.views.hdrLensflareBlur = view_create(2);
			set(screen.views.hdrLensflareBlur, PROCESS_TARGET);
			set(screen.views.hdrLensflareBlur, UNTOUCHABLE);
			set(screen.views.hdrLensflareBlur, NOSHADOW);
			set(screen.views.hdrLensflareBlur, NOPARTICLE);
			reset(screen.views.hdrLensflareBlur, AUDIBLE);
			set(screen.views.hdrLensflareBlur, CHILD);
			screen.views.hdrLensflareBlur.size_x = screen.views.main.size_x/8;
			screen.views.hdrLensflareBlur.size_y = screen.views.main.size_y/8;
			screen.materials.hdrLensflareBlur.event = sc_hdr_MaterialEventHDR;
			screen.materials.hdrLensflareBlur.SC_SKILL = screen;
			set(screen.materials.hdrLensflareBlur, ENABLE_VIEW);
			screen.views.hdrLensflareBlur.material = screen.materials.hdrLensflareBlur;
			screen.views.hdrLensflareBlur.stage = screen.views.hdrLensflareUpsample;
			screen.views.hdrLensflareBlur.bmap = screen.renderTargets.eighth0; //assign temp render target so Acknex does not automatically create a new one
			
			//lensflare1
			screen.views.hdrLensflare = view_create(2);
			set(screen.views.hdrLensflare, PROCESS_TARGET);
			set(screen.views.hdrLensflare, UNTOUCHABLE);
			set(screen.views.hdrLensflare, NOSHADOW);
			set(screen.views.hdrLensflare, NOPARTICLE);
			reset(screen.views.hdrLensflare, AUDIBLE);
			set(screen.views.hdrLensflare, CHILD);
			screen.views.hdrLensflare.size_x = screen.views.main.size_x/8;
			screen.views.hdrLensflare.size_y = screen.views.main.size_y/8;
			screen.materials.hdrLensflare.event = sc_hdr_MaterialEventHDR;
			screen.materials.hdrLensflare.SC_SKILL = screen;
			set(screen.materials.hdrLensflare, ENABLE_VIEW);
			screen.views.hdrLensflare.material = screen.materials.hdrLensflare;
			screen.views.hdrLensflare.stage = screen.views.hdrLensflareBlur;
			screen.views.hdrLensflare.bmap = screen.renderTargets.eighth1; //assign temp render target so Acknex does not automatically create a new one
			
			//lensflare downsample
			screen.views.hdrLensflareDownsample = view_create(2);
			set(screen.views.hdrLensflareDownsample, PROCESS_TARGET);
			set(screen.views.hdrLensflareDownsample, UNTOUCHABLE);
			set(screen.views.hdrLensflareDownsample, NOSHADOW);
			set(screen.views.hdrLensflareDownsample, NOPARTICLE);
			reset(screen.views.hdrLensflareDownsample, AUDIBLE);
			set(screen.views.hdrLensflareDownsample, CHILD);
			screen.views.hdrLensflareDownsample.size_x = screen.views.main.size_x/8;
			screen.views.hdrLensflareDownsample.size_y = screen.views.main.size_y/8;
			screen.materials.hdrLensflareDownsample.event = sc_hdr_MaterialEventHDR;
			screen.materials.hdrLensflareDownsample.SC_SKILL = screen;
			set(screen.materials.hdrLensflareDownsample, ENABLE_VIEW);
			screen.views.hdrLensflareDownsample.material = screen.materials.hdrLensflareDownsample;
			screen.views.hdrLensflareDownsample.stage = screen.views.hdrLensflare;
			screen.views.hdrLensflareDownsample.bmap = screen.renderTargets.eighth0; //assign temp render target so Acknex does not automatically create a new one
		}
		
		//blur y
		screen.views.hdrBlurY = view_create(2);
		set(screen.views.hdrBlurY, PROCESS_TARGET);
		set(screen.views.hdrBlurY, UNTOUCHABLE);
		set(screen.views.hdrBlurY, NOSHADOW);
		set(screen.views.hdrBlurY, NOPARTICLE);
		reset(screen.views.hdrBlurY, AUDIBLE);
		set(screen.views.hdrBlurY, CHILD);
		screen.views.hdrBlurY.size_x = screen.views.main.size_x/4;
		screen.views.hdrBlurY.size_y = screen.views.main.size_y/4;
		screen.materials.hdrBlurY.event = sc_hdr_MaterialEventHDR;
		screen.materials.hdrBlurY.SC_SKILL = screen;
		set(screen.materials.hdrBlurY, ENABLE_VIEW);
		screen.views.hdrBlurY.material = screen.materials.hdrBlurY;
		if(screen.settings.hdr.lensflare.enabled == 1) {
			screen.views.hdrBlurY.stage = screen.views.hdrLensflareDownsample;
		}
		else {
			screen.views.hdrBlurY.stage = screen.views.hdr;
		}
		screen.views.hdrBlurY.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		//blur x
		screen.views.hdrBlurX = view_create(2);
		set(screen.views.hdrBlurX, PROCESS_TARGET);
		set(screen.views.hdrBlurX, UNTOUCHABLE);
		set(screen.views.hdrBlurX, NOSHADOW);
		reset(screen.views.hdrBlurX, AUDIBLE);
		set(screen.views.hdrBlurX, CHILD);
		screen.views.hdrBlurX.size_x = screen.views.main.size_x/4;
		screen.views.hdrBlurX.size_y = screen.views.main.size_y/4;
		screen.materials.hdrBlurX.event = sc_hdr_MaterialEventHDR;
		screen.materials.hdrBlurX.SC_SKILL = screen;
		set(screen.materials.hdrBlurX, ENABLE_VIEW);
		screen.views.hdrBlurX.material = screen.materials.hdrBlurX;
		screen.views.hdrBlurX.stage = screen.views.hdrBlurY;
		screen.views.hdrBlurX.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		//downsample and highpass
		screen.views.hdrDownsample = view_create(2);
		set(screen.views.hdrDownsample, PROCESS_TARGET);
		set(screen.views.hdrDownsample, UNTOUCHABLE);
		set(screen.views.hdrDownsample, NOSHADOW);
		reset(screen.views.hdrDownsample, AUDIBLE);
		set(screen.views.hdrDownsample, CHILD);
		screen.views.hdrDownsample.size_x = screen.views.main.size_x/4;
		screen.views.hdrDownsample.size_y = screen.views.main.size_y/4;
		screen.materials.hdrDownsample.event = sc_hdr_MaterialEventHDR;
		screen.materials.hdrDownsample.SC_SKILL = screen;
		set(screen.materials.hdrDownsample, ENABLE_VIEW);
		screen.views.hdrDownsample.material = screen.materials.hdrDownsample;
		screen.views.hdrDownsample.stage = screen.views.hdrBlurX;
		screen.views.hdrDownsample.bmap = screen.renderTargets.quarter0; //assign temp render target so Acknex does not automatically create a new one
		
		
		
	//apply to camera
	VIEW* view_last;
	view_last = screen.views.main;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.hdrDownsample;
	screen.views.preHDR = view_last;
}

void sc_hdr_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.hdr != NULL)
	{
		if(is(screen.views.hdr,NOSHADOW))
		{
			
			reset(screen.views.hdr,NOSHADOW);
			//purge render targets
			//bmap_purge(screen.views.deferred.bmap);
			//screen.views.deferred.bmap = NULL;
						
			//remove from view chain
			VIEW* view_last;
			view_last = screen.views.main;
			while(view_last.stage != screen.views.hdrDownsample)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.hdr.stage) view_last.stage = screen.views.hdr.stage;
			else view_last.stage = NULL;
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_hdr_mapOrgScene;
			//else view_last.bmap = NULL;
		}
	}
	return 1;
}

void sc_hdr_frm(SC_SCREEN* screen)
{
	if(screen.views.hdr != NULL)
	{
		screen.materials.hdrBlurY.skill1 = floatv(screen.settings.hdr.blurY); //blur strength
		screen.materials.hdrBlurX.skill1 = floatv(screen.settings.hdr.blurX); //blur strength
		screen.materials.hdrDownsample.skill2 = floatv(screen.settings.hdr.brightpass); //brightpass threshold
		screen.materials.hdrDownsample.skill3 = floatv(screen.settings.hdr.intensity); //brightpass rescale/strength
		
		if(screen.views.hdrLensflare != NULL)
		{
			screen.materials.hdrLensflareDownsample.skill2 = floatv(screen.settings.hdr.lensflare.brightpass); //lensflare brightpass threshold
			screen.materials.hdrLensflareDownsample.skill3 = floatv(screen.settings.hdr.lensflare.intensity); //lensflare rescale/strength
		}
	}
}