unit objects;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              objects                  3d       }
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
uses
  strings, vectors, trans, extents, bounds, object_attr, polygons, polymeshes,
  volumes, trans_stack, attr_stack;


type
  object_kind_type = (complex_object,

    {********************}
    { quadric primitives }
    {********************}
    sphere, cylinder, cone, paraboloid, hyperboloid1, hyperboloid2,

    {*******************}
    { planar primitives }
    {*******************}
    plane, disk, ring, triangle, parallelogram, flat_polygon,

    {***********************}
    { non-planar primitives }
    {***********************}
    torus, block, shaded_triangle, shaded_polygon, mesh, blob,

    {************************}
    { non-surface primitives }
    {************************}
    points, lines, volume,

    {*********************}
    { clipping primitives }
    {*********************}
    clipping_plane,

    {*********************}
    { lighting primitives }
    {*********************}
    distant_light, point_light, spot_light); {object_kind_type}


  triangle_normal_ptr_type = ^triangle_normal_type;
  triangle_normal_type = record
    normal1, normal2, normal3: vector_type;
    next: triangle_normal_ptr_type;
  end; {triangle_normal_type}


  {**************************************************}
  { two types of objects: instances and declarations }
  {**************************************************}
  object_inst_ptr_type = ^object_inst_type;
  object_decl_ptr_type = ^object_decl_type;


  {*****************}
  { object instance }
  {*****************}
  object_inst_type = record
    next: object_inst_ptr_type;

    attributes: object_attributes_type;
    trans, shader_trans: trans_type;

    umin, umax: real;
    vmin, vmax: real;

    case kind: object_kind_type of

      complex_object: (
        object_decl_ptr: object_decl_ptr_type
        );

      {**********************}
      { geometric primitives }
      {**********************}
      plane: (
        );

      disk, sphere, cylinder, paraboloid: (
        );

      hyperboloid2: (
        eccentricity: real;
        );

      triangle, parallelogram, block: (
        );

      shaded_triangle: (
        triangle_normal_ptr: triangle_normal_ptr_type;
        );

      ring, cone, hyperboloid1, torus: (
        inner_radius: real;
        );

      blob: (
        threshold: real;
        dimensions: vector_type;
        metaball_ptr: metaball_ptr_type;
        );

      {************************}
      { tessellated primitives }
      {************************}
      flat_polygon: (
        polygon_ptr: polygon_ptr_type;
        );

      shaded_polygon: (
        shaded_polygon_ptr: shaded_polygon_ptr_type
        );

      mesh: (
        mesh_ptr: mesh_ptr_type;
        smoothing, mending, closed: boolean;
        );

      points: (
        points_ptr: points_ptr_type
        );

      lines: (
        lines_ptr: lines_ptr_type
        );

      volume: (
        volume_ptr: volume_ptr_type;
        );

      {*********************}
      { clipping primitives }
      {*********************}
      clipping_plane: (
        );

      {*********************}
      { lighting primitives }
      {*********************}
      distant_light, point_light, spot_light: (
        shadows: boolean;
        spot_angle: real;
        );
  end; {object_inst_type}


  {********************}
  { object declaration }
  {********************}
  object_decl_type = record

    {********************}
    { object identifiers }
    {********************}
    object_id: integer;
    object_decl_id: integer;

    {*****************}
    { sub object list }
    {*****************}
    sub_object_number: integer;
    sub_object_ptr, last_sub_object_ptr: object_inst_ptr_type;
    clipping_plane_ptr, last_clipping_plane_ptr: object_inst_ptr_type;

    {*******************}
    { object attributes }
    {*******************}
    extent_box: extent_box_type;
    luminous: boolean;
    infinite: boolean;

    {**************}
    { object links }
    {**************}
    next, prev: object_decl_ptr_type;
  end; {object_decl_type}


const
  light_sources = [distant_light, point_light, spot_light];
  curved_prims = [sphere..hyperboloid2, torus, blob];
  self_similar_prims = [sphere, cylinder, paraboloid, disk, triangle,
    parallelogram, block];
  tessellated_prims = [flat_polygon, shaded_polygon, mesh, points, lines,
    volume];


