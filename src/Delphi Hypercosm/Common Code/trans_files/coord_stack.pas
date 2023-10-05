unit coord_stack;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            coord_stack                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module implements the transformation stack         }
{       commonly used in describing the geometric               }
{       transformations in a hierarchical model. Also,          }
{       the reverse transformations are provided in the         }
{       coords structure.                                       }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  coord_axes, trans_stack;


const
  coord_stack_size = 64;


type
  {*************************************************************}
  {                     order of transformations                }
  {*************************************************************}
  { The order of transformations is important. For example, the }
  { transformation A x B is not the same as B x A. Therefore,   }
  { the transformation mode is used to change the order that we }
  { apply the transformations. If the aggregate transformation, }
  { or top of stack is A and the transformation that we wish to }
  { apply is T, then the                                        }
  {        premultiply mode yields (T x A) and the              }
  {        postmultiply mode yields (A x T).                    }
  {*************************************************************}


  coord_mode_type = (premultiply_coords, postmultiply_coords);


  coord_stack_ptr_type = ^coord_stack_type;
  coord_stack_type = record
    height: integer;
    stack: array[0..coord_stack_size] of coord_axes_type;
    next: coord_stack_ptr_type;
  end;


{**************************************}
{ routines for allocating coord stacks }
{**************************************}
function New_coord_stack: coord_stack_ptr_type;
function Copy_coord_stack(coord_stack_ptr: coord_stack_ptr_type):
  coord_stack_ptr_type;
procedure Free_coord_stack(var coord_stack_ptr: coord_stack_ptr_type);

{************************************}
{ routines for creating coord stacks }
{************************************}
procedure Reset_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
procedure Push_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
procedure Pop_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
procedure Get_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  var coord_axes: coord_axes_type);
procedure Set_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  coord_axes: coord_axes_type);
function Coord_stack_height(coord_stack_ptr: coord_stack_ptr_type): integer;

{*******************************************}
{ routines for accumulating transformations }
{*******************************************}
procedure Transform_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  coord_axes: coord_axes_type);
procedure Set_coord_mode(mode: coord_mode_type);
function Get_coord_mode: coord_mode_type;

{***************************************************************}
{ routines for converting between trans stacks and coord stacks }
{***************************************************************}
function Trans_to_coord_stack(trans_stack_ptr: trans_stack_ptr_type):
  coord_stack_ptr_type;
function Coord_to_trans_stack(coord_stack_ptr: coord_stack_ptr_type):
  trans_stack_ptr_type;

{**********************}
{ diagnositic routines }
{**********************}
procedure Write_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
procedure Write_coord_mode(mode: coord_mode_type);


implementation
uses
  errors, new_memory, vectors, trans;


const
  memory_alert = false;


var
  coord_stack_free_list: coord_stack_ptr_type;
  coord_mode: coord_mode_type;


  {**************************************}
  { routines for allocating coord stacks }
  {**************************************}


function New_coord_stack: coord_stack_ptr_type;
var
  coord_stack_ptr: coord_stack_ptr_type;
begin
  {********************************}
  { get coord stack from free list }
  {********************************}
  if (coord_stack_free_list <> nil) then
    begin
      coord_stack_ptr := coord_stack_free_list;
      coord_stack_free_list := coord_stack_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new coord stack');
      new(coord_stack_ptr);
    end;

  {******************}
  { init coord stack }
  {******************}
  with coord_stack_ptr^ do
    begin
      height := 0;
      stack[height] := unit_axes;
      next := nil;
    end;

  New_coord_stack := coord_stack_ptr;
end; {function New_coord_stack}


function Copy_coord_stack(coord_stack_ptr: coord_stack_ptr_type):
  coord_stack_ptr_type;
var
  new_coord_stack_ptr: coord_stack_ptr_type;
begin
  new_coord_stack_ptr := New_coord_stack;
  new_coord_stack_ptr^ := coord_stack_ptr^;
  Copy_coord_stack := new_coord_stack_ptr;
end; {function Copy_coord_stack}


procedure Free_coord_stack(var coord_stack_ptr: coord_stack_ptr_type);
begin
  coord_stack_ptr^.next := coord_stack_free_list;
  coord_stack_free_list := coord_stack_ptr;
  coord_stack_ptr := nil;
end; {procedure Free_coord_stack}


