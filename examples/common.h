#define PRAGMA_PATH "fx"
#define PRAGMA_PATH "assets"
#define PRAGMA_PATH "assets\vloga"
#define PRAGMA_PATH "assets\concrete_barrier"


//WED helper functions
action a_spotlight()
{
	//if(is(my,FLAG1)) sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT | SC_LIGHT_SHADOW , vector(my.pan, my.tilt, my.roll), my.skill5);
	//sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT, vector(my.pan, my.tilt, my.roll), my.skill5);
	
	sc_light_create(vector(my.x, my.y, my.z), my.skill4, vector(my.skill1,my.skill2,my.skill3), SC_LIGHT_SPOT | SC_LIGHT_SHADOW , vector(my.pan, my.tilt, my.roll), my.skill5);
	
	ent_remove(my);
}


MATERIAL* mtl_concrete =
{
	effect = "concrete.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 5;
}

MATERIAL* mtl_vloga =
{
	effect = "vloga.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 200;
}

MATERIAL* mtl_levelDefault = 
{
	effect = "levelDefault.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
}