// Soft Sprites
//
// It is HIGHLY recommended to use these instead of normal A7 sprites.
// They render faster and look better
//
// ent - the entity/sprite
// color - tinting of the sprite in RGB 255 values.
// vals:
//			x - fade distance for smooth transition and camera flythrough
//			y - Softness. Higher values result in a more smoother object<->sprite intersection
//			z - not used yet
//	pType - 0 = non-overlay, 1 = overlay, 2 = overlay + BRIGHT

ENTITY* sc_ent_softSprite(ENTITY* ent, VECTOR* color, VECTOR* vals, int pType)
{
	//ent.material = sc_particles_mtl;
	if(pType == 0) ent.material = sc_ent_mtlSoftSprite; //sc_material(ent, SC_MATPARTICLE, sc_mtl_softSprite);
	else if(pType == 1) ent.material = sc_ent_mtlSoftSpriteOverlay;
	else if(pType == 2) ent.material = sc_ent_mtlSoftSpriteOverlayBright;
	sc_skill(ent, SC_OBJECT_DEPTH, -1);
	sc_skill(ent, SC_OBJECT_PASS, SC_PASS_FORWARD);
	sc_skill(ent, SC_OBJECT_DATA_1_X, vals.x);
	sc_skill(ent, SC_OBJECT_DATA_1_Y, vals.y);
	sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
	sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
	sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
	//sc_skill(ent, SC_MYREFRCOL, color);
	//sc_skill(ent, SC_MYTEXMOVE, vector(vals.x,vals.y,0));
	set(ent, TRANSLUCENT);
	
	return ent;
}
ENTITY* sc_ent_softSprite(ENTITY* ent, VECTOR* color, int inFadeDist, int inSoftness, int pType)
{
	return sc_ent_softSprite(ent, color, vector(inFadeDist, inSoftness, 0), pType);
}
//------------------------------------------------------------------------------------------

// Soft Fog
//
// Creates a fog/dust/steam effect out of a plane/sprite
//	Uses entSkin1.rgb as noise and entSkin1.a as alpha
//
// ent - the entity/sprite
// color - colorvector in standardt RGB 255 values.
// vals:
//			x - fade distance for smooth transition and camera flythrough
//			y - Softness. Higher values result in a more smoother object<->sprite intersection
//			z - texture movement speed
//	vals2:
//			x - noisemap.r scale
//			y - noisemap.g scale
//			z - noisemap.b scale
//	pType - fog type. 0 == non overlay | 1 == overlay | 2 == overlay + BRIGHT

ENTITY* sc_ent_softFog(ENTITY* ent, VECTOR* color, VECTOR* vals, VECTOR* vals2, int pType)
{
	//ent.material = sc_particles_mtl;
	if(pType == 0) ent.material = sc_ent_mtlSoftFog; //sc_material(ent, SC_MATPARTICLE, sc_mtl_softFog);
	else if(pType == 1) ent.material = sc_ent_mtlSoftFogOverlay; //sc_material(ent, SC_MATPARTICLE, sc_mtl_softFogOverlay);
	sc_skill(ent, SC_OBJECT_DEPTH, -1);
	sc_skill(ent, SC_OBJECT_PASS, SC_PASS_FORWARD);
	sc_skill(ent, SC_OBJECT_DATA_1_X, vals.x);
	sc_skill(ent, SC_OBJECT_DATA_1_Y, vals.y);
	sc_skill(ent, SC_OBJECT_DATA_2_X, vals2.x);
	sc_skill(ent, SC_OBJECT_DATA_2_Y, vals2.y);
	sc_skill(ent, SC_OBJECT_DATA_2_Z, vals2.z);
	sc_skill(ent, SC_OBJECT_DATA_2_W, vals.z);
	sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
	sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
	sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
	set(ent, TRANSLUCENT);
	
	return ent;
}
ENTITY* sc_ent_softFog(ENTITY* ent, VECTOR* color, int inFadeDist, int inSoftness, int inTexMoveSpeed, VECTOR* noiseScale , int pType)
{
	return sc_ent_softFog(ent, color, vector(inFadeDist, inSoftness, inTexMoveSpeed), noiseScale, pType);
}
//------------------------------------------------------------------------------------------

