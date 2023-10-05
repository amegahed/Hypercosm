unit preview;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              preview                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The preview module builds the viewing data              }
{       structures from the geometry data structs.              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  viewing;


procedure Make_preview;
function Find_view_object(object_id: integer): view_object_decl_ptr_type;


implementation
uses
  errors, new_memory, trans, extents, bounds, b_rep, state_vars, object_attr,
  objects, raytrace, b_rep_quads, b_rep_prims, grid_prims, meshes, anim,
  precalc;


{*******************************************************}
{                 preview data structures               }
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
{       viewing data  |scene|<-->| car |-||             }
{         structs     |-----|    |-----|                }
{                                                       }
{*******************************************************}



const
  decl_block_size = 64;
  memory_alert = false;


type
  preview_mode_type = (initial_preview, incremental_preview, terminal_preview);


  decl_block_ptr_type = ^decl_block_type;
  decl_block_type = record
    ptr_array: array[1..decl_block_size] of view_object_decl_ptr_type;
    next: decl_block_ptr_type;
  end; {decl_block_type}


var
  number_of_entries: integer;
  first_decl_block_ptr, last_decl_block_ptr: decl_block_ptr_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  previous_facets: integer;


function New_decl_block: decl_block_ptr_type;
var
  decl_block_ptr: decl_block_ptr_type;
  counter: integer;
begin
  if memory_alert then
    writeln('allocating new viewing decl block');
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


function Find_view_object(object_id: integer): view_object_decl_ptr_type;
var
  view_object_decl_ptr: view_object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
begin
  Index_decl_list(object_id, decl_block_ptr, block_index);
  if (decl_block_ptr <> nil) then
    view_object_decl_ptr := decl_block_ptr^.ptr_array[block_index]
  else
    view_object_decl_ptr := nil;
  Find_view_object := view_object_decl_ptr;
end; {function Find_view_object}


function Primitive_b_rep(object_ptr: object_inst_ptr_type;
  var new_trans: trans_type): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  mesh_trans: trans_type;
begin
  surface_ptr := nil;

  with object_ptr^ do
    case kind of

      {********************}
      { quadric primitives }
      {********************}
      sphere:
        surface_ptr := Sphere_b_rep(umin, umax, vmin, vmax);

      cylinder:
        surface_ptr := Cylinder_b_rep(umin, umax);

      cone:
        surface_ptr := Cone_b_rep(inner_radius, umin, umax);

      paraboloid:
        surface_ptr := Paraboloid_b_rep(umin, umax);

      hyperboloid1:
        surface_ptr := Hyperboloid1_b_rep(inner_radius, umin, umax);

      hyperboloid2:
        surface_ptr := Hyperboloid2_b_rep(eccentricity, umin, umax);

      {*******************}
      { planar primitives }
      {*******************}
      plane:
        surface_ptr := Plane_b_rep;

      disk:
        surface_ptr := Disk_b_rep(umin, umax);

      ring:
        surface_ptr := Ring_b_rep(inner_radius, umin, umax);

      triangle:
        surface_ptr := Triangle_b_rep;

      parallelogram:
        surface_ptr := Parallelogram_b_rep;

      flat_polygon:
        surface_ptr := Polygon_b_rep(polygon_ptr);

      {***********************}
      { non_planar primitives }
      {***********************}
      torus:
        surface_ptr := Torus_b_rep(inner_radius, umin, umax, vmin, vmax);

      block:
        surface_ptr := Block_b_rep;

      shaded_triangle:
        with triangle_normal_ptr^ do
          surface_ptr := Shaded_triangle_b_rep(normal1, normal2, normal3);

      shaded_polygon:
        surface_ptr := Shaded_polygon_b_rep(shaded_polygon_ptr);

      mesh:
        surface_ptr := Mesh_b_rep(mesh_ptr, smoothing, mending, closed, true);

      blob:
        begin
          surface_ptr := Blob_b_rep(metaball_ptr, threshold, dimensions);
          Unitize_mesh(surface_ptr, mesh_trans);
          Transform_trans(mesh_trans, new_trans);
          new_trans := mesh_trans;
        end;

      {************************}
      { non_surface primitives }
      {************************}
      points:
        surface_ptr := Point_b_rep(points_ptr);

      lines:
        surface_ptr := Line_b_rep(lines_ptr);

      volume:
        begin
          surface_ptr := Volume_b_rep(volume_ptr);
          Unitize_mesh(surface_ptr, mesh_trans);
          Transform_trans(mesh_trans, new_trans);
          new_trans := mesh_trans;
        end;

    end; {case}

  Primitive_b_rep := surface_ptr;
end; {procedure Primitive_b_rep}


function Compressable_view_object(view_object_decl_ptr:
  view_object_decl_ptr_type): boolean;
var
  compressable: boolean;
begin
  if not hierarchy_compression then
    compressable := false
  else if (view_object_decl_ptr^.sub_object_number > min_object_complexity) then
    compressable := false
  else if (view_object_decl_ptr^.clipping_plane_ptr <> nil) then
    compressable := false
  else
    compressable := true;

  Compressable_view_object := compressable;
end; {function Compressable_view_object}


procedure Copy_view_sub_objects(sub_object_ptr: view_object_inst_ptr_type;
  trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type);
var
  surface_ptr: surface_ptr_type;
  view_object_decl_ptr: view_object_decl_ptr_type;
  new_trans, new_shader_trans: trans_type;
  new_attributes: object_attributes_type;
begin
  {***********************************}
  { copy previously created view sub  }
  { objects to a new view object decl }
  {***********************************}
  while (sub_object_ptr <> nil) do
    begin
      {*************************************}
      { transform sub object to new context }
      {*************************************}
      new_trans := sub_object_ptr^.trans;
      Transform_trans(new_trans, trans);

      new_attributes := sub_object_ptr^.attributes;
      Apply_object_attributes(new_attributes, attributes);

      {***********************************}
      { compute new shader transformation }
      {***********************************}
      if (sub_object_ptr^.attributes.shader_ptr <> shader_ptr_type(nil)) then
        begin
          new_shader_trans := sub_object_ptr^.shader_trans;
          Transform_trans(new_shader_trans, trans);
        end
      else
        new_shader_trans := shader_trans;

      case sub_object_ptr^.kind of

        {*********************}
        { complex view object }
        {*********************}
        view_object_decl:
          begin
            view_object_decl_ptr := sub_object_ptr^.object_decl_ptr;

            if Compressable_view_object(view_object_decl_ptr) then
              begin
                {*******************************}
                { copy sub objects' sub objects }
                {*******************************}
                Copy_view_sub_objects(view_object_decl_ptr^.sub_object_ptr,
                  new_trans, new_attributes, new_shader_trans);
                Copy_view_sub_objects(view_object_decl_ptr^.clipping_plane_ptr,
                  new_trans, new_attributes, new_shader_trans);
              end
            else
              begin
                {*****************************}
                { make instance of sub object }
                {*****************************}
                Inst_view_object(view_object_decl_ptr, new_trans,
                  new_attributes, new_shader_trans, ray_object_ptr,
                  sub_object_ptr^.geom_object_ptr,
                  sub_object_ptr^.bounding_kind);
                if ray_object_ptr <> nil then
                  ray_object_ptr := ray_object_ptr^.next
              end;
          end; {complex view objects}

        {***********************}
        { primitive view object }
        {***********************}
        view_object_prim:
          begin
            surface_ptr := Copy_surface(sub_object_ptr^.surface_ptr);
            Inst_view_prim(surface_ptr, new_trans, new_attributes,
              new_shader_trans, ray_object_ptr, sub_object_ptr^.geom_object_ptr,
              sub_object_ptr^.bounding_kind);
            if ray_object_ptr <> nil then
              ray_object_ptr := ray_object_ptr^.next;
          end; {primitive view objects}

        {***********************}
        { clipping plane object }
        {***********************}
        view_object_clip:
          begin
            Inst_view_clip(new_trans, new_attributes, new_shader_trans,
              ray_object_ptr, sub_object_ptr^.geom_object_ptr);
            if ray_object_ptr <> nil then
              ray_object_ptr := ray_object_ptr^.next;
          end; {clipping planes}

      end; {case}

      sub_object_ptr := sub_object_ptr^.next;
    end; {while}
end; {procedure Copy_view_sub_objects}


procedure Make_view_sub_objects(sub_object_ptr: object_inst_ptr_type);
var
  view_object_decl_ptr: view_object_decl_ptr_type;
  surface_ptr: surface_ptr_type;
  bounding_kind: bounding_kind_type;
  new_trans: trans_type;
begin
  {************************************}
  { make new viewing sub objects from  }
  { reference in geometry data structs }
  {************************************}
  while (sub_object_ptr <> nil) do
    begin
      {********************}
      { complex sub object }
      {********************}
      if sub_object_ptr^.kind = complex_object then
        begin
          view_object_decl_ptr :=
            Find_view_object(sub_object_ptr^.object_decl_ptr^.object_id);

          if Compressable_view_object(view_object_decl_ptr) then
            begin
              {*******************************}
              { copy sub objects' sub objects }
              {*******************************}
              Copy_view_sub_objects(view_object_decl_ptr^.sub_object_ptr,
                sub_object_ptr^.trans, sub_object_ptr^.attributes,
                sub_object_ptr^.shader_trans);
              Copy_view_sub_objects(view_object_decl_ptr^.clipping_plane_ptr,
                sub_object_ptr^.trans, sub_object_ptr^.attributes,
                sub_object_ptr^.shader_trans);
            end
          else
            begin
              {*****************************}
              { make instance of sub object }
              {*****************************}
              if (sub_object_ptr^.object_decl_ptr^.infinite) then
                bounding_kind := infinite_non_planar_bounds
              else if
                Null_extent_box(sub_object_ptr^.object_decl_ptr^.extent_box)
                  then
                bounding_kind := null_bounds
              else
                bounding_kind := non_planar_bounds;

              Inst_view_object(view_object_decl_ptr, sub_object_ptr^.trans,
                sub_object_ptr^.attributes, sub_object_ptr^.shader_trans,
                ray_object_ptr, sub_object_ptr, bounding_kind);
              if ray_object_ptr <> nil then
                ray_object_ptr := ray_object_ptr^.next;
            end;
        end {if complex object}

          {***************************}
          { clipping plane sub object }
          {***************************}
      else if sub_object_ptr^.kind = clipping_plane then
        begin
          new_trans := sub_object_ptr^.trans;
          Inst_view_clip(new_trans, sub_object_ptr^.attributes,
            sub_object_ptr^.shader_trans, ray_object_ptr, sub_object_ptr);
          if ray_object_ptr <> nil then
            ray_object_ptr := ray_object_ptr^.next;
        end {if clipping plane}

          {**********************}
          { primitive sub object }
          {**********************}
      else if not (sub_object_ptr^.kind in [distant_light, point_light,
        spot_light]) then
        begin
          new_trans := sub_object_ptr^.trans;
          bounding_kind := Object_bounding_kind(sub_object_ptr^.kind);
          surface_ptr := Primitive_b_rep(sub_object_ptr, new_trans);
          Inst_view_prim(surface_ptr, new_trans, sub_object_ptr^.attributes,
            sub_object_ptr^.shader_trans, ray_object_ptr, sub_object_ptr,
            bounding_kind);
          if ray_object_ptr <> nil then
            ray_object_ptr := ray_object_ptr^.next;
        end; {if light source}

      sub_object_ptr := sub_object_ptr^.next;
    end; {while}
end; {procedure Make_view_sub_objects}


procedure Add_view_object(object_decl_ptr: view_object_decl_ptr_type;
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

  if (decl_block_ptr^.ptr_array[block_index] = nil) then
    decl_block_ptr^.ptr_array[block_index] := object_decl_ptr
  else
    Error('tried to overwrite an existing object');
end; {procedure Add_view_object}


procedure Write_preview_mode(mode: preview_mode_type);
begin
  case mode of

    initial_preview:
      write('initial_preview');

    incremental_preview:
      write('incremental_preview');

    terminal_preview:
      write('terminal_preview');

  end; {case}
end; {procedure Write_preview_mode}


procedure Make_initial_preview;
var
  object_ptr: object_decl_ptr_type;
  view_object_ptr: view_object_decl_ptr_type;
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  bounding_kind: bounding_kind_type;
begin
  {********************************************}
  { duplicate all objects in geometry database }
  {********************************************}
  Goto_first_new_object;
  object_ptr := Next_new_object;
  while (object_ptr <> nil) do
    begin
      view_object_ptr := New_view_object_decl;
      {view_object_ptr^.trans := Inverse_trans(Extent_box_to_trans(object_ptr^.extent_box));}
      {view_object_ptr^.trans := unit_trans;}

      view_object_ptr^.extent_box := object_ptr^.extent_box;
      Add_view_object(view_object_ptr, object_ptr^.object_id);

      if (render_mode in [shaded_mode, shaded_line_mode]) and (shadows or
        reflections or refractions or (facets < 1)) then
        begin
          ray_object_decl_ptr := Find_ray_object(object_ptr^.object_id);
          ray_object_ptr := ray_object_decl_ptr^.sub_object_ptr;
        end
      else
        ray_object_ptr := nil;

      {*****************************************}
      { make view objects from geometry objects }
      {*****************************************}
      Make_view_sub_objects(object_ptr^.sub_object_ptr);
      Make_view_sub_objects(object_ptr^.clipping_plane_ptr);

      End_view_object_decl;
      object_ptr := Next_new_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  view_object_ptr :=
    Find_view_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  if (geometry_scene_ptr^.object_decl_ptr^.infinite) then
    bounding_kind := infinite_non_planar_bounds
  else
    bounding_kind := non_planar_bounds;

  Inst_view_object(view_object_ptr, geometry_scene_ptr^.trans, null_attributes,
    unit_trans, raytracing_scene_ptr, geometry_scene_ptr, bounding_kind);
end; {procedure Make_initial_preview}


procedure Make_incremental_preview;
var
  object_ptr: object_decl_ptr_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
  view_object_ptr: view_object_decl_ptr_type;
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  bounding_kind: bounding_kind_type;
begin
  {***************************************************}
  { update viewing objects to match geometry database }
  {***************************************************}

  {****************************}
  { first, destroy all preview }
  { objects which are unneeded }
  {****************************}
  Goto_first_terminated_object;
  object_ptr := Next_terminated_object;
  while (object_ptr <> nil) do
    begin
      if (object_ptr^.object_id <= number_of_entries) then
        begin
          Index_decl_list(object_ptr^.object_id, decl_block_ptr, block_index);
          Free_view_object(decl_block_ptr^.ptr_array[block_index]);
          object_ptr := Next_terminated_object;
        end;
    end;

  {**************************}
  { next, make all preview   }
  { objects which are needed }
  {**************************}
  Goto_first_created_object;
  object_ptr := Next_created_object;
  while (object_ptr <> nil) do
    begin
      view_object_ptr := New_view_object_decl;
      {view_object_ptr^.trans := Inverse_trans(Extent_box_to_trans(object_ptr^.extent_box));}
      {view_object_ptr^.trans := unit_trans;}
      view_object_ptr^.extent_box := object_ptr^.extent_box;
      Add_view_object(view_object_ptr, object_ptr^.object_id);

      if (render_mode in [shaded_mode, shaded_line_mode]) and (shadows or
        reflections or refractions or (facets < 1)) then
        begin
          ray_object_decl_ptr := Find_ray_object(object_ptr^.object_id);
          ray_object_ptr := ray_object_decl_ptr^.sub_object_ptr;
        end
      else
        ray_object_ptr := nil;

      {*****************************************}
      { make view objects from geometry objects }
      {*****************************************}
      Make_view_sub_objects(object_ptr^.sub_object_ptr);
      Make_view_sub_objects(object_ptr^.clipping_plane_ptr);

      End_view_object_decl;
      object_ptr := Next_created_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  view_object_ptr :=
    Find_view_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  if (geometry_scene_ptr^.object_decl_ptr^.infinite) then
    bounding_kind := infinite_non_planar_bounds
  else
    bounding_kind := non_planar_bounds;

  Inst_view_object(view_object_ptr, geometry_scene_ptr^.trans, null_attributes,
    unit_trans, raytracing_scene_ptr, geometry_scene_ptr, bounding_kind);
end; {procedure Make_incremental_preview}


procedure Make_terminal_preview;
var
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
  counter: integer;
begin
  {*****************************************}
  { destroy all objects in viewing database }
  {*****************************************}
  for counter := 1 to number_of_entries do
    begin
      Index_decl_list(counter, decl_block_ptr, block_index);
      Free_view_object(decl_block_ptr^.ptr_array[block_index]);
    end;
end; {procedure Make_terminal_preview}


procedure Make_preview;
var
  object_ptr: object_decl_ptr_type;
  view_object_ptr: view_object_decl_ptr_type;
  ray_object_decl_ptr: ray_object_decl_ptr_type;
  bounding_kind: bounding_kind_type;
  decl_block_ptr: decl_block_ptr_type;
  block_index: integer;
begin
  if (Get_facets <> previous_facets) then
    begin
      Make_terminal_preview;
      Free_faceted_b_reps;
      previous_facets := Get_facets;
    end;

  {**************************************}
  { destroy all unneeded viewing objects }
  {**************************************}
  Goto_first_terminated_object;
  object_ptr := Next_terminated_object;
  while (object_ptr <> nil) do
    begin
      if (object_ptr^.object_id <= number_of_entries) then
        begin
          Index_decl_list(object_ptr^.object_id, decl_block_ptr, block_index);
          if (decl_block_ptr <> nil) then
            Free_view_object(decl_block_ptr^.ptr_array[block_index]);
          object_ptr := Next_terminated_object;
        end;
    end;

  {***********************************}
  { create all needed viewing objects }
  {***********************************}
  Goto_first_needed_object;
  object_ptr := Next_needed_object;

  while (object_ptr <> nil) do
    begin
      view_object_ptr := Find_view_object(object_ptr^.object_id);
      if (view_object_ptr = nil) then
        begin
          view_object_ptr := New_view_object_decl;
          {view_object_ptr^.trans := Inverse_trans(Extent_box_to_trans(object_ptr^.extent_box));}
          {view_object_ptr^.trans := unit_trans;}
          view_object_ptr^.extent_box := object_ptr^.extent_box;
          Add_view_object(view_object_ptr, object_ptr^.object_id);

          if (render_mode in [shaded_mode, shaded_line_mode]) and (shadows or
            reflections or refractions or (facets < 1)) then
            begin
              ray_object_decl_ptr := Find_ray_object(object_ptr^.object_id);
              if ray_object_decl_ptr <> nil then
                ray_object_ptr := ray_object_decl_ptr^.sub_object_ptr
              else
                ray_object_ptr := nil;
            end
          else
            ray_object_ptr := nil;

          {*****************************************}
          { make view objects from geometry objects }
          {*****************************************}
          Make_view_sub_objects(object_ptr^.sub_object_ptr);
          Make_view_sub_objects(object_ptr^.clipping_plane_ptr);

          End_view_object_decl;
        end;
      object_ptr := Next_needed_object;
    end;

  {*****************************}
  { last, make the scene object }
  {*****************************}
  view_object_ptr :=
    Find_view_object(geometry_scene_ptr^.object_decl_ptr^.object_id);
  if (geometry_scene_ptr^.object_decl_ptr^.infinite) then
    bounding_kind := infinite_non_planar_bounds
  else
    bounding_kind := non_planar_bounds;

  Inst_view_object(view_object_ptr, geometry_scene_ptr^.trans, null_attributes,
    unit_trans, raytracing_scene_ptr, geometry_scene_ptr, bounding_kind);
end; {procedure Make_preview}


initialization
  number_of_entries := 0;
  first_decl_block_ptr := nil;
  last_decl_block_ptr := nil;
  previous_facets := -1;
end.
