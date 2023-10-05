unit precalc;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               precalc                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The precalc module builds the raytracing data           }
{       structures from the geometry data structs.              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  raytrace;


procedure Make_precalc;
function Find_ray_object(object_id: integer): ray_object_decl_ptr_type;


implementation
uses
  new_memory, coord_axes, extents, bounds, object_attr, objects, anim;


{*******************************************************}
{                 precalc data structures               }
{*******************************************************}
{                                                       }
{     decl block                                        }
{     /-------------------\  /--------------------\     }
{     | 1 | 2 | 3 | 4 | 5 |->| 6 | 7 | 8 | 9 | 10 |     }
{     \---------|---------/  \-|------------------/     }
{               |              |                        }
{               \-----\        \-\                      }
{                     |          |                      }
{                     v          v                      }
{                     |-----|    |-----|                }
{    raytracing data  |scene|<-->| car |-||             }
{        structs      |-----|    |-----|                }
{                                                       }
{*******************************************************}


const
  decl_block_size = 64;
  memory_alert = false;


type
  precalc_mode_type = (initial_precalc, incremental_precalc, terminal_precalc);


  decl_block_ptr_type = ^decl_block_type;
  decl_block_type = record
    ptr_array: array[1..decl_block_size] of ray_object_decl_ptr_type;
    next: decl_block_ptr_type;
  end; {decl_block_type}


var
  number_of_entries: integer;
  first_decl_block_ptr, last_decl_block_ptr: decl_block_ptr_type;


function New_decl_block: decl_block_ptr_type;
var
  decl_block_ptr: decl_block_ptr_type;
  counter: integer;
begin
  if memory_alert then
    writeln('allocating new raytracing decl block');
  new(decl_block_ptr);

  with decl_block_ptr^ do
    begin
      for counter := 1 to decl_block_size do
        ptr_array[counter] := nil;
      next := nil;
    end;

  New_decl_block := decl_block_ptr;
end; {function New_decl_block}


procedure Index_decl_list(index: integer;
  var decl_block_ptr: decl_block_ptr_type;
  var block_index: integer);
var
  blocks: integer;
begin
  if (index > number_of_entries) then
    begin
      {**************************}
      { entry is not in the list }
      {**************************}
      decl_block_ptr := nil;
      block_index := 0;
    end
  else if (index = number_of_entries) then
    begin
      {**************************************}
      { accessing the last entry in the list }
      {**************************************}
      decl_block_ptr := last_decl_block_ptr;
      block_index := (index - 1) mod decl_block_size + 1;
    end
  else
    begin
      {*********************************}
      { accessing the entry in the list }
      {*********************************}
      decl_block_ptr := first_decl_block_ptr;
      blocks := (index - 1) div decl_block_size;
      block_index := (index - 1) mod decl_block_size + 1;

      while (blocks >= 1) do
        begin
          decl_block_ptr := decl_block_ptr^.next;
          blocks := blocks - 1;
        end;
    end;
end; {procedure Index_decl_list}


function Find_ray_object(object_id: integer): ray_object_decl_ptr_type;
var
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
begin
  Index_decl_list(object_id, decl_block_ptr, block_index);
  if (decl_block_ptr <> nil) then
    ray_object_decl_ptr := decl_block_ptr^.ptr_array[block_index]
  else
    ray_object_decl_ptr := nil;
  Find_ray_object := ray_object_decl_ptr;
end; {function Find_ray_object}


function New_ray_object_prim(object_ptr: object_inst_ptr_type;
  coord_axes, shader_axes: coord_axes_type): ray_object_inst_ptr_type;
var
  ray_object_inst_ptr: ray_object_inst_ptr_type;
begin
  ray_object_inst_ptr := New_ray_object_inst;
  ray_object_inst_ptr^.kind := object_ptr^.kind;
  ray_object_inst_ptr^.coord_axes := coord_axes;
  ray_object_inst_ptr^.attributes := object_ptr^.attributes;
  ray_object_inst_ptr^.shader_axes := shader_axes;
  ray_object_inst_ptr^.original_object_ptr := ray_object_inst_ptr;
  ray_object_inst_ptr^.bounds.bounding_kind :=
    Object_bounding_kind(object_ptr^.kind);

  with ray_object_inst_ptr^ do
    case kind of

      {********************}
      { quadric primitives }
      {********************}
      sphere:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
          ray_object_inst_ptr^.vmin := object_ptr^.vmin;
          ray_object_inst_ptr^.vmax := object_ptr^.vmax;
        end;

      cylinder:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
        end;

      cone:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
          inner_radius := object_ptr^.inner_radius;
        end;

      paraboloid:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
        end;

      hyperboloid1:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
          inner_radius := object_ptr^.inner_radius;
        end;

      hyperboloid2:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
          eccentricity := object_ptr^.eccentricity;
        end;

      {*******************}
      { planar primitives }
      {*******************}
      plane, disk, triangle, parallelogram:
        ;

      ring:
        inner_radius := object_ptr^.inner_radius;

      flat_polygon:
        begin
          polygon_ptr := object_ptr^.polygon_ptr;
          ray_mesh_data_ptr := New_ray_mesh_data;
        end;

      {***********************}
      { non_planar primitives }
      {***********************}
      torus:
        begin
          ray_object_inst_ptr^.umin := object_ptr^.umin;
          ray_object_inst_ptr^.umax := object_ptr^.umax;
          ray_object_inst_ptr^.vmin := object_ptr^.vmin;
          ray_object_inst_ptr^.vmax := object_ptr^.vmax;
          inner_radius := object_ptr^.inner_radius;
        end;

      block:
        ;

      shaded_triangle:
        begin
          triangle_normal_ptr := object_ptr^.triangle_normal_ptr;
          triangle_interpolation_ptr := New_interpolation;
        end;

      shaded_polygon:
        begin
          shaded_polygon_ptr := object_ptr^.shaded_polygon_ptr;
          ray_mesh_data_ptr := New_ray_mesh_data;
        end;

      mesh:
        begin
          mesh_ptr := object_ptr^.mesh_ptr;
          smoothing := object_ptr^.smoothing;
          mending := object_ptr^.mending;
          closed := object_ptr^.closed;
          ray_mesh_data_ptr := New_ray_mesh_data;
        end;

      blob:
        begin
          threshold := object_ptr^.threshold;
          dimensions := object_ptr^.dimensions;
          metaball_ptr := object_ptr^.metaball_ptr;
        end;

      {************************}
      { non-surface primitives }
      {************************}
      points:
        points_ptr := object_ptr^.points_ptr;

      lines:
        lines_ptr := object_ptr^.lines_ptr;

      volume:
        begin
          volume_ptr := object_ptr^.volume_ptr;
          ray_mesh_data_ptr := New_ray_mesh_data;
        end;

      {*********************}
      { clipping primitives }
      {*********************}
      clipping_plane:
        ;

    end; {case}

  New_ray_object_prim := ray_object_inst_ptr;
end; {function New_ray_object_prim}


function Compressable_ray_object(ray_object_decl_ptr: ray_object_decl_ptr_type):
  boolean;
var
  compressable: boolean;
begin
  if not hierarchy_compression then
    compressable := false
  else if (ray_object_decl_ptr^.sub_object_number > min_object_complexity) then
    compressable := false
  else if (ray_object_decl_ptr^.clipping_plane_ptr <> nil) then
    compressable := false
  else
    compressable := true;

  Compressable_ray_object := compressable;
end; {function Compressable_ray_object}


procedure Copy_ray_sub_objects(sub_object_ptr: ray_object_inst_ptr_type;
  coord_axes: coord_axes_type;
  attributes: object_attributes_type;
  shader_axes: coord_axes_type);
var
  ray_object_inst_ptr: ray_object_inst_ptr_type;
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  new_coord_axes, new_shader_axes: coord_axes_type;
  new_attributes: object_attributes_type;
begin
  {**********************************}
  { copy previously created ray sub  }
  { objects to a new ray object decl }
  {**********************************}
  while (sub_object_ptr <> nil) do
    begin
      {*************************************}
      { transform sub object to new context }
      {*************************************}
      new_coord_axes := sub_object_ptr^.coord_axes;
      Transform_axes_from_axes(new_coord_axes, coord_axes);

      new_attributes := sub_object_ptr^.attributes;
      Apply_object_attributes(new_attributes, attributes);

      {***********************************}
      { compute new shader transformation }
      {***********************************}
      if (sub_object_ptr^.attributes.shader_ptr <> shader_ptr_type(nil)) then
        new_shader_axes := sub_object_ptr^.shader_axes
      else
        begin
          new_shader_axes := shader_axes;
          Transform_axes_to_axes(new_shader_axes, sub_object_ptr^.coord_axes);
        end;

      {********************}
      { complex ray object }
      {********************}
      if sub_object_ptr^.kind = complex_object then
        begin
          ray_object_decl_ptr := sub_object_ptr^.object_decl_ptr;

          if Compressable_ray_object(ray_object_decl_ptr) then
            begin
              {*******************************}
              { copy sub objects' sub objects }
              {*******************************}
              Copy_ray_sub_objects(ray_object_decl_ptr^.sub_object_ptr,
                new_coord_axes, new_attributes, new_shader_axes);
              Copy_ray_sub_objects(ray_object_decl_ptr^.clipping_plane_ptr,
                new_coord_axes, new_attributes, new_shader_axes);
            end
          else
            begin
              {*****************************}
              { make instance of sub object }
              {*****************************}
              Inst_ray_object(ray_object_decl_ptr, new_coord_axes,
                new_attributes, new_shader_axes);
            end;
        end {if complex ray object}

          {**********************}
          { primitive ray object }
          {**********************}
      else
        begin
          ray_object_inst_ptr := New_ray_object_inst;
          ray_object_inst_ptr^ := sub_object_ptr^;
          ray_object_inst_ptr^.coord_axes := new_coord_axes;
          ray_object_inst_ptr^.attributes := new_attributes;
          ray_object_inst_ptr^.shader_axes := new_shader_axes;
          Inst_ray_prim(ray_object_inst_ptr);
        end; {if primitive ray object}

      sub_object_ptr := sub_object_ptr^.next;
    end;
end; {procedure Copy_ray_sub_objects}


procedure Make_ray_sub_objects(sub_object_ptr: object_inst_ptr_type;
  parent_axes: coord_axes_type);
var
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  coord_axes, shader_axes: coord_axes_type;
begin
  {**************************************}
  { make new raytracing sub objects from }
  { reference in geometry data structs   }
  {**************************************}
  while (sub_object_ptr <> nil) do
    begin
      {********************}
      { complex sub object }
      {********************}
      if sub_object_ptr^.kind = complex_object then
        begin
          ray_object_decl_ptr :=
            Find_ray_object(sub_object_ptr^.object_decl_ptr^.object_id);

          {************************************}
          { compute absolute object coord axes }
          {************************************}
          coord_axes := ray_object_decl_ptr^.coord_axes;
          Transform_axes_from_axes(coord_axes,
            Trans_to_axes(sub_object_ptr^.trans));

          {****************************************}
          { compute shader axes relative to object }
          {****************************************}
          shader_axes := Trans_to_axes(sub_object_ptr^.shader_trans);
          Transform_axes_to_axes(shader_axes, coord_axes);

          {*****************************************************}
          { compute object coord axes relative to parent object }
          {*****************************************************}
          Transform_axes_to_axes(coord_axes, parent_axes);

          if Compressable_ray_object(ray_object_decl_ptr) then
            begin
              {*******************************}
              { copy sub objects' sub objects }
              {*******************************}
              Copy_ray_sub_objects(ray_object_decl_ptr^.sub_object_ptr,
                coord_axes, sub_object_ptr^.attributes, shader_axes);
              Copy_ray_sub_objects(ray_object_decl_ptr^.clipping_plane_ptr,
                coord_axes, sub_object_ptr^.attributes, shader_axes);
            end
          else
            begin
              {*****************************}
              { make instance of sub object }
              {*****************************}
              Inst_ray_object(ray_object_decl_ptr, coord_axes,
                sub_object_ptr^.attributes, shader_axes);
            end;
        end {if complex object}

          {**********************}
          { primitive sub object }
          {**********************}
      else if not (sub_object_ptr^.kind in [distant_light, point_light,
        spot_light]) then
        begin
          {******************************}
          { compute primitive coord axes }
          {******************************}
          coord_axes := Trans_to_axes(sub_object_ptr^.trans);

          {*******************************************}
          { compute shader axes relative to primitive }
          {*******************************************}
          shader_axes := Trans_to_axes(sub_object_ptr^.shader_trans);
          Transform_axes_to_axes(shader_axes, coord_axes);

          {********************************************************}
          { compute primitive coord axes relative to parent object }
          {********************************************************}
          Transform_axes_to_axes(coord_axes, parent_axes);

          {*****************************************}
          { instantiate primitive in current object }
          {*****************************************}
          Inst_ray_prim(New_ray_object_prim(sub_object_ptr, coord_axes,
            shader_axes));
        end; {if primitive object}

      sub_object_ptr := sub_object_ptr^.next;
    end;
end; {procedure Make_ray_sub_objects}


procedure Add_ray_object(object_decl_ptr: ray_object_decl_ptr_type;
  object_id: integer);
var
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
begin
  {*********************************}
  { If necessary, create new blocks }
  {*********************************}
  while (number_of_entries < object_id) do
    begin
      if (first_decl_block_ptr = nil) then
        begin
          first_decl_block_ptr := New_decl_block;
          last_decl_block_ptr := first_decl_block_ptr;
        end
      else
        begin
          last_decl_block_ptr^.next := New_decl_block;
          last_decl_block_ptr := last_decl_block_ptr^.next;
        end;
      number_of_entries := number_of_entries + decl_block_size;
    end;

  object_decl_ptr^.object_id := object_id;
  Index_decl_list(object_id, decl_block_ptr, block_index);
  decl_block_ptr^.ptr_array[block_index] := object_decl_ptr;
end; {procedure Add_ray_object}


procedure Write_precalc_mode(mode: precalc_mode_type);
begin
  case mode of
    initial_precalc:
      write('initial_precalc');

    incremental_precalc:
      write('incremental_precalc');

    terminal_precalc:
      write('terminal_precalc');
  end;
end; {procedure Write_precalc_mode}


procedure Make_initial_precalc;
var
  object_ptr: object_decl_ptr_type;
  ray_object_ptr: ray_object_decl_ptr_type;
begin
  {********************************************}
  { duplicate all objects in geometry database }
  {********************************************}
  Goto_first_new_object;
  object_ptr := Next_new_object;
  while (object_ptr <> nil) do
    begin
      ray_object_ptr := New_ray_object_decl;
      ray_object_ptr^.coord_axes :=
        Trans_to_axes(Extent_box_trans(object_ptr^.extent_box));
      Add_ray_object(ray_object_ptr, object_ptr^.object_id);

      {****************************************}
      { make ray objects from geometry objects }
      {****************************************}
      Make_ray_sub_objects(object_ptr^.sub_object_ptr,
        ray_object_ptr^.coord_axes);
      Make_ray_sub_objects(object_ptr^.clipping_plane_ptr,
        ray_object_ptr^.coord_axes);

      End_ray_object_decl;
      object_ptr := Next_new_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  ray_object_ptr :=
    Find_ray_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  Inst_ray_object(ray_object_ptr, Trans_to_axes(geometry_scene_ptr^.trans),
    null_attributes, unit_axes);
end; {procedure Make_initial_precalc}


procedure Make_incremental_precalc;
var
  object_ptr: object_decl_ptr_type;
  ray_object_ptr: ray_object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
begin
  {******************************************************}
  { update raytracing objects to match geometry database }
  {******************************************************}

  {*******************************}
  { first, destroy all raytracing }
  { objects which are unneeded.   }
  {*******************************}
  Goto_first_terminated_object;
  object_ptr := Next_terminated_object;
  while (object_ptr <> nil) do
    begin
      Index_decl_list(object_ptr^.object_id, decl_block_ptr, block_index);
      ray_object_ptr := decl_block_ptr^.ptr_array[block_index];
      Free_voxels(ray_object_ptr^.voxel_space_ptr);
      Free_ray_object(decl_block_ptr^.ptr_array[block_index]);
      object_ptr := Next_terminated_object;
    end;

  {***************************}
  { next, make all raytracing }
  { objects which are needed  }
  {***************************}
  Goto_first_created_object;
  object_ptr := Next_created_object;
  while (object_ptr <> nil) do
    begin
      ray_object_ptr := New_ray_object_decl;
      ray_object_ptr^.coord_axes :=
        Trans_to_axes(Extent_box_trans(object_ptr^.extent_box));
      Add_ray_object(ray_object_ptr, object_ptr^.object_id);

      {****************************************}
      { make ray objects from geometry objects }
      {****************************************}
      Make_ray_sub_objects(object_ptr^.sub_object_ptr,
        ray_object_ptr^.coord_axes);
      Make_ray_sub_objects(object_ptr^.clipping_plane_ptr,
        ray_object_ptr^.coord_axes);

      End_ray_object_decl;
      object_ptr := Next_created_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  ray_object_ptr :=
    Find_ray_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  Inst_ray_object(ray_object_ptr, Trans_to_axes(geometry_scene_ptr^.trans),
    null_attributes, unit_axes);
end; {procedure Make_incremental_precalc}


procedure Make_terminal_precalc;
var
  ray_object_ptr: ray_object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  counter, block_index: integer;
begin
  {********************************************}
  { destroy all objects in raytracing database }
  {********************************************}
  for counter := 1 to number_of_entries do
    begin
      Index_decl_list(counter, decl_block_ptr, block_index);
      ray_object_ptr := decl_block_ptr^.ptr_array[block_index];
      if ray_object_ptr <> nil then
        begin
          Free_voxels(ray_object_ptr^.voxel_space_ptr);
          Free_ray_object(decl_block_ptr^.ptr_array[block_index]);
        end;
    end;
end; {procedure Make_terminal_precalc}


procedure Make_precalc;
var
  object_ptr: object_decl_ptr_type;
  ray_object_ptr: ray_object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
  scene_axes: coord_axes_type;
begin
  {*****************************************}
  { destroy all unneeded raytracing objects }
  {*****************************************}
  Goto_first_terminated_object;
  object_ptr := Next_terminated_object;
  while (object_ptr <> nil) do
    begin
      Index_decl_list(object_ptr^.object_id, decl_block_ptr, block_index);
      if (decl_block_ptr <> nil) then
        begin
          ray_object_ptr := decl_block_ptr^.ptr_array[block_index];
          if (ray_object_ptr <> nil) then
            begin
              Free_voxels(ray_object_ptr^.voxel_space_ptr);
              Free_ray_object(decl_block_ptr^.ptr_array[block_index]);
            end;
        end;
      object_ptr := Next_terminated_object;
    end;

  {**************************************}
  { create all needed raytracing objects }
  {**************************************}
  Goto_first_needed_object;
  object_ptr := Next_needed_object;

  while (object_ptr <> nil) do
    begin
      ray_object_ptr := Find_ray_object(object_ptr^.object_id);
      if (ray_object_ptr = nil) then
        begin
          ray_object_ptr := New_ray_object_decl;
          ray_object_ptr^.coord_axes :=
            Trans_to_axes(Extent_box_trans(object_ptr^.extent_box));
          Add_ray_object(ray_object_ptr, object_ptr^.object_id);

          {****************************************}
          { make ray objects from geometry objects }
          {****************************************}
          Make_ray_sub_objects(object_ptr^.sub_object_ptr,
            ray_object_ptr^.coord_axes);
          Make_ray_sub_objects(object_ptr^.clipping_plane_ptr,
            ray_object_ptr^.coord_axes);

          End_ray_object_decl;
        end;
      object_ptr := Next_needed_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  ray_object_ptr :=
    Find_ray_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  scene_axes := ray_object_ptr^.coord_axes;
  Transform_axes_from_axes(scene_axes,
    Trans_to_axes(geometry_scene_ptr^.trans));

  Inst_ray_object(ray_object_ptr, scene_axes, null_attributes, unit_axes);
end; {procedure Make_precalc}


initialization
  number_of_entries := 0;
  first_decl_block_ptr := nil;
  last_decl_block_ptr := nil;
end.
