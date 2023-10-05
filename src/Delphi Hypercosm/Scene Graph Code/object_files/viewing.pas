unit viewing;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              viewing                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The viewing module provides data structures and         }
{       routines for creating the basic previewing data         }
{       structures for wireframe and z-buffering.               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, extents, bounds, b_rep, object_attr, objects, raytrace;


type
  {*******************************************************}
  { two types of view objects: instances and declarations }
  {*******************************************************}
  view_object_inst_ptr_type = ^view_object_inst_type;
  view_object_decl_ptr_type = ^view_object_decl_type;


  {**********************}
  { view object instance }
  {**********************}
  view_object_kind_type = (view_object_prim, view_object_decl,
    view_object_clip);
  view_object_inst_type = record

    {***************************************}
    { transformation and shading attributes }
    {***************************************}
    trans, shader_trans: trans_type;
    attributes: object_attributes_type;
    bounding_kind: bounding_kind_type;
    distance: real;

    {*******}
    { links }
    {*******}
    ray_object_ptr: ray_object_inst_ptr_type;
    geom_object_ptr: object_inst_ptr_type;
    next, spatial_next: view_object_inst_ptr_type;

    case kind: view_object_kind_type of
      view_object_prim: (
        surface_ptr: surface_ptr_type
        );
      view_object_decl: (
        object_decl_ptr: view_object_decl_ptr_type
        );
      view_object_clip: (
        );
  end; {view_object_inst_type}


  {*************************}
  { view object declaration }
  {*************************}
  view_object_decl_type = record
    object_id: integer;

    {*****************}
    { sub object list }
    {*****************}
    sub_object_number: integer;
    sub_object_ptr, last_sub_object_ptr: view_object_inst_ptr_type;
    clipping_plane_ptr, last_clipping_plane_ptr: view_object_inst_ptr_type;

    {*********************}
    { bounding attributes }
    {*********************}
    extent_box: extent_box_type;
    infinite: boolean;

    {*******}
    { links }
    {*******}
    ray_object_ptr: ray_object_decl_ptr_type;
    next, prev: view_object_decl_ptr_type;
  end; {view_object_decl_type}


var
  viewing_scene_ptr: view_object_inst_ptr_type;


{********************************}
{ routines for declaring objects }
{********************************}
function New_view_object_decl: view_object_decl_ptr_type;
procedure End_view_object_decl;

{************************************}
{ routines for instantiating objects }
{************************************}
procedure Inst_view_prim(surface_ptr: surface_ptr_type;
  trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type;
  bounding_kind: bounding_kind_type);
procedure Inst_view_object(object_decl_ptr: view_object_decl_ptr_type;
  trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type;
  bounding_kind: bounding_kind_type);
procedure Inst_view_clip(trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type);

{**************************************}
{ routine for freeing of a view object }
{ declaration and all of its instances }
{**************************************}
procedure Free_view_object(var object_decl_ptr: view_object_decl_ptr_type);

{*******************************************************}
{ routines for making view objects outside of the graph }
{*******************************************************}
function New_view_object_inst: view_object_inst_ptr_type;
procedure Free_view_object_inst(var object_inst_ptr: view_object_inst_ptr_type);


implementation
uses
  errors, new_memory, constants, vectors, project;


{*******************************************************}
{                 viewing data structures               }
{*******************************************************}
{       The viewing data structs are a graph like       }
{       the geometry data structs, but with certain     }
{       differences:                                    }
{                                                       }
{       1) the graph contains the boundary              }
{          representation and not the pure              }
{          geometric representation.                    }
{       2) the graph will be 'shallower' than           }
{          the geometry graph because objects           }
{          with few subobjects will have been           }
{          removed from the graph to make the           }
{          rendering process more efficient.            }
{          The penalty for compressing the graph        }
{          is that more memory may be used. In          }
{          this way, we can vary the representation     }
{          continuously from a DAG to a display list.   }
{       3) the graph contains bounding boxes            }
{          for culling out objects outside of           }
{          the field of view                            }
{       4) the graph contains distances for             }
{          depth sorting the objects                    }
{*******************************************************}


