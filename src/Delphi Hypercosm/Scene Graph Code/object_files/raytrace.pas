unit raytrace;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              raytrace                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The raytracing module provides data structures and      }
{       routines for creating the basic raytracing data         }
{       structures.                                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, trans, coord_axes, extents, bounds, topology, b_rep, triangles,
  polygons, polymeshes, volumes, object_attr, objects;


const
  max_hierarchy_depth = 32;


type
  {******************************************************}
  { two types of ray objects: instances and declarations }
  {******************************************************}
  ray_object_inst_ptr_type = ^ray_object_inst_type;
  ray_object_decl_ptr_type = ^ray_object_decl_type;


  {***********************************************}
  { spatial data structures for raytracing meshes }
  {***********************************************}
  mesh_mailbox_type = record
    ray: ray_type;
    t: real;
  end; {mesh_mailbox_type}


  {*******************************************}
  { structures for raytracing meshes directly }
  {*******************************************}
  face_node_ptr_type = ^face_node_type;
  face_node_type = record
    face_ptr: face_ptr_type;
    extent_box: extent_box_type;
    mesh_mailbox: mesh_mailbox_type;
    next: face_node_ptr_type;
  end; {face_node_type}


  face_node_ref_ptr_type = ^face_node_ref_type;
  face_node_ref_type = record
    face_node_ptr: face_node_ptr_type;
    next: face_node_ref_ptr_type;
  end; {face_node_ref_type}


  mesh_voxel_ptr_type = ^mesh_voxel_type;
  mesh_voxel_type = record
    subdivision_level: integer;
    extent_box: extent_box_type;
    case subdivided: boolean of
      {*********************}
      { 8 subvoxel pointers }
      {*********************}
      true: (
        subvoxel_ptr: array[left..right, front..back, bottom..top] of
        mesh_voxel_ptr_type
        );
      {*************************************************************}
      { 6 neighbor_voxel pointers + 1 object pointer + next pointer }
      {*************************************************************}
      false: (
        neighbor_voxel_ptr: array[extent_type] of mesh_voxel_ptr_type;
        face_node_ref_ptr: face_node_ref_ptr_type;
        next: mesh_voxel_ptr_type;
        );
  end; {mesh_voxel_type record}


  {***********************************************}
  { structures for raytracing triangulated meshes }
  {***********************************************}
  triangle_node_ptr_type = ^triangle_node_type;
  triangle_node_type = record
    triangle_ptr: triangle_ptr_type;
    mesh_mailbox: mesh_mailbox_type;
    next: triangle_node_ptr_type;
  end; {tri_node_type}


  triangle_node_ref_ptr_type = ^triangle_node_ref_type;
  triangle_node_ref_type = record
    triangle_node_ptr: triangle_node_ptr_type;
    next: triangle_node_ref_ptr_type;
  end; {triangle_node_ref_type}


  triangle_voxel_ptr_type = ^triangle_voxel_type;
  triangle_voxel_type = record
    subdivision_level: integer;
    extent_box: extent_box_type;
    case subdivided: boolean of
      {*********************}
      { 8 subvoxel pointers }
      {*********************}
      true: (
        subvoxel_ptr: array[left..right, front..back, bottom..top] of
        triangle_voxel_ptr_type
        );
      {*************************************************************}
      { 6 neighbor_voxel pointers + 1 object pointer + next pointer }
      {*************************************************************}
      false: (
        neighbor_voxel_ptr: array[extent_type] of triangle_voxel_ptr_type;
        triangle_node_ref_ptr: triangle_node_ref_ptr_type;
        next: triangle_voxel_ptr_type;
        );
  end; {triangle_voxel_type record}


  {**********************************************************}
  { structures for locating a unique object in the hierarchy }
  {**********************************************************}
  transform_stack_type = record
    depth: integer;
    stack: array[1..max_hierarchy_depth] of ray_object_inst_ptr_type;
  end; {transform_stack_type}


  hierarchical_object_type = record
    object_ptr: ray_object_inst_ptr_type;
    mesh_face_ptr: face_ptr_type;
    mesh_point_ptr: point_ptr_type;
    transform_stack: transform_stack_type;
  end; {hierarchical_object_type}


  {************************************************}
  { spatial data structures for raytracing objects }
  {************************************************}
  mailbox_type = record
    ray: ray_type;
    t: real;
    primitive_object: hierarchical_object_type;
  end; {mailbox_type}


  transform_cache_type = record
    transform_stack: transform_stack_type;
    global_coord_axes: coord_axes_type;
    global_attributes: object_attributes_type;
  end; {transform_cache_type}


  {*******************************}
  { this structure contains the   }
  { information needed to do a    }
  { bilinear normal interpolation }
  {*******************************}
  interpolation_ptr_type = ^interpolation_type;
  interpolation_type = record
    t: real;
    left_t, right_t: real;
    left_vector1, left_vector2: vector_type;
    right_vector1, right_vector2: vector_type;
    next: interpolation_ptr_type;
  end; {interpolation_type}


  {***********************************************}
  { miscillaneous data needed to raytrace meshes: }
  { It is not included in the variant record for  }
  { ray object insts because doing that would     }
  { increase the storage size of all ray_objects. }
  {***********************************************}
  ray_mesh_data_ptr_type = ^ray_mesh_data_type;
  ray_mesh_data_type = record
    {*********************}
    { b rep related stuff }
    {*********************}
    surface_ptr: surface_ptr_type;
    triangle_ptr: triangle_ptr_type;

    {**********************}
    { normal related stuff }
    {**********************}
    normal_interpolation: interpolation_type;
    texture_interpolation: interpolation_type;
    u_axis_interpolation: interpolation_type;
    v_axis_interpolation: interpolation_type;
    mesh_normal: vector_type;

    {*********************}
    { voxel related stuff }
    {*********************}
    face_node_ptr: face_node_ptr_type;
    mesh_voxel_ptr: mesh_voxel_ptr_type;

    triangle_node_ptr: triangle_node_ptr_type;
    triangle_voxel_ptr: triangle_voxel_ptr_type;

    next: ray_mesh_data_ptr_type;
  end; {ray_mesh_data_type}


  {************************************************}
  { if we raytrace tessellated primitives, then we }
  { can share the voxels for the self similar ones }
  {************************************************}
  prim_mesh_ptr_array_type = array[object_kind_type] of ray_mesh_data_ptr_type;


  {*********************}
  { ray object instance }
  {*********************}
  ray_object_inst_type = record
    object_id: integer;
    next: ray_object_inst_ptr_type;

    attributes: object_attributes_type;
    coord_axes: coord_axes_type;
    shader_axes: coord_axes_type;
    normal_coord_axes: coord_axes_type;
    normal_shader_axes: coord_axes_type;

    umin, umax: real;
    vmin, vmax: real;

    {********************************************}
    { used for raytracing tessellated primitives }
    {********************************************}
    ray_mesh_data_ptr: ray_mesh_data_ptr_type;
    original_object_ptr: ray_object_inst_ptr_type;

    {**********************}
    { efficiency variables }
    {**********************}
    bounds: bounding_type;
    mailbox: mailbox_type;
    transform_cache: transform_cache_type;

    case kind: object_kind_type of

      complex_object: (
        object_decl_ptr: ray_object_decl_ptr_type
        );

      {**********************}
      { geometric primitives }
      {**********************}
      plane, clipping_plane: (
        );

      disk, sphere, cylinder, paraboloid: (
        );

      hyperboloid2: (
        eccentricity: real
        );

      triangle, parallelogram, block: (
        );

      blob: (
        threshold: real;
        dimensions: vector_type;
        metaball_ptr: metaball_ptr_type;
        );

      {************************}
      { tessellated primitives }
      {************************}
      shaded_triangle: (
        triangle_normal_ptr: triangle_normal_ptr_type;
        triangle_interpolation_ptr: interpolation_ptr_type;
        );

      ring, cone, hyperboloid1, torus: (
        inner_radius: real
        );

      flat_polygon: (
        polygon_ptr: polygon_ptr_type;
        );

      shaded_polygon: (
        shaded_polygon_ptr: shaded_polygon_ptr_type;
        );

      mesh: (
        mesh_ptr: mesh_ptr_type;
        smoothing, mending, closed: boolean;
        );

      points: (
        points_ptr: points_ptr_type;
        );

      lines: (
        lines_ptr: lines_ptr_type;
        );

      volume: (
        volume_ptr: volume_ptr_type;
        );
  end; {ray_object_inst_type}


  object_ref_ptr_type = ^object_ref_type;
  object_ref_type = record
    object_ptr: ray_object_inst_ptr_type;
    next: object_ref_ptr_type;
  end; {object_ref_type}


  voxel_ptr_type = ^voxel_type;
  voxel_type = record
    subdivision_level: integer;
    extent_box: extent_box_type;
    case subdivided: boolean of
      {*********************}
      { 8 subvoxel pointers }
      {*********************}
      true: (
        subvoxel_ptr: array[left..right, front..back, bottom..top] of
        voxel_ptr_type
        );
      {*************************************************************}
      { 6 neighbor_voxel pointers + 1 object pointer + next pointer }
      {*************************************************************}
      false: (
        neighbor_voxel_ptr: array[extent_type] of voxel_ptr_type;
        object_ref_ptr: object_ref_ptr_type;
        next: voxel_ptr_type;
        );
  end; {voxel_type}


  {************************}
  { ray object declaration }
  {************************}
  ray_object_decl_type = record
    voxel_space_ptr: voxel_ptr_type;
    object_id: integer;

    {*****************}
    { sub object list }
    {*****************}
    sub_object_number: integer;
    sub_object_ptr, last_sub_object_ptr: ray_object_inst_ptr_type;
    clipping_plane_ptr, last_clipping_plane_ptr: ray_object_inst_ptr_type;

    infinite: boolean;
    coord_axes: coord_axes_type;
    next, prev: ray_object_decl_ptr_type;
  end; {ray_object_decl_type}


var
  raytracing_scene_ptr: ray_object_inst_ptr_type;
  raytracing_decls_ptr: ray_object_decl_ptr_type;
  prim_mesh_ptr_array: prim_mesh_ptr_array_type;


  {**************************************************}
  { To properly raytrace shadow and reflection rays, }
  { the source face must be set to the target face   }
  { and vertex of the previous ray. If we are firing }
  { rays from the vertices, then we must set the     }
  { source vertex ptr to the originating vertex.     }
  {**************************************************}
  source_face_ptr: face_ptr_type;
  target_face_ptr: face_ptr_type;
  source_point_ptr: point_ptr_type;


  {********************************************}
  { shall we draw the voxels as we build them? }
  {********************************************}
  draw_voxels: boolean;


procedure Init_transform_stack(var transform_stack: transform_stack_type);
procedure Init_hierarchical_obj(var obj: hierarchical_object_type);

{********************************}
{ routines for declaring objects }
{********************************}
function New_ray_object_decl: ray_object_decl_ptr_type;
procedure End_ray_object_decl;

{************************************}
{ routines for instantiating objects }
{************************************}
function New_ray_object_inst: ray_object_inst_ptr_type;
procedure Inst_ray_prim(object_ptr: ray_object_inst_ptr_type);
procedure Inst_ray_object(object_decl_ptr: ray_object_decl_ptr_type;
  coord_axes: coord_axes_type;
  attributes: object_attributes_type;
  shader_axes: coord_axes_type);

{**************************************}
{ routine for freeing of an object's   }
{ declaration and all of its instances }
{**************************************}
procedure Free_ray_object(var object_decl_ptr: ray_object_decl_ptr_type);
procedure Free_ray_object_inst(var object_ptr: ray_object_inst_ptr_type);
procedure Free_ray_object_copy(var object_ptr: ray_object_inst_ptr_type);

{*****************************************}
{ routines for creating ray object voxels }
{*****************************************}
function New_voxel: voxel_ptr_type;
function New_object_ref: object_ref_ptr_type;
procedure Free_voxels(var voxel_ptr: voxel_ptr_type);
procedure Free_object_refs(var object_ref_ptr: object_ref_ptr_type);

{***********************************}
{ routines for creating mesh voxels }
{***********************************}
function New_mesh_voxel: mesh_voxel_ptr_type;
function New_face_node: face_node_ptr_type;
function New_face_node_ref: face_node_ref_ptr_type;
procedure Free_mesh_voxels(var mesh_voxel_ptr: mesh_voxel_ptr_type);
procedure Free_face_nodes(var face_node_ptr: face_node_ptr_type);
procedure Free_face_node_refs(var face_node_ref_ptr: face_node_ref_ptr_type);

{***************************************}
{ routines for creating triangle voxels }
{***************************************}
function New_triangle_voxel: triangle_voxel_ptr_type;
function New_triangle_node: triangle_node_ptr_type;
function New_triangle_node_ref: triangle_node_ref_ptr_type;
procedure Free_triangle_voxels(var triangle_voxel_ptr: triangle_voxel_ptr_type);
procedure Free_triangle_nodes(var triangle_node_ptr: triangle_node_ptr_type);
procedure Free_triangle_node_refs(var triangle_node_ref_ptr:
  triangle_node_ref_ptr_type);

{******************************************}
{ routines for creating miscillaneous data }
{******************************************}
function New_interpolation: interpolation_ptr_type;
function New_ray_mesh_data: ray_mesh_data_ptr_type;
procedure Free_interpolation(var interpolation_ptr: interpolation_ptr_type);
procedure Free_ray_mesh_data(var ray_mesh_data_ptr: ray_mesh_data_ptr_type);
function Interpolate(interpolation: interpolation_type): vector_type;

{**********************************}
{ routines for querying primitives }
{**********************************}
function Partial_surface(ray_object_ptr: ray_object_inst_ptr_type): boolean;
function Self_similar_surface(ray_object_ptr: ray_object_inst_ptr_type):
  boolean;

implementation
uses
  errors, new_memory, constants;


{*******************************************************}
{                 raytracing data structures            }
{*******************************************************}
{       The raytracing data structs are a graph like    }
{       the geometry data structs, but with certain     }
{       differences:                                    }
{                                                       }
{       1) the graph will be 'shallower' than           }
{          the geometry graph because objects           }
{          with few subobjects will have been           }
{          removed from the graph to make the           }
{          rendering process more efficient.            }
{          The penalty for compressing the graph        }
{          is that more memory may be used. In          }
{          this way, we can vary the representation     }
{          continuously from a DAG to a display list.   }
{       3) the graph contains bounding boxes            }
{          and voxel (octree) data structures for       }
{          efficient ray intersection tests.            }
{*******************************************************}


