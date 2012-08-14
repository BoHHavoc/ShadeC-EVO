void sc_materials_init()
{
	//if(sc_materials_initialized != 0) return; //return if materials are already initialized
	
	sc_materials_mapData = bmap_createblack(256, 1, 32); //256 different datasets
	//r = lightfunction
	//g = diffuse smoothness
	//b = diffuse wrap
	//a = not used yet
	
	//get materials from xml
	SC_MATERIAL_DATA* matData;
	var materialdata;
	var format = bmap_lock(sc_materials_mapData,0);
	
	matData = sc_material_loadDataFromXML("001");
	materialdata = pixel_for_vec(vector( matData.diffuseWrap, matData.diffuseSmoothness, matData.lightFunction), 100, format); //blinn phong
	pixel_to_bmap(sc_materials_mapData, matData.materialID, 0, materialdata);
	materialdata = pixel_for_vec(vector(128,128,2),100,format); //Cook Torrance
	pixel_to_bmap(sc_materials_mapData,2,0,materialdata);
	materialdata = pixel_for_vec(vector(128,128,4),100,format); //Oren Nayar
	pixel_to_bmap(sc_materials_mapData,3,0,materialdata);
	
	
	materialdata = pixel_for_vec(vector(192,255,2),100,format); //Oren Nayar with high diffuse wrap and diffuse smoothness
	pixel_to_bmap(sc_materials_mapData,51,0,materialdata);	//

	
	
	
	
	bmap_unlock(sc_materials_mapData);
	/*
	if(sc_materials_brdf == NULL)
	{
		//SC_MATERIALS_BRDF* brdfmaterials;
		//brdfmaterials = sys_malloc(sizeof(SC_MATERIALS_BRDF));
		//memset(brdfmaterials,0,sizeof(SC_MATERIALS_BRDF));
	}
	
	sc_materials_brdf[0].LUTIndex = (float)1/(float)SC_MATERIALS_BRDF_SIZE; //Blinn-Phong
	sc_materials_brdf[0].diffuseRoughness = 0; //diffuse roughness
	sc_materials_brdf[0].diffuseWrap = 0; //diffuse wrap
	sc_materials_brdf[0].specularStrength = 1; //specular stength
	*/
	//if(!sc_materials_texMatData1) sc_materials_texMatData1 = sc_volumeTexture_create(sc_materials_sMatData1);
	
	sc_materials_initialized = 1;
}

SC_MATERIAL_DATA* sc_material_loadDataFromXML(STRING* inFilename)
{
	SC_MATERIAL_DATA* matData;
	matData = sys_malloc(sizeof(SC_MATERIAL_DATA));
	//memset(matData,0,sizeof(SC_MATERIAL_DATA));
	
	matData.materialID = 1;
	matData.lightFunction = 0;
	matData.diffuseWrap = 128;
	matData.diffuseSmoothness = 128;
	return matData;
}

