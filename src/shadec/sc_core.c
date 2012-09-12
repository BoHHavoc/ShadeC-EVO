//Set custom z-buffer as Acknex screws this up
#ifdef SC_CUSTOM_ZBUFFER
	var sc_currentZBufferSize[2] = {0,0};
	
	int sc_checkZBuffer(int newSizeX, int newSizeY)
	{
		if(newSizeX > sc_currentZBufferSize[0] || newSizeY > sc_currentZBufferSize[1])
		{
			VECTOR newZBuffer;
			vec_set(newZBuffer, nullvector);
			
			newZBuffer.x = newSizeX;
			newZBuffer.y = newSizeY;
			if(newZBuffer.x < screen_size.x) newZBuffer.x = screen_size.x;
			if(newZBuffer.y < screen_size.y) newZBuffer.y = screen_size.y;
			
			if(newZBuffer.x > sc_currentZBufferSize[0]) sc_currentZBufferSize[0] = newZBuffer.x;
			else newZBuffer.x = sc_currentZBufferSize[0];
			if(newZBuffer.y > sc_currentZBufferSize[1]) sc_currentZBufferSize[1] = newZBuffer.y;
			else newZBuffer.y = sc_currentZBufferSize[1];
			
			bmap_zbuffer(bmap_createblack(newZBuffer.x, newZBuffer.y, 32));
			
			return 0;
		}
		else
		{
			bmap_zbuffer(bmap_createblack(sc_currentZBufferSize[0], sc_currentZBufferSize[1], 32));
			//bmap_zbuffer(bmap_createblack(screen_size.x, screen_size.y, 32));
			return 1;
		}
	}
	
#endif


//check if gfx card supports certain texture formats
var sc_getTexCaps(var tex)
{
	LPDIRECT3D9 mypD3D;
	mypD3D = pd3d;
	if(tex == D3DFMT_R16F) return (mypD3D)->CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DFMT_X8R8G8B8, D3DUSAGE_RENDERTARGET, D3DRTYPE_TEXTURE, D3DFMT_R16F);
	else if(tex == D3DFMT_R32F) return (mypD3D)->CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DFMT_X8R8G8B8, D3DUSAGE_RENDERTARGET, D3DRTYPE_TEXTURE, D3DFMT_R32F);
	else if(tex == D3DFMT_A16B16G16R16F) return (mypD3D)->CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DFMT_X8R8G8B8, D3DUSAGE_RENDERTARGET, D3DRTYPE_TEXTURE, D3DFMT_A16B16G16R16F);
	else if(tex == D3DFMT_A32B32G32R32F) return (mypD3D)->CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DFMT_X8R8G8B8, D3DUSAGE_RENDERTARGET, D3DRTYPE_TEXTURE, D3DFMT_A32B32G32R32F);
	else return -1;
	free(mypD3D);
}


//Add an effect to a views stage chain
VIEW* sc_ppAdd(MATERIAL* Material,VIEW* View,BMAP* bmap)
{
	VIEW* sc_view_last;
	//find the last view of "View"s effectchain and store its pointer
	sc_view_last = View;
	while(sc_view_last.stage != NULL)
	{
		sc_view_last = sc_view_last.stage;
	}
	
	//create a new view as the stored views stage
	sc_view_last.stage = view_create(0);
	set(sc_view_last.stage,PROCESS_TARGET);
	set(sc_view_last.stage,CHILD);
		
	//assign "Material" to the just created view
	sc_view_last = sc_view_last.stage;
	sc_view_last.material = Material;
	
	//if a bmap is given, render the view into it
	if(bmap != NULL)
	{
		sc_view_last.bmap = bmap;
	}
	
	//return the pointer to the new view
	return(sc_view_last);
}


