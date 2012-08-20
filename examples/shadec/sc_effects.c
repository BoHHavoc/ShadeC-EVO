//Screen Explosion Refract
//
//		entPos = position of entity
//		strength = refract strength
//		scatter = random position scatter (if > 0)
//		duration = duration of effect
//		map = pointer to normalmap
var sc_effect_explosionRefractScreen_(VECTOR* entPos, var inStrength, var inScatter, var inDuration, BMAP* map, VIEW* inView)
{
	proc_mode = PROC_GLOBAL;
	
	if(map == NULL) return (0);
	
	VECTOR pos;
	vec_set(pos, entPos);
	VECTOR tempVec;
	vec_set(tempVec,pos);
	MATERIAL* mtl_expl;
	VIEW* effectView = inView;
	
	var strength, scatter, duration;
	strength = inStrength;
	scatter = inScatter;
	duration = inDuration;
	
	if(NULL != vec_to_screen(tempVec,inView))
	{
		
		mtl_expl = mtl_create();
		effect_load(mtl_expl, sc_effects_strRefractScreen);
		mtl_expl.skin1 = map;
		sc_ppAdd(mtl_expl,inView,NULL);
	}
	else return 0;
	
	var str = 0;
	var count=0;
	while(count < duration)
	{
		count += 2*time_frame;
		str = vec_dist(pos, inView.x)/strength;
		mtl_expl.skill1 = floatv(count/str);
		
		vec_set(tempVec,pos);
		tempVec.x += random(scatter) - (scatter/2);
		tempVec.y += random(scatter) - (scatter/2);
		tempVec.z += random(scatter) - (scatter/2);
		vec_to_screen(tempVec,inView);
		tempVec.x = ((tempVec.x/screen_size.x)-0.5);
		tempVec.y = ((tempVec.y/screen_size.y)-0.5);
		mtl_expl.skill2 = floatv(-tempVec.x);
		mtl_expl.skill3 = floatv(-tempVec.y);
		
		wait(1);
	}
	count = duration;
	mtl_expl.skill1 = floatv(count*str);
	
	while(count > 0)
	{
		count -= 0.15*time_frame;
		str = vec_dist(pos, inView.x)/strength;
		mtl_expl.skill1 = floatv(count/str);
		
		
		vec_set(tempVec,pos);
		tempVec.x += random(scatter) - (scatter/2);
		tempVec.y += random(scatter) - (scatter/2);
		tempVec.z += random(scatter) - (scatter/2);
		vec_to_screen(tempVec,inView);
		tempVec.x = ((tempVec.x/screen_size.x)-0.5);
		tempVec.y = ((tempVec.y/screen_size.y)-0.5);
		mtl_expl.skill2 = floatv(-tempVec.x);
		mtl_expl.skill3 = floatv(-tempVec.y);

		wait(1);
	}
	
	count = 0;
	mtl_expl.skill1 = floatv(count);
	sc_ppRemove(mtl_expl,effectView,NULL);
	wait(1);
	//bmap_purge(mtl_expl.skin1);
	//ptr_remove(mtl_expl.skin1);
	ptr_remove(mtl_expl);
		
	return (1);
}
var sc_effect_explosionRefractScreen(VECTOR* entPos, var strength, var scatter, var duration, BMAP* map)
{
	sc_effect_explosionRefractScreen_(entPos, strength, scatter, duration, map, camera);
}
var sc_effect_explosionRefractScreen(VECTOR* entPos, var strength, var scatter, var duration, BMAP* map, VIEW* inView)
{
	sc_effect_explosionRefractScreen_(entPos, strength, scatter, duration, map, inView);
}
//--------------------------------------------------------------