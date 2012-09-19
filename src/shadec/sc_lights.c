//----------------------------------------------------------------------------------------------------------------------------------//
// LOCAL LIGHTS																																										//
//----------------------------------------------------------------------------------------------------------------------------------//

// Light handling functions

void sc_light_updatePointMtx(ENTITY* inLight)
{
	//static D3DXMATRIX testmtx;
	D3DXMATRIX testmtx;
	//testmtx = sys_malloc(sizeof(D3DXMATRIX));
	D3DXMatrixRotationYawPitchRoll( testmtx, inLight.pan/360, inLight.tilt/360, inLight.roll/360 );
	sc_skill(inLight, SC_OBJECT_LIGHT_MATRIX, testmtx);
	//sys_free(testmtx);
}

void sc_light_updateSpotMtx(ENTITY* inLight)
{
	SC_OBJECT* ObjData = (SC_OBJECT*)(inLight.SC_SKILL);
	
	
	float fTexAdj[16] =
		{ 0.5, 0.0, 0.0, 0.0,
		  0.0,-0.5,	0.0, 0.0,
		  0.0, 0.0, 1.0, 0.0,
		  0.0, 0.0, 0.0, 1.0 };
		  
	fTexAdj[12] = 0.5 + ((float)0.5/(float)256);
	fTexAdj[13] = 0.5 + ((float)0.5/(float)256);
	
	
	VECTOR lightDir;

	//lightDir = malloc(sizeof(VECTOR));
	if(inLight.tilt > 89.9 && inLight.tilt < 90.1 || inLight.tilt < -89.9 && inLight.tilt > -90.1)
	{
		vec_set(lightDir, inLight.pan);
		lightDir.y += 0.2;
		vec_for_angle(lightDir,lightDir);
	}
	else vec_for_angle(lightDir, inLight.pan);
	
	sc_skill(inLight, SC_OBJECT_LIGHT_DIR, lightDir);
	//if(lightDir.y == -90) lightDir.y = 80; //might have to comment this in again (?)
	
	/*
	//if spotlight has a shadowview attached
	if(ObjData.light.view != NULL)
	{
		D3DXMATRIX matView_, matProj_;
		view_to_matrix(ObjData.light.view, &matView_, &matProj_);
		mat_multiply(&matView_, &matProj_);
		mat_multiply(&matView_, fTexAdj);
		sc_skill(inLight, SC_OBJECT_LIGHT_MATRIX, &matView_);
		
		ptr_remove(matView_);
		ptr_remove(matProj_);
		return;
	}
	*/
	
	
	//create lightViewMatrix
	D3DXVECTOR3 vEyePt;
	D3DXVECTOR3 vLookatPt;
	D3DXVECTOR3 vUpVec;
	//vEyePt = sys_malloc(sizeof(D3DXVECTOR3));
	//vLookatPt = sys_malloc(sizeof(D3DXVECTOR3));
	//vUpVec = sys_malloc(sizeof(D3DXVECTOR3));
	
	vEyePt.x = inLight.x;
	vEyePt.y = inLight.z;
	vEyePt.z = inLight.y;
	vLookatPt.x = inLight.x + lightDir.x;	
	vLookatPt.y = inLight.z + lightDir.z;
	vLookatPt.z = inLight.y + lightDir.y;
	vUpVec.x = 0;
	vUpVec.y = 1;
	vUpVec.z = 0;

	D3DXMATRIX mtxLightView;
	//mtxLightView = sys_malloc(sizeof(D3DXMATRIX));
	D3DXMatrixLookAtLH( &mtxLightView, vEyePt, vLookatPt, vUpVec);
	
	//create lightProjectionMatrix
	D3DXMATRIX mtxLightProj;
	D3DXMatrixPerspectiveFovLH(&mtxLightProj, 	(((float)ObjData.light.arc/(float)180))*SC_PI, (float)1, (float)1, (float)ObjData.light.range );
		
	
	//pass projection matrix to light	
	D3DXMATRIX mtxLightWorldViewProj;
	//mtxLightWorldViewProj = sys_malloc(sizeof(D3DXMATRIX));
	mat_set(&mtxLightWorldViewProj, &mtxLightView);
	mat_multiply(&mtxLightWorldViewProj, &mtxLightProj);
	mat_multiply(&mtxLightWorldViewProj, fTexAdj);
	
	sc_skill(inLight, SC_OBJECT_LIGHT_MATRIX, &mtxLightWorldViewProj);
	
	/*
	//this lags like hell
	sys_free(vEyePt);
	sys_free(vLookatPt);
	sys_free(vUpVec);
	sys_free(mtxLightView);
	sys_free(mtxLightProj);
	sys_free(mtxLightWorldViewProj);
	*/
	
	//better
	ptr_remove(vEyePt);
	ptr_remove(vLookatPt);
	ptr_remove(vUpVec);
	ptr_remove(mtxLightView);
	ptr_remove(mtxLightProj);
	ptr_remove(mtxLightWorldViewProj);
}