var sc_materials_event()
{
	SC_SCREEN* screen = sc_screen_default;
	if(screen == NULL) return(1);
	
	
	switch(render_view)
	{
		case screen.views.gBuffer:
			
			
			//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)(render_d3dxeffect);
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)(mtl->d3deffect);
			
			if(my != NULL)
			{
				if(my.SC_SKILL != NULL) //entity has SC_SKILL
				{
					SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);
					
					if(ObjData.depth == -1) return(1); //clip from gBuffer
					if(ObjData.pass != SC_PASS_GBUFFER) return(1); //only render entities which have the SC_PASS_GBUFFER flag set
					
					
					if(pEffect != NULL)
					{
						pEffect->SetFloat("clipFar", screen.views.main.clip_far);
						pEffect->SetFloat("alphaClip", 1-(my.alpha/100));
						pEffect->SetFloat("materialID", ObjData.material.id); 
						pEffect->SetVector("vecEmissive_SHADEC", ObjData.emissive);
						pEffect->SetVector("vecColor_SHADEC", ObjData.color);
					}
					return (0);
				}
				else //entity has no SC_SKILL
				{
					if(pEffect != NULL)
					{
						pEffect->SetFloat("clipFar", screen.views.main.clip_far);
						pEffect->SetFloat("alphaClip", 1-(my.alpha/100));
						pEffect->SetFloat("materialID", 0.003921); 
						pEffect->SetVector("vecEmissive_SHADEC", sc_vec4Null);
						pEffect->SetVector("vecColor_SHADEC", sc_vec4Null);
					}
					return(0);
				}
			}
			
			//entity has no my pointer
			if(pEffect != NULL)
			{
				pEffect->SetFloat("clipFar", screen.views.main.clip_far);
				pEffect->SetFloat("alphaClip", 0.5);
				pEffect->SetFloat("materialID", 0.003921);
				pEffect->SetVector("vecEmissive_SHADEC", sc_vec4Null);
				pEffect->SetVector("vecColor_SHADEC", sc_vec4Null);
			}
			
			//mtl.skill1 = floatv(0.5); //alpha cutout
			//mtl.skill17 = floatv(screen.views.main.clip_far); //max depth
			//mtl.skill18 = floatv(0.0039); //brdf index (0 and 0.0039 = blinn-phong (special case as blinn-phong is on tex-sheet 1 and 128!)
			return(0);
		break;
		
		
		case screen.views.deferredLighting:
		
			//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)(mtl->d3deffect);
			if(pEffect != NULL)
			{
				pEffect->SetTexture("texBRDFLut", sc_deferredLighting_texBRDFLUT); //assign volumetric brdf lut
				//pEffect->SetFloat("brdfTest1", brdfTest1);
				//pEffect->SetFloat("brdfTest2", brdfTest2);
				pEffect->SetTexture("texMaterialLUT", sc_materials_mapData.d3dtex);
				//pEffect->SetTexture("texMatData1", sc_materials_texMatData1); //assign volumetric brdf data
			}
			if(my)
			{	
				if(my.SC_SKILL && render_view == screen.views.deferredLighting)
				{
					SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);
					if(ObjData == NULL) return(1); //don't render entity if it's not a Shade-C Object 
					if(ObjData.light.range > 0)
					{
						mtl.skin1 = screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH]; //point to gBuffer: normals and depth
						mtl.skin2 = ObjData.light.projMap; //projection map
						mtl.skin3 = ObjData.light.shadowMap; //shadowmap
						mtl.skin4 = screen.renderTargets.gBuffer[SC_GBUFFER_MATERIAL_DATA]; //point to gBuffer: brdf data
						
						mtl.skill1 = floatv(my.x - screen.views.main.x); //light pos in camera space
						mtl.skill2 = floatv(my.y - screen.views.main.y); //light pos in camera space
						mtl.skill3 = floatv(my.z - screen.views.main.z); //light pos in camera space
						mtl.skill4 = floatv(ObjData.light.range);
						mtl.skill5 = floatv(ObjData.light.color.x);
						mtl.skill6 = floatv(ObjData.light.color.y);
						mtl.skill7 = floatv(ObjData.light.color.z);
						mtl.skill8 = floatv(screen.views.main.clip_far); //set camera depth
						
						//spotlight
						mtl.skill9 = floatv(ObjData.light.dir.x);
						mtl.skill10 = floatv(ObjData.light.dir.y);
						mtl.skill11 = floatv(ObjData.light.dir.z);
						
						/*
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
						*/
						
						//Pass light-projection-matrix (shadows, projectionmap, etc)
						if(ObjData.light.matrix != NULL)
						{
							//mat_set(mtl.matrix, ObjData.light.matrix);
							mat_set(mtl.matrix, matViewInv);
							mat_multiply(mtl.matrix, ObjData.light.matrix);
						}
						
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
			mtl.skill8 = floatv(screen.views.main.clip_far); //set view clip_far
			
			mtl.skill9 = floatv(0);
			mtl.skill10 = floatv(0);
			mtl.skill11 = floatv(0);
			mtl.skill12 = floatv(0);
			
			//clear the screen
			//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
			//pd3dDevice->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), (float)0.0, 0);
			return(1);
		break;
		
		case screen.views.main:
			if(my != NULL)
			{
				//if(my.skill2 == 1) mtl.skill1 = floatv(1);
				if(my.SC_SKILL != NULL)
				{
					SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);

					if(ObjData.pass != SC_PASS_FORWARD) return(1); //only render entities which have the SC_PASS_FORWARD flag set
					
					//pass data to effect	
					//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
					LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
					if(pEffect != NULL)
					{
						pEffect->SetTexture("texNormalsAndDepth", screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH].d3dtex);
						pEffect->SetVector("data1", ObjData.data.data1 );
						pEffect->SetVector("data2", ObjData.data.data2 );
						pEffect->SetVector("data3", ObjData.data.data3 );
						
						pEffect->SetFloat("clipFar", screen.views.main.clip_far);
						pEffect->SetFloat("alphaClip", 1-(my.alpha/100));
						pEffect->SetFloat("materialID", ObjData.material.id); 
						pEffect->SetVector("vecEmissive_SHADEC", ObjData.emissive);
						pEffect->SetVector("vecColor_SHADEC", ObjData.color);
						/*
						D3DXVECTOR4 tempVec4;
						tempVec4.x = ObjData.data.data1.x; //softsprite/fog: camera fade distance
						tempVec4.y = ObjData.data.data1.y; // softsprite/fog: softness
						tempVec4.z = ObjData.data.data1.z;
						tempVec4.w = ObjData.data.data1.w;
						pEffect->SetVector("data1", tempVec4 );
						tempVec4.x = ObjData.data.data2.x; //softfog: noise texture R scale
						tempVec4.y = ObjData.data.data2.y; //softfog: noise texture G scale
						tempVec4.z = ObjData.data.data2.z; //softfog: noise texture B scale
						tempVec4.w = ObjData.data.data2.w; //softfog: noise texture movement speed
						pEffect->SetVector("data2", tempVec4 );
						tempVec4.x = ObjData.data.data3.x; //softsprite/fog: color R
						tempVec4.y = ObjData.data.data3.y; //softsprite/fog: color G
						tempVec4.z = ObjData.data.data3.z; //softsprite/fog: color B
						tempVec4.w = ObjData.data.data3.w;
						pEffect->SetVector("data3", tempVec4 );
						sys_free(tempVec4);
						*/
						return(0);
					}
				}
			}
			return(1);
		break;
		
		case screen.views.refract:
			if(my != NULL)
			{
				//if(my.skill2 == 1) mtl.skill1 = floatv(1);
				if(my.SC_SKILL != NULL)
				{
					SC_OBJECT* ObjData = (SC_OBJECT*)(my.SC_SKILL);

					if(ObjData.pass != SC_PASS_REFRACT) return(1); //only render entities which have the SC_PASS_FORWARD flag set
						
					//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
					LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
					if(pEffect != NULL)
					{
						pEffect->SetTexture("texNormalsAndDepth", screen.renderTargets.gBuffer[SC_GBUFFER_NORMALS_AND_DEPTH].d3dtex);
						pEffect->SetVector("data1", ObjData.data.data1 );
						pEffect->SetVector("data2", ObjData.data.data2 );
						pEffect->SetVector("data3", ObjData.data.data3 );
						
						pEffect->SetFloat("clipFar", screen.views.main.clip_far);
						pEffect->SetFloat("alphaClip", 1-(my.alpha/100));
						pEffect->SetFloat("materialID", ObjData.material.id); 
						pEffect->SetVector("vecEmissive_SHADEC", ObjData.emissive);
						pEffect->SetVector("vecColor_SHADEC", ObjData.color);
						/*
						D3DXVECTOR4 tempVec4;
						tempVec4.x = ObjData.data.data1.x;
						tempVec4.y = ObjData.data.data1.y; // shield: softness
						tempVec4.z = ObjData.data.data1.z; // shield: texture movement speed
						tempVec4.w = ObjData.data.data1.w; // shield: texture offset
						pEffect->SetVector("data1", tempVec4 );
						tempVec4.x = ObjData.data.data2.x; 
						tempVec4.y = ObjData.data.data2.y; 
						tempVec4.z = ObjData.data.data2.z; 
						tempVec4.w = ObjData.data.data2.w;
						pEffect->SetVector("data2", tempVec4 );
						tempVec4.x = ObjData.data.data3.x; //shield: color R
						tempVec4.y = ObjData.data.data3.y; //shield: color G
						tempVec4.z = ObjData.data.data3.z; //shield: color B
						tempVec4.w = ObjData.data.data3.w;
						pEffect->SetVector("data3", tempVec4 );
						sys_free(tempVec4);
						*/
						return(0);
					}
				}
			}
			return(1);
		break;
		
		default:
			return(1); //don't render
		break;
	}
}