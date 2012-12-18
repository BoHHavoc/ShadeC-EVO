/***************************************************************************

Basic Example on how to use lights and materials


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
	level_load("02.wmb");
	wait(5); //wait for level load
	//set suncolor to zero (setting sun_color in WED to zero does NOTHING! This is a bug in gamestudio)
	//if suncolor == 0, sun will not be rendered. Set this for pure indoor scenes to boost performance!
	//vec_set(sun_color, vector(0,0,0)); 
	vec_set(sun_color, vector(255,240,230)); 
	//set ambient color to zero as we want a dark level with nice shadows ;)
	//vec_set(ambient_color, vector(0,0,0));
	vec_set(ambient_color, vector(32,32,32));
	//vec_set(ambient_color, vector(180,180,180));
		
	//create a camera object so we can move around the scene
	you = ent_create(NULL, vector(168,-478, 212), v_camera);
	you.pan = 123;
	you.tilt = -18;
	camera.arc = 75;
	camera.clip_far = 5000; //set this as low as possible to increase performance AND visuals!
	
	//mtl_particle = myMtl_particle;
	
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
	sc_screen_default.settings.ssao.quality = SC_LOW; //set ssao quality. SC_LOW, SC_MEDIUM, SC_HIGH, SC_ULTRA
	sc_screen_default.settings.ssao.enabled = 1; //enable to activate SSAO
	
	sc_screen_default.settings.lights.sunShadows = 1; //enable shadows for the sun
	sc_screen_default.settings.lights.sunShadowResolution = 512; //reduce shadow resolution as we are manually setting the shadow range to 5000 and can therefor get away with a small shadowmap
	sc_screen_default.settings.lights.sunPssmSplitWeight = 0.7; //high res near splits, low res far splits
	sc_screen_default.settings.lights.sunShadowRange = 5000; //manually set the shadow range...we don't need realtime shadows in the far distant! If set to 0 (default) shadow range will be set to camera.clip_far
	sc_screen_default.settings.lights.sunShadowBias = 0.001; //manually set the shadow bias
	sc_screen_default.settings.antialiasing.enabled = 1; //enable antialiasing
		
	//initialize shade-c, use default screen object
	sc_setup(sc_screen_default);
	
	//tweak effect parameters anytime you want
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.hdr.brightpass = 0.85;
	sc_screen_default.settings.hdr.intensity = 2;
	sc_screen_default.settings.hdr.lensflare.brightpass = 0.0;
	sc_screen_default.settings.hdr.lensflare.intensity = 0.25;
	sc_screen_default.settings.dof.focalPos = 300;
	sc_screen_default.settings.dof.focalWidth = 600;
	sc_screen_default.settings.ssao.radius = 30;	
	sc_screen_default.settings.ssao.intensity = 4;
	sc_screen_default.settings.ssao.selfOcclusion = 0.0004; //we want a bit of self occlusion... lower values result in even more self occlusion
	sc_screen_default.settings.ssao.brightOcclusion = 0.25; //low value: ssao will only be visible in shadows and dark areas. high value: ssao will always be visible. Range: 0-1
	
	
	//create a spotlight which we will rotate later
	//please note that the light's red color value is above 255, which makes this an hdr light
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
   	
	   wait(1);
  }
  
}