void sc_light_setRange(ENTITY* inLight, var inRange)
{
	set(inLight, PASSABLE);
	inLight.scale_x = 1;
	inLight.scale_y = 1;
	inLight.scale_z = 1;
	vec_scale(inLight.scale_x, inRange*2);
	sc_skill(inLight, SC_OBJECT_LIGHT_RANGE, inRange);
	
	
	SC_OBJECT* ObjData = (SC_OBJECT*)(inLight.SC_SKILL);
	if(ObjData.light.view != NULL)
	{
		ObjData.light.view.clip_far = inRange;
	}
}

void sc_light_setColor(ENTITY* inLight, VECTOR* inColor)
{
	sc_skill(inLight, SC_OBJECT_LIGHT_COLOR, inColor);
}

void sc_light_setArc(ENTITY* inLight, var inArc)
{
	sc_skill(inLight, SC_OBJECT_LIGHT_ARC, inArc );
	sc_light_updateSpotMtx(inLight);
}

void sc_light_setProjTex(ENTITY* inLight, BMAP* inTex)
{
	if(inTex != NULL) sc_skill(inLight, SC_OBJECT_LIGHT_PROJMAP, inTex);
	else sc_skill(inLight, SC_OBJECT_LIGHT_PROJMAP, sc_lights_map_defaultProjTex);
}



/*
void sc_light_updateSpotDir(ENTITY* inLight)
{
	VECTOR lightDir;
	vec_for_angle(lightDir, inLight.pan);
	sc_skill(inLight, SC_MYLIGHTDIR, lightDir);
}
*/


void sc_light_checkSpotFrustum()
{
	wait(3);
	
	ENTITY* inLight = my;
	//ent_create(CUBE_MDL, inLight.x, NULL);
	//ent_create(CUBE_MDL, nullvector, NULL);
	SC_OBJECT* ObjData = (SC_OBJECT*)(inLight.SC_SKILL);
	
	
	
	SC_SCREEN* screen;
	//HAVOC : CHANGE THIS (sc_screen_default)
	while(sc_screen_default == NULL) wait(1);
	SC_SCREEN* screen = sc_screen_default;
	VIEW* playerView = screen.views.main;
	//
	
	while(inLight)
	{
		
		#ifdef SC_USEPVS
		//check if light has been clipped by engine or main view is far away from light
		if( (inLight.eflags&CLIPPED) || abs(vec_dist(playerView.x, inLight.x)) > ObjData.light.clipRange + ObjData.light.range )
		{
			reset(ObjData.light.view, SHOW);
			//ObjData.myLightMtl = sc_lpp_mtlS;
		}
		else
		{
			set(ObjData.light.view,SHOW);
			/*
			//lightview intersects with camera? OBB-OBB check
			if( sc_physics_intersectViewView(playerView, ObjData.light.view) )
			{
				set(ObjData.light.view, SHOW);
				
				
//				//lightview intersects with camera? cone-sphere check
//				if( sc_physics_intersectViewSphere(screen.views.main, inLight.x, ObjData.light.range) )
//				{
//					//sc_light_setColor(inLight, vector(255, 0,0) );
//					reset(ObjData.light.view, SHOW);
//				}
//				else
//				{
//					//sc_light_setColor(inLight, vector(0, 255,0) );
//					set(ObjData.light.view, SHOW);
//				}
				
				
				
			}
			else
			{
				//sc_light_setColor(inLight, vector(255, 0,0) );
				reset(ObjData.light.view, SHOW);
			}
			*/
		}
		
		#else
		
		//check if light has been clipped by engine or playerView is far away from light
		if( (inLight.eflags&CLIPPED) || abs(vec_dist(playerView.x, inLight.x)) > ObjData.light.clipRange + ObjData.light.range )
		{
			reset(ObjData.light.view, SHOW);
		}
		else
		{
			//lightview intersects with camera? OBB-OBB check | or main view is far away from light
			if( sc_physics_intersectViewView(playerView, ObjData.light.view) && vec_dist(playerView.x, inLight.x) < ObjData.light.clipRange + ObjData.light.range )
			{
				set(ObjData.light.view, SHOW);
				
				/*
				//lightview intersects with camera? cone-sphere check
				if( sc_physics_intersectViewSphere(screen.views.main, inLight.x, ObjData.light.range) )
				{
					//sc_light_setColor(inLight, vector(255, 0,0) );
					reset(ObjData.light.view, SHOW);
				}
				else
				{
					//sc_light_setColor(inLight, vector(0, 255,0) );
					set(ObjData.light.view, SHOW);
				}
				*/
				
			}
			else
			{
				//sc_light_setColor(inLight, vector(255, 0,0) );
				reset(ObjData.light.view, SHOW);
			}
		}
		#endif
		
		wait(10);
	}
}