{*******************************************************}
{               raytracing data structures              }
{*******************************************************}
{       Note: decls are linked in chronological order   }
{       of their declaration: from simple to complex.   }
{                                                       }
{       Not shown: backpointers are kept from each      }
{       declaration of an object to each of its         }
{       instances and the parent of each instance.      }
{                                                       }
{                  <-next      prev->                   }
{                                                       }
{                  |-----|    |-----|                   }
{   ray_decl_ptr-> |scene|<-->| car |-||                }
{                  |-----| /->|-----|                   }
{                     |    |     |                      }
{                  /-----\ |  /-----\                   }
{                  | car |-/  |cylnd|        note:      }
{                  \-----/    \-----/     'shallower'   }
{                     |          |        graph than    }
{                  /-----\    /-----\   graph depicted  }
{                  |plane|    |cylnd|    in geometry    }
{                  \-----/    \-----/       module      }
{                     |          |                      }
{                  /-----\    /-----\                   }
{                  |light|    |block|                   }
{                  \-----/    \-----/                   }
{                     |          |                      }
{                     -          -                      }
{*******************************************************}


{*******************************************************}
{ if an object has less than this number of subobjects, }
{ then wherever it is instantiated, instead of making   }
{ a reference to the declaration, we will explicitly    }
{ copy all the subobjects and transform them to the     }
{ coordinated of the instance. This expanded form of    }
{ the graph takes more memory but is more efficient to  }
{ render from.                                          }
{*******************************************************}
const
  min_complexity = 64;


  {*******************************************************}
  {       raytracing_decls_ptr always points to the       }
  {       most primitive (least complex) raytracing_decl. }
  {               (the first one declared)                }
  {                                                       }
  {       last_raytracing_decl_ptr always points to the   }
  {       least primitive (most complex) raytracing_decl  }
  {               (the last one declared)                 }
  {                                                       }
  {       In the case that objects are generated          }
  {       recursively, the build order is reversed.       }
  {       The most complex object is made, then the       }
  {       subobjets are made, then we go back to the      }
  {       complex object again. To implement this, we     }
  {       need a stack, and current_raytracing_decl_ptr   }
  {       always points to the current object being       }
  {       defined which is at the top of the stack.       }
  {*******************************************************}
