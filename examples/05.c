/***************************************************************************

Basic Example on how to use write and use custom materials/shaders

***************************************************************************/

#include <litec.h>
#include <acknex.h>
#include <default.c>

//#define DEBUG_PSSM

//include Shade-C
#define PRAGMA_PATH "shadec"
#include "shade-c.h"

#include "common.h"


void setupMaterial()
{
	//convert skills to floats so they can be used in the shader
	mtl.skill1 = floatv(mtl.skill1);
	mtl.skill2 = floatv(mtl.skill2);
	mtl.skill3 = floatv(mtl.skill3);
	mtl.skill4 = floatv(mtl.skill4);
	
	
	//after setting everything up, switch to Shade-C's material event.
	// !! THIS IS IMPORTANT !!
	mtl.flags = ENABLE_RENDER;
	mtl.event = sc_materials_event; 
}

MATERIAL* mtlTexMove =
{
	//this effect adds texture movement
	effect = "05_animatedTexture.fx";
	flags = ENABLE_RENDER;
	event = setupMaterial;
	skill1 = 0.1; //texture movement speed in x direction
	skill2 = 0.8; //texture movement speed in y direction
	
	power = 25;
}

MATERIAL* mtlLivingBloom =
{
	//this effects moves the vertexes of the model around
	//it also adds the whole model to the emissive buffer, which will make the object glow
	effect = "05_livingBloom.fx";
	flags = ENABLE_RENDER;
	event = setupMaterial;
	skill1 = 0.25; // x vertex movement strength
	skill2 = 0.25; // y vertex movement strength
	skill3 = 0.1; // movement speed
	skill4 = 0.1; // glow strength
	
	power = 25;
	
}
MATERIAL* mtlLivingBloomShadow =
{
	//this effect does the same as the effect above, but this time its for the shadowmap shader
	effect = "05_livingBloomShadow.fx";
}

MATERIAL* mtlDissolve =
{
	//this effect dissolves/desintegrates the object
	//it also adds emissive color to parts where desintegration will occur next
	effect = "05_dissolve.fx";
	flags = ENABLE_RENDER;
	event = setupMaterial;
	skill1 = 10; //dissolve value, the lower this gets, the more of the object will be dissolved
	skill2 = 1; //emissive color red
	skill3 = 0.5; //emissive color green
	skill4 = 0.25; //emissive color blue
	
	power = 25;
}
MATERIAL* mtlDissolveShadow =
{
	//this effect does the same as the effect above, but this time its for the shadowmap shader
	effect = "05_dissolveShadow.fx";
}



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
	level_load("05.wmb");
	wait(3); //wait for level load
	//set suncolor to zero (setting sun_color in WED to zero does NOTHING! This is a bug in gamestudio)
	//if suncolor == 0, sun will not be rendered. Set this for pure indoor scenes to boost performance!
	vec_set(sun_color, vector(0,0,0)); 
	//vec_set(sun_color, vector(255,240,230)); 
	//set ambient color to zero as we want a dark level with nice shadows ;)
	vec_set(ambient_color, vector(0,0,0));
	//vec_set(ambient_color, vector(96,96,96));

	//create a camera object so we can move around the scene
	you = ent_create(NULL, vector(-800,0, 200), v_camera);
	you.tilt = -10;
	camera.clip_far = 5000; //set this as low as possible to increase performance AND visuals!
	
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
	sc_screen_default.settings.hdr.enabled = 1; //enable Bloom/HDR
		
	//initialize shade-c, use default screen object
	sc_setup(sc_screen_default);
	
	//tweak effect parameters anytime you want
	// -> more info in sc_core.h, in struct SC_SETTINGS
	sc_screen_default.settings.hdr.brightpass = 0.85;
	sc_screen_default.settings.hdr.intensity = 2;
	sc_screen_default.settings.hdr.lensflare.brightpass = 0.0;
	sc_screen_default.settings.hdr.lensflare.intensity = 0.25;
	
	
	
	
	//Add objects and apply custom materials
	//Texture Movement
	you = ent_create("vloga.mdl", vector(-200,0,60), NULL);
	vec_scale(you.scale_x, 0.5);
	you.material = mtlTexMove;
	set(you, SHADOW);
	
	//Living Bloom Thingy
	you = ent_create("vloga.mdl", vector(200,-300,60), NULL);
	vec_scale(you.scale_x, 0.5);
	you.material = mtlLivingBloom;
	set(you, SHADOW);
	//we have to set a custom shadowmap shader for this object, as the object's vertices are changed by the living bloom shader
	sc_skill(you, SC_OBJECT_MATERIAL_SHADOWMAP, mtlLivingBloomShadow);
	
	//Dissolve
	ENTITY* dissolveObject = ent_create("vloga.mdl", vector(0,200,60), NULL);
	vec_scale(dissolveObject.scale_x, 0.5);
	dissolveObject.material = mtlDissolve;
	set(dissolveObject, SHADOW);
	//we have to set a custom shadowmap shader for this object, as the object's alpha is changed by the dissolve shader
	sc_skill(dissolveObject, SC_OBJECT_MATERIAL_SHADOWMAP, mtlDissolveShadow);
	dissolveObject.skill1 = 4; //this one will be counted to zero in a loop. The resulting value will then be passed to the dissolve shader
	
	while(1)
	{
		//animate dissolve effect
		dissolveObject.skill1 -= time_step*0.05;
		if(dissolveObject.skill1 <= 0) dissolveObject.skill1 = 7;
		dissolveObject.material.skill1 = floatv(dissolveObject.skill1);
		wait(1);
	}
}