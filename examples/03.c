/***************************************************************************

Basic Example on how to use terrains

NOT FNISHED YET!!! DONT USE!!!

***************************************************************************/

#include <litec.h>
#include <acknex.h>
#include <default.c>

//#define DEBUG_PSSM

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
	shadow_stencil = -1; //turn off all engine intern shadow calculations. THIS IS IMPORTANT!
	level_load("");
	wait(5); //wait for level load
	//set suncolor to zero (setting sun_color in WED to zero does NOTHING! This is a bug in gamestudio)
	//if suncolor == 0, sun will not be rendered. Set this for pure indoor scenes to boost performance!
	vec_set(sun_color, vector(0,0,0)); 
	//vec_set(sun_color, vector(155,140,130)); 
	//set ambient color to zero as we want a dark level with nice shadows ;)
	//vec_set(ambient_color, vector(0,0,0));
	//vec_set(ambient_color, vector(180,180,180));
		
	//create a camera object so we can move around the scene
	you = ent_create(NULL, vector(168,-478, 212), v_camera);
	you.pan = 123;
	you.tilt = -18;
	camera.arc = 75;
	/*you = ent_create(NULL, vector(-224,-317, 119), v_camera);
	you.pan = 138;
	you.tilt = -44;
	camera.arc = 75;*/
	camera.clip_far = 5000; //set this as low as possible to increase performance AND visuals!
	
	//load terrain
	you = ent_create("terrain01.mdl", nullvector, NULL);
	sc_ent_terrain(you, "assets/terrainTextures/terrainAtlas01.dds");
	set(you, SHADOW);
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	//video_set(1280, 720, 0, 2);
	video_set(800, 600, 0, 2);
	
	//setup skies
	sc_sky(skycube);
	
	//set camera as main view of sc_screen_default
	sc_screen_default = sc_screen_create(camera);
	
	//enable/disable Shade-C effects. You have to set these before calling sc_setup()
	//If you want to change these during runtime, simply call sc_setup() again after you enabled/disabled an effect
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.forward.enabled = 0; //enable if you need particles or custom materials which can't be rendered in the deferred pipeline
	sc_screen_default.settings.refract.enabled = 0; //enable for refractive effects such as heat haze and glass
	sc_screen_default.settings.hdr.enabled = 0; //enable Bloom/HDR
	sc_screen_default.settings.hdr.lensflare.enabled = 1; //enable for a nice lensflare effect in combination with HDR/Bloom
	sc_screen_default.settings.dof.enabled = 0; //enable Depth of Field Effect
	sc_screen_default.settings.ssao.enabled = 0; //enable to activate SSAO
	sc_screen_default.settings.lights.sunShadows = 0; //enable shadows for the sun
	sc_screen_default.settings.lights.sunShadowResolution = 256; //reduce shadow resolution as we are blurring the shadowmap and therefore can get away with low res shadows
	sc_screen_default.settings.lights.sunPssmBlurSplits = 2; //blur the first two pssm splits
	sc_screen_default.settings.lights.sunPssmSplitWeight = 0.7; //high res near splits, low res far splits
	
	
	//initialize shade-c, use default screen object
	sc_setup(sc_screen_default);
	//wait(3); //wait for Shade-C
	
	//tweak effect parameters anytime you want
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.hdr.brightpass = 0.65;
	sc_screen_default.settings.hdr.intensity = 1.0;
	sc_screen_default.settings.hdr.lensflare.brightpass = 0.0;
	sc_screen_default.settings.hdr.lensflare.intensity = 0.5;
	sc_screen_default.settings.dof.focalPos = 300;
	sc_screen_default.settings.dof.focalWidth = 600;
	sc_screen_default.settings.ssao.radius = 25;	
	sc_screen_default.settings.ssao.intensity = 5;
	sc_screen_default.settings.ssao.selfOcclusion = 0.0004; //we want a bit of self occlusion... lower values result in even more self occlusion
	
	/*
	while(1)
  {
    sun_angle.pan += time_frame; 
    sun_angle.pan %= 360; 
    sun_angle.tilt = fsin(sun_angle.pan, 45) + 45;
    sun_light = sun_angle.tilt;
    wait(1);
  }
  */
}