void sc_setup(SC_SCREEN* screen);
void sc_setup(VIEW* inView){
	if(inView.size_x == 0 || inView.size_y == 0){
		inView.size_x = screen_size.x;
		inView.size_y = screen_size.y;
	}
	else if(inView == camera)
	{
		camera.size_x = screen_size.x;
		camera.size_y = screen_size.y;
	}
	sc_screen_default = sc_screen_create(inView);
	sc_setup(sc_screen_default);
}
void sc_setup(){ sc_setup(camera);}