const
  stack_size = 256;
  memory_alert = false;


  {****************************************************}
  { voxels are allocated in blocks to speed allocation }
  {****************************************************}
const
  block_size = 512;


type
  ray_object_decl_stack_ptr_type = ^ray_object_decl_stack_type;
  ray_object_decl_stack_type = array[1..stack_size] of ray_object_decl_ptr_type;


  {****************************}
  { block allocation of voxels }
  {****************************}
  voxel_block_ptr_type = ^voxel_block_type;
  voxel_block_type = array[0..block_size] of voxel_type;

  object_ref_block_ptr_type = ^object_ref_block_type;
  object_ref_block_type = array[0..block_size] of object_ref_type;


  {*********************************}
  { block allocation of mesh voxels }
  {*********************************}
  mesh_voxel_block_ptr_type = ^mesh_voxel_block_type;
  mesh_voxel_block_type = array[0..block_size] of mesh_voxel_type;

  face_node_block_ptr_type = ^face_node_block_type;
  face_node_block_type = array[0..block_size] of face_node_type;

  face_node_ref_block_ptr_type = ^face_node_ref_block_type;
  face_node_ref_block_type = array[0..block_size] of face_node_ref_type;


  {*************************************}
  { block allocation of triangle voxels }
  {*************************************}
  triangle_voxel_block_ptr_type = ^triangle_voxel_block_type;
  triangle_voxel_block_type = array[0..block_size] of triangle_voxel_type;

  triangle_node_block_ptr_type = ^triangle_node_block_type;
  triangle_node_block_type = array[0..block_size] of triangle_node_type;

  triangle_node_ref_block_ptr_type = ^triangle_node_ref_block_type;
  triangle_node_ref_block_type = array[0..block_size] of triangle_node_ref_type;


