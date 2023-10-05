unit anim;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               anim                    3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The animanager provides a method of creating and        }
{       maintaining the geometry data structs as an             }
{       animation runs.                                         }
{                                                               }
{       During the animation, objects are created and           }
{       destroyed and this module provides a means of           }
{       keeping track of which  objects persist from            }
{       frame to frame and which need to be made or             }
{       destroyed.                                              }
{                                                               }
{       The animanager also provides unique integer             }
{       identifiers for each new object that it creates         }
{       so that the viewing and raytracing data structures      }
{       can be linked to the geometry.                          }
{                                                               }
{       This is necessary, so that when the geometry            }
{       changes, the other structures can be made to            }
{       change to match.                                        }
{                                                               }
{       By using integer ids, a certain id can index a          }
{       different representation of a particular object         }
{       in each of the different layers.                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, objects;


{*******************************}
{ routines for grouping objects }
{*******************************}
procedure Begin_object_group(object_group_id: integer);
procedure Name_object_group(name: string_type);
procedure End_object_group;
procedure Next_object_group;

{*******************************}
{ routines for creating objects }
{*******************************}
function New_object: object_decl_ptr_type;
procedure Name_object(name: string_type);
procedure End_object;

{***********************************}
{ routines for buiding the database }
{***********************************}
procedure Goto_first_needed_object;
function Next_needed_object: object_decl_ptr_type;

{**********************************************}
{ routines for initially building the database }
{**********************************************}
procedure Goto_first_new_object;
function Next_new_object: object_decl_ptr_type;

{**************************************************}
{ routines for incrementally updating the database }
{**************************************************}
procedure Goto_first_created_object;
function Next_created_object: object_decl_ptr_type;

procedure Goto_first_terminated_object;
function Next_terminated_object: object_decl_ptr_type;


implementation
uses
  errors, new_memory;


{*******************************************************}
{               animanager implementation               }
{*******************************************************}
{       The reason for the free list is that as the     }
{       animation runs, objects come into existance     }
{       and disappear again, so we recycle their ids.   }
{*******************************************************}
{                   -        -        -        -        }
{                   |        |        |        |        }
{       free     /-----\  /-----\  /-----\  /-----\     }
{       list ->  | id6 |->| id4 |->| id2 |->| id1 |-//  }
{                \-----/  \-----/  \-----/  \-----/     }
{                   ^        ^        ^        ^        }
{                   |        |        |        |        }
{                   \---- \  |        \------\ \-\      }
{       id block          |  \-------\       |   |      }
{       /-----------------|-\  /-----|-------|---|-\    }
{    \\-| 10| 9 | 8 | 7 | 6 |<-| 5 | 4 | 3 | 2 | 1 |    }
{       \---------|---|-----/  \-|-------|---------/    }
{          /------/   |          |       \--\           }
{ created  |          |          |          |           }
{ objs     v          v          v          v           }
{  |    /-----\    /-----\    /-----\    /-----\        }
{  \--->| id8 |--->| id7 |-|  | id5 |    | id3 |        }
{       \-----/    \-----/    \-----/    \-----/        }
{          |          |          |          |           }
{          v          v          v          v           }
{               pointers to geometry decls              }
{*******************************************************}


const
  id_block_size = 64;
  verbose = false;


type
  object_id_ptr_type = ^object_id_type;
  object_id_type = record
    {************************************}
    { These flags are used to find which }
    { of the objects are not used in the }
    { current object_group so we can     }
    { delete them from the database.     }
    {************************************}
    object_id: integer;
    used, touched: boolean;
    name: string_type;
    object_decl_ptr: object_decl_ptr_type;
    next: object_id_ptr_type;
  end; {object_id_type}


  id_block_ptr_type = ^id_block_type;
  id_block_type = record
    ptr_array: array[1..id_block_size] of object_id_ptr_type;
    next: id_block_ptr_type;
  end; {id_block_type}


  object_group_id_ptr_type = ^object_group_id_type;
  object_group_id_type = record
    object_group_id: integer;
    name: string_type;
    object_decl_ptr: object_decl_ptr_type;
    next: object_group_id_ptr_type;
  end; {object_group_id_type}


  {*******************************************************}
  {       first_object_id_ptr always points to the        }
  {       most primitive (least complex) new decl.        }
  {               (the first one declared)                }
  {                                                       }
  {       last_object_id_ptr always points to the         }
  {       least primitive (most complex) object decl      }
  {               (the last one declared)                 }
  {                                                       }
  {       In the case that objects are generated          }
  {       recursively, the build order is reversed.       }
  {       The most complex object is made, then the       }
  {       subobjets are made, then we go back to the      }
  {       complex object again. To implement this, we     }
  {       need a stack, and created_object_id_ptr         }
  {       always points to the current object being       }
  {       defined which is at the top of the stack.       }
  {*******************************************************}


const
  stack_size = 256;
  memory_alert = false;


type
  object_id_stack_ptr_type = ^object_id_stack_type;
  object_group_id_stack_ptr_type = ^object_group_id_stack_type;
  object_id_stack_type = array[0..stack_size] of object_id_ptr_type;
  object_group_id_stack_type = array[0..stack_size] of object_group_id_ptr_type;


var
  object_id_stack: object_id_stack_ptr_type;
  object_group_id_stack: object_group_id_stack_ptr_type;
  object_id_stack_ptr: integer;
  object_group_id_stack_ptr: integer;

  first_id_block_ptr, last_id_block_ptr: id_block_ptr_type;
  number_of_entries: integer;

  {************}
  { free lists }
  {************}
  object_id_free_list: object_id_ptr_type;
  object_group_id_free_list: object_group_id_ptr_type;

  {***********************************************}
  { internal pointers to created and terminated   }
  { lists point to start of object id lists.      }
  {***********************************************}
  first_object_id_ptr, last_object_id_ptr: object_id_ptr_type;
  first_local_id_ptr, last_local_id_ptr: object_id_ptr_type;
  current_object_id_ptr, terminated_object_id_ptr: object_id_ptr_type;

  {***********************************************}
  { pointers to object_id lists controlled by     }
  { interface functions.                          }
  {***********************************************}
  created_object_id_ptr, dead_object_id_ptr: object_id_ptr_type;
  new_object_decl_ptr: object_decl_ptr_type;
  needed_object_decl_ptr: object_decl_ptr_type;

  {*****************************************************}
  { list of object_groups which point into object graph }
  {*****************************************************}
  object_group_id_list: object_group_id_ptr_type;
  current_object_group_id_ptr: object_group_id_ptr_type;
  previous_object_group_id_ptr: object_group_id_ptr_type;


  {**************************}
  { object id stack routines }
  {**************************}


procedure Push_object_id_stack(object_id_ptr: object_id_ptr_type);
begin
  if (object_id_stack_ptr < stack_size) then
    begin
      object_id_stack_ptr := object_id_stack_ptr + 1;
      object_id_stack^[object_id_stack_ptr] := object_id_ptr;
      current_object_id_ptr := object_id_ptr;
    end
  else
    Error('object id stack overflow');
end; {function Push_object_id_stack}


procedure Pop_object_id_stack;
begin
  if (object_id_stack_ptr > 0) then
    begin
      object_id_stack_ptr := object_id_stack_ptr - 1;
      current_object_id_ptr := object_id_stack^[object_id_stack_ptr];
    end
  else
    Error('object id stack underflow');
end; {procedure Pop_object_id_stack}


{********************************}
{ object group id stack routines }
{********************************}


procedure Push_object_group_id_stack(object_group_id_ptr:
  object_group_id_ptr_type);
begin
  if (object_group_id_stack_ptr < stack_size) then
    begin
      object_group_id_stack_ptr := object_group_id_stack_ptr + 1;
      object_group_id_stack^[object_group_id_stack_ptr] := object_group_id_ptr;
      current_object_group_id_ptr := object_group_id_ptr;
    end
  else
    Error('object group id stack overflow');
end; {function Push_object_group_id_stack}


procedure Pop_object_group_id_stack;
begin
  if (object_group_id_stack_ptr > 0) then
    begin
      object_group_id_stack_ptr := object_group_id_stack_ptr - 1;
      current_object_group_id_ptr :=
        object_group_id_stack^[object_group_id_stack_ptr];
    end
  else
    Error('object group id stack underflow');
end; {procedure Pop_object_group_id_stack}


function New_id_block: id_block_ptr_type;
var
  id_block_ptr: id_block_ptr_type;
  counter: integer;
begin
  if memory_alert then
    writeln('allocating new id block');
  new(id_block_ptr);

  with id_block_ptr^ do
    begin
      for counter := 1 to id_block_size do
        ptr_array[counter] := nil;
      next := nil;
    end;

  New_id_block := id_block_ptr;
end; {function New_id_block}


function New_object_id: object_id_ptr_type;
var
  index: integer;
  object_id_ptr: object_id_ptr_type;
begin
  if object_id_free_list <> nil then
    begin
      {***************************}
      { take new id off free list }
      {***************************}
      object_id_ptr := object_id_free_list;
      object_id_free_list := object_id_free_list^.next;
    end
  else
    begin
      {********************}
      { make new object id }
      {********************}
      if memory_alert then
        writeln('allocating new object id');
      new(object_id_ptr);

      {**********************************}
      { If necessary, create a new block }
      {**********************************}
      if (number_of_entries mod id_block_size) = 0 then
        begin
          if (first_id_block_ptr = nil) then
            begin
              first_id_block_ptr := New_id_block;
              last_id_block_ptr := first_id_block_ptr;
            end
          else
            begin
              last_id_block_ptr^.next := New_id_block;
              last_id_block_ptr := last_id_block_ptr^.next;
            end;
        end;

      number_of_entries := number_of_entries + 1;
      object_id_ptr^.object_id := number_of_entries;

      {***********************}
      { store id ptr in block }
      {***********************}
      index := (number_of_entries - 1) mod id_block_size + 1;
      last_id_block_ptr^.ptr_array[index] := object_id_ptr;
    end;

  {**********************}
  { initialize object id }
  {**********************}
  object_id_ptr^.name := '';
  object_id_ptr^.next := nil;

  if verbose then
    writeln('new anim object with id = ', object_id_ptr^.object_id: 1);

  New_object_id := object_id_ptr;
end; {function New_object_id}


procedure Free_object_id(var object_id_ptr: object_id_ptr_type);
begin
  if verbose then
    writeln('free anim object with id = ', object_id_ptr^.object_id: 1);

  {****************************}
  { add object id to free list }
  {****************************}
  object_id_ptr^.next := object_id_free_list;
  object_id_free_list := object_id_ptr;
  object_id_ptr := nil;
end; {procedure Free_object_id}


function New_object_group_id: object_group_id_ptr_type;
var
  object_group_id_ptr: object_group_id_ptr_type;
begin
  {************************************}
  { get object group id from free list }
  {************************************}
  if (object_group_id_free_list <> nil) then
    begin
      object_group_id_ptr := object_group_id_free_list;
      object_group_id_free_list := object_group_id_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new object group id');
      new(object_group_id_ptr);
    end;

  object_group_id_ptr^.object_group_id := 0;
  object_group_id_ptr^.object_decl_ptr := nil;
  object_group_id_ptr^.next := nil;

  New_object_group_id := object_group_id_ptr;
end; {function New_object_group_id}


procedure Free_object_group_id(var object_group_id_ptr:
  object_group_id_ptr_type);
begin
  {**********************************}
  { add object group id to free list }
  {**********************************}
  object_group_id_ptr^.next := object_group_id_free_list;
  object_group_id_free_list := object_group_id_ptr;
  object_group_id_ptr := nil;
end; {procedure Free_object_group_id}


{***********************************************}
{ routines for grouping objects by object group }
{***********************************************}


procedure Begin_object_group(object_group_id: integer);
var
  object_group_id_ptr: object_group_id_ptr_type;
  found: boolean;
begin
  if verbose then
    writeln('beginning object group with id =  ', object_group_id: 1);

  {*************************************************************}
  { create new object group and either add it to the list of    }
  { object groups or substitute for a preexisting object group. }
  {*************************************************************}
  object_group_id_ptr := object_group_id_list;
  found := false;
  while (object_group_id_ptr <> nil) and not found do
    begin
      if (object_group_id_ptr^.object_group_id = object_group_id) then
        found := true
      else
        object_group_id_ptr := object_group_id_ptr^.next;
    end;

  if not found then
    begin
      object_group_id_ptr := New_object_group_id;
      object_group_id_ptr^.object_group_id := object_group_id;
      object_group_id_ptr^.next := object_group_id_list;
      object_group_id_list := object_group_id_ptr;
    end;

  {*****************************}
  { initialize new object group }
  {*****************************}
  object_group_id_ptr^.name := '';
  object_group_id_ptr^.object_decl_ptr := nil;

  Push_object_group_id_stack(object_group_id_ptr);
end; {procedure Begin_object_group}


procedure Name_object_group(name: string_type);
begin
  current_object_group_id_ptr^.name := name;
end; {procedure Name_object_group}


procedure Index_decl_list(index: integer;
  var id_block_ptr: id_block_ptr_type;
  var block_index: integer);
var
  blocks: integer;
begin
  if (index > number_of_entries) then
    writeln('Error - id index out of range')
  else
    begin
      if (index = number_of_entries) then
        begin
          {**************************************}
          { accessing the last entry in the list }
          {**************************************}
          id_block_ptr := last_id_block_ptr;
          block_index := (index - 1) mod id_block_size + 1;
        end
      else
        begin
          id_block_ptr := first_id_block_ptr;
          blocks := (index - 1) div id_block_size;
          block_index := (index - 1) mod id_block_size + 1;

          while (blocks >= 1) do
            begin
              id_block_ptr := id_block_ptr^.next;
              blocks := blocks - 1;
            end;
        end;
    end;
end; {procedure Index_decl_list}


function Find_object(object_id: integer): object_decl_ptr_type;
var
  id_block_ptr: id_block_ptr_type;
  block_index: integer;
begin
  Index_decl_list(object_id, id_block_ptr, block_index);
  Find_object := id_block_ptr^.ptr_array[block_index]^.object_decl_ptr;
end; {function Find_object}


function Find_object_id(object_id: integer): object_id_ptr_type;
var
  id_block_ptr: id_block_ptr_type;
  block_index: integer;
begin
  Index_decl_list(object_id, id_block_ptr, block_index);
  Find_object_id := id_block_ptr^.ptr_array[block_index];
end; {function Find_object_id}


procedure Touch_objects(object_id: integer);
var
  object_inst_ptr: object_inst_ptr_type;
  object_id_ptr: object_id_ptr_type;
begin
  object_id_ptr := Find_object_id(object_id);

  {***********************************************}
  { if object has not been previously touched,    }
  { then recursively touch all of its subobjects. }
  {***********************************************}
  object_id_ptr^.used := true;
  if not object_id_ptr^.touched then
    begin
      if verbose then
        writeln('touching object named "', object_id_ptr^.name, '"');

      object_inst_ptr := object_id_ptr^.object_decl_ptr^.sub_object_ptr;
      while (object_inst_ptr <> nil) do
        begin
          if (object_inst_ptr^.kind = complex_object) then
            Touch_objects(object_inst_ptr^.object_decl_ptr^.object_id);
          object_inst_ptr := object_inst_ptr^.next;
        end;
    end;
  object_id_ptr^.touched := true;
end; {procedure Touch_objects}


procedure End_object_group;
var
  prev, next: object_id_ptr_type;
  object_id_ptr: object_id_ptr_type;
  object_decl_ptr: object_decl_ptr_type;
  object_group_id_ptr: object_group_id_ptr_type;
  counter: integer;
begin
  if verbose then
    writeln('ending object group named "', current_object_group_id_ptr^.name,
      '"');

  {**************************************************************}
  { mark all objects in the graph as being unused and untouched. }
  {**************************************************************}
  object_decl_ptr := geometry_decls_ptr;
  while (object_decl_ptr <> nil) do
    begin
      object_id_ptr := Find_object_id(object_decl_ptr^.object_id);
      object_id_ptr^.used := false;
      object_id_ptr^.touched := false;
      object_decl_ptr := object_decl_ptr^.next;
    end;

  {*****************************************************}
  { mark all incomplete objects as unused and untouched }
  {*****************************************************}
  for counter := 0 to object_id_stack_ptr do
    begin
      object_id_ptr := object_id_stack^[counter];
      if (object_id_ptr <> nil) then
        begin
          object_id_ptr^.used := false;
          object_id_ptr^.touched := false;
        end;
    end;

  {*************************************************}
  { touch all objects associated with object groups }
  {*************************************************}
  if verbose then
    begin
      writeln;
      writeln('touching objects...');
    end;

  object_group_id_ptr := object_group_id_list;
  while (object_group_id_ptr <> nil) do
    begin
      if (object_group_id_ptr <> current_object_group_id_ptr) then
        if object_group_id_ptr^.object_decl_ptr <> nil then
          Touch_objects(object_group_id_ptr^.object_decl_ptr^.object_id);
      object_group_id_ptr := object_group_id_ptr^.next;
    end;
  if current_object_group_id_ptr <> nil then
    if current_object_group_id_ptr^.object_decl_ptr <> nil then
      Touch_objects(current_object_group_id_ptr^.object_decl_ptr^.object_id);

  {*******************************************************}
  { move objects used in current object group from global }
  { object creation list to local object creation list    }
  {*******************************************************}
  if (object_group_id_stack_ptr <= 1) then
    begin
      {**************************}
      { non nested object groups }
      {**************************}
      first_local_id_ptr := first_object_id_ptr;
      last_local_id_ptr := last_object_id_ptr;
      first_object_id_ptr := nil;
      last_object_id_ptr := nil;
    end
  else
    begin
      {**********************}
      { nested object groups }
      {**********************}
      first_local_id_ptr := nil;
      last_local_id_ptr := nil;

      prev := nil;
      next := first_object_id_ptr;
      while (next <> nil) do
        begin
          if (next^.used) then
            begin
              {********************************}
              { remove object from global list }
              {********************************}
              object_id_ptr := next;
              if (prev <> nil) then
                prev^.next := next;
              next := next^.next;

              if (object_id_ptr = first_object_id_ptr) then
                first_object_id_ptr := next;

              if (object_id_ptr = last_object_id_ptr) then
                last_object_id_ptr := prev;

              {**************************}
              { add object to local list }
              {**************************}
              object_id_ptr^.next := nil;
              if last_local_id_ptr = nil then
                begin
                  first_local_id_ptr := object_id_ptr;
                  last_local_id_ptr := object_id_ptr;
                end
              else
                begin
                  last_local_id_ptr^.next := object_id_ptr;
                  last_local_id_ptr := object_id_ptr;
                end;
            end
          else
            begin
              prev := next;
              next := next^.next;
            end;
        end;
    end;

  {*************************************************}
  { touch all objects in the process of being built }
  {*************************************************}
  for counter := 0 to object_id_stack_ptr do
    begin
      object_id_ptr := object_id_stack^[counter];
      if (object_id_ptr <> nil) then
        Touch_objects(object_id_ptr^.object_id);
    end;

  {*********************************}
  { last, remove all unused objects }
  {*********************************}
  object_decl_ptr := geometry_decls_ptr;
  terminated_object_id_ptr := nil;
  while (object_decl_ptr <> nil) do
    begin
      object_id_ptr := Find_object_id(object_decl_ptr^.object_id);
      if not object_id_ptr^.used then
        begin
          {*****************************}
          { Add object to start of list }
          { of objects to be terminated }
          {*****************************}
          object_id_ptr^.next := terminated_object_id_ptr;
          terminated_object_id_ptr := object_id_ptr;

          if verbose then
            writeln('removing object named "', object_id_ptr^.name, '"');
        end;
      object_decl_ptr := object_decl_ptr^.next;
    end;

  dead_object_id_ptr := terminated_object_id_ptr;
  new_object_decl_ptr := geometry_decls_ptr;
  previous_object_group_id_ptr := current_object_group_id_ptr;
  Pop_object_group_id_stack;
end; {procedure End_object_group}


procedure Next_object_group;
var
  object_id_ptr: object_id_ptr_type;
begin
  {*****************************}
  { free all terminated objects }
  {*****************************}
  while terminated_object_id_ptr <> nil do
    begin
      object_id_ptr := terminated_object_id_ptr;
      terminated_object_id_ptr := terminated_object_id_ptr^.next;

      {*************}
      { free object }
      {*************}
      Free_geom_object(object_id_ptr^.object_decl_ptr);
      Free_object_id(object_id_ptr);
    end;
end; {procedure Next_object_group}


{*******************************}
{ routines for creating objects }
{*******************************}


function New_object: object_decl_ptr_type;
var
  object_id_ptr: object_id_ptr_type;
begin
  {**********************}
  { create new object id }
  {**********************}
  object_id_ptr := New_object_id;

  {**********************}
  { initialize object_id }
  {**********************}
  object_id_ptr^.object_decl_ptr := New_geom_object_decl;
  object_id_ptr^.object_decl_ptr^.object_id := object_id_ptr^.object_id;
  object_id_ptr^.name := '';
  object_id_ptr^.next := nil;
  Push_object_id_stack(object_id_ptr);

  {*******************************************************}
  { assign first new object to uninitialized object group }
  {*******************************************************}
  if (current_object_group_id_ptr^.object_decl_ptr = nil) then
    current_object_group_id_ptr^.object_decl_ptr :=
      object_id_ptr^.object_decl_ptr;

  New_object := object_id_ptr^.object_decl_ptr;
end; {function New_object}


procedure Name_object(name: string_type);
begin
  current_object_id_ptr^.name := name;
end; {procedure Name_object}


procedure End_object;
begin
  End_geom_object_decl;

  {**********************************}
  { add new object id to end of list }
  { of newly created object ids      }
  {**********************************}
  current_object_id_ptr^.next := nil;
  if last_object_id_ptr = nil then
    begin
      first_object_id_ptr := current_object_id_ptr;
      last_object_id_ptr := current_object_id_ptr;
    end
  else
    begin
      last_object_id_ptr^.next := current_object_id_ptr;
      last_object_id_ptr := current_object_id_ptr;
    end;

  Pop_object_id_stack;
end; {procedure End_object}


{**********************************************}
{ routines for initially building the database }
{**********************************************}


procedure Goto_first_new_object;
begin
  new_object_decl_ptr := geometry_decls_ptr;
end; {procedure Goto_first_new_object}


function Next_new_object: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
  object_id_ptr: object_id_ptr_type;
  found: boolean;
begin
  found := false;
  object_decl_ptr := nil;

  while (new_object_decl_ptr <> nil) and (not found) do
    begin
      object_id_ptr := Find_object_id(new_object_decl_ptr^.object_id);
      if object_id_ptr^.used then
        begin
          found := true;
          object_decl_ptr := new_object_decl_ptr;
        end;
      new_object_decl_ptr := new_object_decl_ptr^.next;
    end;

  Next_new_object := object_decl_ptr;
end; {function Next_new_object}


{**************************************************}
{ routines for incrementally updating the database }
{**************************************************}


procedure Goto_first_created_object;
begin
  created_object_id_ptr := first_local_id_ptr;
end; {procedure Goto_first_created_object}


procedure Goto_first_terminated_object;
begin
  dead_object_id_ptr := terminated_object_id_ptr;
end; {procedure Goto_first_terminated_object}


function Next_created_object: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  if (created_object_id_ptr <> nil) then
    begin
      object_decl_ptr := created_object_id_ptr^.object_decl_ptr;
      created_object_id_ptr := created_object_id_ptr^.next;
    end
  else
    object_decl_ptr := nil;
  Next_created_object := object_decl_ptr;
end; {function Next_created_object}


function Next_terminated_object: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  if (dead_object_id_ptr <> nil) then
    begin
      object_decl_ptr := dead_object_id_ptr^.object_decl_ptr;
      dead_object_id_ptr := dead_object_id_ptr^.next;
    end
  else
    object_decl_ptr := nil;
  Next_terminated_object := object_decl_ptr;
end; {function Next_terminated_object}


{***********************************}
{ routines for buiding the database }
{***********************************}


procedure Goto_first_needed_object;
var
  object_decl_ptr: object_decl_ptr_type;
  object_id_ptr: object_id_ptr_type;
begin
  {**************************************************************}
  { mark all objects in the graph as being unused and untouched. }
  {**************************************************************}
  object_decl_ptr := geometry_decls_ptr;
  while (object_decl_ptr <> nil) do
    begin
      object_id_ptr := Find_object_id(object_decl_ptr^.object_id);
      object_id_ptr^.used := false;
      object_id_ptr^.touched := false;
      object_decl_ptr := object_decl_ptr^.next;
    end;

  if previous_object_group_id_ptr <> nil then
    if previous_object_group_id_ptr^.object_decl_ptr <> nil then
      Touch_objects(previous_object_group_id_ptr^.object_decl_ptr^.object_id);
  needed_object_decl_ptr := geometry_decls_ptr;
end; {procedure Goto_first_needed_object}


function Next_needed_object: object_decl_ptr_type;
var
  found: boolean;
  object_id_ptr: object_id_ptr_type;
  object_decl_ptr: object_decl_ptr_type;
begin
  found := false;
  object_decl_ptr := nil;

  while (needed_object_decl_ptr <> nil) and (not found) do
    begin
      object_id_ptr := Find_object_id(needed_object_decl_ptr^.object_id);
      if object_id_ptr^.used then
        begin
          found := true;
          object_decl_ptr := needed_object_decl_ptr;
        end;
      needed_object_decl_ptr := needed_object_decl_ptr^.next;
    end;

  Next_needed_object := object_decl_ptr;
end; {function Next_needed_object}


initialization
  first_id_block_ptr := nil;
  last_id_block_ptr := nil;
  number_of_entries := 0;

  object_id_free_list := nil;
  object_group_id_free_list := nil;

  {***********************}
  { initialize free lists }
  {***********************}
  first_object_id_ptr := nil;
  last_object_id_ptr := nil;

  current_object_id_ptr := nil;
  terminated_object_id_ptr := nil;

  created_object_id_ptr := nil;
  dead_object_id_ptr := nil;

  object_group_id_list := nil;

  if memory_alert then
    writeln('allocating new object id stack');
  new(object_id_stack);

  object_id_stack_ptr := -1;
  Push_object_id_stack(nil);

  if memory_alert then
    writeln('allocating new object group id stack');
  new(object_group_id_stack);

  object_group_id_stack_ptr := -1;
  Push_object_group_id_stack(nil);
end.
