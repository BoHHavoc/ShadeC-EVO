/***************************************************************************

Basic Example on how to setup Shade-C

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

void main()
{
	d3d_triplebuffer = 1; //don't let the gpu wait for data
	level_load(NULL);
	wait(3);
	
	//create a camera object so we can move around the scene
	you = ent_create(NULL, nullvector, v_camera);
	you.pan = 211;
	you.tilt = 21;
	camera.arc = 75;
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	video_set(1280, 720, 0, 2);
	
	//set fog
	fog_color=1;
	d3d_fogcolor1.red=5;
	d3d_fogcolor1.green=5;
	d3d_fogcolor1.blue=10;
	camera.fog_start=100;
	camera.fog_end=1000;
	
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
	
	while(1) {
		sc_screen_default.settings.hdr.intensity += time_step*0.01;
		if( sc_screen_default.settings.hdr.intensity > 1) sc_screen_default.settings.hdr.intensity = 0;
		
		wait(1);
	}
}