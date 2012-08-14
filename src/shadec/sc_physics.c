//-----------------------------------------------------------------------------------------------------------
// OBB - Oriented Bounding Box
//-----------------------------------------------------------------------------------------------------------
SC_OBB* sc_physics_createOBB(VECTOR* inPos, VECTOR* inNormalX, VECTOR* inNormalY, VECTOR* inNormalZ, VECTOR* inSize)
{
	SC_OBB* obb= sys_malloc(sizeof(SC_OBB));
	
	//pos
	//vec_set(obb.c, inPos);
	obb.c[0] = inPos.x;
	obb.c[1] = inPos.y;
	obb.c[2] = inPos.z;
		
	//obb normals
	vec_set( obb.u[0], inNormalX );
	vec_set( obb.u[1], inNormalY );
	vec_set( obb.u[2], inNormalZ );
	
	//obb size
	//vec_set( obb.e, inSize );
	obb.e[0] = inSize.x;
	obb.e[1] = inSize.y;
	obb.e[2] = inSize.z;
	
	return obb;
}

// OBB - OBB Intersection Test
int sc_physics_intersectOBBOBB(SC_OBB* a, SC_OBB* b)
{
	var EPSILON = 1;
	int i = 0;
	int j = 0;
	
	var ra = 0;
	var rb = 0;
	var R[3][3];
	var AbsR[3][3];
	for(i = 0; i < 3; i++)
	{
		for(j = 0; j < 3; j ++)
		{
			R[i][j] = 0;
			AbsR[i][j] = 0;
		}
	}
		
	// Compute rotation matrix expressing b in a’s coordinate frame
	
	for (i = 0; i < 3; i++)
	{
		for (j = 0; j < 3; j++)
		{
			R[0][0] = vec_dot(a.u[i], b.u[j]);
		}
		
	}
	
	// Compute translation vector t
	var t[3];
	//vec_zero(t);
	t[0] = 0;
	t[1] = 0;
	t[2] = 0;
	vec_diff(t, b.c, a.c);
	
	// Bring translation into a’s coordinate frame
	//t = Vector(Dot(t, a.u[0]), Dot(t, a.u[2]), Dot(t, a.u[2]));
	//schreibfehler ? a.u[2] -> a.u[1] ?
	vec_set(t, vector( vec_dot(t, a.u[0]), vec_dot(t, a.u[1]), vec_dot(t, a.u[2]) ));
	
	// Compute common subexpressions. Add in an epsilon term to
	// counteract arithmetic errors when two edges are parallel and
	// their cross product is (near) null (see text for details)
	for (i = 0; i < 3; i++)
	{
		for (j = 0; j < 3; j++)
		{
			AbsR[i][j] = abs(R[i][j]) + EPSILON;
		}
	}
	
	
	// Test axes L = A0, L = A1, L = A2
	for (i = 0; i < 3; i++)
	{
		ra = a.e[i];
		rb = b.e[0] * AbsR[i][0] + b.e[1] * AbsR[i][1] + b.e[2] * AbsR[i][2];
		if (abs(t[i]) > ra + rb) return 0;
	}
	
	// Test axes L = B0, L = B1, L = B2
	for (i = 0; i < 3; i++)
	{
		ra = a.e[0] * AbsR[0][i] + a.e[1] * AbsR[1][i] + a.e[2] * AbsR[2][i];
		rb = b.e[i];
		if (abs(t[0] * R[0][i] + t[1] * R[1][i] + t[2] * R[2][i]) > ra + rb) return 0;
	}
	
	// Test axis L = A0 x B0
	ra = a.e[1] * AbsR[2][0] + a.e[2] * AbsR[1][0];
	rb = b.e[1] * AbsR[0][2] + b.e[2] * AbsR[0][1];
	if (abs(t[2] * R[1][0] - t[1] * R[2][0]) > ra + rb) return 0;
	// Test axis L = A0 x B1
	ra = a.e[1] * AbsR[2][1] + a.e[2] * AbsR[1][1];
	rb = b.e[0] * AbsR[0][2] + b.e[2] * AbsR[0][0];
	if (abs(t[2] * R[1][1] - t[1] * R[2][1]) > ra + rb) return 0;
	// Test axis L = A0 x B2
	ra = a.e[1] * AbsR[2][2] + a.e[2] * AbsR[1][2];
	rb = b.e[0] * AbsR[0][1] + b.e[1] * AbsR[0][0];
	if (abs(t[2] * R[1][2] - t[1] * R[2][2]) > ra + rb) return 0;
	// Test axis L = A1 x B0
	ra = a.e[0] * AbsR[2][0] + a.e[2] * AbsR[0][0];
	rb = b.e[1] * AbsR[1][2] + b.e[2] * AbsR[1][1];
	if (abs(t[0] * R[2][0] - t[2] * R[0][0]) > ra + rb) return 0;
	// Test axis L = A1 x B1
	ra = a.e[0] * AbsR[2][1] + a.e[2] * AbsR[0][1];
	rb = b.e[0] * AbsR[1][2] + b.e[2] * AbsR[1][0];
	if (abs(t[0] * R[2][1] - t[2] * R[0][1]) > ra + rb) return 0;
	// Test axis L = A1 x B2
	ra = a.e[0] * AbsR[2][2] + a.e[2] * AbsR[0][2];
	rb = b.e[0] * AbsR[1][1] + b.e[1] * AbsR[1][0];
	if (abs(t[0] * R[2][2] - t[2] * R[0][2]) > ra + rb) return 0;
	// Test axis L = A2 x B0
	ra = a.e[0] * AbsR[1][0] + a.e[1] * AbsR[0][0];
	rb = b.e[1] * AbsR[2][2] + b.e[2] * AbsR[2][1];
	if (abs(t[1] * R[0][0] - t[0] * R[1][0]) > ra + rb) return 0;
	// Test axis L = A2 x B1
	ra = a.e[0] * AbsR[1][1] + a.e[1] * AbsR[0][1];
	rb = b.e[0] * AbsR[2][2] + b.e[2] * AbsR[2][0];
	if (abs(t[1] * R[0][1] - t[0] * R[1][1]) > ra + rb) return 0;
	// Test axis L = A2 x B2
	ra = a.e[0] * AbsR[1][2] + a.e[1] * AbsR[0][2];
	rb = b.e[0] * AbsR[2][1] + b.e[1] * AbsR[2][0];
	if (abs(t[1] * R[0][2] - t[0] * R[1][2]) > ra + rb) return 0;
	
	// Since no separating axis is found, the OBBs must be intersecting
	return 1;
}


