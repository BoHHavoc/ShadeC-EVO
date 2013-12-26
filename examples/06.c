/***************************************************************************

Basic Example on how to setup and use transparent materials/objects


***************************************************************************/

#include <litec.h>
#include <acknex.h>
#include <default.c>

//include Shade-C
#define PRAGMA_PATH "shadec"
#include "shade-c.h"

#include "common.h"


ENTITY* skycube =
{
  type = "plain_abraham+6.tga";
  flags2 = SKY | CUBE | SHOW;
  red = 130;
  green = 130;
  blue = 130;
}

//simple camera script...
void v_camera()
{
	set(my,INVISIBLE);
	set(my,PASSABLE);
	while(1)
	{
		c_move(my,vector(key_force.y*25*time_step,-key_force.x*25*time_step,0),nullvector,IGNORE_PASSABLE);
		my.pan -= mickey.x;
		my.tilt -= mickey.y;
		
		vec_set(camera.x,my.x);
		vec_set(camera.pan,my.pan);

		wait(1);
	}
}

//this is attached to the car's windows in 06.wmb
//have a look at 06_transparent.fx to see how transparency is done
MATERIAL* mtl_carWindow =
{
	effect = "06_transparent.fx";
	flags = ENABLE_RENDER;
	event = sc_materials_event;
	
	power = 200;
}


void main()
{	
	shadow_stencil = -1; //turn off all engine intern shadow calculations. THIS IS IMPORTANT!
	level_load("02.wmb");
	wait(5); //wait for level load
	//set suncolor to zero (setting sun_color in WED to zero does NOTHING! This is a bug in gamestudio)
	//if suncolor == 0, sun will not be rendered. Set this for pure indoor scenes to boost performance!
	//vec_set(sun_color, vector(0,0,0)); 
	vec_set(sun_color, vector(255,240,230)); 
	//set ambient color to zero as we want a dark level with nice shadows ;)
	//vec_set(ambient_color, vector(0,0,0));
	vec_set(ambient_color, vector(90,90,90));
	//vec_set(ambient_color, vector(180,180,180));
		
	//create a camera object so we can move around the scene
	you = ent_create(NULL, vector(168,-478, 212), v_camera);
	you.pan = 123;
	you.tilt = -18;
	camera.arc = 75;
	camera.clip_far = 50000; //set this as low as possible to increase performance AND visuals!
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	//video_set(1280, 720, 0, 2);
	video_set(800, 600, 0, 2);
	
	//set fog
	fog_color=1;
	d3d_fogcolor1.red=160;
	d3d_fogcolor1.green=200;
	d3d_fogcolor1.blue=220;
	camera.fog_start=500;
	camera.fog_end=1500;
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	//video_set(1280, 720, 0, 2);
	video_set(800, 600, 0, 2);
	
	//setup skies
	sc_sky(skycube);
	
	//create shade-c stuff - open sc_wrapper.c to edit settings in function "sc_get_settings"
	//SHADEC_LOW
	//SHADEC_MEDIUM
	//SHADEC_HIGH
	//SHADEC_ULTRA
	sc_create(SHADEC_ULTRA);
	
	
	you = ent_create(SPHERE_MDL, vector(150,-360,58), NULL);
	you.material = mtl_car;
	vec_scale(you.scale_x, 10);
	set(you, SHADOW);
	
	
	
	
	
	//create a spotlight which we will rotate later
	//please note that the light's red color value is above 255, which automatically makes this an hdr light
	ENTITY* spotlight = sc_light_create(vector(-86,-82,322), 1000, vector(1024,512,0), SC_LIGHT_SPOT | SC_LIGHT_SHADOW);
	//set initial rotation
	spotlight.pan = 188;
	spotlight.tilt = -43;
	//update the spotlight as we changed its rotation
	sc_light_update(spotlight); 
	
	while(1)
	{
		
//		//move the sun around the scene
//		sun_angle.pan += time_frame; 
//		sun_angle.pan %= 360; 
//   	sun_angle.tilt = fsin(sun_angle.pan, 45) + 45;
//   	//set the sunlight brightness
//   	sun_light = sun_angle.tilt;
   	
   	
   	
   	//rotate the spotlight
   	spotlight.pan += time_step*5;
   	//update the spotlight
   	sc_light_update(spotlight);
   	
   	
   	//DEBUG_BMAP(sc_screen_default.renderTargets.gBuffer[0],0,1);
   	
	   wait(1);
  }
  
}