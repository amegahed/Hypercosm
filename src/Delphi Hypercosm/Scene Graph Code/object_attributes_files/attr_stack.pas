unit attr_stack;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             attr_stack                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module implements the attributes stack used        }
{       in describing the hierarchy of non geometric            }
{       attributes in a hierarchical model.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  object_attr;


const
  attributes_stack_size = 64;


type
  {*************************************************************}
  {               order of attributes applications              }
  {*************************************************************}
  { The order of transformations is important. For example, the }
  { transformation A x B is not the same as B x A. Therefore,   }
  { the transformation mode is used to change the order that we }
  { apply the transformations. If the aggregate transformation, }
  { or top of stack is A and the transformation that we wish to }
  { apply is T, then the                                        }
  {        preapply mode yields (T x A) and the                 }
  {        postapply mode yields (A x T).                       }
  {*************************************************************}


  attributes_mode_type = (preapply_attributes, postapply_attributes);


  attributes_stack_ptr_type = ^attributes_stack_type;
  attributes_stack_type = record
    height: integer;
    stack: array[0..attributes_stack_size] of object_attributes_type;
    next: attributes_stack_ptr_type;
  end;


  {*******************************************}
  { routines for allocating attributes stacks }
  {*******************************************}
function New_attributes_stack: attributes_stack_ptr_type;
function Copy_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type):
  attributes_stack_ptr_type;
procedure Free_attributes_stack(var attributes_stack_ptr:
  attributes_stack_ptr_type);

{*****************************************}
{ routines for creating attributes stacks }
{*****************************************}
procedure Reset_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);
procedure Push_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);
procedure Pop_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type);
procedure Get_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type;
  var attributes: object_attributes_type);
procedure Set_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type;
  attributes: object_attributes_type);
function Attributes_stack_height(attributes_stack_ptr:
  attributes_stack_ptr_type): integer;
procedure Write_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);

{**************************************}
{ routines for accumulating attributes }
{**************************************}
procedure Apply_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type;
  attributes: object_attributes_type);
procedure Set_attributes_mode(mode: attributes_mode_type);
function Get_attributes_mode: attributes_mode_type;
procedure Write_attributes_mode(mode: attributes_mode_type);


implementation
uses
  errors, new_memory;


const
  memory_alert = false;


var
  attributes_stack_free_list: attributes_stack_ptr_type;
  attributes_mode: attributes_mode_type;


  {*******************************************}
  { routines for allocating attributes stacks }
  {*******************************************}


function New_attributes_stack: attributes_stack_ptr_type;
var
  attributes_stack_ptr: attributes_stack_ptr_type;
begin
  {*************************************}
  { get attributes stack from free list }
  {*************************************}
  if (attributes_stack_free_list <> nil) then
    begin
      attributes_stack_ptr := attributes_stack_free_list;
      attributes_stack_free_list := attributes_stack_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new attributes stack');
      new(attributes_stack_ptr);
    end;

  {***********************}
  { init attributes stack }
  {***********************}
  with attributes_stack_ptr^ do
    begin
      height := 0;
      stack[height] := null_attributes;
      next := nil;
    end;

  New_attributes_stack := attributes_stack_ptr;
end; {function New_attributes_stack}


function Copy_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type):
  attributes_stack_ptr_type;
var
  new_attributes_stack_ptr: attributes_stack_ptr_type;
begin
  new_attributes_stack_ptr := New_attributes_stack;
  new_attributes_stack_ptr^ := attributes_stack_ptr^;
  Copy_attributes_stack := new_attributes_stack_ptr;
end; {function Copy_attributes_stack}


procedure Free_attributes_stack(var attributes_stack_ptr:
  attributes_stack_ptr_type);
begin
  attributes_stack_ptr^.next := attributes_stack_free_list;
  attributes_stack_free_list := attributes_stack_ptr;
  attributes_stack_ptr := nil;
end; {procedure Free_attributes_stack}


{*****************************************}
{ routines for creating attributes stacks }
{*****************************************}


procedure Reset_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);
begin
  with attributes_stack_ptr^ do
    begin
      height := 0;
      stack[height] := null_attributes;
    end;
end; {procedure Reset_attributes_stack}


procedure Push_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);
begin
  with attributes_stack_ptr^ do
    begin
      height := height + 1;
      if (height <= attributes_stack_size) then
        stack[height] := stack[height - 1]
      else
        Error('attributes stack overflow');
    end;
end; {procedure Push_attributes_stack}


procedure Pop_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type);
begin
  with attributes_stack_ptr^ do
    begin
      if (height > 0) then
        height := height - 1
      else
        Error('attributes stack underflow');
    end;
end; {procedure Pop_attributes_stack}


procedure Get_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type;
  var attributes: object_attributes_type);
begin
  with attributes_stack_ptr^ do
    begin
      attributes := stack[height];
    end;
end; {procedure Get_attributes_stack}


procedure Set_attributes_stack(attributes_stack_ptr: attributes_stack_ptr_type;
  attributes: object_attributes_type);
begin
  with attributes_stack_ptr^ do
    begin
      stack[height] := attributes;
    end;
end; {procedure Set_attributes_stack}


function Attributes_stack_height(attributes_stack_ptr:
  attributes_stack_ptr_type): integer;
begin
  Attributes_stack_height := attributes_stack_ptr^.height;
end; {function Attributes_stack_height}


procedure Write_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type);
var
  counter: integer;
begin
  writeln('attributes_stack:');
  for counter := 0 to attributes_stack_ptr^.height do
    begin
      writeln('level = ', counter);
      writeln('attributes:');
      Write_object_attributes(attributes_stack_ptr^.stack[counter]);
    end;
end; {procedure Write_attributes_stack}


{**************************************}
{ routines for accumulating attributes }
{**************************************}


procedure Apply_attributes_stack(attributes_stack_ptr:
  attributes_stack_ptr_type;
  attributes: object_attributes_type);
begin
  with attributes_stack_ptr^ do
    begin
      case attributes_mode of
        preapply_attributes:
          Apply_object_attributes(stack[height], attributes);

        postapply_attributes:
          begin
            Apply_object_attributes(attributes, stack[height]);
            stack[height] := attributes;
          end;
      end;
    end;
end; {procedure Apply_attributes_stack}


procedure Set_attributes_mode(mode: attributes_mode_type);
begin
  attributes_mode := mode;
end; {procedure Set_attributes_mode}


function Get_attributes_mode: attributes_mode_type;
begin
  Get_attributes_mode := attributes_mode;
end; {function Get_attributes_mode}


procedure Write_attributes_mode(mode: attributes_mode_type);
begin
  case mode of
    preapply_attributes:
      write('preapply_attributes');

    postapply_attributes:
      write('postapply_attributes');
  end;
end; {procedure Write_attributes_mode}


initialization
  attributes_stack_free_list := nil;
  attributes_mode := preapply_attributes;
end.