var
  stack: ray_object_decl_stack_ptr_type;
  stack_ptr: integer;
  last_raytracing_decl_ptr: ray_object_decl_ptr_type;
  last_raytracing_inst_ptr: ray_object_inst_ptr_type;
  current_raytracing_decl_ptr: ray_object_decl_ptr_type;

  {**************************************************}
  { free lists for object instances and declarations }
  {**************************************************}
  inst_free_list: ray_object_inst_ptr_type;
  decl_free_list: ray_object_decl_ptr_type;
  object_number: integer;

  {***********************}
  { free lists for voxels }
  {***********************}
  object_ref_free_list: object_ref_ptr_type;
  voxel_free_list: voxel_ptr_type;

  {****************************}
  { free lists for mesh voxels }
  {****************************}
  face_node_free_list: face_node_ptr_type;
  face_node_ref_free_list: face_node_ref_ptr_type;
  mesh_voxel_free_list: mesh_voxel_ptr_type;

  {********************************}
  { free lists for triangle voxels }
  {********************************}
  triangle_node_free_list: triangle_node_ptr_type;
  triangle_node_ref_free_list: triangle_node_ref_ptr_type;
  triangle_voxel_free_list: triangle_voxel_ptr_type;

  {******************************}
  { free lists for miscillaneous }
  {******************************}
  interpolation_free_list: interpolation_ptr_type;
  ray_mesh_data_free_list: ray_mesh_data_ptr_type;

  {****************************}
  { block allocation of voxels }
  {****************************}
  voxel_block_ptr: voxel_block_ptr_type;
  voxel_counter: integer;

  object_ref_block_ptr: object_ref_block_ptr_type;
  object_ref_counter: integer;

  {*********************************}
  { block allocation of mesh voxels }
  {*********************************}
  mesh_voxel_block_ptr: mesh_voxel_block_ptr_type;
  mesh_voxel_counter: integer;

  face_node_block_ptr: face_node_block_ptr_type;
  face_node_counter: integer;

  face_node_ref_block_ptr: face_node_ref_block_ptr_type;
  face_node_ref_counter: integer;

  {*************************************}
  { block allocation of triangle voxels }
  {*************************************}
  triangle_voxel_block_ptr: triangle_voxel_block_ptr_type;
  triangle_voxel_counter: integer;

  triangle_node_block_ptr: triangle_node_block_ptr_type;
  triangle_node_counter: integer;

  triangle_node_ref_block_ptr: triangle_node_ref_block_ptr_type;
  triangle_node_ref_counter: integer;


procedure Push_ray_object_stack(ray_object_decl_ptr: ray_object_decl_ptr_type);
begin
  if (stack_ptr < stack_size) then
    begin
      stack_ptr := stack_ptr + 1;
      stack^[stack_ptr] := ray_object_decl_ptr;
      current_raytracing_decl_ptr := ray_object_decl_ptr;
    end
  else
    Error('ray object stack overflow');
end; {procedure Push_ray_object_stack}


procedure Pop_ray_object_stack;
begin
  if (stack_ptr > 0) then
    begin
      stack_ptr := stack_ptr - 1;
      current_raytracing_decl_ptr := stack^[stack_ptr];
    end
  else
    Error('ray object stack underflow');
end; {procedure Pop_ray_object_stack}


procedure Init_prim_mesh_ptr_array;
var
  counter: object_kind_type;
begin
  for counter := sphere to spot_light do
    prim_mesh_ptr_array[counter] := nil;
end; {procedure Init_prim_mesh_ptr_array}


procedure Init_transform_stack(var transform_stack: transform_stack_type);
begin
  transform_stack.depth := 0;
end; {procedure Init_transform_stack}


procedure Init_hierarchical_obj(var obj: hierarchical_object_type);
begin
  with obj do
    begin
      object_ptr := nil;
      mesh_face_ptr := nil;
      mesh_point_ptr := nil;
      Init_transform_stack(transform_stack);
    end;
end; {procedure Init_hierarchical_obj}


function New_ray_object_decl: ray_object_decl_ptr_type;
var
  new_object_ptr: ray_object_decl_ptr_type;
begin
  {*************************}
  { get decl from free list }
  {*************************}
  if (decl_free_list <> nil) then
    begin
      new_object_ptr := decl_free_list;
      decl_free_list := decl_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new ray object decl');
      new(new_object_ptr);

      object_number := object_number + 1;
    end;

  {************************}
  { initialize object decl }
  {************************}
  with new_object_ptr^ do
    begin
      coord_axes := unit_axes;
      voxel_space_ptr := nil;

      infinite := false;
      sub_object_number := 0;

      sub_object_ptr := nil;
      last_sub_object_ptr := nil;

      clipping_plane_ptr := nil;
      last_clipping_plane_ptr := nil;

      next := nil;
      prev := nil;
    end;

  last_raytracing_inst_ptr := nil;
  Push_ray_object_stack(new_object_ptr);
  New_ray_object_decl := new_object_ptr;
end; {function New_ray_object_decl}


function New_ray_object_inst: ray_object_inst_ptr_type;
var
  object_ptr: ray_object_inst_ptr_type;
begin
  {*****************************}
  { get instance from free list }
  {*****************************}
  if (inst_free_list <> nil) then
    begin
      object_ptr := inst_free_list;
      inst_free_list := inst_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new ray object inst');
      new(object_ptr);
    end;

  {****************************}
  { initialize new object inst }
  {****************************}
  object_ptr^.umin := 0;
  object_ptr^.umax := 0;
  object_ptr^.vmin := 0;
  object_ptr^.vmax := 0;
  object_ptr^.mailbox.ray.location := zero_vector;
  object_ptr^.mailbox.ray.direction := zero_vector;
  object_ptr^.mailbox.t := 0;
  object_ptr^.next := nil;
  object_ptr^.ray_mesh_data_ptr := nil;
  object_ptr^.original_object_ptr := nil;

  New_ray_object_inst := object_ptr;
end; {function New_ray_object_inst}


procedure Inst_ray_prim(object_ptr: ray_object_inst_ptr_type);
begin
  {********************************************}
  { create special transformations for normals }
  {********************************************}
  object_ptr^.normal_coord_axes := Normal_axes(object_ptr^.coord_axes);
  object_ptr^.normal_shader_axes := Normal_axes(object_ptr^.shader_axes);

  {*******************}
  { set special flags }
  {*******************}
  if object_ptr^.kind = plane then
    current_raytracing_decl_ptr^.infinite := true;

  {****************************}
  { add object to current decl }
  {****************************}
  object_ptr^.next := nil;
  with current_raytracing_decl_ptr^ do
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
end; {procedure Inst_ray_prim}


procedure Inst_ray_object(object_decl_ptr: ray_object_decl_ptr_type;
  coord_axes: coord_axes_type;
  attributes: object_attributes_type;
  shader_axes: coord_axes_type);
var
  object_ptr: ray_object_inst_ptr_type;