ENTITY* sc_light_createFunc(int inType, var inRange, VECTOR* inColor, VECTOR* inPos, VECTOR* inDir, BMAP* inProjMap, var inSpotArc)
{
	ENTITY* ent;
	
	//correct inDir
	//vec_set(inDir, vector(inDir.y, inDir.x, inDir.z));
	//correct inSpot
	//if(inSpot.y > inSpot.x) inSpot.y = inSpot.x - 1;
		
	//create light model
	//pointlight
	//if(inType == SC_LIGHT_P || inType == SC_LIGHT_PS || inType == SC_LIGHT_PSC || inType == SC_LIGHT_PSCA || inType == SC_LIGHT_PC || inType == SC_LIGHT_PCA)
	//	ent = ent_createlocal("sc_pl.mdl", inPos, sc_light_ent);
	//spotlight
	//if(inType == SC_LIGHT_S || inType == SC_LIGHT_SS)
	
	if(inType == SC_LIGHT_S_SPEC_SHADOW
			|| inType == SC_LIGHT_S_SHADOW)
		ent = ent_createlocal(sc_lights_mdlPointLight, inPos, sc_light_checkSpotFrustum);
	else
		ent = ent_createlocal(sc_lights_mdlPointLight, inPos, NULL); //local light
	
	set(ent, PASSABLE);
	ent.flags2 |= UNTOUCHABLE;
	
	//set color
	sc_light_setColor(ent, inColor);
	
	//set range
	sc_light_setRange(ent,inRange);

	//set dir
	vec_set(ent.pan, inDir);
	
	//set position
	vec_set(ent.x, inPos);
	
	//set projection
	sc_light_setProjTex(ent, inProjMap);
	
	//clip from gBuffer
	sc_skill(ent, SC_OBJECT_DEPTH, -1);
	//#ifdef SC_USE_NOFLAG1
		//set(ent, FLAG1);
	//#endif
	
	//set stencil reference for camera-outside-lightvolume case, so light clipping can be optimized
	sc_skill(ent, SC_OBJECT_LIGHT_STENCILREF, sc_lights_stencilRefCurrent);
	sc_lights_stencilRefCurrent += 1;
	if(sc_lights_stencilRefCurrent > 254) sc_lights_stencilRefCurrent = 1;
	
	//assign light material
	//pointlight	
	if(inType == SC_LIGHT_P) ent.material = sc_lights_mtlPoint; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlPoint);
	if(inType == SC_LIGHT_P_SPEC) ent.material = sc_lights_mtlPointSpec; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlPointSpec);
	if(inType == SC_LIGHT_P_SPEC_PROJ) ent.material = sc_lights_mtlPointSpecProj; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlPointProj);
	if(inType == SC_LIGHT_P_PROJ) ent.material = sc_lights_mtlPointProj; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlPointProj);
	//spotlight
	if(inType == SC_LIGHT_S) ent.material = sc_lights_mtlSpot; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlSpot);
	if(inType == SC_LIGHT_S_SPEC) ent.material = sc_lights_mtlSpotSpec; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlSpotSpec);
	if(inType == SC_LIGHT_S_SPEC_SHADOW) ent.material = sc_lights_mtlSpotSpecShadow; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlSpotSpecShadow);
	if(inType == SC_LIGHT_S_SHADOW) ent.material = sc_lights_mtlSpotShadow; //sc_material(ent, SC_MATERIAL_LIGHT, sc_lights_mtlSpotShadow);
	
	//update pointlight projection matrix
	if(
		inType == SC_LIGHT_P_SPEC_PROJ ||
		inType == SC_LIGHT_P_PROJ
	)
	{
		sc_light_updatePointMtx(ent);
	}
	
	
	//set spotlight dir and cone values
	if(
		inType == SC_LIGHT_S ||
		inType == SC_LIGHT_S_SPEC ||
		inType == SC_LIGHT_S_SPEC_SHADOW ||
		inType == SC_LIGHT_S_SHADOW
		)
	{
		//set dir
		//sc_light_updateSpotDir(ent);		
		
		//set spot arc
		sc_light_setArc(ent, inSpotArc);
		
		//update spot matrix
		//sc_light_updateSpotMtx(ent);
		
		
		
		//shadowcasting spotlight?
		if(
			inType == SC_LIGHT_S_SPEC_SHADOW
			|| inType == SC_LIGHT_S_SHADOW)
		{
			
			//create shadowmap view
			VIEW* shadowView = view_create(-800);
			vec_set(shadowView.x, ent.x);
			vec_set(shadowView.pan, ent.pan);
			shadowView.arc = inSpotArc;
			shadowView.aspect = 1;
			shadowView.clip_near = 0;
			shadowView.clip_far = inRange;
			shadowView.size_x = 256;
			shadowView.size_y = 256;
			#ifndef SC_A7
				shadowView.bg = pixel_for_vec(COLOR_WHITE,0,8888);
			#endif
			shadowView.lod = shadow_lod;
			
			//set shadowview flags
			set(shadowView, SHOW);
			reset(shadowView, AUDIBLE);
			set(shadowView, UNTOUCHABLE);
			set(shadowView, NOSHADOW);
			set(shadowView, SHADOW);
			set(shadowView, NOPARTICLE);
			//set(shadowView, CULL_CW);
			#ifdef SC_USE_NOFLAG1
				set(shadowView, NOFLAG1);
			#endif
			
			//create shadowview material
			shadowView.material = mtl_create();
			effect_load(shadowView.material, sc_lights_sMaterialShadowmapLocal);
			shadowView.material.event = sc_lights_mtlShadowmapLocalRenderEvent;
			set(shadowView.material,ENABLE_RENDER);
			set(shadowView.material,PASS_SOLID);
			/*
			shadowView.material.skill4 = floatv(inRange);
			shadowView.material.skill5 = ent.x;
			shadowView.material.skill6 = ent.y;
			shadowView.material.skill7 = ent.z;	
			*/
			shadowView.material.skill30 = inRange;

			//apply shadow rendertarget
			#ifdef SC_CUSTOM_ZBUFFER
				sc_checkZBuffer(256, 256);
			#endif
			BMAP* shadowBmap = bmap_createblack(256,256,12);
			//bmap_to_mipmap(shadowBmap);
			//shadowView.bmap = shadowBmap;
			shadowView.bmap = bmap_createblack(256,256,12);
			
			
			//blur light depthmap
			VIEW* blurView = view_create(-799);
			set(blurView, CHILD);
			set(blurView, PROCESS_TARGET);
			shadowView.stage = blurView;
			blurView.bmap = shadowBmap;
			blurView.material = mtl_create();
			effect_load(blurView.material, sc_lights_sMaterialShadowmapBlur);
			blurView.material.skill1 = floatv((float)1/(float)shadowView.size_x);
			//

			//create shadowdepth material
			/*
			MATERIAL* shadowMtl = mtl_create();
			effect_load(shadowMtl, sc_lights_sMaterialShadowmapLocal);
			shadowMtl.event = sc_lights_mtlShadowmapLocalRenderEvent;
			set(shadowMtl,ENABLE_RENDER);
			set(shadowMtl,PASS_SOLID);
			shadowMtl.skill4 = floatv(inRange);
			shadowMtl.skill5 = ent.x;
			shadowMtl.skill6 = ent.y;
			shadowMtl.skill7 = ent.z;
			//apply to view
			shadowView.material = shadowMtl;
			*/
			
			sc_skill(ent, SC_OBJECT_LIGHT_SHADOWMAP, shadowBmap);
			sc_skill(ent, SC_OBJECT_LIGHT_VIEW, shadowView);
			//sc_material(ent, SC_MATERIAL_LIGHT_SHADOWMAP, shadowMtl);
			
			//sc_light_checkSpotFrustum(ent);
			
			//static lightmap
			//wait(10);
			//reset(shadowView, SHOW);
			//ptr_remove(shadowView);
		}
		
	}
	
	return ent;	
}