{*******************************************************}
{                 viewing data structures               }
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
{  view_decl_ptr-> |scene|<-->| car |-||                }
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
  {       viewing_decls_ptr always points to the          }
  {       most primitive (least complex) view_decl.       }
  {               (the first one declared)                }
  {                                                       }
  {       last_viewing_decl_ptr always points to the      }
  {       least primitive (most complex) view_decl        }
  {               (the last one declared)                 }
  {                                                       }
  {       In the case that objects are generated          }
  {       recursively, the build order is reversed.       }
  {       The most complex object is made, then the       }
  {       subobjets are made, then we go back to the      }
  {       complex object again. To implement this, we     }
  {       need a stack, and current_viewing_decl_ptr      }
  {       always points to the current object being       }
  {       defined which is at the top of the stack.       }
  {*******************************************************}
const
  stack_size = 256;
  memory_alert = false;


type
  view_object_decl_stack_ptr_type = ^view_object_decl_stack_type;
  view_object_decl_stack_type = array[1..stack_size] of
    view_object_decl_ptr_type;


var
  stack: view_object_decl_stack_ptr_type;
  stack_ptr: integer;
  viewing_decls_ptr: view_object_decl_ptr_type;
  last_viewing_decl_ptr: view_object_decl_ptr_type;
  current_viewing_decl_ptr: view_object_decl_ptr_type;
  object_number: integer;

  {**************************************************}
  { free lists for object instances and declarations }
  {**************************************************}
  inst_free_list: view_object_inst_ptr_type;
  decl_free_list: view_object_decl_ptr_type;


{************************************}
{ routines for creating view objects }
{************************************}


procedure Push_view_object_stack(view_object_decl_ptr:
  view_object_decl_ptr_type);
begin
  if (stack_ptr < stack_size) then
    begin
      stack_ptr := stack_ptr + 1;
      stack^[stack_ptr] := view_object_decl_ptr;
      current_viewing_decl_ptr := view_object_decl_ptr;
    end
  else
    Error('view object stack overflow');
end; {procedure Push_view_object_stack}


procedure Pop_view_object_stack;
begin
  if (stack_ptr > 0) then
    begin
      stack_ptr := stack_ptr - 1;
      current_viewing_decl_ptr := stack^[stack_ptr];
    end
  else
    Error('view object stack underflow');
end; {procedure Pop_view_object_stack}


procedure Init_view_object_decl(object_decl_ptr: view_object_decl_ptr_type);
begin
  with object_decl_ptr^ do
    begin
      {*****************************}
      { initialize sub object lists }
      {*****************************}
      sub_object_number := 0;
      sub_object_ptr := nil;
      last_sub_object_ptr := nil;

      clipping_plane_ptr := nil;
      last_clipping_plane_ptr := nil;

      {********************************}
      { initialize bounding attributes }
      {********************************}
      extent_box := zero_extent_box;
      infinite := false;

      {******************}
      { initialize links }
      {******************}
      ray_object_ptr := nil;
      next := nil;
      prev := nil;
    end;
end; {function Init_view_object_decl}


function New_view_object_decl: view_object_decl_ptr_type;
var
  new_object_ptr: view_object_decl_ptr_type;
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
        writeln('allocating new view object decl');
      new(new_object_ptr);

      object_number := object_number + 1;
    end;

  {****************************}
  { initialize new object decl }
  {****************************}
  Init_view_object_decl(new_object_ptr);

  Push_view_object_stack(new_object_ptr);
  New_view_object_decl := new_object_ptr;
end; {function New_view_object_decl}


procedure Init_view_object_inst(object_ptr: view_object_inst_ptr_type);
begin
  with object_ptr^ do
    begin
      {**************************************************}
      { initialize transformation and shading attributes }
      {**************************************************}
      trans := unit_trans;
      shader_trans := unit_trans;
      attributes := null_attributes;
      bounding_kind := null_bounds;
      distance := 0;

      {******************}
      { initialize links }
      {******************}
      ray_object_ptr := nil;
      geom_object_ptr := nil;
      next := nil;
      spatial_next := nil;
    end;
end; {procedure Init_view_object_inst}