int sc_physics_intersectViewView(VIEW* view1, VIEW* view2)
{
	return 0;
	if(view1 == NULL || view2 == NULL) return 0;
	
	VECTOR vecDir;
	VECTOR pos;
	VECTOR normalX;
	VECTOR normalY;
	VECTOR normalZ;
	VECTOR boxSize;
	VECTOR tempAngle;
	vec_zero(vecDir);
	vec_zero(pos);
	vec_zero(normalX);
	vec_zero(normalY);
	vec_zero(normalZ);
	vec_zero(boxSize);
	vec_zero(tempAngle);
	
	
	//view 1 obb ------------------------------------------------------------------------------------------
	//get view direction
	vec_for_angle(vecDir, view1.pan);
	//set object distance to view
	vec_scale(vecDir, view1.clip_far/2);
	
	//set position
	vec_set(pos, view1.x);
	vec_add(pos, vecDir);
	
	//set normals
	//X
	vec_for_angle(normalX, view1.pan);
	//Y
	vec_set(tempAngle, view1.pan);
	ang_rotate(tempAngle, vector(90,0,0));
	vec_for_angle(normalY, tempAngle);
	//Z
	vec_set(tempAngle, view1.pan);
	ang_rotate(tempAngle, vector(0,90,0));
	vec_for_angle(normalZ, tempAngle);
	
	boxSize.x = view1.clip_far/2; //half-depth
	boxSize.y = tanv(view1.arc/2) * view1.clip_far; //half-width
	boxSize.z = boxSize.y * view1.aspect; //height
	//Hfar = 2 * tan(fov / 2) * farDist
	//Wfar = Hfar * ratio
	
	SC_OBB* obb1 = sc_physics_createOBB( pos, normalX, normalY, normalZ , boxSize );
	
	//-----------------------------------------------------------------------------------------------------

	vec_zero(vecDir);
	vec_zero(pos);
	vec_zero(normalX);
	vec_zero(normalY);
	vec_zero(normalZ);
	vec_zero(boxSize);
	vec_zero(tempAngle);
	
	//view 2 obb ------------------------------------------------------------------------------------------
	//get view direction
	vec_for_angle(vecDir, view2.pan);
	//set object distance to view
	vec_scale(vecDir, view2.clip_far/2);
	
	//set position
	vec_set(pos, view2.x);
	vec_add(pos, vecDir);
	
	//set normals
	//X
	vec_for_angle(normalX, view2.pan);
	//Y
	vec_set(tempAngle, view2.pan);
	ang_rotate(tempAngle, vector(90,0,0));
	vec_for_angle(normalY, tempAngle);
	//Z
	vec_set(tempAngle, view2.pan);
	ang_rotate(tempAngle, vector(0,90,0));
	vec_for_angle(normalZ, tempAngle);
	
	//set size
	boxSize.x = view2.clip_far/2; //half-depth
	boxSize.y = tanv(view2.arc/2) * view2.clip_far; //half-width
	boxSize.z = boxSize.y * view2.aspect; //height
	//Hfar = 2 * tanv(fov / 2) * farDist
	//Wfar = Hfar * ratio
	
	SC_OBB* obb2 = sc_physics_createOBB( pos, normalX, normalY, normalZ , boxSize );
	
	//check if views intersect
	int res = sc_physics_intersectOBBOBB(obb1, obb2);
	sys_free(obb1);
	sys_free(obb2);
	
	return res;
}



