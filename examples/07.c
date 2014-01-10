/***************************************************************************

Basic Example on how to use fog


***************************************************************************/

#include <litec.h>
#include <acknex.h>
#include <default.c>

//include Shade-C
#define PRAGMA_PATH "shadec"
#include "shade-c.h"

#include "common.h"

#include <keys.c>

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
	camera.clip_far = 5000; //set this as low as possible to increase performance AND visuals!
	
	//set resolution before calling sc_setup
	//if you want to change resolution again, simple call sc_setup() again after you changed the resolution
	//video_set(1280, 720, 0, 2);
	video_set(800, 600, 0, 2);
	
	//setup skies
	sc_sky(skycube);
	

	//set camera as main view of sc_screen_default
	sc_screen_default = sc_screen_create(camera);
	
	
	//FOG
	fog_color=1;
	d3d_fogcolor1.red=200;
	d3d_fogcolor1.green=240;
	d3d_fogcolor1.blue=255;
	camera.fog_start=100;
	camera.fog_end=500;
	//turn on shade-c's height based fog (for 100% fog set both values very high (default: 9999990 & 9999999)
	sc_screen_default.settings.fogData.x = 10; //height fog start
	sc_screen_default.settings.fogData.y = 200; //height fog end
	//to attach the fog ground plane to the camera, call this in a while loop
	//sc_screen_default.settings.heightFog.x = camera.y; //height fog start
	//sc_screen_default.settings.heightFog.y = 500 + camera.y; //height fog end
	//You can also apply noise to the fog, to give it a more volumetric look. Setting fogNoise to NULL disables the noise effect
	sc_screen_default.settings.fogNoise = bmap_create("sc_noise00.tga");
	//Scale of the noise texture
	sc_screen_default.settings.fogNoiseScale = 6;
	//If noise if activated, you can set the speed of it's movement
	sc_screen_default.settings.fogData.z = 5;
	sc_screen_default.settings.fogData.w = -2;
	
	//enable/disable Shade-C effects. You have to set these before calling sc_setup()
	//If you want to change these during runtime, simply call sc_setup() again after you enabled/disabled an effect
	// -> more info in sc_core.h, in struct SC_SETTINGS
	
	sc_screen_default.settings.forward.enabled = 0; //enable if you need particles or custom materials which can't be rendered in the deferred pipeline
	sc_screen_default.settings.refract.enabled = 0; //enable for refractive effects such as heat haze and glass
	sc_screen_default.settings.hdr.enabled = 1; //enable Bloom/HDR
	sc_screen_default.settings.hdr.lensflare.enabled = 1; //enable for a nice lensflare effect in combination with HDR/Bloom
	sc_screen_default.settings.dof.enabled = 0; //enable Depth of Field Effect
	sc_screen_default.settings.ssao.quality = SC_MEDIUM; //set ssao quality. SC_LOW, SC_MEDIUM, SC_HIGH, SC_ULTRA
	sc_screen_default.settings.ssao.enabled = 1; //enable to activate SSAO
	sc_screen_default.settings.lights.sunShadows = 1; //enable shadows for the sun
	sc_screen_default.settings.lights.sunShadowResolution = 512; //reduce shadow resolution as we are manually setting the shadow range to 5000 and can therefor get away with a small shadowmap
	sc_screen_default.settings.lights.sunPssmSplitWeight = 0.7; //high res near splits, low res far splits
	sc_screen_default.settings.lights.sunShadowRange = 5000; //manually set the shadow range...we don't need realtime shadows in the far distant! If set to 0 (default) shadow range will be set to camera.clip_far
	sc_screen_default.settings.lights.sunShadowBias = 0.001; //set the shadow bias
	sc_screen_default.settings.antialiasing.enabled = 1; //enable antialiasing
	sc_screen_default.settings.bitdepthGBuffer = 32; //8 bit g-buffer (default). change to 12222 or 14444 for 16bit/32bit g-buffer which might result in nicer lighting at the cost of performance
	sc_screen_default.settings.bitdepthLBuffer = 32; //8 bit lighting (default). change to 12222 or 14444 for 16bit/32bit lighting buffer which results in nicer lighting at the cost of performance
	sc_screen_default.settings.bitdepthGRTs = 32; //8 bit generic rendertargets (default). change to 12222 or 14444 for 16bit/32bit generic rendertargets
	
	//initialize shade-c, use default screen object
	sc_setup(sc_screen_default);
	
	//tweak effect parameters anytime you want
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.hdr.brightpass = 0.85;
	sc_screen_default.settings.hdr.intensity = 1;
	sc_screen_default.settings.hdr.lensflare.brightpass = 0.0;
	sc_screen_default.settings.hdr.lensflare.intensity = 0.25;
	sc_screen_default.settings.dof.focalPos = 700;
	sc_screen_default.settings.dof.focalWidth = 300;
	//sc_screen_default.settings.dof.blurX = 1;
	//sc_screen_default.settings.dof.blurY = 1.5;
	sc_screen_default.settings.ssao.radius = 30;	
	sc_screen_default.settings.ssao.intensity = 4;
	sc_screen_default.settings.ssao.selfOcclusion = 0.0004; //we want a bit of self occlusion... lower values result in even more self occlusion
	sc_screen_default.settings.ssao.brightOcclusion = 0.25; //low value: ssao will only be visible in shadows and dark areas. high value: ssao will always be visible. Range: 0-1
	
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
   	
   	if(key_hit(16))
   	{
   		sc_setup(sc_screen_default);
   	}
   	//DEBUG_BMAP(sc_screen_default.views.sunShadowDepth[0].bmap, 0, 0.5);
   	//DEBUG_BMAP(sc_screen_default.settings.fogNoise, 0, 0.5);
   	
	   wait(1);
  }
  
  
}