function New_view_object_inst: view_object_inst_ptr_type;
var
  object_ptr: view_object_inst_ptr_type;
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
        writeln('allocating new view object inst');
      new(object_ptr);
    end;

  {*****************************}
  { initialize view object inst }
  {*****************************}
  Init_view_object_inst(object_ptr);

  New_view_object_inst := object_ptr;
end; {function New_view_object_inst}


procedure Inst_view_prim(surface_ptr: surface_ptr_type;
  trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type;
  bounding_kind: bounding_kind_type);
var
  object_ptr: view_object_inst_ptr_type;
begin
  {****************************}
  { make instance of primitive }
  {****************************}
  object_ptr := New_view_object_inst;
  object_ptr^.kind := view_object_prim;
  object_ptr^.surface_ptr := surface_ptr;
  object_ptr^.trans := trans;
  object_ptr^.attributes := attributes;
  object_ptr^.shader_trans := shader_trans;
  object_ptr^.ray_object_ptr := ray_object_ptr;
  object_ptr^.geom_object_ptr := geom_object_ptr;
  object_ptr^.bounding_kind := bounding_kind;

  if bounding_kind in infinite_bounding_kinds then
    current_viewing_decl_ptr^.infinite := true;

  {****************************}
  { add object to current decl }
  {****************************}
  object_ptr^.next := nil;
  with current_viewing_decl_ptr^ do
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
end; {procedure Inst_view_prim}


procedure Inst_view_clip(trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type);
var
  object_ptr: view_object_inst_ptr_type;
begin
  {*********************************}
  { make instance of clipping plane }
  {*********************************}
  object_ptr := New_view_object_inst;
  object_ptr^.kind := view_object_clip;
  object_ptr^.trans := trans;
  object_ptr^.attributes := attributes;
  object_ptr^.shader_trans := shader_trans;
  object_ptr^.ray_object_ptr := ray_object_ptr;
  object_ptr^.geom_object_ptr := geom_object_ptr;
  object_ptr^.bounding_kind := null_bounds;

  {****************************}
  { add object to current decl }
  {****************************}
  object_ptr^.next := nil;
  with current_viewing_decl_ptr^ do
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
    end;
end; {procedure Inst_view_clip}


procedure Inst_view_object(object_decl_ptr: view_object_decl_ptr_type;
  trans: trans_type;
  attributes: object_attributes_type;
  shader_trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type;
  geom_object_ptr: object_inst_ptr_type;
  bounding_kind: bounding_kind_type);
var
  object_ptr: view_object_inst_ptr_type;
begin
  if (object_decl_ptr <> nil) then
    begin
      {*************************}
      { make instance of object }
      {*************************}
      object_ptr := New_view_object_inst;
      object_ptr^.kind := view_object_decl;
      object_ptr^.object_decl_ptr := object_decl_ptr;
      object_ptr^.trans := trans;
      object_ptr^.attributes := attributes;
      object_ptr^.shader_trans := shader_trans;
      object_ptr^.ray_object_ptr := ray_object_ptr;
      object_ptr^.geom_object_ptr := geom_object_ptr;
      object_ptr^.bounding_kind := bounding_kind;

      if (current_viewing_decl_ptr <> nil) then
        begin
          if bounding_kind in infinite_bounding_kinds then
            current_viewing_decl_ptr^.infinite := true;

          {****************************}
          { add object to current decl }
          {****************************}
          object_ptr^.next := nil;
          with current_viewing_decl_ptr^ do
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
          if viewing_scene_ptr <> nil then
            begin
              {********************************}
              { add current scene to free list }
              {********************************}
              viewing_scene_ptr^.next := inst_free_list;
              inst_free_list := viewing_scene_ptr;
            end;

          viewing_scene_ptr := object_ptr;
          object_ptr^.next := nil;
        end;
    end
  else
    Error('Can not instantiate a nonexistant object.');
end; {procedure Inst_view_object}


procedure Extend_infinite_extents(var extent_box: extent_box_type;
  object_ptr: view_object_inst_ptr_type);
var
  bounds: bounding_type;
  bounding_box: bounding_box_type;