/*
// Cone <-> Sphere
int sc_physics_intersectConeSphere (VECTOR* inConePos, VECTOR* inConeDir, var inConeArc, VECTOR* inSpherePos, var inSphereRadius )
{
	//VECTOR inConePos;
	//var inSphereRadius;
	//var inConeArc;
	//VECTOR inConeDir;
	//VECTOR inSpherePos;
	var coneArcSin = sinv(inConeArc/2);
	var coneArcCos = cosv(inConeArc/2);
	VECTOR vecTemp;
	
	VECTOR U;
	vec_set(vecTemp, inConeDir);
	vec_scale(vecTemp, inSphereRadius/coneArcSin);
	vec_set(U, inConePos);
	vec_sub(U, vecTemp);
	VECTOR D;
	vec_set(D, inSpherePos);
	vec_sub(D, U);
	//vec_diff(D, inSpherePos,U);
	if ( vec_dot(inConeDir,D) >= vec_length(D)*coneArcCos )
	{
		// center is inside K’’
		vec_set(D, inSpherePos);
		vec_sub(D, inConePos);
		//vec_diff(D, inSpherePos,inConePos);
		if ( -vec_dot(inConeDir,D) >= vec_length(D)*coneArcSin )
		{
			// center is inside K’’ and inside K’
			return vec_length(D) <= inSphereRadius;
		}
		else
		{
			// center is inside K’’ and outside K’
			return 1;
		}
	}
	else
	{
	// center is outside K’’
	return 0;
	}
}
*/

//-----------------------------------------------------------------------------------------------------------
// View <-> Sphere BUGGY
//-----------------------------------------------------------------------------------------------------------
int sc_physics_intersectViewSphere(VIEW* inView,VECTOR* inPos,var inRadius)
{
	
	VECTOR vcTemp1,vcTemp2,vcTemp3;
	vec_zero(vcTemp1);
	vec_zero(vcTemp2);
	vec_zero(vcTemp3);
	
	var vTemp1=0;
	var vTemp2=0;
	var vTemp3=0;
	
	vec_for_angle(vcTemp1,inView.pan);
	vec_diff(vcTemp2,inPos,inView.x);
	
	vTemp1=vec_dot(vcTemp1,vcTemp2);
	
	vec_set(vcTemp3,inView.x);
	vec_scale(vcTemp1,vTemp1);
	vec_add(vcTemp3,vcTemp1);
	
	vec_diff(vcTemp1,inPos,vcTemp3);
	vTemp2=vec_length(vcTemp1);
	
	vTemp1=tanv(atanv( sqrt(2) * tanv(inView.arc/2) ))*vTemp1;
	
	return (vTemp2-vTemp1>inRadius);
	
	
	/*
	VECTOR viewDir;
	vec_for_angle(viewDir, inView.pan);
	//vec_scale(viewDir, 5);
	return sc_physics_intersectConeSphere (inView.x, viewDir, inView.arc, inPos, inRadius );
	*/
}