//remove an effect from a views stage chain
int sc_ppRemove(MATERIAL* Material,VIEW* View,VIEW* StageView)
{
	VIEW* sc_view_last;
	//find the view with the material selected or "StageView" and the previous view
	sc_view_last = View;
	while(sc_view_last.material != Material && ((StageView == NULL)+(sc_view_last.stage != NULL)) != NULL)
	{
		View = sc_view_last;
		sc_view_last = sc_view_last.stage;
		
		//return one if the stage doesn´t exist
		if(sc_view_last == NULL){return(1);}
	}
	
	//pass the views stage to the previous view
	View.stage = sc_view_last.stage;
	
	//reset the views bmap to null
	sc_view_last.bmap = NULL;
	
	//remove the view
	ptr_remove(sc_view_last);
	
	//return null if everything worked
	return(0);
}

void sc_settings_setDefaults(SC_SETTINGS* settings)
{
	//HDR
	settings.hdr.enabled = 0;
	settings.hdr.blurX = 8;
	settings.hdr.blurY = 12;
	settings.hdr.brightpass = 0.25;
	settings.hdr.intensity = 1;
	settings.hdr.lensflare.enabled = 0;
	settings.hdr.lensflare.brightpass = 0.3;
	settings.hdr.lensflare.intensity = 0.5;
	
	//DOF
	settings.dof.enabled = 0;
	settings.dof.blurX = 2;
	settings.dof.blurY = 3;
	settings.dof.focalPos = 500;
	settings.dof.focalWidth = 2000;
	
	//Forward Rendering
	settings.forward.enabled = 0;
	
	//Refractions
	settings.refract.enabled = 0;
	
	//SSAO
	settings.ssao.enabled = 0;
	settings.ssao.radius = 25;
	settings.ssao.intensity = 1;
	//settings.ssao.selfOcclusion = 0.85;
	settings.ssao.selfOcclusion = 0.0004; //0.0005 gets rid of almost all self occlusion
	
	//SUN
	settings.lights.sunShadows = 0;
	settings.lights.sunPssmSplits = 3;
	settings.lights.sunPssmSplitWeight = 0.5;
	settings.lights.sunPssmBlurSplits = 0;
	settings.lights.sunShadowResolution = 1024;
	
	//Antialiasing
	settings.antialiasing.enabled = 0;
}

SC_SCREEN* sc_screen_create(VIEW* inView)
{
	SC_SCREEN* screen;
	screen = sys_malloc(sizeof(SC_SCREEN));
	//memset(screen, 0, sizeof(SC_SCREEN)); 
	
	//screen.views = sys_malloc(sizeof(SC_SCREEN_VIEWS));
	//memset(screen.views, 0, sizeof(SC_SCREEN_VIEWS));
	
	
	if(inView.size_x == 0 || inView.size_y == 0){
		inView.size_x = screen_size.x;
		inView.size_y = screen_size.y;
	}
	
	screen.views.main = inView;
	
	//screen.renderTargets = sys_malloc(sizeof(SC_SCREEN_RENDERTARGETS));
	//memset(screen.renderTargets, 0, sizeof(SC_SCREEN_RENDERTARGETS));
	
	//screen.materials = sys_malloc(sizeof(SC_SCREEN_MATERIALS));
	//memset(screen.materials, 0, sizeof(SC_SCREEN_MATERIALS));
	
	sc_settings_setDefaults(screen.settings);

	return screen;
}