void sc_light_update(ENTITY* inLight)
{
	SC_OBJECT* ObjData = (SC_OBJECT*)(inLight.SC_SKILL);
	if(ObjData.light.view != NULL)
	{
		ObjData.light.view.pan = inLight.pan;
		ObjData.light.view.tilt = inLight.tilt;
		ObjData.light.view.roll = inLight.roll;
		ObjData.light.view.x = inLight.x;
		ObjData.light.view.y = inLight.y;
		ObjData.light.view.z = inLight.z;
		ObjData.light.view.arc = ObjData.light.arc;
		ObjData.light.view.material.skill30 = ObjData.light.range;
	}
	
	//sc_light_updateSpotDir(inLight);
	sc_light_updateSpotMtx(inLight);
	//sc_light_updatePointMtx(inLight);
}

int sc_lpp_getLightType(unsigned int inBitflag)
{
	int bitMask = 0;
	
	//pointlights
	bitMask = (SC_LIGHT_POINT);
	if( inBitflag == bitMask) return SC_LIGHT_P;
	
	bitMask = (SC_LIGHT_POINT | SC_LIGHT_SPECULAR);
	if( inBitflag == bitMask) return SC_LIGHT_P_SPEC;
	
	bitMask = (SC_LIGHT_POINT | SC_LIGHT_PROJECTION);
	if( inBitflag == bitMask) return SC_LIGHT_P_PROJ;
	
	bitMask = SC_LIGHT_POINT | SC_LIGHT_SPECULAR | SC_LIGHT_PROJECTION;
	if( (inBitflag & bitMask) == bitMask) return SC_LIGHT_P_SPEC_PROJ;
	
	
	//spotlights
	bitMask = (SC_LIGHT_SPOT);
	if( inBitflag == bitMask || inBitflag == (bitMask | SC_LIGHT_PROJECTION) ) return SC_LIGHT_S;
	
	bitMask = (SC_LIGHT_SPOT | SC_LIGHT_SPECULAR);
	if( inBitflag == bitMask || inBitflag == (bitMask | SC_LIGHT_PROJECTION) ) return SC_LIGHT_S_SPEC;
	
	bitMask = (SC_LIGHT_SPOT | SC_LIGHT_SHADOW);
	if( inBitflag == bitMask || inBitflag == (bitMask | SC_LIGHT_PROJECTION) ) return SC_LIGHT_S_SHADOW;

	bitMask = (SC_LIGHT_SPOT | SC_LIGHT_SPECULAR | SC_LIGHT_SHADOW);
	if( inBitflag == bitMask || inBitflag == (bitMask | SC_LIGHT_PROJECTION) ) return SC_LIGHT_S_SPEC_SHADOW;

	return SC_LIGHT_P;
}


