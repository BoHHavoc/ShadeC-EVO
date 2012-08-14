/***************************************************************************

Basic Example on how to setup Shade-C

***************************************************************************/

#include <litec.h>
#include <acknex.h>
#include <default.c>

//include Shade-C
#define PRAGMA_PATH "shadec"
#include "shade-c.h"


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
	level_load(NULL);
	wait(3);
	
	//create a camera object so we can move around the scene
	you = ent_create(NULL, nullvector, v_camera);
	you.pan = 211;
	you.tilt = 21;
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	video_set(1280, 720, 0, 2);
	
	//setup skies
	sc_sky(skycube);
	
	//set camera sizes (this is only needed if you use "camera" as main view due to a bug in Acknex)
	camera.size_x = screen_size.x;
	camera.size_y = screen_size.y;
	//set camera as main view of sc_screen_default
	sc_screen_default = sc_screen_create(camera);
	
	//enable/disable Shade-C effects. You have to set these before calling sc_setup()
	//If you want to change these during runtime, simply call sc_setup() again after you enabled/disabled an effect
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.forward.enabled = 1; //enable if you need particles or custom materials which can't be rendered in the deferred pipeline
	sc_screen_default.settings.refract.enabled = 1; //enable for refractive effects such as heat haze and glass
	sc_screen_default.settings.hdr.enabled = 1; //enable Bloom/HDR
	sc_screen_default.settings.hdr.lensflare.enabled = 1; //enable for a nice lensflare effect in combination with HDR/Bloom
	sc_screen_default.settings.dof.enabled = 0; //enable Depth of Field Effect
	sc_screen_default.settings.ssao.enabled = 0; //enable to activate SSAO
	
	//initialize shade-c, use default screen object
	sc_setup(sc_screen_default);
	
	//tweak effect parameters anytime you want
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.hdr.lensflare.brightpass = 0.2;
	sc_screen_default.settings.hdr.lensflare.intensity = 0.8;
	
	while(1) {
		sc_screen_default.settings.hdr.intensity += time_step*0.01;
		if( sc_screen_default.settings.hdr.intensity > 1) sc_screen_default.settings.hdr.intensity = 0;
		
		wait(1);
	}
}