void sc_setupScreenquad(SC_SCREEN* screen)
{
	screen.vertexScreenquad[0].x = screen.views.main.size_x - 0.5; screen.vertexScreenquad[0].y = 0.0 - 0.5;// screen.vertexScreenquad[0].color = 0xFFFFFFFF;
   screen.vertexScreenquad[0].u = 1; screen.vertexScreenquad[0].v = 0;
   screen.vertexScreenquad[1].x = 0.0 - 0.5; screen.vertexScreenquad[1].y = 0.0 - 0.5;// screen.vertexScreenquad[1].color = 0xFFFFFFFF;
   screen.vertexScreenquad[1].u = 0.0; screen.vertexScreenquad[1].v = 0;
   screen.vertexScreenquad[2].x = screen.views.main.size_x - 0.5; screen.vertexScreenquad[2].y = screen.views.main.size_y - 0.5;// screen.vertexScreenquad[2].color = 0xFFFFFFFF;
   screen.vertexScreenquad[2].u = 1.0; screen.vertexScreenquad[2].v = 1.0;
   screen.vertexScreenquad[3].x = 0.0 - 0.5; screen.vertexScreenquad[3].y = screen.views.main.size_y - 0.5;// screen.vertexScreenquad[3].color = 0xFFFFFFFF;
   screen.vertexScreenquad[3].u = 0; screen.vertexScreenquad[3].v = 1.0;
   screen.vertexScreenquad[0].z = screen.vertexScreenquad[1].z = screen.vertexScreenquad[2].z = screen.vertexScreenquad[3].z = 0.0; // z buffer - paint over everything
   screen.vertexScreenquad[0].rhw = screen.vertexScreenquad[1].rhw = screen.vertexScreenquad[2].rhw = screen.vertexScreenquad[3].rhw = 1.0; // no perspective
}