begin
  while (object_ptr <> nil) do
    begin
      if object_ptr^.bounding_kind in infinite_bounding_kinds then
        if object_ptr^.kind <> view_object_decl then
          begin
            {***************************}
            { infinite primitive object }
            {***************************}
            Make_bounds(bounds,
              To_finite_bounding_kind(object_ptr^.bounding_kind),
              object_ptr^.trans);
            Extend_extent_box_to_bounds(extent_box, bounds);
          end
        else
          begin
            {*************************}
            { infinite complex object }
            {*************************}
            Make_bounding_box_from_extent_box(bounding_box,
              object_ptr^.object_decl_ptr^.extent_box);
            Transform_bounding_box(bounding_box, object_ptr^.trans);
            Extend_extent_box_to_bounding_box(extent_box, bounding_box);
          end;

      object_ptr := object_ptr^.next;
    end;
end; {procedure Extend_infinite_extents}


procedure End_view_object_decl;
begin
  {***************************************}
  { extend extents by infinite subobjects }
  {***************************************}
  with current_viewing_decl_ptr^ do
    if infinite then
      Extend_infinite_extents(extent_box, sub_object_ptr);

  {************************}
  { insert at tail of list }
  {************************}
  if viewing_decls_ptr = nil then
    begin
      viewing_decls_ptr := current_viewing_decl_ptr;
      last_viewing_decl_ptr := current_viewing_decl_ptr
    end
  else
    begin
      current_viewing_decl_ptr^.next := nil;
      current_viewing_decl_ptr^.prev := last_viewing_decl_ptr;
      last_viewing_decl_ptr^.next := current_viewing_decl_ptr;
      last_viewing_decl_ptr := current_viewing_decl_ptr;
    end;

  Pop_view_object_stack;
end; {procedure End_view_object_decl}


procedure Free_view_object_inst(var object_inst_ptr: view_object_inst_ptr_type);
begin
  if (object_inst_ptr^.kind = view_object_prim) then
    Free_surface(object_inst_ptr^.surface_ptr);

  {*****************************}
  { add sub object to free list }
  {*****************************}
  object_inst_ptr^.next := inst_free_list;
  inst_free_list := object_inst_ptr;
end; {procedure Free_view_object_inst}


procedure Free_view_object_insts(var object_inst_ptr:
  view_object_inst_ptr_type);
var
  temp_object_inst_ptr: view_object_inst_ptr_type;
begin
  while (object_inst_ptr <> nil) do
    begin
      temp_object_inst_ptr := object_inst_ptr;
      object_inst_ptr := object_inst_ptr^.next;
      Free_view_object_inst(temp_object_inst_ptr);
    end;
end; {procedure Free_view_object_insts}


procedure Free_view_object(var object_decl_ptr: view_object_decl_ptr_type);
begin
  if (object_decl_ptr <> nil) then
    begin
      {******************}
      { free sub_objects }
      {******************}
      Free_view_object_insts(object_decl_ptr^.sub_object_ptr);
      Free_view_object_insts(object_decl_ptr^.clipping_plane_ptr);

      {******************}
      { free object decl }
      {******************}
      if object_decl_ptr^.prev <> nil then
        object_decl_ptr^.prev^.next := object_decl_ptr^.next
      else
        viewing_decls_ptr := object_decl_ptr^.next;

      if object_decl_ptr^.next <> nil then
        object_decl_ptr^.next^.prev := object_decl_ptr^.prev
      else
        last_viewing_decl_ptr := object_decl_ptr^.prev;

      {******************************}
      { add object decl to free list }
      {******************************}
      object_decl_ptr^.next := decl_free_list;
      decl_free_list := object_decl_ptr;
      object_decl_ptr := nil;
    end;
end; {procedure Free_view_object}


initialization
  viewing_decls_ptr := nil;
  last_viewing_decl_ptr := nil;
  current_viewing_decl_ptr := nil;
  viewing_scene_ptr := nil;

  {*****************************}
  { init view object decl stack }
  {*****************************}
  if memory_alert then
    writeln('allocating new viewing object decl stack');
  new(stack);

  stack_ptr := 0;
  Push_view_object_stack(nil);
  object_number := 0;
end.