// Shield Impact Effect
//
// Use sc_shield.mdl as model
//
// ent - the entity
// color - color of impact
// softness - softness of object<->effect intersections
// loop - loop shield effect? 0 or 1
// entity.alpha is supported
void sc_ent_shieldImpact(ENTITY* ent, VECTOR* color, var softness, var loop)
{
   //sc_skill(ent, SC_MYSHADOWRECV, 0);
   ent.material = sc_ent_mtlShield;
   sc_skill(ent, SC_OBJECT_PASS, SC_PASS_REFRACT);
   sc_skill(ent, SC_OBJECT_DEPTH, -1);
   var texMoveX = 15;
   
   //shield spark animation
   var myTemp = 0;
   //sc_skill(ent, SC_MYTEXMOVE, vector(texMoveX,softness,myTemp));
   sc_skill(ent, SC_OBJECT_DATA_1_Y, softness);
   sc_skill(ent, SC_OBJECT_DATA_1_Z, texMoveX);
   sc_skill(ent, SC_OBJECT_DATA_1_W, myTemp);
   //sc_skill(ent, SC_MYREFRCOL, color);
   sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
   var timePassed = 0;
   if(loop == 0)
   {
      while(myTemp <= 8 && ent != NULL)
      {
         timePassed += time_frame;
         if(timePassed >= 1)
         {
            timePassed = 0;
            myTemp += 1;
            //sc_skill(ent,SC_MYTEXMOVE, vector(texMoveX,softness,myTemp));
            sc_skill(ent, SC_OBJECT_DATA_1_W, myTemp);
         }
         //if(my) {
         //   vec_set(ent.x, my.x);
         //   if(my.skill11 != OFF) break;
         //}
         //else break;
         wait(1);
      }
   }
   else
   {
      while(ent)
      {
         timePassed += time_frame*2;
         if(timePassed >= 1)
         {
            timePassed = 0;
            myTemp += 1;
            sc_skill(ent, SC_OBJECT_DATA_1_W, myTemp);
         }
         if(myTemp > 8) myTemp = 0;
         //if(my) {
         //   vec_set(ent.x, my.x);
         //   if(my.skill11 != OFF) break;
         //}
         //else break;
         wait(1);
      }
      
   }
   ent_remove(ent);
}
//------------------------------------------------------------------------------------------

// Shield Burn Effect
//
// Use sc_shieldBurn.mdl as model
//
// ent - the entity
// color - color of burn
// softness - softness of object<->effect intersections
// entity.alpha is supported
void sc_ent_shieldBurn(ENTITY* ent, VECTOR* color, int softness, int texMoveSpeed)
{
	ent.material = sc_ent_mtlShieldBurn;
	sc_skill(ent, SC_OBJECT_PASS, SC_PASS_REFRACT);
   sc_skill(ent, SC_OBJECT_DEPTH, -1);

	
	//object<->effect intersection softness
	sc_skill(ent, SC_OBJECT_DATA_1_Y, softness);
	//refract texture movement speed
   sc_skill(ent, SC_OBJECT_DATA_1_Z, texMoveSpeed);
   //coloring
   sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
}
//------------------------------------------------------------------------------------------

// Energy Sphere Effect
//
// Use sc_energySphere.mdl as model
//
// ent - the entity
// color - color of the effect
// softness - softness of object<->effect intersections
// entity.alpha is supported
void sc_ent_energySphere(ENTITY* ent, VECTOR* color, var softness)
{
   ent.material = sc_ent_mtlEnergySphere;
   sc_skill(ent, SC_OBJECT_PASS, SC_PASS_REFRACT);
	sc_skill(ent, SC_OBJECT_DEPTH, -1);
 
   //object<->effect intersection softness
   sc_skill(ent, SC_OBJECT_DATA_1_Y, softness);
   //coloring
   sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
    
   VECTOR myPos;
    
   var uvPos = 0;
 
   var timePassed = 0;
   while(timePassed < 48)
   {
		timePassed += time_frame;
		vec_set(myPos.x,camera.x);
		vec_sub(myPos.x,ent.x);
		vec_to_angle(ent.pan,myPos.x);
        
      if(uvPos == 0)
      {
			//sc_skill(ent, SC_MYTEXMOVE,vector((random(1)+time_step),softness,0) );
         sc_skill(ent, SC_OBJECT_DATA_1_Z, (random(1)+time_step) );
		}
        
      uvPos += time_frame*12;
        
      if(uvPos >= 10)
      {
			uvPos = 0;
      }
		wait(1);
	}
	ent_remove(ent);
}
/*
void sc_ent_energySphere(ENTITY* ent, VECTOR* color, var softness)
{
	ent.material = sc_ent_mtlEnergySphere;
	sc_skill(ent, SC_OBJECT_PASS, SC_PASS_REFRACT);
   sc_skill(ent, SC_OBJECT_DEPTH, -1);
   
   //object<->effect intersection softness
	sc_skill(ent, SC_OBJECT_DATA_1_Y, softness);
   //coloring
   sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
	
	VECTOR myPos;
	
	var uvPos = 0;
	
	var timePassed = 0;
	while(ent)
	{
		
		vec_set(myPos.x,camera.x); 
		vec_sub(myPos.x,ent.x);
		vec_to_angle(ent.pan,myPos.x);
		
		if(uvPos == 0)
		{
			//sc_skill(ent, SC_MYTEXMOVE,vector((random(1)+time_step),softness,0) );
			sc_skill(ent, SC_OBJECT_DATA_1_Z, (random(1)+time_step) );
		}
		
		uvPos += time_frame*12;
		
		if(uvPos >= 10)
		{
			uvPos = 0;
		}
		wait(1);
	}
}
*/
//------------------------------------------------------------------------------------------