ENTITY* sc_light_create()
{
	return sc_light_createFunc(SC_LIGHT_P, 500, vector(128,128,128), nullvector, nullvector, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos)
{
	return sc_light_createFunc(SC_LIGHT_P, 500, vector(128,128,128), inPos, nullvector, NULL, 90);
}

ENTITY* sc_light_create(int inType)
{
	return sc_light_createFunc(sc_lpp_getLightType(inType), 500, vector(128,128,128), nullvector, nullvector, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange)
{
	return sc_light_createFunc(SC_LIGHT_P, inRange, vector(128,128,128), inPos, nullvector, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor)
{
	return sc_light_createFunc(SC_LIGHT_P, inRange, inColor, inPos, nullvector, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType)
{
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, nullvector, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, BMAP* inProjMap)
{
	int inType = SC_LIGHT_POINT;
	if(inProjMap != NULL) inType |= SC_LIGHT_PROJECTION;
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, nullvector, inProjMap, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, BMAP* inProjMap)
{
	if(inProjMap != NULL) inType |= SC_LIGHT_PROJECTION;
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, nullvector, inProjMap, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, BMAP* inProjMap, VECTOR* inDir)
{
	if(inProjMap != NULL) inType |= SC_LIGHT_PROJECTION;
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, inDir, inProjMap, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, VECTOR* inDir)
{
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, inDir, NULL, 90);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, VECTOR* inDir, var inSpotArc)
{
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, inDir, NULL, inSpotArc);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, BMAP* inProjMap, var inSpotArc)
{
	if(inProjMap != NULL) inType |= SC_LIGHT_PROJECTION;
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, nullvector, inProjMap, inSpotArc);
}

ENTITY* sc_light_create(VECTOR* inPos, var inRange, VECTOR* inColor, int inType, BMAP* inProjMap, VECTOR* inDir, var inSpotArc)
{
	if(inProjMap != NULL) inType |= SC_LIGHT_PROJECTION;
	return sc_light_createFunc(sc_lpp_getLightType(inType), inRange, inColor, inPos, inDir, inProjMap, inSpotArc);
}


var sc_lights_mtlShadowmapLocalRenderEvent()
{
	//mtl.skill1 = floatv(0); //wind...
	//mtl.skill2 = floatv(0.5); //depth alpha clip
	//mtl.skill3 = floatv(0); //shadow bias
	if(my)
	{
		#ifndef SC_A7
				LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
		#else
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
		#endif
		//mtl.skill2 = floatv(1-(my.alpha/100));
		pEffect->SetFloat("alphaClip", 1-(my.alpha/100));
		pEffect->SetFloat("clipFar", mtl.skill30);
		
		if(my.SC_SKILL)
		{
			SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);
			//if(ObjData == NULL) return(1);
		
			//mtl.skill3 = floatv(ObjData.shadowBias);
			
			//check if object casts local shadows
			if(ObjData.castShadow == 2 || ObjData.castShadow == 3)
			{
				
				#ifndef SC_A7
					//check if object has specific shadowmap material applied
					if(ObjData.material.shadowmap != NULL)
					{
						//Set basic shadowmap parameters for new material			
						LPD3DXEFFECT pEffect2 = (LPD3DXEFFECT)(ObjData.material.shadowmap->d3deffect);
						if(pEffect2)
						{
							pEffect2->SetFloat("alphaClip", 1-(my.alpha/100));
							pEffect2->SetFloat("clipFar", mtl.skill30);
						}
						
						//change current material to new one
						mtl = ObjData.material.shadowmap;
						
						//get material skills from object material
						mtl.skill1 = my.material.skill1;
						mtl.skill2 = my.material.skill2;
						mtl.skill3 = my.material.skill3;
						mtl.skill4 = my.material.skill4;
						mtl.skill5 = my.material.skill5;
						mtl.skill6 = my.material.skill6;
						mtl.skill7 = my.material.skill7;
						mtl.skill8 = my.material.skill8;
						mtl.skill9 = my.material.skill9;
						mtl.skill10 = my.material.skill10;
						mtl.skill11 = my.material.skill11;
						mtl.skill12 = my.material.skill12;
						mtl.skill13 = my.material.skill13;
						mtl.skill14 = my.material.skill14;
						mtl.skill15 = my.material.skill15;
						mtl.skill16 = my.material.skill16;
						mtl.skill17 = my.material.skill17;
						mtl.skill18 = my.material.skill18;
						mtl.skill19 = my.material.skill19;
						mtl.skill20 = my.material.skill20;
					}
				#endif
				
				//ptr_remove(screen);
				return(0);
			}
			
		}
		else
		{
			return (0);
		}
		
		//free(screen);
	}
	return(1);
}