void sc_getFrustumPoints(SC_SCREEN* screen)
{
	if(!screen) return 0;
	
	/*
	float Hfar = 2 * tan(fov / 2) * zFar;
	float Wfar = Hfar * ratio;
	
	D3DXVECTOR3 farCenter = mPosition + mLook * zFar;
	
	D3DXVECTOR3 farTopLeft = farCenter + (mUp * Hfar/2) – (mRight * Wfar/2);
	D3DXVECTOR3 farTopRight = farCenter + (mUp * Hfar/2) + (mRight * Wfar/2);
	D3DXVECTOR3 farDownLeft = farCenter – (mUp * Hfar/2) – (mRight * Wfar/2);
	D3DXVECTOR3 farDownRight = farCenter – (mUp * Hfar/2) + (mRight * Wfar/2);
*/
	
	
	/*
	//float fov = 70.0f*(pi/360.0f)*2.0f;
	//float aspect_ratio = 4.0f/3.0f;
	//float fov = screen.views.main.arc*(3.14159265/360.0)*2.0;
	
	float Hfar = 2 * tanv(screen.views.main.arc*0.5) * screen.views.main.clip_far;
	float Wfar = Hfar * (screen.views.main.size_x/screen.views.main.size_y);
	
	VECTOR up;
	//vec_set(up, screen.views.main.x);
	vec_for_angle(up, vector(screen.views.main.pan, screen.views.main.tilt, screen.views.main.roll));
	vec_rotate(up, vector(0, 90, 0));
	VECTOR right;
	//vec_set(right, screen.views.main.x);
	vec_for_angle(right, vector(screen.views.main.pan, screen.views.main.tilt, screen.views.main.roll));
	vec_rotate(right, vector(-90, 0, 0));
	VECTOR up_, right_;
	
	//fc = p + d * farDist
	VECTOR position;
	vec_set(position, screen.views.main.x);
	
	VECTOR normalizedViewDir;
	vec_for_angle(normalizedViewDir, vector(screen.views.main.pan, screen.views.main.tilt, screen.views.main.roll));
	
	vec_scale(normalizedViewDir, screen.views.main.clip_far);
	
	vec_add(position, normalizedViewDir);
	
	VECTOR fc;
	vec_set(fc, position);
	//
	
	//ftl = fc + (up * Hfar/2) - (right * Wfar/2)
	vec_set(up_, up);
	vec_set(right_, right);
	
	VECTOR ftl;
	vec_set(ftl, fc);
	
	vec_scale(up_, Hfar*0.5);
	vec_add(ftl, up_);
	
	vec_scale(right_, Wfar*0.5);
	vec_sub(ftl, right_);
	//
	
	//ftr = fc + (up * Hfar/2) + (right * Wfar/2)
	vec_set(up_, up);
	vec_set(right_, right);
	
	VECTOR ftr;
	vec_set(ftr, fc);
	
	vec_scale(up_, Hfar*0.5);
	vec_add(ftr, up_);
	
	vec_scale(right_, Wfar*0.5);
	vec_add(ftr, right_);
	//
	
	//fbl = fc - (up * Hfar/2) - (right * Wfar/2)
	vec_set(up_, up);
	vec_set(right_, right);
	
	VECTOR fbl;
	vec_set(fbl, fc);
	
	vec_scale(up_, Hfar*0.5);
	vec_sub(fbl, up_);
	
	vec_scale(right_, Wfar*0.5);
	vec_sub(fbl, right_);
	//
	
	//fbr = fc - (up * Hfar/2) + (right * Wfar/2)
	vec_set(up_, up);
	vec_set(right_, right);
	
	VECTOR fbr;
	vec_set(fbr, fc);
	
	vec_scale(up_, Hfar*0.5);
	vec_sub(fbr, up_);
	
	vec_scale(right_, Wfar*0.5);
	vec_add(fbr, right_);
	//
	
	D3DXVECTOR3 tr_;
	D3DXVECTOR3 tl_;
	D3DXVECTOR3 bl_;
	
	tr_.x = ftr.x;
	tr_.y = ftr.z;
	tr_.z = ftr.y;
	
	tl_.x = ftl.x;
	tl_.y = ftl.z;
	tl_.z = ftl.y;

	bl_.x = fbl.x;
	bl_.y = fbl.z;
	bl_.z = fbl.y;
	
	
	//draw_point3d(nullvector, vector(255,0,0), 100, 2);
	//draw_line3d(vector(0,0,1), NULL, 100);
	//draw_line3d(ftl, vector(255,0,0), 100);
	
	D3DXMATRIX _matView;
	D3DXMATRIX _matProj;
	//_matView = sys_malloc(sizeof(D3DXMATRIX));
	//_matProj = sys_malloc(sizeof(D3DXMATRIX));
	view_to_matrix(screen.views.main, _matView, _matProj);
	D3DXVec3Transform(tr_, tr_, _matView);
	D3DXVec3Transform(tl_, tl_, _matView);
	D3DXVec3Transform(bl_, bl_, _matView);
	
	//tr.x = -screen.main.clip_far;
	//tr.y = 0;
	//tr.z = 0;
	ftr.x = tr_.x;
	ftr.y = tr_.y;
	ftr.z = tr_.z;
		
	ftl.x = tl_.x;
	ftl.y = tl_.y;
	ftl.z = tl_.z;
		
	fbl.x = bl_.x;
	fbl.y = bl_.y;
	fbl.z = bl_.z;

	//store frustum points
	screen.frustumPoints.x = ftr.x;
	screen.frustumPoints.y = ftl.x;
	screen.frustumPoints.z = fbl.y;
	screen.frustumPoints.w = ftl.y;
	*/


	
	
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
	//_matView = sys_malloc(sizeof(D3DXMATRIX));
	//_matProj = sys_malloc(sizeof(D3DXMATRIX));
	view_to_matrix(screen.views.main, _matView, _matProj);
	D3DXVec3Transform(tr_, tr_, _matView);
	D3DXVec3Transform(tl_, tl_, _matView);
	D3DXVec3Transform(bl_, bl_, _matView);
			
			
			
	//tr.x = -screen.main.clip_far;
	//tr.y = 0;
	//tr.z = 0;
	tr.x = tr_.x;
	tr.y = tr_.y;
	tr.z = tr_.z;
		
	tl.x = tl_.x;
	tl.y = tl_.y;
	tl.z = tl_.z;
		
	bl.x = bl_.x;
	bl.y = bl_.y;
	bl.z = bl_.z;

	//store frustum points
	screen.frustumPoints.x = tr.x;
	screen.frustumPoints.y = tl.x;
	screen.frustumPoints.z = bl.y;
	screen.frustumPoints.w = tl.y;
	
}