{************************************}
{ routines for creating coord stacks }
{************************************}


procedure Reset_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
begin
  with coord_stack_ptr^ do
    begin
      height := 0;
      stack[height] := unit_axes;
    end;
end; {procedure Reset_coord_stack}


procedure Push_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
begin
  with coord_stack_ptr^ do
    begin
      height := height + 1;
      if (height <= coord_stack_size) then
        stack[height] := stack[height - 1]
      else
        Error('coord stack overflow');
    end;
end; {procedure Push_coord_stack}


procedure Pop_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
begin
  with coord_stack_ptr^ do
    begin
      if (height > 0) then
        height := height - 1
      else
        Error('coord stack underflow');
    end;
end; {procedure Pop_coord_stack}


procedure Get_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  var coord_axes: coord_axes_type);
begin
  with coord_stack_ptr^ do
    begin
      coord_axes := stack[height];
    end;
end; {procedure Get_coord_stack}


procedure Set_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  coord_axes: coord_axes_type);
begin
  with coord_stack_ptr^ do
    begin
      stack[height] := coord_axes;
    end;
end; {procedure Set_coord_stack}


function Coord_stack_height(coord_stack_ptr: coord_stack_ptr_type): integer;
begin
  Coord_stack_height := coord_stack_ptr^.height;
end; {function Coord_stack_height}


procedure Write_coord_stack(coord_stack_ptr: coord_stack_ptr_type);
var
  counter: integer;
begin
  writeln('coord_stack:');
  for counter := 0 to coord_stack_ptr^.height do
    begin
      writeln('level = ', counter);
      writeln('coord axes:');
      Write_trans(coord_stack_ptr^.stack[counter].trans);
    end;
end; {procedure Write_coord_stack}


{*******************************************}
{ routines for accumulating transformations }
{*******************************************}


procedure Transform_coord_stack(coord_stack_ptr: coord_stack_ptr_type;
  coord_axes: coord_axes_type);
begin
  with coord_stack_ptr^ do
    begin
      case coord_mode of
        premultiply_coords:
          Transform_axes_from_axes(stack[height], coord_axes);

        postmultiply_coords:
          begin
            Transform_axes_from_axes(coord_axes, stack[height]);
            stack[height] := coord_axes;
          end;
      end;
    end;
end; {procedure Transform_coord_stack}


procedure Set_coord_mode(mode: coord_mode_type);
begin
  coord_mode := mode;
end; {procedure Set_coord_mode}


function Get_coord_mode: coord_mode_type;
begin
  Get_coord_mode := coord_mode;
end; {function Get_coord_mode}


procedure Write_coord_mode(mode: coord_mode_type);
begin
  case mode of
    premultiply_coords:
      write('premultiply_coords');

    postmultiply_coords:
      write('postmultiply_coords');
  end;
end; {procedure Write_coord_mode}


{***************************************************************}
{ routines for converting between trans stacks and coord stacks }
{***************************************************************}


function Trans_to_coord_stack(trans_stack_ptr: trans_stack_ptr_type):
  coord_stack_ptr_type;
var
  coord_stack_ptr: coord_stack_ptr_type;
  counter: integer;
begin
  coord_stack_ptr := New_coord_stack;
  coord_stack_ptr^.height := trans_stack_ptr^.height;
  for counter := 0 to trans_stack_ptr^.height do
    coord_stack_ptr^.stack[counter] :=
      Trans_to_axes(trans_stack_ptr^.stack[counter]);
  Trans_to_coord_stack := coord_stack_ptr;
end; {function Trans_to_coord_stack}


function Coord_to_trans_stack(coord_stack_ptr: coord_stack_ptr_type):
  trans_stack_ptr_type;
var
  trans_stack_ptr: trans_stack_ptr_type;
  counter: integer;
begin
  trans_stack_ptr := New_trans_stack;
  trans_stack_ptr^.height := coord_stack_ptr^.height;
  for counter := 0 to coord_stack_ptr^.height do
    trans_stack_ptr^.stack[counter] :=
      Axes_to_trans(coord_stack_ptr^.stack[counter]);
  Coord_to_trans_stack := trans_stack_ptr;
end; {function Coord_to_trans_stack}


initialization
  coord_stack_free_list := nil;
  coord_mode := premultiply_coords;
end.
