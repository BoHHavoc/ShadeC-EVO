//------------------------------------------------------------------------------
//----- USER INPUT -------------------------------------------------------------
//------------------------------------------------------------------------------

//assign skins
#define SKIN_ALBEDO (skin1.xyz) //diffusemap
#define SKIN_ALPHA (skin1.w) //alphamap
#define SKIN_NORMAL (skin2.xyz) //normalmap
#define SKIN_GLOSS (skin2.w) //glossmap
//...

#define NORMALMAPPING //do normalmapping?

#define GLOSSMAP //entity has glossmap?

#define ALPHA //entity has alphamap?
#define TRANSPARENT //entity alpha should be interpreted as transparent/translucent?

//------------------------------------------------------------------------------
// ! END OF USER INPUT !
//------------------------------------------------------------------------------

#include <scHeaderObject>

//custom code goes here

#include <scObject>