void sc_skill_(ENTITY* ent,int objMode, var objVar)
{	
	VECTOR* objVec;
	BMAP* objMap;
	D3DXMATRIX* objMtx;
	VIEW* objView;
	if(objMode == 0){return;}
	
	SC_OBJECT* myData;// = sys_malloc(sizeof(SC_OBJECT));

	if(ent)
	{
		if(ent.SC_SKILL) //check if my.skill99 has already been set
		{	
			//restore data that is already there
			//SC_OBJECT* ObjData = (SC_OBJECT*)(my->skill99);
			//myData = ObjData;
			myData = (SC_OBJECT*)(ent.SC_SKILL);
		}
		
		else //if there is no data, write default null data
		{
			myData = sys_malloc(sizeof(SC_OBJECT));
			memset(myData,0,sizeof(SC_OBJECT));
			
			myData.light = sys_malloc(sizeof(SC_OBJECT_LIGHT));
			memset(myData.light, 0, sizeof(SC_OBJECT_LIGHT));
			
			myData.data = sys_malloc(sizeof(SC_OBJECT_DATA));
			memset(myData.data, 0, sizeof(SC_OBJECT_DATA)); 
			
			//light data
			myData->light.dir.x = 0;
			myData->light.dir.y = 0;
			myData->light.dir.z = 0;
   		myData->light.color.x = 2;
   		myData->light.color.y = 2;
   		myData->light.color.z = 2;
   		myData->light.range = 0;
   		myData->light.clipRange = sc_lights_defaultClipRange;
   		myData->light.arc = 0;
			myData->light.projMap = NULL;
			myData->light.shadowMap = NULL;
			myData->light.view = NULL;
			//myData->light.material = NULL;
			myData->light.matrix = NULL;
			myData->light.stencilRef = 0;
			//myData->light.lightModelMap = (var)sc_volumeTexture_create("sc_deferredLighting_equations.dds");
				
			//material
			myData->material.id = (float)1/(float)255;
				
			//data
			myData->data->data1.x = 1;
			myData->data->data1.y = 1;
			myData->data->data1.z = 1;
			myData->data->data1.w = 1;
			myData->data->data2.x = 1;
			myData->data->data2.y = 1;
			myData->data->data2.z = 1;
			myData->data->data2.w = 1;
			myData->data->data3.x = 1;
			myData->data->data3.y = 1;
			myData->data->data3.z = 1;
			myData->data->data3.w = 1;
			
			//general data
			myData->depth = 0;
			myData->shadowBias = 0;
			myData->castShadow = 3;
			myData->pass = SC_PASS_GBUFFER;
			myData->emissive.x = 0;
			myData->emissive.y = 0;
			myData->emissive.z = 0;
			myData->emissive.w = 0;
			myData->color.x = 0;
			myData->color.y = 0;
			myData->color.z = 0;
			myData->color.w = 0;
		}
	}
	
	//LIGHT
	if(objMode == SC_OBJECT_LIGHT_DIR){
		objVec = objVar;
		myData->light.dir.x = objVec.x;
		myData->light.dir.y = objVec.y;
		myData->light.dir.z = objVec.z;
	}
	
	if(objMode == SC_OBJECT_LIGHT_COLOR){
		objVec = objVar;
		myData->light.color.x = objVec.x/128;
		myData->light.color.y = objVec.y/128;
		myData->light.color.z = objVec.z/128;
	}
	
	if(objMode == SC_OBJECT_LIGHT_RANGE){
		myData->light.range = objVar;
	}
	
	if(objMode == SC_OBJECT_LIGHT_CLIPRANGE){
		myData->light.clipRange = objVar;
	}
	
	if(objMode == SC_OBJECT_LIGHT_ARC){
		myData->light.arc = objVar;
	}
	
	if(objMode == SC_OBJECT_LIGHT_PROJMAP){
		objMap = objVar;
		myData->light.projMap = objMap;
	}
	
	if(objMode == SC_OBJECT_LIGHT_SHADOWMAP){
		objMap = objVar;
		myData->light.shadowMap = objMap;
	}
	
	if(objMode == SC_OBJECT_LIGHT_VIEW){
		objView = objVar;
		myData->light.view = objView;
	}
	
	if(objMode == SC_OBJECT_LIGHT_MATRIX){
		objMtx = (D3DXMATRIX*)objVar;
		if(myData->light.matrix == NULL) myData->light.matrix = sys_malloc(sizeof(D3DXMATRIX));
		mat_set(myData->light.matrix, objMtx);
	}
	
	if(objMode == SC_OBJECT_LIGHT_STENCILREF){
		myData->light.stencilRef = (int)objVar;
	}
	
	//MATERIAL
	if(objMode == SC_OBJECT_MATERIAL_ID){
		myData->material.id = (float)objVar/(float)255;
	}
	
	//DATA
	
	if(objMode == SC_OBJECT_DATA_1_X){
		myData->data->data1.x = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_1_Y){
		myData->data->data1.y = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_1_Z){
		myData->data->data1.z = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_1_W){
		myData->data->data1.w = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_2_X){
		myData->data->data2.x = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_2_Y){
		myData->data->data2.y = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_2_Z){
		myData->data->data2.z = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_2_W){
		myData->data->data2.w = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_3_X){
		myData->data->data3.x = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_3_Y){
		myData->data->data3.y = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_3_Z){
		myData->data->data3.z = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_3_W){
		myData->data->data3.w = (float)objVar;
	}
	if(objMode == SC_OBJECT_DATA_1){
		objVec = (VECTOR*)objVar;
		myData->data->data1.x = (float)objVec.x;
		myData->data->data1.y = (float)objVec.y;
		myData->data->data1.z = (float)objVec.z;
	}
	if(objMode == SC_OBJECT_DATA_2){
		objVec = (VECTOR*)objVar;
		myData->data->data2.x = (float)objVec.x;
		myData->data->data2.y = (float)objVec.y;
		myData->data->data2.z = (float)objVec.z;
	}
	if(objMode == SC_OBJECT_DATA_3){
		objVec = (VECTOR*)objVar;
		myData->data->data3.x = (float)objVec.x;
		myData->data->data3.y = (float)objVec.y;
		myData->data->data3.z = (float)objVec.z;
	}
	
	//GENERAL
	if(objMode == SC_OBJECT_SHADOWBIAS){
		myData->shadowBias = objVar*0.0001;
	}
	
	if(objMode == SC_OBJECT_DEPTH){
		myData->depth = objVar;
	}
	
	if(objMode == SC_OBJECT_CASTSHADOW){
		myData->castShadow = objVar;
	}
	
	if(objMode == SC_OBJECT_PASS){
		myData->pass = objVar;
	}
	
	if(objMode == SC_OBJECT_EMISSIVE){
		objVec = (VECTOR*)objVar;
		myData->emissive.x = (float)objVec.x/255;
		myData->emissive.y = (float)objVec.y/255;
		myData->emissive.z = (float)objVec.z/255;
	}
	
	if(objMode == SC_OBJECT_COLOR){
		objVec = (VECTOR*)objVar;
		myData->color.x = (float)objVec.x/255;
		myData->color.y = (float)objVec.y/255;
		myData->color.z = (float)objVec.z/255;
	}
	
	ent->SC_SKILL = myData;
}

