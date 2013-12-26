// Original code by Nils Daumann | www.slindev.com
// http://www.opserver.de/ubb7/ubbthreads.php?ubb=showflat&Number=357697&Main=42496#Post357697

/* Usage

// Material event assigning the texture to the shader
void shd_voltex_set()
{
	//LPD3DXEFFECT A7_eff = (LPD3DXEFFECT)render_d3dxeffect;
	LPD3DXEFFECT A7_eff = (LPD3DXEFFECT)mtl->d3deffect;
	if(A7_eff != NULL)
	{
		A7_eff->SetTexture("voltex", (LPDIRECT3DVOLUMETEXTURE9)mtl.skill1); //"voltex" is the textures name within the shader, mtl.skill1 is missused as a pointer to the texture
	}
}

//Usage:
somematerial.event = shd_matevent_colorGrading; 
somematerial.flags |= ENABLE_VIEW; //for a pp effect, probably ENABLE_RENDER when applied to entities
somematerial.skill1 = (var)sc_volumeTexture_create("yourvoltex.dds"); //creation of the volumetexture, returns LPDIRECT3DVOLUMETEXTURE9

*/


//#include <d3d9.h>

// Creates a volume texture from the given filename
LPDIRECT3DVOLUMETEXTURE9 sc_volumeTexture_create(STRING *filename)
{
	LPDIRECT3DVOLUMETEXTURE9 temptex;
	char** c;
	for (c = pPaths; *c != NULL; c++)
	{
		STRING* str_="";
		str_cpy(str_,*c);
		str_cat(str_,filename);
		HRESULT res = D3DXCreateVolumeTextureFromFile((LPDIRECT3DDEVICE9)pd3ddev, _chr(str_), &temptex);
		if(res == S_OK)
		{
			return temptex;
		}
	}
	
	error("can't create sc_deferredLighting_LUT.dds");
	return NULL;
}