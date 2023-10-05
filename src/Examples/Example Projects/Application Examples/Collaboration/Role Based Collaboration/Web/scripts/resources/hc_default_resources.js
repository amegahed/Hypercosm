/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm        hc_default_resources.js         3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines the runtime resources (textures      |
|        and sounds) that are used by SketchUp applets.         |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

function getIconResources(resourcePath) {
  return [
    'about_icon.gif, ' + resourcePath + '/textures/about_icon.gif',
    'back_arrow_icon.gif, ' + resourcePath + '/textures/back_arrow_icon.gif',
    'blue_dial_icon.gif, ' + resourcePath + '/textures/blue_dial_icon.gif',
    'camera_icon.gif, ' + resourcePath + '/textures/camera_icon.gif',
    'cartoon_icon.gif, ' + resourcePath + '/textures/cartoon_icon.gif',
    'color_wheel_icon.gif, ' + resourcePath + '/textures/color_wheel_icon.gif',
    'dial_arrow.gif, ' + resourcePath + '/textures/dial_arrow.gif',
    'dial_icon.gif, ' + resourcePath + '/textures/dial_icon.gif',
    'dial_labels.gif, ' + resourcePath + '/textures/dial_labels.gif',
    'dock_texture.png, ' + resourcePath + '/textures/dock_texture.png',
    'edges_icon.gif, ' + resourcePath + '/textures/edges_icon.gif',
    'flat_icon.gif, ' + resourcePath + '/textures/flat_icon.gif',
    'gauge_icon.gif, ' + resourcePath + '/textures/gauge_icon.gif',
    'graphics_icon.gif, ' + resourcePath + '/textures/graphics_icon.gif',
    'green_dial_icon.gif, ' + resourcePath + '/textures/green_dial_icon.gif',
    'help_icon.gif, ' + resourcePath + '/textures/help_icon.gif',
    'hide_icon.gif, ' + resourcePath + '/textures/hide_icon.gif',
    'lighting_icon.gif, ' + resourcePath + '/textures/lighting_icon.gif',
    'mouse_icon.gif, ' + resourcePath + '/textures/mouse_icon.gif',
    'object_icon.gif, ' + resourcePath + '/textures/object_icon.gif',
    'one_button_icon.gif, ' + resourcePath + '/textures/one_button_icon.gif',
    'outline_icon.gif, ' + resourcePath + '/textures/outline_icon.gif',
    'pan_icon.gif, ' + resourcePath + '/textures/pan_icon.gif',
    'red_dial_icon.gif, ' + resourcePath + '/textures/red_dial_icon.gif',
    'render_modes_icon.gif, ' + resourcePath + '/textures/render_modes_icon.gif',
    'rotate_icon.gif, ' + resourcePath + '/textures/rotate_icon.gif',
    'scene_icon.gif, ' + resourcePath + '/textures/scene_icon.gif',
    'shadow_icon.gif, ' + resourcePath + '/textures/shadow_icon.gif',
    'smooth_icon.gif, ' + resourcePath + '/textures/smooth_icon.gif',
    'spin_icon.gif, ' + resourcePath + '/textures/spin_icon.gif',
    'two_button_icon.gif, ' + resourcePath + '/textures/two_button_icon.gif',
    'upright_icon.gif, ' + resourcePath + '/textures/upright_icon.gif',
    'two_button_icon.gif, ' + resourcePath + '/textures/two_button_icon.gif',
    'wireframe_icon.gif, ' + resourcePath + '/textures/wireframe_icon.gif',
    'x_ray_icon.gif, ' + resourcePath + '/textures/x_ray_icon.gif',
    'monochrome_icon.gif, ' + resourcePath + '/textures/monochrome_icon.gif',
    'monochrome_hidden_line_icon.gif, ' + resourcePath + '/textures/monochrome_hidden_line_icon.gif',
    'monochrome_edges_icon.gif, ' + resourcePath + '/textures/monochrome_edges_icon.gif',
    'zoom_icon.gif, ' + resourcePath + '/textures/zoom_icon.gif'
  ];
}    // getIconResources

function getSoundResources(resourcePath) {
  return [
    'deselect.wav, ' + resourcePath + '/sounds/deselect.wav',
    'hide.wav, ' + resourcePath + '/sounds/hide.wav',
    'select.wav, ' + resourcePath + '/sounds/select.wav',
    'show.wav, ' + resourcePath + '/sounds/show.wav'
  ];
}    // getSoundResources

function getDefaultResources(resourcePath) {
  return getTransparencyResources(resourcePath).concat(
  getIconResources(resourcePath).concat(
  getSoundResources(resourcePath)));
}	// getDefaultResources