begin
  if (object_decl_ptr <> nil) then
    begin
      {*************************}
      { make instance of object }
      {*************************}
      object_ptr := New_ray_object_inst;
      object_ptr^.kind := complex_object;
      object_ptr^.object_decl_ptr := object_decl_ptr;
      object_ptr^.object_id := object_decl_ptr^.object_id;
      object_ptr^.coord_axes := coord_axes;
      object_ptr^.attributes := attributes;
      object_ptr^.shader_axes := shader_axes;

      {********************************************}
      { create special transformations for normals }
      {********************************************}
      object_ptr^.normal_coord_axes := Normal_axes(object_ptr^.coord_axes);
      object_ptr^.normal_shader_axes := Normal_axes(object_ptr^.shader_axes);

      {*******************}
      { set bounding kind }
      {*******************}
      if object_decl_ptr^.infinite then
        object_ptr^.bounds.bounding_kind := infinite_non_planar_bounds
      else
        object_ptr^.bounds.bounding_kind := non_planar_bounds;

      if (current_raytracing_decl_ptr <> nil) then
        begin
          {*******************}
          { set special flags }
          {*******************}
          if object_decl_ptr^.infinite then
            current_raytracing_decl_ptr^.infinite := true;

          {****************************}
          { add object to current decl }
          {****************************}
          object_ptr^.next := nil;
          with current_raytracing_decl_ptr^ do
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
              sub_object_number := sub_object_number + 1;
            end;
        end
      else
        begin
          {**********************************}
          { make object current scene object }
          {**********************************}
          if raytracing_scene_ptr <> nil then
            begin
              {********************************}
              { add current scene to free list }
              {********************************}
              raytracing_scene_ptr^.next := inst_free_list;
              inst_free_list := raytracing_scene_ptr;
            end;

          raytracing_scene_ptr := object_ptr;
          object_ptr^.next := nil;
        end;
    end
  else
    Error('Can not instantiate a nonexistant object.');
end; {procedure Inst_ray_object}


procedure End_ray_object_decl;
begin
  {************************}
  { insert at tail of list }
  {************************}
  if raytracing_decls_ptr = nil then
    begin
      raytracing_decls_ptr := current_raytracing_decl_ptr;
      last_raytracing_decl_ptr := current_raytracing_decl_ptr
    end
  else
    begin
      current_raytracing_decl_ptr^.next := nil;
      current_raytracing_decl_ptr^.prev := last_raytracing_decl_ptr;
      last_raytracing_decl_ptr^.next := current_raytracing_decl_ptr;
      last_raytracing_decl_ptr := current_raytracing_decl_ptr;
    end;

  Pop_ray_object_stack;
end; {procedure End_ray_object_decl}


{*****************************************}
{ routines for creating ray object voxels }
{*****************************************}


function New_object_ref: object_ref_ptr_type;
var
  object_ref_ptr: object_ref_ptr_type;
  index: integer;
begin
  {*******************************}
  { get object ref from free list }
  {*******************************}
  if (object_ref_free_list <> nil) then
    begin
      object_ref_ptr := object_ref_free_list;
      object_ref_free_list := object_ref_free_list^.next;
    end
  else
    begin
      index := object_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new object ref block');
          new(object_ref_block_ptr);
        end;
      object_ref_ptr := @object_ref_block_ptr^[index];
      object_ref_counter := object_ref_counter + 1;
    end;

  {***********************}
  { initialize object ref }
  {***********************}
  object_ref_ptr^.next := nil;

  New_object_ref := object_ref_ptr;
end; {function New_object_ref}


function New_voxel: voxel_ptr_type;
var
  voxel_ptr: voxel_ptr_type;
  index: integer;
begin
  {**************************}
  { get voxel from free list }
  {**************************}
  if (voxel_free_list <> nil) then
    begin
      voxel_ptr := voxel_free_list;
      voxel_free_list := voxel_free_list^.next;
    end
  else
    begin
      index := voxel_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new voxel block');
          new(voxel_block_ptr);
        end;
      voxel_ptr := @voxel_block_ptr^[index];
      voxel_counter := voxel_counter + 1;
    end;

  New_voxel := voxel_ptr;
end; {function New_voxel}


procedure Free_ray_object_inst(var object_ptr: ray_object_inst_ptr_type);
var
  mesh_object: boolean;
begin
  mesh_object := (object_ptr^.kind in (curved_prims + tessellated_prims));

  if mesh_object and not Self_similar_surface(object_ptr) then
    begin
      if (object_ptr = object_ptr^.original_object_ptr) then
        if (object_ptr^.ray_mesh_data_ptr <> nil) then
          begin
            {**************************************}
            { free mesh for non self similar prims }
            {**************************************}
            Free_ray_mesh_data(object_ptr^.ray_mesh_data_ptr);
          end;
    end
  else

    {***************************}
    { free shaded triangle data }
    if (object_ptr^.kind = shaded_triangle) then
      begin
        Free_interpolation(object_ptr^.triangle_interpolation_ptr);
      end;

  {*****************************}
  { add sub object to free list }
  {*****************************}
  object_ptr^.next := inst_free_list;
  inst_free_list := object_ptr;
  object_ptr := nil;
end; {procedure Free_ray_object_inst}


procedure Free_ray_object_insts(var object_inst_ptr: ray_object_inst_ptr_type);
var
  temp_object_inst_ptr: ray_object_inst_ptr_type;
begin
  while (object_inst_ptr <> nil) do
    begin
      temp_object_inst_ptr := object_inst_ptr;
      object_inst_ptr := object_inst_ptr^.next;
      Free_ray_object_inst(temp_object_inst_ptr);
    end;
end; {procedure Free_ray_object_insts}


procedure Free_ray_object(var object_decl_ptr: ray_object_decl_ptr_type);
begin
  if (object_decl_ptr <> nil) then
    begin
      {******************}
      { free sub_objects }
      {******************}
      Free_ray_object_insts(object_decl_ptr^.sub_object_ptr);
      Free_ray_object_insts(object_decl_ptr^.clipping_plane_ptr);

      {******************}
      { free object decl }
      {******************}
      if object_decl_ptr^.prev <> nil then
        object_decl_ptr^.prev^.next := object_decl_ptr^.next
      else
        raytracing_decls_ptr := object_decl_ptr^.next;

      if object_decl_ptr^.next <> nil then
        object_decl_ptr^.next^.prev := object_decl_ptr^.prev
      else
        last_raytracing_decl_ptr := object_decl_ptr^.prev;

      {******************************}
      { add object decl to free list }
      {******************************}
      object_decl_ptr^.next := decl_free_list;
      decl_free_list := object_decl_ptr;
      object_decl_ptr := nil;
    end;
end; {procedure Free_ray_object}


procedure Free_ray_object_copy(var object_ptr: ray_object_inst_ptr_type);
begin
  object_ptr^.next := inst_free_list;
  inst_free_list := object_ptr;
  object_ptr := nil;
end; {procedure Free_ray_object_copy}


