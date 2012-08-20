typedef struct{
	var c[3]; // OBB center point
	VECTOR u[3]; // Local x-, y-, and z-axes
	//VECTOR e; // Positive halfwidth extents of OBB along each axis
	var e[3]; // Positive halfwidth extents of OBB along each axis
} SC_OBB;