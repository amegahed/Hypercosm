unit picture_inits;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            picture_inits              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains miscillaneous routines to set      }
{       up the data structures for rendering.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


procedure Init_picture_units;


implementation
uses
  colors, pixel_colors, video, images, bitmaps, keyboard_input, noise, project,
  clip_planes, viewports, anim, precalc, preview, state_vars, z_vertices,
  z_pipeline, z_buffer, textures, lighting, luxels, coords, shading,
  intersect, walk_voxels, make_boxels, scan, system_events;


procedure Init_picture_units;
begin
  {***************************}
  { initialize system modules }
  {***************************}
  Init_video;
  Init_images;
  Init_bitmaps;
  Init_keyboard_input;
  Init_system_events;

  {****************************}
  { initialize display modules }
  {****************************}
  Init_colors;
  Init_pixel_colors;
  Init_noise;
  {Init_logo;}

  {****************************}
  { initialize viewing modules }
  {****************************}
  Init_project;
  Init_clip_planes;
  Init_viewports;

  {******************************}
  { initialize rendering modules }
  {******************************}
  Init_state_vars;
  Init_z_vertices;
  Init_z_pipeline;
  Init_z_buffer;

  {****************************}
  { initialize shading modules }
  {****************************}
  Init_textures;
  Init_lighting;
  Init_luxels;
  Init_coords;
  Init_shading;

  {*******************************}
  { initialize raytracing modules }
  {*******************************}
  Init_intersect;
  Init_walk_voxels;
  Init_make_boxels;
  Init_scanning;

  {*************************}
  { initialize anim modules }
  {*************************}
  Init_anim;
  Init_precalc;
  Init_preview;
end; {procedure Init_picture_units}


end. {module picture_inits}

