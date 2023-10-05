unit object_inits;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            object_inits               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The objects module provides data structures and         }
{       routines for creating the basic modeling data           }
{       structures which describe the geometry.                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


procedure Init_object_units;


implementation
uses
  strings, constants, trigonometry, vectors, vectors2, trans, trans2,
  coord_axes, trans_stack, coord_stack, extents, bounds, triangles, polygons,
  polymeshes, volumes, isomeshes, geometry, topology, b_rep, make_b_rep,
  grid_prims, xform_b_rep, materials, object_attr, attr_stack, meshes,
  mesh_prims, b_rep_prims, objects, raytrace, viewing;


procedure Init_object_units;
begin
  {**************************}
  { initialize basic modules }
  {**************************}
  Init_strings;

  {*************************}
  { initialize math modules }
  {*************************}
  Init_constants;
  Init_trigonometry;

  {***************************}
  { initialize vector modules }
  {***************************}
  Init_vectors;
  Init_vectors2;

  {******************************}
  { initialize transform modules }
  {******************************}
  Init_transform;
  Init_transform2;
  Init_coord_axes;
  Init_trans_stack;
  Init_coord_stack;

  {*****************************}
  { initialize geometry modules }
  {*****************************}
  Init_extents;
  Init_bounds;
  Init_triangles;
  Init_polygons;
  Init_polymeshes;
  Init_volumes;
  Init_isomeshes;

  {**************************}
  { initialize b rep modules }
  {**************************}
  Init_geometry;
  Init_topology;
  Init_b_rep;
  Init_make_b_rep;
  Init_xform_b_rep;

  {*************************}
  { initialize mesh modules }
  {*************************}
  Init_meshes;
  Init_grid_prims;
  Init_mesh_prims;
  Init_b_rep_prims;

  {***************************}
  { initialize object modules }
  {***************************}
  Init_materials;
  Init_object_attributes;
  Init_attributes_stack;
  Init_objects;
  Init_raytrace;
  Init_viewing;
end; {procedure Init_object_units}


end. {module object_inits}