void sc_material(ENTITY* ent,int objMode, MATERIAL* mat)
{	
	//SC_OBJECT* myData = sys_malloc(sizeof(SC_OBJECT));
	SC_OBJECT* myData;

	if(ent)
	{
		if(ent.SC_SKILL) //check if my.skill99 has already been set
		{	
			//restore data that is already there
			//SC_OBJECT* ObjData = (SC_OBJECT*)(my->skill99);
			//myData = ObjData;
			myData = (SC_OBJECT*)(ent.SC_SKILL);
		}
		
		else //if there is no data, write default null data
		{
			myData = sys_malloc(sizeof(SC_OBJECT));
			memset(myData,0,sizeof(SC_OBJECT));
			
			myData.light = sys_malloc(sizeof(SC_OBJECT_LIGHT));
			memset(myData.light, 0, sizeof(SC_OBJECT_LIGHT));
			
			myData.data = sys_malloc(sizeof(SC_OBJECT_DATA));
			memset(myData.data, 0, sizeof(SC_OBJECT_DATA)); 
			
			//light data
			myData->light.dir.x = 0;
			myData->light.dir.y = 0;
			myData->light.dir.z = 0;
   		myData->light.color.x = 2;
   		myData->light.color.y = 2;
   		myData->light.color.z = 2;
   		myData->light.range = 0;
   		myData->light.clipRange = sc_lights_defaultClipRange;
   		myData->light.arc = 0;
			myData->light.projMap = NULL;
			myData->light.shadowMap = NULL;
			myData->light.view = NULL;
			//myData->light.material = NULL;
			myData->light.matrix = NULL;
			myData->light.stencilRef = 0;
			//myData->light.lightModelMap = (var)sc_volumeTexture_create("sc_deferredLighting_equations.dds");
				
			//material
			myData->material.id = (float)1/(float)255;
				
			//data
			myData->data->data1.x = 1;
			myData->data->data1.y = 1;
			myData->data->data1.z = 1;
			myData->data->data1.w = 1;
			myData->data->data2.x = 1;
			myData->data->data2.y = 1;
			myData->data->data2.z = 1;
			myData->data->data2.w = 1;
			myData->data->data3.x = 1;
			myData->data->data3.y = 1;
			myData->data->data3.z = 1;
			myData->data->data3.w = 1;
			
			//general data
			myData->depth = 0;
			myData->shadowBias = 0;
			myData->castShadow = 3;
			myData->pass = SC_PASS_GBUFFER;
			myData->emissive.x = 0;
			myData->emissive.y = 0;
			myData->emissive.z = 0;
			myData->emissive.w = 0;
			myData->color.x = 0;
			myData->color.y = 0;
			myData->color.z = 0;
			myData->color.w = 0;
		}
	}
	
	/*
	if(objMode == SC_MATREFRACT)
	{
		ent.material = sc_refract_mtl;
		myData->myMatRefract = mat;
	}
	if(objMode == SC_MATSHADOW)
	{
		myData->myMatShadow = mat;
	}
	
	if(objMode == SC_MATERIAL_GBUFFER)
	{
		myData->materials.gBuffer = mat;
	}
	if(objMode == SC_MATERIAL_LIGHT)
	{
		//ent.material = sc_lights_material;
		//myData->light.material = mat;
		
		ent->material = mat;
		//ent->material->flags = ENABLE_RENDER;
		//ent->material->event = sc_materials_event;
	}
	*/
	if(objMode == SC_MATERIAL_LIGHT_SHADOWMAP)
	{
		myData->light.materialShadowmap = mat;
	}
	/*
	if(objMode == SC_MATPARTICLE)
	{
		myData->myMatParticle = mat;
	}
	*/
	
	ent->SC_SKILL = myData;
}


void sc_sky(ENTITY* ent)
{
	//sc_skill(ent,SC_MYREFRACT,3);
	//sc_skill(ent,SC_MYDEPTH,1);
	//sc_skill(ent, SC_OBJECT_PASS, SC_PASS_FORWARD);
	//sc_skill(ent, SC_OBJECT_DEPTH, 1);
	ent.material = sc_material_sky;
}
