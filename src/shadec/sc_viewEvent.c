void sc_viewEvent_init(SC_SCREEN* screen)
{
	if(!screen) return 0;
	sc_viewEvent_destroy(screen);
	
	screen.materials.viewEvent = mtl_create();
	effect_load(screen.materials.viewEvent, "technique t1{ pass p0	{}	}");
	screen.materials.viewEvent.flags = ENABLE_VIEW | ENABLE_TREE;
	screen.materials.viewEvent.event = sc_viewEvent_event;
	screen.materials.viewEvent.SC_SKILL = screen;
}

void sc_viewEvent_destroy(SC_SCREEN* screen)
{
	if(!screen) return 0;
	if(screen.materials.viewEvent)
	{
		sys_free(screen.materials.viewEvent);
		//ptr_remove(screen.materials.viewEvent);
	}
}

BMAP* testmap5 = "sc_energySphere_alpha.tga";

var sc_viewEvent_event()
{
	SC_SCREEN* screen = (SC_SCREEN*)(mtl.SC_SKILL); //get current shade-c screen object
	if(screen)
	{
		if(screen.views.gBuffer == NULL)
		{
			return(1);
		}
	}
	else
	{
		return(1);
	}
	
	switch(render_view)
	{
		case screen.views.deferredLighting:
			IDirect3DDevice9* pd3dDev = (IDirect3DDevice9*)(pd3ddev);
			if (!pd3dDev) return;
			//pd3dDev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, ambient_color.red/2, ambient_color.green/2, ambient_color.blue/2), 1.0, 0);
			//pd3dDev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(255, 255, 255, 255), 1.0, 0);
			pd3dDev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(255, 255-(ambient_color.red/2), 255-(ambient_color.green/2), 255-(ambient_color.blue/2)), 1.0, 0);
			//pd3dDev->Clear(0, NULL, D3DCLEAR_ZBUFFER, D3DCOLOR_ARGB(0, 0, 0, 0), 0.0, 0);
			
			if(screen.views.sun != NULL)
			{
				
				
				//put code for rendering directional lights here
				//draw fullscreen quad,apply directional light shader and blend
				//set render states
				pd3dDev->SetRenderState(D3DRS_LIGHTING, FALSE);
				pd3dDev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
				pd3dDev->SetRenderState(D3DRS_BLENDOP, 1); // = D3DBLENDOP_ADD
				//pd3dDev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE); //normal blending
				//pd3dDev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE); //normal blending
				pd3dDev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_DESTCOLOR); //needed for lighting pack algorythm
				pd3dDev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ZERO); //needed for lighting pack algorythm
				pd3dDev->SetRenderState(D3DRS_ZENABLE, FALSE);
				pd3dDev->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
				
				
				// now draw the screen aligned quad
				pd3dDev->SetFVF(SC_D3DFVF_SCREENQUAD);
				//pd3dDev->SetTexture (0, screen.renderTargets.gBuffer[0].d3dtex);
				pd3dDev->SetTexture (0, screen.views.sun.bmap.d3dtex);
				pd3dDev->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP,2,(LPVOID)screen.vertexScreenquad,sizeof(SC_VERTEX_SCREENQUAD));	
			}
			
			
			
			/*
			//LPD3DXEFFECT pEffect = (LPD3DXEFFECT)render_d3dxeffect;
			LPD3DXEFFECT pEffect = (LPD3DXEFFECT)mtl->d3deffect;
			if(pEffect != NULL)
			{
				//IDirect3DDevice9* pd3dDevice = (IDirect3DDevice9*)(pd3ddev);
				//D3DXCreateEffectFromFile(pd3dDevice,"marine.fx",NULL,NULL,0,NULL,&pEffect,NULL);
				//HAVOC : PUT THIS IN MAIN EVENT LOOP!?
				pEffect->SetTexture("texBRDFLut", sc_deferredLighting_texBRDFLUT); //assign volumetric brdf lut
				pEffect->SetFloat("brdfTest1", brdfTest1);
				pEffect->SetFloat("brdfTest2", brdfTest2);
				pEffect->SetTexture("texMatData1", sc_materials_texMatData1); //assign volumetric brdf data
				//pEffect->SetVectorArray("brdfData1", sc_material_brdfData1, SC_MATERIAL_BRDF_SIZE);
			}	
			*/	
		break;
		
		case screen.views.main:
			IDirect3DDevice9* pd3dDev = (IDirect3DDevice9*)(pd3ddev);
			if (!pd3dDev) return(1);
			pd3dDev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0, 1);		
			//screen.views.preForward.bmap = screen.renderTargets.full0;
			
			draw_quad(screen.views.preForward.bmap,vector(0,0,0),NULL,NULL,NULL,NULL,100,0);
			
			/*
			//render sky/backdrop/scene as screen aligned quad
			// set some render and stage states
			//pd3dDev->SetVertexShader(NULL);
			pd3dDev->SetRenderState(D3DRS_LIGHTING, FALSE);
			pd3dDev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
			pd3dDev->SetRenderState(D3DRS_ZENABLE, FALSE);
			pd3dDev->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
			//pd3dDev->SetTextureStageState(0,D3DTSS_COLORARG2,D3DTA_DIFFUSE);
			//pd3dDev->SetTextureStageState(0,D3DTSS_COLOROP,D3DTOP_SELECTARG2);
			//pd3dDev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
			//pd3dDev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
			//pd3dDev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
			//pd3dDev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
			//pd3dDev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
			// now draw the screen aligned quad
			pd3dDev->SetFVF(SC_D3DFVF_SCREENQUAD);
			pd3dDev->SetTexture (0, screen.views.preForward.bmap.d3dtex);
			pd3dDev->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP,2,(LPVOID)screen.vertexScreenquad,sizeof(SC_VERTEX_SCREENQUAD));	
			*/
		break;
		
		case screen.views.refract:
			IDirect3DDevice9* pd3dDev = (IDirect3DDevice9*)(pd3ddev);
			if(!pd3dDev) return(1);
			pd3dDev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0, 1);
			//screen.views.preRefract.bmap = screen.renderTargets.full0;
			
			draw_quad(screen.views.preRefract.bmap,vector(0,0,0),NULL,NULL,NULL,NULL,100,0);
			
			/*
			//render sky/backdrop/scene as screen aligned quad
			// set some render and stage states
			//pd3dDev->SetVertexShader(NULL);
			pd3dDev->SetRenderState(D3DRS_LIGHTING, FALSE);
			pd3dDev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
			pd3dDev->SetRenderState(D3DRS_ZENABLE, FALSE);
			pd3dDev->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
			//pd3dDev->SetTextureStageState(0,D3DTSS_COLORARG2,D3DTA_DIFFUSE);
			//pd3dDev->SetTextureStageState(0,D3DTSS_COLOROP,D3DTOP_SELECTARG2);
			//pd3dDev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
			//pd3dDev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
			//pd3dDev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
			//pd3dDev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
			//pd3dDev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
			// now draw the screen aligned quad
			pd3dDev->SetFVF(SC_D3DFVF_SCREENQUAD);
			pd3dDev->SetTexture (0, screen.views.preRefract.bmap.d3dtex);
			pd3dDev->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP,1,(LPVOID)screen.vertexScreenquad,sizeof(SC_VERTEX_SCREENQUAD));	
			*/
		break;
			
		default:
		break;
	}
	
	return(0);
	
}
/*
MATERIAL* sc_viewEvent_material =
{
	flags = ENABLE_VIEW;
	event = sc_viewEvent_event;
	effect = "
		technique t1
		{
			pass p0
			{
			}
		}
	";
}
*/