//----------------------------------------------------------------------------------------------------------------------------------//
// SUN																																										//
//----------------------------------------------------------------------------------------------------------------------------------//

#ifndef SC_A7
	#include <shadows.c>
#endif

void sc_lights_MaterialEventSun()
{
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL);

	if(render_view == screen.views.sun)
	{
		screen.views.sun.bmap = screen.renderTargets.full0;
		
		//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
		#ifndef SC_A7
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
		#else
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
		#endif
		
		//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)(mtl->d3deffect);
		if(pEffect != NULL)
		{
			pEffect->SetVector("frustumPoints", screen.frustumPoints);
			//pEffect->SetFloat("clipFar", screen.views.main.clip_far);
			pEffect->SetTexture("texBRDFLut", sc_deferredLighting_texBRDFLUT); //assign volumetric brdf lut
			pEffect->SetTexture("texMaterialLUT", sc_materials_mapData.d3dtex);
		}
	}
}

void sc_lights_initSun(SC_SCREEN* screen)
{
	if(sun_color.red == 0 && sun_color.green == 0 && sun_color.blue == 0) return;
	
	//create materials
	screen.materials.sun = mtl_create();
	if(screen.settings.lights.sunShadows == 0) effect_load(screen.materials.sun, sc_lights_sMaterialSun);
	else effect_load(screen.materials.sun, sc_lights_sMaterialSunShadow);
	screen.materials.sun.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]; //point to gBuffer: normals and depth
	//screen.materials.sun.skin2 = ObjData.light.projMap; //projection map
	//screen.materials.sun.skin3 = ObjData.light.shadowMap; //shadowmap
	screen.materials.sun.skin4 = screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]; //point to gBuffer: brdf data
	screen.materials.sun.SC_SKILL = screen;
	set(screen.materials.sun, ENABLE_VIEW);
	screen.materials.sun.event = sc_lights_MaterialEventSun;
		
	//setup views
	screen.views.sun = view_create(-997);
	set(screen.views.sun, PROCESS_TARGET);
	set(screen.views.sun, UNTOUCHABLE);
	set(screen.views.sun, NOSHADOW);
	reset(screen.views.sun, AUDIBLE);
	set(screen.views.sun, NOPARTICLE);
	set(screen.views.sun, NOSKY);
	set(screen.views.sun, CHILD);
	screen.views.sun.size_x = screen.views.main.size_x;
	screen.views.sun.size_y = screen.views.main.size_y;
	screen.views.sun.material = screen.materials.sun;
	screen.views.sun.bmap = screen.renderTargets.full0;
	
	
	#ifndef SC_A7
	//PSSM SHADOWS
	if(screen.settings.lights.sunShadows == 1)
	{
		sun_angle.roll = 1.1*maxv(vec_length(level_ent->max_x),vec_length(level_ent->min_x));
		//screen.renderTargets.sunShadowDepth = bmap_createblack(screen.settings.lights.sunShadowResolution, screen.settings.lights.sunShadowResolution, 12222);
		//screen.materials.sun.skin3 = screen.renderTargets.sunShadowDepth;
				
		int i = 0;
		for(i=0; i<screen.settings.lights.sunPssmSplits; i++)
		{	
			
			screen.views.sunShadowDepth[i] = view_create(-800);
			
			#ifndef SC_A7
				screen.views.sunShadowDepth[i].bg = pixel_for_vec(COLOR_WHITE,0,8888);
			#endif
			screen.views.sunShadowDepth[i].lod = shadow_lod;
				
			/*
			//set shadowview flags
			set(screen.views.sunShadowDepth[i], SHOW);
			reset(screen.views.sunShadowDepth[i], AUDIBLE);
			set(screen.views.sunShadowDepth[i], UNTOUCHABLE);
			set(screen.views.sunShadowDepth[i], NOSHADOW);
			set(screen.views.sunShadowDepth[i], SHADOW);
			set(screen.views.sunShadowDepth[i], NOPARTICLE);
			set(screen.views.sunShadowDepth[i], ISOMETRIC);
			//set(screen.views.sunShadowDepth[i], CULL_CW);
			#ifdef SC_USE_NOFLAG1
				set(screen.views.sunShadowDepth[i], NOFLAG1);
			#endif
			*/
			screen.views.sunShadowDepth[i]->flags |= SHOW|UNTOUCHABLE|NOSHADOW|NOPARTICLE|NOLOD|NOSKY|ISOMETRIC|SHADOW;
			
		
			//create rendertarget
			screen.renderTargets.sunShadowDepth[i] = bmap_createblack(screen.settings.lights.sunShadowResolution, screen.settings.lights.sunShadowResolution, 14);
			
			
			if(i < screen.settings.lights.sunPssmBlurSplits)
			{
			//assign rendertarget
			//screen.views.sunShadowDepth[i].bmap = screen.renderTargets.sunShadowDepth[i];
			screen.views.sunShadowDepth[i].bmap = bmap_createblack(screen.settings.lights.sunShadowResolution, screen.settings.lights.sunShadowResolution, 14);
			
			//blur light depthmap
			VIEW* blurView = view_create(-799);
			blurView.size_x = screen.settings.lights.sunShadowResolution;
			blurView.size_y = screen.settings.lights.sunShadowResolution;
			set(blurView, CHILD);
			set(blurView, PROCESS_TARGET);
			screen.views.sunShadowDepth[i].stage = blurView;
			blurView.bmap = screen.renderTargets.sunShadowDepth[i];
			blurView.material = mtl_create();
			effect_load(blurView.material, sc_lights_sMaterialShadowmapBlur);
			//blurView.material.skill1 = floatv((float)(2.25-i)/(float)screen.settings.lights.sunShadowResolution);
			if(i==0) blurView.material.skill1 = floatv((float)(1.5)/(float)screen.settings.lights.sunShadowResolution);
			if(i==1) blurView.material.skill1 = floatv((float)(0.75)/(float)screen.settings.lights.sunShadowResolution);
			if(i==2) blurView.material.skill1 = floatv((float)(0.25)/(float)screen.settings.lights.sunShadowResolution);
			//
			}
			else
			{
				screen.views.sunShadowDepth[i].bmap = screen.renderTargets.sunShadowDepth[i];
			}
			
			//create material
			screen.views.sunShadowDepth[i].material = mtl_create();
			
			switch(i){
				case 0:
					effect_load(screen.views.sunShadowDepth[i].material,sc_lights_sMaterialShadowmapSplit1);
				break;
				case 1:
					effect_load(screen.views.sunShadowDepth[i].material,sc_lights_sMaterialShadowmapSplit2);
				break;
				case 2:
					effect_load(screen.views.sunShadowDepth[i].material,sc_lights_sMaterialShadowmapSplit3);
				break;
				case 3:
					effect_load(screen.views.sunShadowDepth[i].material,sc_lights_sMaterialShadowmapSplit4);
				break;
				default:
				break;
			}
			
			//pass number of splits to sun shader
			screen.materials.sun.skill13 = floatv(screen.settings.lights.sunPssmSplits);
			
		}
		
		bmap_zbuffer(bmap_createblack(maxv(screen_size.x,screen.settings.lights.sunShadowResolution),maxv(screen_size.y,screen.settings.lights.sunShadowResolution),32));
	}
	#endif
	//------------
	
	
	
	
	//apply sun to camera
	VIEW* view_last;
	view_last = screen.views.gBuffer;
	while(view_last.stage != NULL)
	{
		view_last = view_last.stage;
	}
	view_last.stage = screen.views.sun;
	
}

