unit trans_stack;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            trans_stack                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module implements the transformation stack         }
{       commonly used in describing the geometric               }
{       transformations in a hierarchical model.                }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  trans;


const
  trans_stack_size = 64;


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


  trans_mode_type = (premultiply_trans, postmultiply_trans);


  trans_stack_ptr_type = ^trans_stack_type;
  trans_stack_type = record
    height: integer;
    stack: array[0..trans_stack_size] of trans_type;
    next: trans_stack_ptr_type;
  end;


{**************************************}
{ routines for allocating trans stacks }
{**************************************}
function New_trans_stack: trans_stack_ptr_type;
function Copy_trans_stack(trans_stack_ptr: trans_stack_ptr_type):
  trans_stack_ptr_type;
procedure Free_trans_stack(var trans_stack_ptr: trans_stack_ptr_type);

{************************************}
{ routines for creating trans stacks }
{************************************}
procedure Reset_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
procedure Push_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
procedure Pop_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
procedure Get_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  var trans: trans_type);
procedure Set_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  trans: trans_type);
function Trans_stack_height(trans_stack_ptr: trans_stack_ptr_type): integer;
procedure Write_trans_stack(trans_stack_ptr: trans_stack_ptr_type);

{*******************************************}
{ routines for accumulating transformations }
{*******************************************}
procedure Transform_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  trans: trans_type);
procedure Set_trans_mode(mode: trans_mode_type);
function Get_trans_mode: trans_mode_type;
procedure Write_trans_mode(mode: trans_mode_type);


implementation
uses
  errors, new_memory, vectors;


const
  memory_alert = false;


var
  trans_stack_free_list: trans_stack_ptr_type;
  trans_mode: trans_mode_type;


  {**************************************}
  { routines for allocating trans stacks }
  {**************************************}


function New_trans_stack: trans_stack_ptr_type;
var
  trans_stack_ptr: trans_stack_ptr_type;
begin
  {********************************}
  { get trans stack from free list }
  {********************************}
  if (trans_stack_free_list <> nil) then
    begin
      trans_stack_ptr := trans_stack_free_list;
      trans_stack_free_list := trans_stack_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new trans stack');
      new(trans_stack_ptr);
    end;

  {******************}
  { init trans stack }
  {******************}
  with trans_stack_ptr^ do
    begin
      height := 0;
      stack[height] := unit_trans;
      next := nil;
    end;

  New_trans_stack := trans_stack_ptr;
end; {function New_trans_stack}


function Copy_trans_stack(trans_stack_ptr: trans_stack_ptr_type):
  trans_stack_ptr_type;
var
  new_trans_stack_ptr: trans_stack_ptr_type;
begin
  new_trans_stack_ptr := New_trans_stack;
  new_trans_stack_ptr^ := trans_stack_ptr^;
  Copy_trans_stack := new_trans_stack_ptr;
end; {function Copy_trans_stack}


procedure Free_trans_stack(var trans_stack_ptr: trans_stack_ptr_type);
begin
  trans_stack_ptr^.next := trans_stack_free_list;
  trans_stack_free_list := trans_stack_ptr;
  trans_stack_ptr := nil;
end; {procedure Free_trans_stack}


{************************************}
{ routines for creating trans stacks }
{************************************}


procedure Reset_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
begin
  with trans_stack_ptr^ do
    begin
      height := 0;
      stack[height] := unit_trans;
    end;
end; {procedure Reset_trans_stack}


procedure Push_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
begin
  with trans_stack_ptr^ do
    begin
      height := height + 1;
      if (height <= trans_stack_size) then
        stack[height] := stack[height - 1]
      else
        Error('transformation stack overflow');
    end;
end; {procedure Push_trans_stack}


procedure Pop_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
begin
  with trans_stack_ptr^ do
    begin
      if (height > 0) then
        height := height - 1
      else
        Error('transformation stack underflow');
    end;
end; {procedure Pop_trans_stack}


procedure Get_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  var trans: trans_type);
begin
  with trans_stack_ptr^ do
    begin
      trans := stack[height];
    end;
end; {procedure Get_trans_stack}


procedure Set_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  trans: trans_type);
begin
  with trans_stack_ptr^ do
    begin
      stack[height] := trans;
    end;
end; {procedure Set_trans_stack}


function Trans_stack_height(trans_stack_ptr: trans_stack_ptr_type): integer;
begin
  Trans_stack_height := trans_stack_ptr^.height;
end; {function Trans_stack_height}


procedure Write_trans_stack(trans_stack_ptr: trans_stack_ptr_type);
var
  counter: integer;
begin
  writeln('trans_stack:');
  for counter := 0 to trans_stack_ptr^.height do
    begin
      writeln('level = ', counter);
      writeln('trans:');
      Write_trans(trans_stack_ptr^.stack[counter]);
    end;
end; {procedure Write_trans_stack}


{*******************************************}
{ routines for accumulating transformations }
{*******************************************}


procedure Transform_trans_stack(trans_stack_ptr: trans_stack_ptr_type;
  trans: trans_type);
begin
  with trans_stack_ptr^ do
    begin
      case trans_mode of
        premultiply_trans:
          Transform_trans(stack[height], trans);

        postmultiply_trans:
          begin
            Transform_trans(trans, stack[height]);
            stack[height] := trans;
          end;
      end;
    end;
end; {procedure Transform_trans_stack}


procedure Set_trans_mode(mode: trans_mode_type);
begin
  trans_mode := mode;
end; {procedure Set_trans_mode}


function Get_trans_mode: trans_mode_type;
begin
  Get_trans_mode := trans_mode;
end; {function Get_trans_mode}


procedure Write_trans_mode(mode: trans_mode_type);
begin
  case mode of
    premultiply_trans:
      write('premultiply_trans');

    postmultiply_trans:
      write('postmultiply_trans');
  end;
end; {procedure Write_trans_mode}


initialization
  trans_stack_free_list := nil;
  trans_mode := premultiply_trans;
end.