procedure Free_object_refs(var object_ref_ptr: object_ref_ptr_type);
var
  temp_object_ref_ptr: object_ref_ptr_type;
begin
  {******************************}
  { add object refs to free list }
  {******************************}
  while (object_ref_ptr <> nil) do
    begin
      temp_object_ref_ptr := object_ref_ptr;
      object_ref_ptr := object_ref_ptr^.next;
      temp_object_ref_ptr^.next := object_ref_free_list;
      object_ref_free_list := temp_object_ref_ptr;
    end;
end; {procedure Free_object_refs}


procedure Free_voxels(var voxel_ptr: voxel_ptr_type);
var
  counter1, counter2, counter3: extent_type;
begin
  if (voxel_ptr <> nil) then
    begin
      if voxel_ptr^.subdivided then
        begin
          {****************}
          { free subvoxels }
          {****************}
          for counter1 := left to right do
            for counter2 := front to back do
              for counter3 := bottom to top do
                Free_voxels(voxel_ptr^.subvoxel_ptr[counter1, counter2,
                  counter3]);
        end
      else
        begin
          {******************************}
          { add object refs to free list }
          {******************************}
          Free_object_refs(voxel_ptr^.object_ref_ptr);
        end;
      {************************}
      { add voxel to free list }
      {************************}
      voxel_ptr^.next := voxel_free_list;
      voxel_free_list := voxel_ptr;
      voxel_ptr := nil;
    end;
end; {procedure Free_voxels}


{***********************************}
{ routines for creating mesh voxels }
{***********************************}


function New_mesh_voxel: mesh_voxel_ptr_type;
var
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  index: integer;
begin
  {*******************************}
  { get mesh voxel from free list }
  {*******************************}
  if (mesh_voxel_free_list <> nil) then
    begin
      mesh_voxel_ptr := mesh_voxel_free_list;
      mesh_voxel_free_list := mesh_voxel_free_list^.next;
    end
  else
    begin
      index := mesh_voxel_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new mesh voxel block');
          new(mesh_voxel_block_ptr);
        end;
      mesh_voxel_ptr := @mesh_voxel_block_ptr^[index];
      mesh_voxel_counter := mesh_voxel_counter + 1;
    end;

  New_mesh_voxel := mesh_voxel_ptr;
end; {function New_mesh_voxel}


function New_face_node: face_node_ptr_type;
var
  face_node_ptr: face_node_ptr_type;
  index: integer;
begin
  {******************************}
  { get face node from free list }
  {******************************}
  if (face_node_free_list <> nil) then
    begin
      face_node_ptr := face_node_free_list;
      face_node_free_list := face_node_free_list^.next;
    end
  else
    begin
      index := face_node_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new face node block');
          new(face_node_block_ptr);
        end;
      face_node_ptr := @face_node_block_ptr^[index];
      face_node_counter := face_node_counter + 1;
    end;

  {**********************}
  { initialize face node }
  {**********************}
  face_node_ptr^.mesh_mailbox.ray.location := zero_vector;
  face_node_ptr^.mesh_mailbox.ray.direction := zero_vector;
  face_node_ptr^.mesh_mailbox.t := 0;
  face_node_ptr^.face_ptr := nil;
  face_node_ptr^.next := nil;

  New_face_node := face_node_ptr;
end; {function New_face_node}


function New_face_node_ref: face_node_ref_ptr_type;
var
  face_node_ref_ptr: face_node_ref_ptr_type;
  index: integer;
begin
  {**********************************}
  { get face node ref from free list }
  {**********************************}
  if (face_node_ref_free_list <> nil) then
    begin
      face_node_ref_ptr := face_node_ref_free_list;
      face_node_ref_free_list := face_node_ref_free_list^.next;
    end
  else
    begin
      index := face_node_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new face node ref block');
          new(face_node_ref_block_ptr);
        end;
      face_node_ref_ptr := @face_node_ref_block_ptr^[index];
      face_node_ref_counter := face_node_ref_counter + 1;
    end;

  {**************************}
  { initialize face node ref }
  {**************************}
  face_node_ref_ptr^.next := nil;

  New_face_node_ref := face_node_ref_ptr;
end; {function New_face_node_ref}


procedure Free_mesh_voxels(var mesh_voxel_ptr: mesh_voxel_ptr_type);
var
  counter1, counter2, counter3: extent_type;
begin
  if (mesh_voxel_ptr <> nil) then
    begin
      if mesh_voxel_ptr^.subdivided then
        begin
          {****************}
          { free subvoxels }
          {****************}
          for counter1 := left to right do
            for counter2 := front to back do
              for counter3 := bottom to top do
                Free_mesh_voxels(mesh_voxel_ptr^.subvoxel_ptr[counter1,
                  counter2, counter3]);
        end
      else
        begin
          {*********************************}
          { add face node refs to free list }
          {*********************************}
          Free_face_node_refs(mesh_voxel_ptr^.face_node_ref_ptr);
        end;
      {*****************************}
      { add mesh_voxel to free list }
      {*****************************}
      mesh_voxel_ptr^.next := mesh_voxel_free_list;
      mesh_voxel_free_list := mesh_voxel_ptr;
      mesh_voxel_ptr := nil;
    end;
end; {procedure Free_mesh_voxels}


procedure Free_face_nodes(var face_node_ptr: face_node_ptr_type);
var
  temp_face_node_ptr: face_node_ptr_type;
begin
  {*****************************}
  { add face nodes to free list }
  {*****************************}
  while (face_node_ptr <> nil) do
    begin
      temp_face_node_ptr := face_node_ptr;
      face_node_ptr := face_node_ptr^.next;
      temp_face_node_ptr^.next := face_node_free_list;
      face_node_free_list := temp_face_node_ptr;
    end;
end; {procedure Free_face_nodes}


procedure Free_face_node_refs(var face_node_ref_ptr: face_node_ref_ptr_type);
var
  temp_face_node_ref_ptr: face_node_ref_ptr_type;
begin
  {*********************************}
  { add face node refs to free list }
  {*********************************}
  while (face_node_ref_ptr <> nil) do
    begin
      temp_face_node_ref_ptr := face_node_ref_ptr;
      face_node_ref_ptr := face_node_ref_ptr^.next;
      temp_face_node_ref_ptr^.next := face_node_ref_free_list;
      face_node_ref_free_list := temp_face_node_ref_ptr;
    end;
end; {procedure Free_face_node_refs}


{***************************************}
{ routines for creating triangle voxels }
{***************************************}