void sc_lights_destroySun(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.views.sun != NULL)
	{
		if(is(screen.views.sun,NOSHADOW))
		{
			
			reset(screen.views.sun,NOSHADOW);
			//purge render targets
			if(screen.views.sun.bmap) bmap_purge(screen.views.sun.bmap);
			screen.views.sun.bmap = NULL;
		
			//remove dof from view chain
			VIEW* view_last;
			view_last = screen.views.gBuffer;
			while(view_last.stage != screen.views.sun && view_last.stage != NULL)
			{
				view_last = view_last.stage;
			}
				
			if(screen.views.sun.stage) view_last.stage = screen.views.sun.stage;
			else view_last.stage = NULL;
			
			//if(screen.sc_dof_view.bmap) view_last.bmap = screen.sc_hdr_mapOrgScene;
			//else view_last.bmap = NULL;
			
			
			//remove PSSM
			int i=0;
			for(i=0; i<4; i++) {
				if(screen.views.sunShadowDepth[i] == NULL) continue;
				if(screen.views.sunShadowDepth[i].material != NULL) ptr_remove(screen.views.sunShadowDepth[i].material);
				if(screen.views.sunShadowDepth[i].bmap != NULL) {
					bmap_purge(screen.views.sunShadowDepth[i].bmap);
					ptr_remove(screen.views.sunShadowDepth[i].bmap);
				}
				if(screen.views.sunShadowDepth[i] != NULL) ptr_remove(screen.views.sunShadowDepth[i]);
				if(screen.renderTargets.sunShadowDepth[i] != NULL) ptr_remove(screen.renderTargets.sunShadowDepth[i]);
			}
			
		}
	}
	return 1;
}

