#define PRAGMA_PATH "fx"
#define PRAGMA_PATH "assets"
#define PRAGMA_PATH "assets\vloga"
#define PRAGMA_PATH "assets\byNobiax"


//WED helper functions
action a_spotlight()
{
	//return;
	//if(is(my,FLAG1)) sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT | SC_LIGHT_SHADOW , vector(my.pan, my.tilt, my.roll), my.skill5);
	//sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT, vector(my.pan, my.tilt, my.roll), my.skill5);
	
	sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT | SC_LIGHT_SHADOW , vector(my.pan, my.tilt, my.roll), my.skill5);
	
	ent_remove(my);
}

MATERIAL* mtl_car =
{
	effect = "car.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 200;
}
MATERIAL* mtl_metal2 = //mtl_metal2 because mtl_metal is already taken by gamestudio!
{
	effect = "metal2.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 100;
}
MATERIAL* mtl_stone =
{
	effect = "stone.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 5;
}

MATERIAL* mtl_wood =
{
	effect = "wood.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 5;
}

MATERIAL* mtl_levelDefault = 
{
	effect = "levelDefault.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
}

MATERIAL* mtl_levelDefaultNM = 
{
	effect = "levelDefaultNM.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 5;
}