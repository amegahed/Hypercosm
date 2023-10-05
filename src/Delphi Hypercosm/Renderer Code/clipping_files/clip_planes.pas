unit clip_planes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             clip_planes               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for defining clipping        }
{       planes which can be configured to clip to an            }
{       arbitrary convex region.                                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors;


type
  plane_type = record
    origin, normal: vector_type;
  end; {plane_type}


  clipping_plane_ptr_type = ^clipping_plane_type;
  clipping_plane_type = record
    plane: plane_type;
    next: clipping_plane_ptr_type;
  end; {clipping_plane_type}


var
  {******************************}
  { user defined clipping planes }
  {******************************}
  clipping_planes_ptr: clipping_plane_ptr_type;


{******************************}
{ routines for creating planes }
{******************************}
function To_plane(origin, normal: vector_type): plane_type;
function Reverse_plane(plane: plane_type): plane_type;

{***************************************************}
{ routines for setting user defined clipping planes }
{***************************************************}
procedure Push_clipping_plane(var clipping_plane_ptr: clipping_plane_ptr_type;
  origin, normal: vector_type);
procedure Pop_clipping_plane(var clipping_plane_ptr: clipping_plane_ptr_type);


implementation
uses
  errors, new_memory;


const
  memory_alert = false;


var
  clipping_plane_free_list: clipping_plane_ptr_type;


{******************************}
{ routines for creating planes }
{******************************}


function To_plane(origin, normal: vector_type): plane_type;
var
  plane: plane_type;
begin
  plane.origin := origin;
  plane.normal := normal;
  To_plane := plane;
end; {function To_plane}


function Reverse_plane(plane: plane_type): plane_type;
begin
  plane.normal := Vector_reverse(plane.normal);
  Reverse_plane := plane;
end; {function Reverse_plane}


{***************************************************}
{ routines for setting user defined clipping planes }
{***************************************************}


function New_clipping_plane(origin, normal: vector_type):
  clipping_plane_ptr_type;
var
  clipping_plane_ptr: clipping_plane_ptr_type;
begin
  {***********************************}
  { get clipping plane from free list }
  {***********************************}
  if (clipping_plane_free_list <> nil) then
    begin
      clipping_plane_ptr := clipping_plane_free_list;
      clipping_plane_free_list := clipping_plane_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new clipping plane');
      new(clipping_plane_ptr);
    end;

  {********************}
  { initialize surface }
  {********************}
  clipping_plane_ptr^.plane.origin := origin;
  clipping_plane_ptr^.plane.normal := Vector_reverse(normal);
  clipping_plane_ptr^.next := nil;

  New_clipping_plane := clipping_plane_ptr;
end; {function New_clipping_plane}


procedure Free_clipping_plane(var clipping_plane_ptr: clipping_plane_ptr_type);
begin
  {*********************************}
  { add clipping plane to free list }
  {*********************************}
  clipping_plane_ptr^.next := clipping_plane_free_list;
  clipping_plane_free_list := clipping_plane_ptr;
  clipping_plane_ptr := nil;
end; {procedure Free_clipping_plane}


procedure Push_clipping_plane(var clipping_plane_ptr: clipping_plane_ptr_type;
  origin, normal: vector_type);
var
  new_clipping_plane_ptr: clipping_plane_ptr_type;
begin
  new_clipping_plane_ptr := New_clipping_plane(origin, normal);
  new_clipping_plane_ptr^.next := clipping_plane_ptr;
  clipping_plane_ptr := new_clipping_plane_ptr;
end; {procedure Push_clipping_plane}


procedure Pop_clipping_plane(var clipping_plane_ptr: clipping_plane_ptr_type);
var
  temp: clipping_plane_ptr_type;
begin
  if clipping_plane_ptr <> nil then
    begin
      temp := clipping_plane_ptr;
      clipping_plane_ptr := clipping_plane_ptr^.next;
      Free_clipping_plane(temp);
    end;
end; {procedure Pop_clipping_plane}


initialization
  clipping_planes_ptr := nil;
  clipping_plane_free_list := nil;
end.