void sc_lights_frmSun(SC_SCREEN* screen)
{
	if(screen.views.sun != NULL)
	{
		if(
			screen.settings.lights.sunPos.x == 0
			&& screen.settings.lights.sunPos.y == 0
			&& screen.settings.lights.sunPos.z == 0
			) //global sun
		{
			VECTOR distantSunPos;
			vec_for_angle(distantSunPos, sun_angle);
			vec_scale(distantSunPos, 9999999);
			screen.materials.sun.skill1 = floatv(distantSunPos.x);
			screen.materials.sun.skill2 = floatv(distantSunPos.y);
			screen.materials.sun.skill3 = floatv(distantSunPos.z);
		}
		else //local sun
		{
			screen.materials.sun.skill1 = floatv(screen.settings.lights.sunPos.x);
			screen.materials.sun.skill2 = floatv(screen.settings.lights.sunPos.y);
			screen.materials.sun.skill3 = floatv(screen.settings.lights.sunPos.z);
		}
		
		screen.materials.sun.skill4 = floatv(0); //local sun lightrange (not used)
		
		//sun color
		screen.materials.sun.skill5 = floatv(sun_color.red/255);
		screen.materials.sun.skill6 = floatv(sun_color.green/255);
		screen.materials.sun.skill7 = floatv(sun_color.blue/255);
		screen.materials.sun.skill8 = floatv(screen.views.main.clip_far);
		
		
		
		
		
		
		#ifndef SC_A7
		// PSSM main loop
		if(screen.settings.lights.sunPssmSplits>0 && screen.settings.lights.sunShadows == 1)
		{
		// update the views _after_ the camera was updated!
		//	proc_mode = PROC_LATE;
	
		// set up the split distances and the shadow view
			pssm_split(screen.views.main, screen.settings.lights.sunPssmSplits, screen.settings.lights.sunPssmSplitWeight);
			//pssm_viewcpy(screen.views.main, screen.views.sun);
	
		// set up the split view transformation matrices
			D3DXMATRIX matSplit[4];
			int i=0;
			for(i=0; i<screen.settings.lights.sunPssmSplits; i++) 
			{
		// look from the sun onto the scene			
				screen.views.sunShadowDepth[i]->pan = 180 + sun_angle.pan;
				screen.views.sunShadowDepth[i]->tilt = -sun_angle.tilt;
				vec_set(screen.views.sunShadowDepth[i]->x,sun_pos);
	
		// calculate the split view clipping borders and transformation matrix			
				view_to_split(screen.views.main, pssm_splitdist[i],pssm_splitdist[i+1], screen.views.sunShadowDepth[i], &matSplit[i]);
				LPD3DXEFFECT fx = screen.views.sunShadowDepth[i]->material->d3deffect; 
				if(fx) fx->SetMatrix("matSplitViewProj",&matSplit[i]);
				
		// create a texture matrix from the split view proj matrix			
				D3DXMatrixMultiply(&matSplit[i],&matSplit[i],pssm_texscale(screen.settings.lights.sunShadowResolution));
			
		#ifdef DEBUG_PSSM		
				DEBUG_BMAP(screen.views.sunShadowDepth[i]->bmap,300 + i*220,0.2);
				var pssm_fps = 16/time_frame;
				DEBUG_VAR(pssm_fps,200);
				DEBUG_VAR(pssm_splitdist[i+1],220 + i*20);
		#endif
				//set depthmapshader maxDepth	
				screen.views.sunShadowDepth[i].material.skill4 = floatv(screen.views.sunShadowDepth[i].clip_far);
			}
	
		//put matrices to world space
			//mat_multiply(matSplit[0], matViewInv);
		// use a DX function to copy the 4 texture matrices to the shadow shader
			LPD3DXEFFECT fx = screen.views.sun->material->d3deffect;
			if(fx) {
				fx->SetMatrixArray("matTex",matSplit,screen.settings.lights.sunPssmSplits);
				if(screen.views.sunShadowDepth[0] != NULL) fx->SetTexture("shadowTex1",screen.renderTargets.sunShadowDepth[0].d3dtex);
				if(screen.views.sunShadowDepth[1] != NULL) fx->SetTexture("shadowTex2",screen.renderTargets.sunShadowDepth[1].d3dtex);
				if(screen.views.sunShadowDepth[2] != NULL) fx->SetTexture("shadowTex3",screen.renderTargets.sunShadowDepth[2].d3dtex);
				if(screen.views.sunShadowDepth[3] != NULL) fx->SetTexture("shadowTex4",screen.renderTargets.sunShadowDepth[3].d3dtex);
			}
						
			screen.views.sun.material.skill4 = floatv(screen.views.sunShadowDepth[0].clip_far);
	
		#ifdef DEBUG_PSSM		
			DEBUG_BMAP(screen.views.sun->bmap,20,0.2);
		#endif
		}
		#endif
		
		
	}
}