var
  geometry_scene_ptr: object_inst_ptr_type;
  geometry_decls_ptr: object_decl_ptr_type;
  last_geometry_decl_ptr: object_decl_ptr_type;
  current_geometry_decl_ptr: object_decl_ptr_type;


  {***********************}
  { transformation stacks }
  {***********************}
  model_trans_stack_ptr: trans_stack_ptr_type;
  shader_trans_stack_ptr: trans_stack_ptr_type;
  model_attr_stack_ptr: attributes_stack_ptr_type;


  {***********************************************************}
  { This constant governs how complex an object must be to    }
  { warrant a complex object to be created. If this constant  }
  { is set too low, then aggregate objects will be too simple }
  { to justify the overhead in visibility and transformation  }
  { costs. If the constant is too high, then the hierarchy    }
  { will be flattened out too much to reap the benefits of    }
  { the hierarchical description.                             }
  {***********************************************************}
  hierarchy_compression: boolean;
  min_object_complexity: integer;


{********************************}
{ routines for declaring objects }
{********************************}
function New_geom_object_decl: object_decl_ptr_type;
procedure End_geom_object_decl;

procedure Push_object_stack(object_decl_ptr: object_decl_ptr_type);
function Pop_object_stack: object_decl_ptr_type;

{************************************}
{ routines for instantiating objects }
{************************************}
function New_geom_object_inst(kind: object_kind_type): object_inst_ptr_type;
procedure Inst_geom_prim(object_ptr: object_inst_ptr_type);
procedure Inst_geom_object(object_decl_ptr: object_decl_ptr_type;
  trans: trans_type);

{******************************************}
{ routines for creating primitive geometry }
{******************************************}
function New_triangle_normals(normal1: vector_type;
  normal2: vector_type;
  normal3: vector_type): triangle_normal_ptr_type;