function New_triangle_voxel: triangle_voxel_ptr_type;
var
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  index: integer;
begin
  {***********************************}
  { get triangle voxel from free list }
  {***********************************}
  if (triangle_voxel_free_list <> nil) then
    begin
      triangle_voxel_ptr := triangle_voxel_free_list;
      triangle_voxel_free_list := triangle_voxel_free_list^.next;
    end
  else
    begin
      index := triangle_voxel_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new triangle voxel block');
          new(triangle_voxel_block_ptr);
        end;
      triangle_voxel_ptr := @triangle_voxel_block_ptr^[index];
      triangle_voxel_counter := triangle_voxel_counter + 1;
    end;

  New_triangle_voxel := triangle_voxel_ptr;
end; {function New_mesh_voxel}


function New_triangle_node: triangle_node_ptr_type;
var
  triangle_node_ptr: triangle_node_ptr_type;
  index: integer;
begin
  {**********************************}
  { get triangle node from free list }
  {**********************************}
  if (triangle_node_free_list <> nil) then
    begin
      triangle_node_ptr := triangle_node_free_list;
      triangle_node_free_list := triangle_node_free_list^.next;
    end
  else
    begin
      index := triangle_node_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new triangle node block');
          new(triangle_node_block_ptr);
        end;
      triangle_node_ptr := @triangle_node_block_ptr^[index];
      triangle_node_counter := triangle_node_counter + 1;
    end;

  {**************************}
  { initialize triangle node }
  {**************************}
  triangle_node_ptr^.mesh_mailbox.ray.location := zero_vector;
  triangle_node_ptr^.mesh_mailbox.ray.direction := zero_vector;
  triangle_node_ptr^.mesh_mailbox.t := 0;
  triangle_node_ptr^.triangle_ptr := nil;
  triangle_node_ptr^.next := nil;

  New_triangle_node := triangle_node_ptr;
end; {function New_triangle_node}


function New_triangle_node_ref: triangle_node_ref_ptr_type;
var
  triangle_node_ref_ptr: triangle_node_ref_ptr_type;
  index: integer;
begin
  {**************************************}
  { get triangle node ref from free list }
  {**************************************}
  if (triangle_node_ref_free_list <> nil) then
    begin
      triangle_node_ref_ptr := triangle_node_ref_free_list;
      triangle_node_ref_free_list := triangle_node_ref_free_list^.next;
    end
  else
    begin
      index := triangle_node_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new triangle node ref block');
          new(triangle_node_ref_block_ptr);
        end;
      triangle_node_ref_ptr := @triangle_node_ref_block_ptr^[index];
      triangle_node_ref_counter := triangle_node_ref_counter + 1;
    end;

  {******************************}
  { initialize triangle node ref }
  {******************************}
  triangle_node_ref_ptr^.next := nil;

  New_triangle_node_ref := triangle_node_ref_ptr;
end; {function New_triangle_node_ref}


procedure Free_triangle_voxels(var triangle_voxel_ptr: triangle_voxel_ptr_type);
var
  counter1, counter2, counter3: extent_type;
begin
  if (triangle_voxel_ptr <> nil) then
    begin
      if triangle_voxel_ptr^.subdivided then
        begin
          {****************}
          { free subvoxels }
          {****************}
          for counter1 := left to right do
            for counter2 := front to back do
              for counter3 := bottom to top do
                Free_triangle_voxels(triangle_voxel_ptr^.subvoxel_ptr[counter1,
                  counter2, counter3]);
        end
      else
        begin
          {*************************************}
          { add triangle node refs to free list }
          {*************************************}
          Free_triangle_node_refs(triangle_voxel_ptr^.triangle_node_ref_ptr);
        end;
      {*********************************}
      { add triangle_voxel to free list }
      {*********************************}
      triangle_voxel_ptr^.next := triangle_voxel_free_list;
      triangle_voxel_free_list := triangle_voxel_ptr;
      triangle_voxel_ptr := nil;
    end;
end; {procedure Free_triangle_voxels}


procedure Free_triangle_nodes(var triangle_node_ptr: triangle_node_ptr_type);
var
  temp_triangle_node_ptr: triangle_node_ptr_type;
begin
  {*********************************}
  { add triangle nodes to free list }
  {*********************************}
  while (triangle_node_ptr <> nil) do
    begin
      temp_triangle_node_ptr := triangle_node_ptr;
      triangle_node_ptr := triangle_node_ptr^.next;
      temp_triangle_node_ptr^.next := triangle_node_free_list;
      triangle_node_free_list := temp_triangle_node_ptr;
    end;
end; {procedure Free_triangle_nodes}


procedure Free_triangle_node_refs(var triangle_node_ref_ptr:
  triangle_node_ref_ptr_type);
var
  temp_triangle_node_ref_ptr: triangle_node_ref_ptr_type;
begin
  {*************************************}
  { add triangle node refs to free list }
  {*************************************}
  while (triangle_node_ref_ptr <> nil) do
    begin
      temp_triangle_node_ref_ptr := triangle_node_ref_ptr;
      triangle_node_ref_ptr := triangle_node_ref_ptr^.next;
      temp_triangle_node_ref_ptr^.next := triangle_node_ref_free_list;
      triangle_node_ref_free_list := temp_triangle_node_ref_ptr;
    end;
end; {procedure Free_triangle_node_refs}


{******************************************}
{ routines for creating miscillaneous data }
{******************************************}


function New_interpolation: interpolation_ptr_type;
var
  interpolation_ptr: interpolation_ptr_type;
begin
  {**********************************}
  { get interpolation from free list }
  {**********************************}
  if (interpolation_free_list <> nil) then
    begin
      interpolation_ptr := interpolation_free_list;
      interpolation_free_list := interpolation_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new interpolation');
      new(interpolation_ptr);
    end;

  {********************}
  { init interpolation }
  {********************}
  interpolation_ptr^.next := nil;

  New_interpolation := interpolation_ptr;
end; {function New_interpolation}


function New_ray_mesh_data: ray_mesh_data_ptr_type;
var
  ray_mesh_data_ptr: ray_mesh_data_ptr_type;
begin
  {**********************************}
  { get ray_mesh_data from free list }
  {**********************************}
  if (ray_mesh_data_free_list <> nil) then
    begin
      ray_mesh_data_ptr := ray_mesh_data_free_list;
      ray_mesh_data_free_list := ray_mesh_data_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new ray mesh data');
      new(ray_mesh_data_ptr);
    end;

  {********************}
  { init ray mesh data }
  {********************}
  with ray_mesh_data_ptr^ do
    begin
      surface_ptr := nil;
      triangle_ptr := nil;
      face_node_ptr := nil;
      mesh_voxel_ptr := nil;
      triangle_node_ptr := nil;
      triangle_voxel_ptr := nil;
      next := nil;
    end;

  New_ray_mesh_data := ray_mesh_data_ptr;
