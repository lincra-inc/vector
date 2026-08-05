// The collection provides plenty of ready-to-go shaders, 
// but when you want to make some advanced customizations, 
// like disabling lighting, you can create your own shader file, 
// define a few macros, and include the main file: common.gdshaderinc. 
// To learn more, read the documentation on the GitHub repository. 
// Here's an example file:
shader_type spatial;

// Use vertex_snap_resolution global uniform instead of vertex_snap_intensity
#define OVERRIDE_VERTEX_SNAP_RESOLUTION

// Disable light from Light3D nodes
#define UNSHADED

#include "res://external/ursc/spatial/common.gdshaderinc"