{**************************************}
{ routine for freeing of an object's   }
{ declaration and all of its instances }
{**************************************}
procedure Write_object_kind(object_kind: object_kind_type);
procedure Free_geom_object(object_decl_ptr: object_decl_ptr_type);
function Object_bounding_kind(kind: object_kind_type): bounding_kind_type;


implementation
uses
  errors, new_memory, colors, state_vars;


{*******************************************************}
{               geometry data structures                }
{*******************************************************}
{       Note: decls are linked in chronological order   }
{       of their declaration: from simple to complex.   }
{                                                       }
{       Not shown: backpointers are kept from each      }
{       declaration of an object to each of its         }
{       instances and the parent of each instance.      }
{                                                       }
{                <- next        prev->                  }
{                                                       }
{       |-----|    |-----|    |-----|    |-----|        }
{    \\-|scene|<-->| car |<-->| axel|<-->|wheel|<-decls }
{       |-----| /->|-----| /->|-----| /->|-----|        }
{          |    |     |    |     |    |     |           }
{       /-----\ |  /-----\ |  /-----\ |  /-----\        }
{       | car |-/  | axel|-|  |wheel|-|  |cylnd|        }
{       \-----/    \-----/ |  \-----/ |  \-----/        }
{          |          |    |     |    |     |           }
{       /-----\    /-----\ |  /-----\ |  /-----\        }
{       |plane|    | axel|-/  |wheel|-/  |cylnd|        }
{       \-----/    \-----/    \-----/    \-----/        }
{          |          |          |          |           }
{       /-----\    /-----\    /-----\                   }
{       |light|    |block|    |cylnd|                   }
{       \-----/    \-----/    \-----/                   }
{          |          |          |                      }
{          -          -          -                      }
{*******************************************************}


{*******************************************************}
{       geometry_decls_ptr always points to the         }
{       most primitive (least complex) object decl.     }
{               (the first one declared)                }
{                                                       }
{       last_geometry_decl_ptr always points to the     }
{       least primitive (most complex) object decl      }
{               (the last one declared)                 }
{                                                       }
{       In the case that objects are generated          }
{       recursively, the build order is reversed.       }
{       The most complex object is made, then the       }
{       subobjets are made, then we go back to the      }
{       complex object again. To implement this, we     }
{       need a stack, and current_geometry_decl_ptr     }
{       always points to the current object being       }
{       defined which is at the top of the stack.       }
{*******************************************************}


const
  stack_size = 256;
  memory_alert = false;


type
  object_decl_stack_ptr_type = ^object_decl_stack_type;
  object_decl_stack_type = array[1..stack_size] of object_decl_ptr_type;


var
  {******************************************}
  { stacks for defining hierarchy of objects }
  {******************************************}
  object_stack: object_decl_stack_ptr_type;
  object_stack_ptr: integer;

  {**************************************************}
  { free lists for object instances and declarations }
  {**************************************************}
  inst_free_list: object_inst_ptr_type;
  decl_free_list: object_decl_ptr_type;
  triangle_normal_free_list: triangle_normal_ptr_type;


procedure Push_object_stack(object_decl_ptr: object_decl_ptr_type);
begin
  if (object_stack_ptr < stack_size) then
    begin
      object_stack_ptr := object_stack_ptr + 1;
      object_stack^[object_stack_ptr] := object_decl_ptr;
      current_geometry_decl_ptr := object_decl_ptr;
    end
  else
    Error('object stack overflow');
end; {function Push_object_stack}


function Pop_object_stack: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  object_decl_ptr := nil;

  if (object_stack_ptr > 0) then
    begin
      object_decl_ptr := object_stack^[object_stack_ptr];
      object_stack_ptr := object_stack_ptr - 1;
      current_geometry_decl_ptr := object_stack^[object_stack_ptr];
    end
  else
    Error('object stack underflow');

  Pop_object_stack := object_decl_ptr;
end; {function Pop_object_stack}


{*******************************************}
{ routines for creating object declarations }
{*******************************************}


procedure Init_geom_object_decl(object_decl_ptr: object_decl_ptr_type);
begin
  with object_decl_ptr^ do
    begin
      {*******************************}
      { initialize object identifiers }
      {*******************************}
      object_id := 0;
      object_decl_id := 0;

      {*****************}
      { sub object list }
      {*****************}
      sub_object_number := 0;
      sub_object_ptr := nil;
      last_sub_object_ptr := nil;
      clipping_plane_ptr := nil;
      last_clipping_plane_ptr := nil;

      {*******************}
      { object attributes }
      {*******************}
      Init_extent_box(extent_box);
      luminous := false;
      infinite := false;

      {**************}
      { object links }
      {**************}
      next := nil;
      prev := nil;
    end;
end; {procedure Init_geom_object_decl}


function New_geom_object_decl: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  {*************************************}
  { get geom object decl from free list }
  {*************************************}
  if (decl_free_list <> nil) then
    begin
      object_decl_ptr := decl_free_list;
      decl_free_list := decl_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new object decl');
      new(object_decl_ptr);
    end;

  {*****************************}
  { initialize geom object decl }
  {*****************************}
  Init_geom_object_decl(object_decl_ptr);

  Push_object_stack(object_decl_ptr);
  New_geom_object_decl := object_decl_ptr;
end; {function New_geom_object_decl}


{****************************************}
{ routines for creating object instances }
{****************************************}


procedure Init_geom_object_inst(object_inst_ptr: object_inst_ptr_type;
  kind: object_kind_type);
begin
  object_inst_ptr^.kind := kind;

  with object_inst_ptr^ do
    begin
      attributes := null_attributes;
      umin := 0;
      umax := 0;
      vmin := 0;
      vmax := 0;
      next := nil;
    end;
end; {procedure Init_geom_object_inst}


function New_geom_object_inst(kind: object_kind_type): object_inst_ptr_type;
var
  object_inst_ptr: object_inst_ptr_type;
begin
  {*****************************}
  { get instance from free list }
  {*****************************}
  if (inst_free_list <> nil) then
    begin
      object_inst_ptr := inst_free_list;
      inst_free_list := inst_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new object inst');
      new(object_inst_ptr);
    end;

  {*****************************}
  { initialize geom object inst }
  {*****************************}
  Init_geom_object_inst(object_inst_ptr, kind);

  New_geom_object_inst := object_inst_ptr;
end; {function New_geom_object_inst}


{************************************************}
{ routines to allocate and free triangle normals }
{************************************************}


function New_triangle_normals(normal1: vector_type;
  normal2: vector_type;
  normal3: vector_type): triangle_normal_ptr_type;
var
  triangle_normal_ptr: triangle_normal_ptr_type;
begin
  {*************************************}
  { get triangle normals from free list }
  {*************************************}
  if (triangle_normal_free_list <> nil) then
    begin
      triangle_normal_ptr := triangle_normal_free_list;
      triangle_normal_free_list := triangle_normal_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new triangle normals');
      new(triangle_normal_ptr);
    end;

  {*****************************}
  { initialize triangle normals }
  {*****************************}
  triangle_normal_ptr^.normal1 := normal1;
  triangle_normal_ptr^.normal2 := normal2;
  triangle_normal_ptr^.normal3 := normal3;
  triangle_normal_ptr^.next := nil;

  New_triangle_normals := triangle_normal_ptr;
end; {function New_triangle_normals}


procedure Free_triangle_normals(var triangle_normal_ptr:
  triangle_normal_ptr_type);
begin
  triangle_normal_ptr^.next := triangle_normal_free_list;
  triangle_normal_free_list := triangle_normal_ptr;
  triangle_normal_ptr := nil;
end; {procedure Free_triangle_normals}


{****************************}
{ routines to create objects }
{****************************}


procedure Set_default_color(object_ptr: object_inst_ptr_type);
var
  color: color_type;
begin
  case object_ptr^.kind of
    complex_object:
      color := white_color;

    {********************}
    { quadric primitives }
    {********************}
    sphere:
      color := sphere_color;
    cylinder:
      color := cylinder_color;
    cone:
      color := cone_color;
    paraboloid:
      color := paraboloid_color;
    hyperboloid1:
      color := hyperboloid1_color;
    hyperboloid2:
      color := hyperboloid2_color;

    {*******************}
    { planar primitives }
    {*******************}
    plane:
      color := plane_color;
    disk:
      color := disk_color;
    ring:
      color := ring_color;
    triangle:
      color := triangle_color;
    parallelogram:
      color := parallelogram_color;
    flat_polygon:
      color := polygon_color;

    {***********************}
    { non-planar primitives }
    {***********************}
    torus:
      color := torus_color;
    block:
      color := block_color;
    shaded_triangle:
      color := shaded_triangle_color;
    shaded_polygon:
      color := shaded_polygon_color;
    mesh:
      color := mesh_color;
    blob:
      color := blob_color;

    {************************}
    { non-surface primitives }
    {************************}
    points:
      color := point_color;
    lines:
      color := line_color;
    volume:
      color := volume_color;

    {*********************}
    { clipping primitives }
    {*********************}
    clipping_plane:
      color := white_color;

    {*********************}
    { lighting primitives }
    {*********************}
    distant_light, point_light, spot_light:
      color := white_color;
  end;

  {***********************}
  { set object attributes }
  {***********************}
  Set_default_color_attributes(object_ptr^.attributes, color);
end; {procedure Set_default_color}


procedure Inst_geom_prim(object_ptr: object_inst_ptr_type);
var
  trans: trans_type;
begin
  if (object_ptr <> nil) then
    begin
      {*******************}
      { set special flags }
      {*******************}
      if (object_ptr^.kind = plane) then
        current_geometry_decl_ptr^.infinite := true;
      if (object_ptr^.kind in light_sources) then
        current_geometry_decl_ptr^.luminous := true;

      Get_attributes_stack(model_attr_stack_ptr, object_ptr^.attributes);
      Set_default_color(object_ptr);

      {****************************************}
      { transform primitive to current context }
      {****************************************}
      Get_trans_stack(model_trans_stack_ptr, trans);
      Transform_trans(object_ptr^.trans, trans);

      {******************}
      { set shader trans }
      {******************}
      Get_trans_stack(shader_trans_stack_ptr, object_ptr^.shader_trans);

      {****************************}
      { add object to current decl }
      {****************************}
      object_ptr^.next := nil;
      with current_geometry_decl_ptr^ do
        begin

          {****************************}
          { add to clipping plane list }
          {****************************}
          if object_ptr^.kind = clipping_plane then
            begin
              if (last_clipping_plane_ptr <> nil) then
                begin
                  last_clipping_plane_ptr^.next := object_ptr;
                  last_clipping_plane_ptr := object_ptr;
                end
              else
                begin
                  clipping_plane_ptr := object_ptr;
                  last_clipping_plane_ptr := object_ptr;
                end;
            end

              {************************}
              { add to sub object list }
              {************************}
          else
            begin
              if (last_sub_object_ptr <> nil) then
                begin
                  last_sub_object_ptr^.next := object_ptr;
                  last_sub_object_ptr := object_ptr;
                end
              else
                begin
                  sub_object_ptr := object_ptr;
                  last_sub_object_ptr := object_ptr;
                end;

              if not (object_ptr^.kind in light_sources) then
                sub_object_number := sub_object_number + 1;
            end;
        end;
    end;
end; {procedure Inst_geom_prim}


procedure Inst_geom_object(object_decl_ptr: object_decl_ptr_type;
  trans: trans_type);
var
  object_ptr: object_inst_ptr_type;
begin
  if (object_decl_ptr <> nil) then
    begin
      {*************************}
      { make instance of object }
      {*************************}
      object_ptr := New_geom_object_inst(complex_object);
      object_ptr^.trans := trans;
      object_ptr^.object_decl_ptr := object_decl_ptr;

      {***********************}
      { set object attributes }
      {***********************}
      Get_attributes_stack(model_attr_stack_ptr, object_ptr^.attributes);
      Set_default_color(object_ptr);

      {******************}
      { set shader trans }
      {******************}
      Get_trans_stack(shader_trans_stack_ptr, object_ptr^.shader_trans);

      if (current_geometry_decl_ptr <> nil) then
        begin
          {*******************}
          { set special flags }
          {*******************}
          if (object_decl_ptr^.luminous) then
            current_geometry_decl_ptr^.luminous := true;
          if (object_decl_ptr^.infinite) then
            current_geometry_decl_ptr^.infinite := true;

          {****************************}
          { add object to current decl }
          {****************************}
          object_ptr^.next := nil;
          with current_geometry_decl_ptr^ do
            begin
              if (last_sub_object_ptr <> nil) then
                begin
                  last_sub_object_ptr^.next := object_ptr;
                  last_sub_object_ptr := object_ptr;
                end
              else
                begin
                  sub_object_ptr := object_ptr;
                  last_sub_object_ptr := object_ptr;
                end;

              if not (object_ptr^.kind in light_sources) then
                sub_object_number := sub_object_number + 1;
            end;
        end
      else
        begin
          {**********************************}
          { make object current scene object }
          {**********************************}
          if geometry_scene_ptr <> nil then
            begin
              geometry_scene_ptr^.next := inst_free_list;
              inst_free_list := geometry_scene_ptr;
            end;
          geometry_scene_ptr := object_ptr;
        end;
    end
  else
    Error('Can not instantiate a nonexistant object.');
end; {procedure Inst_geom_object}


procedure Make_object_bounds(var bounds: bounding_type;
  object_ptr: object_inst_ptr_type);
var
  bounds_trans: trans_type;
begin
  case object_ptr^.kind of
    plane:
      Make_bounds(bounds, infinite_planar_bounds, object_ptr^.trans);

    disk, ring, triangle, shaded_triangle, parallelogram:
      Make_bounds(bounds, planar_bounds, object_ptr^.trans);

    sphere, cylinder, cone, paraboloid, hyperboloid1, hyperboloid2:
      Make_bounds(bounds, non_planar_bounds, object_ptr^.trans);

    block, torus, flat_polygon, shaded_polygon, mesh, blob:
      Make_bounds(bounds, non_planar_bounds, object_ptr^.trans);

    points, lines, volume:
      Make_bounds(bounds, non_planar_bounds, object_ptr^.trans);

    clipping_plane:
      Make_bounds(bounds, null_bounds, object_ptr^.trans);

    distant_light, point_light, spot_light:
      Make_bounds(bounds, infinite_non_planar_bounds, object_ptr^.trans);

    complex_object:
      begin
        if not Null_extent_box(object_ptr^.object_decl_ptr^.extent_box) then
          begin
            bounds_trans :=
              Extent_box_trans(object_ptr^.object_decl_ptr^.extent_box);
            Transform_trans(bounds_trans, object_ptr^.trans);
            Make_bounds(bounds, non_planar_bounds, bounds_trans);
          end
        else
          Make_bounds(bounds, null_bounds, unit_trans);
      end;
  end; {case}
end; {procedure Make_object_bounds}


procedure End_geom_object_decl;
var
  object_ptr: object_decl_ptr_type;
  sub_object_ptr: object_inst_ptr_type;
  bounds: bounding_type;
begin
  {**************************************************}
  { When an object is ended, we compute the bounding }
  { box of the object around all of its component    }
  { parts, and set the coord axes in the declaration }
  { to reflect the bounding box of the entire object.}
  { Next, we rescale all of the parts so that they   }
  { fit within the unit cube.                        }
  {                                                  }
  { We store the dimentions of the entire object in  }
  { the decl so that when an object is instantiated, }
  { we know how to scale the coords of the instance  }
  { to get the desired dimensions.                   }
  {                                                  }
  { To preserve the property that a subobject's      }
  { dimensions can be found by multiplying the       }
  { coords of the instance by the coords in the      }
  { decl, we must rescale all the parts to fit in    }
  { a unit cube.                                     }
  {**************************************************}

  {**************************************}
  { take object off of declaration stack }
  {**************************************}
  object_ptr := Pop_object_stack;

  {*************************************}
  { calculate bounds on all sub_objects }
  {*************************************}
  Init_extent_box(object_ptr^.extent_box);
  sub_object_ptr := object_ptr^.sub_object_ptr;
  while (sub_object_ptr <> nil) do
    begin
      if not (sub_object_ptr^.kind in [clipping_plane] + light_sources) then
        begin
          Make_object_bounds(bounds, sub_object_ptr);
          Extend_extent_box_to_bounds(object_ptr^.extent_box, bounds);
        end;
      sub_object_ptr := sub_object_ptr^.next;
    end; {while}

  {************************}
  { insert at tail of list }
  {************************}
  object_ptr^.next := nil;
  object_ptr^.prev := last_geometry_decl_ptr;
  if geometry_decls_ptr = nil then
    begin
      geometry_decls_ptr := object_ptr;
      last_geometry_decl_ptr := object_ptr;
    end
  else
    begin
      last_geometry_decl_ptr^.next := object_ptr;
      last_geometry_decl_ptr := object_ptr;
    end;
end; {procedure End_geom_object_decl}


procedure Free_geom_object_inst(var object_inst_ptr: object_inst_ptr_type);
begin
  with object_inst_ptr^ do
    begin
      {*****************}
      { free shader AST }
      {*****************}
      Free_object_attributes(attributes);

      {**************************}
      { free sub_object geometry }
      {**************************}
      if (kind = shaded_triangle) then
        begin
          Free_triangle_normals(triangle_normal_ptr);
        end

      else if (kind = blob) then
        begin
          Free_metaballs(metaball_ptr);
        end

      else if (kind = volume) then
        begin
          Free_volume(volume_ptr);
        end

      else if (kind in tessellated_prims) then
        case kind of
          flat_polygon:
            Free_polygon(polygon_ptr);

          shaded_polygon:
            Free_shaded_polygon(shaded_polygon_ptr);

          mesh:
            Free_mesh(mesh_ptr);

          points:
            Free_points(points_ptr);

          lines:
            Free_lines(lines_ptr);
        end;
    end;

  {*****************************}
  { add sub object to free list }
  {*****************************}
  object_inst_ptr^.next := inst_free_list;
  inst_free_list := object_inst_ptr;
end; {procedure Free_geom_object_inst}


procedure Free_geom_object_insts(var object_inst_ptr: object_inst_ptr_type);
var
  temp_object_ptr: object_inst_ptr_type;
begin
  while (object_inst_ptr <> nil) do
    begin
      temp_object_ptr := object_inst_ptr;
      object_inst_ptr := object_inst_ptr^.next;
      Free_geom_object_inst(temp_object_ptr);
    end;
end; {procedure Free_geom_object_insts}


procedure Free_geom_object(object_decl_ptr: object_decl_ptr_type);
begin
  {******************}
  { free sub_objects }
  {******************}
  Free_geom_object_insts(object_decl_ptr^.sub_object_ptr);
  Free_geom_object_insts(object_decl_ptr^.clipping_plane_ptr);

  {******************}
  { free object decl }
  {******************}
  if (object_decl_ptr^.prev <> nil) then
    object_decl_ptr^.prev^.next := object_decl_ptr^.next
  else
    geometry_decls_ptr := object_decl_ptr^.next;

  if object_decl_ptr^.next <> nil then
    object_decl_ptr^.next^.prev := object_decl_ptr^.prev
  else
    last_geometry_decl_ptr := object_decl_ptr^.prev;

  {******************************}
  { add object decl to free list }
  {******************************}
  object_decl_ptr^.next := decl_free_list;
  decl_free_list := object_decl_ptr;
end; {procedure Free_geom_object}


procedure Write_object_kind(object_kind: object_kind_type);
begin
  case object_kind of
    {**********************}
    { geometric primitives }
    {**********************}
    complex_object:
      write('complex_object');

    {********************}
    { quadric primitives }
    {********************}
    sphere:
      write('sphere');
    cylinder:
      write('cylinder');
    cone:
      write('cone');
    paraboloid:
      write('paraboloid');
    hyperboloid1:
      write('hyperboloid1');
    hyperboloid2:
      write('hyperboloid2');

    {*******************}
    { planar primitives }
    {*******************}
    plane:
      write('plane');
    disk:
      write('disk');
    ring:
      write('ring');
    triangle:
      write('triangle');
    parallelogram:
      write('parallelogram');
    flat_polygon:
      write('flat_polygon');

    {***********************}
    { non_planar primitives }
    {***********************}
    torus:
      write('torus');
    block:
      write('block');
    shaded_triangle:
      write('shaded_triangle');
    shaded_polygon:
      write('shaded_polygon');
    mesh:
      write('mesh');
    blob:
      write('blob');

    {************************}
    { non_surface primitives }
    {************************}
    points:
      write('points');
    lines:
      write('lines');
    volume:
      write('volume');

    {*********************}
    { clipping primitives }
    {*********************}
    clipping_plane:
      write('clipping_plane');

    {*********************}
    { lighting primitives }
    {*********************}
    distant_light:
      write('distant_light');
    point_light:
      write('point_light');
    spot_light:
      write('spot_light');

  end; {case}
end; {procedure Write_object_kind}


function Object_bounding_kind(kind: object_kind_type): bounding_kind_type;
var
  bounding_kind: bounding_kind_type;
begin
  bounding_kind := null_bounds;
  
  case kind of

    {********************}
    { quadric primitives }
    {********************}
    sphere, cylinder, cone, paraboloid, hyperboloid1, hyperboloid2:
      bounding_kind := non_planar_bounds;

    {*******************}
    { planar primitives }
    {*******************}
    plane:
      bounding_kind := infinite_planar_bounds;
    disk, ring, triangle, parallelogram, flat_polygon:
      bounding_kind := planar_bounds;

    {***********************}
    { non_planar primitives }
    {***********************}
    torus, block, mesh, blob:
      bounding_kind := non_planar_bounds;
    shaded_triangle, shaded_polygon:
      bounding_kind := planar_bounds;

    {************************}
    { non-surface primitives }
    {************************}
    points, lines, volume:
      bounding_kind := non_planar_bounds;

    {*********************}
    { clipping primitives }
    {*********************}
    clipping_plane:
      bounding_kind := infinite_planar_bounds;

  end; {case}

  Object_bounding_kind := bounding_kind;
end; {function Object_bounding_kind}


initialization
  {***************************************************}
  { initialize parameters controlling hierarchy depth }
  {***************************************************}
  hierarchy_compression := false;
  min_object_complexity := 32;

  {***************************}
  { initialize geometry lists }
  {***************************}
  geometry_decls_ptr := nil;
  last_geometry_decl_ptr := nil;
  geometry_scene_ptr := nil;

  {*******************}
  { init object stack }
  {*******************}
  if memory_alert then
    writeln('allocating new object stack');
  new(object_stack);

  object_stack_ptr := 0;
  Push_object_stack(nil);
  current_geometry_decl_ptr := nil;

  {****************************}
  { init transformation stacks }
  {****************************}
  model_trans_stack_ptr := New_trans_stack;
  shader_trans_stack_ptr := New_trans_stack;
  model_attr_stack_ptr := New_attributes_stack;

  Push_trans_stack(model_trans_stack_ptr);
  Push_trans_stack(shader_trans_stack_ptr);

  {*****************}
  { init free lists }
  {*****************}
  inst_free_list := nil;
  decl_free_list := nil;
  triangle_normal_free_list := nil;
end.