end; {function New_ray_mesh_data}


procedure Free_interpolation(var interpolation_ptr: interpolation_ptr_type);
begin
  {********************************}
  { add interpolation to free list }
  {********************************}
  interpolation_ptr^.next := interpolation_free_list;
  interpolation_free_list := interpolation_ptr;
end; {procedure Free_interpolation}


procedure Free_ray_mesh_data(var ray_mesh_data_ptr: ray_mesh_data_ptr_type);
begin
  {*************************************}
  { free data hanging off ray mesh data }
  {*************************************}
  with ray_mesh_data_ptr^ do
    begin
      Free_surface(surface_ptr);
      Free_triangles(triangle_ptr);

      Free_face_nodes(face_node_ptr);
      Free_mesh_voxels(mesh_voxel_ptr);

      Free_triangle_nodes(triangle_node_ptr);
      Free_triangle_voxels(triangle_voxel_ptr);
    end;

  {********************************}
  { add ray mesh data to free list }
  {********************************}
  ray_mesh_data_ptr^.next := ray_mesh_data_free_list;
  ray_mesh_data_free_list := ray_mesh_data_ptr;
end; {procedure Free_ray_mesh_data}


procedure Check_interpolation(interpolation: interpolation_type);
var
  error: boolean;
begin
  error := false;
  with interpolation do
    begin
      {*******************************}
      { check if normals are too tiny }
      {*******************************}
      if Vector_length(left_vector1) < tiny then
        error := true;
      if Vector_length(left_vector2) < tiny then
        error := true;
      if Vector_length(right_vector1) < tiny then
        error := true;
      if Vector_length(right_vector2) < tiny then
        error := true;

      {****************************}
      { write all normals if error }
      {****************************}
      if error then
        begin
          write('left_vector1 = ');
          Write_vector(left_vector1);
          writeln;

          write('left_vector2 = ');
          Write_vector(left_vector2);
          writeln;

          write('right_vector1 = ');
          Write_vector(right_vector1);
          writeln;

          write('right_vector2 = ');
          Write_vector(right_vector2);
          writeln;
        end;
    end;
end; {procedure Check_interpolation}


function Interpolate(interpolation: interpolation_type): vector_type;
var
  left_delta, right_delta: vector_type;
  left_vector, right_vector: vector_type;
  delta, answer: vector_type;
begin
  with interpolation do
    begin
      {******************}
      { interpolate left }
      {******************}
      left_delta := Vector_difference(left_vector2, left_vector1);
      left_vector := Vector_sum(left_vector1, Vector_scale(left_delta, left_t));

      {*******************}
      { interpolate right }
      {*******************}
      right_delta := Vector_difference(right_vector2, right_vector1);
      right_vector := Vector_sum(right_vector1, Vector_scale(right_delta,
        right_t));

      {************************************}
      { interpolate between left and right }
      {************************************}
      delta := Vector_difference(right_vector, left_vector);
      answer := Vector_sum(left_vector, Vector_scale(delta, t));
    end;

  Interpolate := answer;
end; {function Interpolate}


function Partial_surface(ray_object_ptr: ray_object_inst_ptr_type): boolean;
var
  partial: boolean;
begin
  partial := false;
  
  with ray_object_ptr^ do
    if kind in curved_prims then
      case kind of

        sphere:
          partial := (umin <> 0) or (umax <> 360) or (vmin <> -90) or (vmax <>
            90);

        cylinder, cone, paraboloid, hyperboloid1, hyperboloid2, disk, ring:
          partial := (umin <> 0) or (umax <> 360);

        torus:
          partial := (umin <> 0) or (umax <> 360) or (vmin <> -90) or (vmax <>
            90);

      end
    else
      partial := false;

  Partial_surface := partial;
end; {function Partial_surface}


function Self_similar_surface(ray_object_ptr: ray_object_inst_ptr_type):
  boolean;
begin
  if ray_object_ptr^.kind in self_similar_prims then
    Self_similar_surface := not Partial_surface(ray_object_ptr)
  else
    Self_similar_surface := false;
end; {function Self_similar_surface}


initialization
  Init_prim_mesh_ptr_array;

  {***********************}
  { init raytracing graph }
  {***********************}
  raytracing_decls_ptr := nil;
  last_raytracing_decl_ptr := nil;
  current_raytracing_decl_ptr := nil;
  raytracing_scene_ptr := nil;

  {****************************}
  { init ray object decl stack }
  {****************************}
  if memory_alert then
    writeln('allocating new ray object decl stack');
  new(stack);

  stack_ptr := 0;
  Push_ray_object_stack(nil);
  object_number := 0;

  {***********************}
  { init voxel free lists }
  {***********************}
  object_ref_free_list := nil;
  voxel_free_list := nil;

  {****************************}
  { init mesh voxel free lists }
  {****************************}
  face_node_free_list := nil;
  face_node_ref_free_list := nil;
  mesh_voxel_free_list := nil;

  {********************************}
  { init triangle voxel free lists }
  {********************************}
  face_node_free_list := nil;
  face_node_ref_free_list := nil;
  mesh_voxel_free_list := nil;

  {*******************************}
  { init miscillaneous free lists }
  {*******************************}
  interpolation_free_list := nil;
  ray_mesh_data_free_list := nil;

  {*****************************}
  { init voxel block allocation }
  {*****************************}
  voxel_counter := 0;
  voxel_block_ptr := nil;

  object_ref_counter := 0;
  object_ref_block_ptr := nil;

  {**********************************}
  { init mesh voxel block allocation }
  {**********************************}
  mesh_voxel_counter := 0;
  mesh_voxel_block_ptr := nil;

  face_node_counter := 0;
  face_node_block_ptr := nil;

  face_node_ref_counter := 0;
  face_node_ref_block_ptr := nil;

  {**************************************}
  { init triangle voxel block allocation }
  {**************************************}
  triangle_voxel_counter := 0;
  triangle_voxel_block_ptr := nil;

  triangle_node_counter := 0;
  triangle_node_block_ptr := nil;

  triangle_node_ref_counter := 0;
  triangle_node_ref_block_ptr := nil;

  {***********************}
  { secondary ray markers }
  {***********************}
  source_face_ptr := nil;
  target_face_ptr := nil;
  source_point_ptr := nil;
end.