// Heat Haze Effect
//
// Use a texture/sprite with alphachannel as entity.
// RGB: tileable normalmap
// A: transparency
//
// ent - the entity
// color - color of the effect
// softness - softness of object<->effect intersections
// speed - speed of normalmap uv shifting
// strength - strength of refraction
// entity.alpha is supported
void sc_ent_heatHaze(ENTITY* ent, VECTOR* color, var softness, var speed, var strength)
{
	ent.material = sc_ent_mtlHeatHaze;
	sc_skill(ent, SC_OBJECT_PASS, SC_PASS_REFRACT);
      
   //object<->effect intersection softness
   sc_skill(ent, SC_OBJECT_DATA_1_X, speed);
	sc_skill(ent, SC_OBJECT_DATA_1_Y, softness);
	sc_skill(ent, SC_OBJECT_DATA_1_Z, strength);
   //coloring
   sc_skill(ent, SC_OBJECT_DATA_3_X, color.x/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Y, color.y/255);
   sc_skill(ent, SC_OBJECT_DATA_3_Z, color.z/255);
}


//------------------------------------------------------------------------------------------

/*
// Water
//
// needs sc_bRefract = 1
//
// ent - the entity
// inMtl - the watermaterial
// texMove - texture movement (xy) and bumpstrength (z)

void sc_ent_water(ENTITY* ent, MATERIAL* inMtl, VECTOR* texMove)
{
	sc_skill(ent, SC_MYREFRACT, 2);
	sc_skill(ent, SC_MYDEPTH, -1);
	sc_material(ent, SC_MATREFRACT, inMtl);
	sc_skill(ent, SC_MYTEXMOVE, texMove);
}
//------------------------------------------------------------------------------------------
*/


/*
//assigns the given material as gBuffer material
int sc_ent_assignMaterial(ENTITY* inEntity, MATERIAL* inMaterial)
{
	if(inMaterial != NULL && inEntity != NULL)
	{
		sc_material(inEntity, SC_MATERIAL_GBUFFER, inMaterial);
		return 1;
	}
	return 0;
}

 //load effect from file and attach to entity as gBuffer material
MATERIAL* sc_ent_createMaterialFromFile(ENTITY* inEntity, STRING* inFile)
{
	if(inFile != NULL)
	{
		MATERIAL* tempMat = mtl_create();
		effect_load(tempMat, inFile);
		sc_material(inEntity, SC_MATERIAL_GBUFFER, tempMat);
		return tempMat;
	}
	return NULL;
}

 //load effect from entity.string1 and attach to entity as gBuffer material
MATERIAL* sc_ent_createMaterialFromEntString1(ENTITY* inEntity)
{
	if(my.string1 != NULL)
	{
		MATERIAL* tempMat = mtl_create();
		effect_load(tempMat, inEntity.string1);
		sc_material(inEntity, SC_MATERIAL_GBUFFER, tempMat);
		return tempMat;
	}
	return NULL;
}

 //load effect from entity.string2 and attach to entity as gBuffer material
MATERIAL* sc_ent_createMaterialFromEntString2(ENTITY* inEntity)
{
	if(my.string2 != NULL)
	{
		MATERIAL* tempMat = mtl_create();
		effect_load(tempMat, inEntity.string2);
		sc_material(inEntity, SC_MATERIAL_GBUFFER, tempMat);
		return tempMat;
	}
	return NULL;
}
*/