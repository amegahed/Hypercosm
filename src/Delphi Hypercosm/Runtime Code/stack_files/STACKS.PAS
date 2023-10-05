unit stacks;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               stacks                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These stack routines can be used to simulate the        }
{       action of the system stack in a procedural language     }
{       with nested procedures and formal procedures            }
{       (procedures passed as parameters).                      }
{                                                               }
{       For this reason, the interpreter uses stacks with       }
{       static and dynamic chains similar to those used in      }
{       languages such as Pascal, Modula, and Ada.              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, data;


type
  stack_addr_type = record
    stack_index: stack_index_type;
    static_links: integer;
    dynamic_links: integer;
  end; {stack_addr_type}


  {************************************************}
  { routines for moving data to and from the stack }
  {************************************************}
procedure Reset_stacks;
procedure Push_stack_data(data: data_type);
procedure Push_stack(number: stack_index_type);
procedure Set_max_stack_size(size: stack_index_type);

{**********************************************}
{ routines to get data from the stack and heap }
{**********************************************}
function Get_stack(stack_addr: stack_addr_type): data_type;
function Get_local_stack(index: stack_index_type): data_type;
function Get_global_stack(index: stack_index_type): data_type;

{********************************************}
{ routines to set data on the stack and heap }
{********************************************}
procedure Set_stack(stack_addr: stack_addr_type;
  data: data_type);
procedure Set_local_stack(index: stack_index_type;
  data: data_type);
procedure Set_global_stack(index: stack_index_type;
  data: data_type);

{**********************************************}
{ routines to convert from local stack frame   }
{ indices or addresses to global stack indices }
{**********************************************}
function Stack_addr_to_index(stack_addr: stack_addr_type): stack_index_type;
function Local_index_to_global(index: stack_index_type): stack_index_type;

{******************************}
{ miscillaneous stack routines }
{******************************}
function Stack_frame_height: stack_index_type;
function Stack_height: stack_index_type;
procedure Copy_stack(source_index, dest_index: stack_index_type;
  size: stack_index_type);
procedure Touch_stack;

{******************************************************}
{ routines for controlling the linking of stack frames }
{******************************************************}
procedure Push_stack_frame(static_link: stack_index_type);
procedure Pop_stack_frame;
function Get_static_link: stack_index_type;
procedure Set_static_link(stack_index: stack_index_type);

{********************************************}
{ routines for writing out contents of stack }
{********************************************}
procedure Write_stacks;
procedure Write_stack_address(stack_addr: stack_addr_type);


{*******************************************************}
{       static links:                                   }
{       Since a deeply nested function can access       }
{       its own local variables as well as those        }
{       of surrounding functions, several activation    }
{       records (stack frames) may need to be accessed. }
{       The number of links to follow to get to the     }
{       correct activation record is determined at      }
{       compile time and is equal to the difference     }
{       in lexical scoping level between the current    }
{       procedure and the procedure in which the        }
{       variable is located.                            }
{                                                       }
{       dynamic links:                                  }
{       These links tell where beginning of the         }
{       previous activation record is so when the       }
{       current activation record is popped off the     }
{       stack, we know where the previous one begins.   }
{*******************************************************}


{*******************************************************}
{               usage of stack data structs             }
{*******************************************************}
{       At the beginning of each procedure, push a      }
{       new stack frame onto the stack and follow       }
{       this by pushing the local vars onto the stack.  }
{       To access variables, we must provide a stack    }
{       address which has three fields:                 }
{       index, static_links, and dynamic links          }
{       The index is an offset from the beginning       }
{       of the stack frame.                             }
{       Static links and dynamic links tell how to      }
{       get to the stack frame. The dynamic links       }
{       Allow procedure calls to be nested inside one   }
{       another. When a procedure is called, to get to  }
{       the caller's stack frame, we must follow one    }
{       dynamic link. If we want to get to the stack    }
{       frame belonging to the caller of the caller,    }
{       then we must follow two dynamic links.          }
{*******************************************************}


implementation
uses
  errors, new_memory, heaps, handles, memrefs;


{*******************************************************}
{         implementation of stack data structs          }
{*******************************************************}
{                                                       }
{       stack frame (activation record) organization:   }
{                                                       }
{       sp->                                            }
{               |-----------------------|               }
{               |           .           |               }
{               |           .           |               }
{               |           .           |               }
{               |-----------------------|               }
{               |     local variables   |               }
{               |-----------------------|               }
{               |      dynamic link     |               }
{               |-----------------------|               }
{      bp->     |      static link      |               }
{               |-----------------------|               }
{                                                       }
{       The stack is implemented as an array so the     }
{       static and dynamic links are integer indices    }
{       into the stack. The stack_ptr always points     }
{       to the next available place in the stack and    }
{       the base_ptr always points to the base of the   }
{       current activation record.                      }
{*******************************************************}



const
  memory_alert = false;
  auto_stack_init = true;


type
  stack_type = data_type;
  stack_ptr_type = ^stack_type;


var
  stack: stack_ptr_type;
  top_stack_index, base_stack_index, max_stack_index: stack_index_type;
  max_stack_size: stack_index_type;


function New_stack(size: stack_index_type): stack_ptr_type;
var
  stack, stack_ptr: stack_ptr_type;
  counter, stack_size: longint;
begin
  max_stack_index := size;
  stack_size := size * sizeof(stack_type);
  if memory_alert then
    writeln('allocating new stack');
  stack := stack_ptr_type(New_ptr(stack_size));

  {******************}
  { initialize stack }
  {******************}
  if auto_stack_init then
    begin
      stack_ptr := stack;
      for counter := 1 to size do
        begin
          stack_ptr^.kind := error_data;
          stack_ptr := stack_ptr_type(longint(stack_ptr) + sizeof(stack_type));
        end;
    end;

  New_stack := stack;
end; {function New_stack}


function Index_stack(index: stack_index_type): stack_ptr_type;
begin
  Index_stack := stack_ptr_type(longint(stack) + longint(index) *
    sizeof(stack_type));
end; {function Index_stack}


procedure Reset_stacks;
begin
  base_stack_index := 1;
  top_stack_index := 3;

  Index_stack(1)^ := Stack_index_to_data(1);
  Index_stack(2)^ := Stack_index_to_data(1);
end; {procedure Reset_stacks}


procedure Double_stack;
var
  old_stack: stack_ptr_type;
  old_stack_size, new_stack_size: stack_index_type;
  old_stack_ptr, new_stack_ptr: stack_ptr_type;
  counter: stack_index_type;
begin
  {****************}
  { save old stack }
  {****************}
  old_stack := stack;
  old_stack_size := max_stack_index;
  new_stack_size := old_stack_size * 2;

  {**************************}
  { check for stack overflow }
  {**************************}
  if max_stack_size <> 0 then
    if new_stack_size > max_stack_size then
      Error('Stack overflow.');

  {******************}
  { create new stack }
  {******************}
  stack := New_stack(new_stack_size);

  {*****************************}
  { copy old stack to new stack }
  {*****************************}
  old_stack_ptr := old_stack;
  new_stack_ptr := stack;
  for counter := 1 to old_stack_size do
    begin
      new_stack_ptr^ := old_stack_ptr^;
      old_stack_ptr := stack_ptr_type(longint(old_stack_ptr) +
        sizeof(stack_type));
      new_stack_ptr := stack_ptr_type(longint(new_stack_ptr) +
        sizeof(stack_type));
    end;

  Free_ptr(ptr_type(old_stack));
end; {procedure Double_stack}


procedure Push_stack_data(data: data_type);
var
  stack_ptr: stack_ptr_type;
begin
  while (top_stack_index + 1 >= max_stack_index) do
    Double_stack;

  stack_ptr := stack_ptr_type(longint(stack) + longint(top_stack_index) *
    sizeof(stack_type));
  stack_ptr^ := data;
  top_stack_index := top_stack_index + 1;
end; {procedure Push_stack_data}


procedure Push_stack(number: stack_index_type);
begin
  if (number < 0) then
    Error('Can not push a negative number of entries on to stack.');

  top_stack_index := top_stack_index + number;
  while (top_stack_index >= max_stack_index) do
    Double_stack;
end; {procedure Push_stack}


procedure Set_max_stack_size(size: stack_index_type);
begin
  max_stack_size := size;
end; {procedure Set_max_stack_size}


{**********************************************}
{ routines to get data from the stack and heap }
{**********************************************}


function Get_stack(stack_addr: stack_addr_type): data_type;
var
  stack_ptr: stack_ptr_type;
  stack_index: stack_index_type;
  counter: integer;
begin
  stack_index := base_stack_index;

  {**************************}
  { follow the dynamic links }
  {**************************}
  if (stack_addr.dynamic_links <> 0) then
    for counter := 1 to stack_addr.dynamic_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index + 1) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  {*************************}
  { follow the static links }
  {*************************}
  if (stack_addr.static_links <> 0) then
    for counter := 1 to stack_addr.static_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  stack_index := stack_index + stack_addr.stack_index;
  stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index + 1) *
    sizeof(stack_type));
  Get_stack := stack_ptr^;
end; {function Get_stack}


function Get_local_stack(index: stack_index_type): data_type;
var
  stack_ptr: stack_ptr_type;
begin
  stack_ptr := stack_ptr_type(longint(stack) + longint(base_stack_index + index
    + 1) * sizeof(stack_type));
  Get_local_stack := stack_ptr^;
end; {function Get_local_stack}


function Get_global_stack(index: stack_index_type): data_type;
var
  stack_ptr: stack_ptr_type;
begin
  stack_ptr := stack_ptr_type(longint(stack) + longint(index + 2) *
    sizeof(stack_type));
  Get_global_stack := stack_ptr^;
end; {function Get_global_stack}


{********************************************}
{ routines to set data on the stack and heap }
{********************************************}


procedure Set_stack(stack_addr: stack_addr_type;
  data: data_type);
var
  stack_ptr: stack_ptr_type;
  stack_index: stack_index_type;
  counter: integer;
begin
  stack_index := base_stack_index;

  {**************************}
  { follow the dynamic links }
  {**************************}
  if (stack_addr.dynamic_links <> 0) then
    for counter := 1 to stack_addr.dynamic_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index + 1) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  {*************************}
  { follow the static links }
  {*************************}
  if (stack_addr.static_links <> 0) then
    for counter := 1 to stack_addr.static_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  stack_index := stack_index + stack_addr.stack_index;
  stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index + 1) *
    sizeof(stack_type));
  stack_ptr^ := data;
end; {procedure Set_stack}


procedure Set_local_stack(index: stack_index_type;
  data: data_type);
var
  stack_ptr: stack_ptr_type;
begin
  stack_ptr := stack_ptr_type(longint(stack) + longint(base_stack_index + index
    + 1) * sizeof(stack_type));
  stack_ptr^ := data
end; {procedure Set_local_stack}


procedure Set_global_stack(index: stack_index_type;
  data: data_type);
var
  stack_ptr: stack_ptr_type;
begin
  stack_ptr := stack_ptr_type(longint(stack) + longint(index + 2) *
    sizeof(stack_type));
  stack_ptr^ := data
end; {procedure Set_global_stack}


{**********************************************}
{ routines to convert from local stack frame   }
{ indices or addresses to global stack indices }
{**********************************************}


function Stack_addr_to_index(stack_addr: stack_addr_type): stack_index_type;
var
  stack_ptr: stack_ptr_type;
  stack_index: stack_index_type;
  counter: integer;
begin
  stack_index := base_stack_index;

  {**************************}
  { follow the dynamic links }
  {**************************}
  if (stack_addr.dynamic_links <> 0) then
    for counter := 1 to stack_addr.dynamic_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index + 1) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  {*************************}
  { follow the static links }
  {*************************}
  if (stack_addr.static_links <> 0) then
    for counter := 1 to stack_addr.static_links do
      begin
        stack_ptr := stack_ptr_type(longint(stack) + longint(stack_index) *
          sizeof(stack_type));
        stack_index := stack_ptr^.stack_index;
      end;

  Stack_addr_to_index := stack_index + (stack_addr.stack_index - 1);
end; {function Stack_addr_to_index}


function Local_index_to_global(index: stack_index_type): stack_index_type;
begin
  Local_index_to_global := base_stack_index + (index - 1);
end; {function Local_index_to_global}


{******************************}
{ miscillaneous stack routines }
{******************************}


function Stack_frame_height: stack_index_type;
begin
  Stack_frame_height := top_stack_index - base_stack_index - 2;
end; {function Stack_frame_height}


function Stack_height: stack_index_type;
begin
  Stack_height := top_stack_index - 1;
end; {function Stack_height}


procedure Copy_stack(source_index, dest_index: stack_index_type;
  size: stack_index_type);
var
  counter: stack_index_type;
  stack_ptr1, stack_ptr2: stack_ptr_type;
begin
  {***************}
  { copy elements }
  {***************}
  source_index := source_index + 2;
  dest_index := dest_index + 2;

  stack_ptr1 := stack_ptr_type(longint(stack) + longint(dest_index) *
    sizeof(stack_type));
  stack_ptr2 := stack_ptr_type(longint(stack) + longint(source_index) *
    sizeof(stack_type));
  for counter := 1 to size do
    begin
      stack_ptr1^ := stack_ptr2^;
      stack_ptr1 := stack_ptr_type(longint(stack) + sizeof(stack_type));
      stack_ptr2 := stack_ptr_type(longint(stack) + sizeof(stack_type));
    end;
end; {procedure Copy_stack}


procedure Touch_stack;
var
  counter: longint;
  data: data_type;
begin
  for counter := 1 to Stack_height do
    begin
      data := Get_global_stack(counter);
      if data.kind = handle_data then
        Touch_handle(data.handle)
      else if data.kind = memref_data then
        Touch_memref(data.memref);
    end;
end; {procedure Touch_stack}


{******************************************************}
{ routines for controlling the linking of stack frames }
{******************************************************}


procedure Push_stack_frame(static_link: stack_index_type);
var
  stack_ptr: stack_ptr_type;
begin
  while (top_stack_index + 2 >= max_stack_index) do
    Double_stack;

  {************************************}
  { Make new stack frame's static link }
  {************************************}
  stack_ptr := stack_ptr_type(longint(stack) + longint(top_stack_index) *
    sizeof(stack_type));
  stack_ptr^ := Stack_index_to_data(static_link);

  {*************************************}
  { Make new stack frame's dynamic link }
  {*************************************}
  stack_ptr := stack_ptr_type(longint(stack_ptr) + sizeof(stack_type));
  stack_ptr^ := Stack_index_to_data(base_stack_index);

  {*********************************}
  { Advance stack_ptr and base_ptr  }
  {*********************************}
  base_stack_index := top_stack_index;
  top_stack_index := top_stack_index + 2;
end; {procedure Push_stack_frame}


procedure Pop_stack_frame;
var
  stack_ptr: stack_ptr_type;
begin
  {************************************}
  { stack_ptr gets current base_ptr    }
  { base ptr gets current dynamic link }
  {************************************}
  top_stack_index := base_stack_index;
  stack_ptr := stack_ptr_type(longint(stack) + longint(base_stack_index + 1) *
    sizeof(stack_type));
  base_stack_index := stack_ptr^.stack_index;
end; {procedure Pop_stack_frame}


function Get_static_link: stack_index_type;
begin
  Get_static_link := base_stack_index;
end; {function Get_static_link}


procedure Set_static_link(stack_index: stack_index_type);
var
  stack_ptr: stack_ptr_type;
begin
  stack_ptr := stack_ptr_type(longint(stack) + longint(base_stack_index) *
    sizeof(stack_type));
  stack_ptr^ := Stack_index_to_data(stack_index);
end; {procedure Set_static_link}


{********************************************}
{ routines for writing out contents of stack }
{********************************************}


procedure Write_stack_address(stack_addr: stack_addr_type);
begin
  writeln('index = ', stack_addr.stack_index);
  writeln('static_links = ', stack_addr.static_links);
  writeln('dynamic_links = ', stack_addr.dynamic_links);
end; {procedure Write_stack_address}


procedure Write_stacks;
var
  index, limit: stack_index_type;
  temp_base_index: stack_index_type;
  static_link: stack_index_type;
  dynamic_link: stack_index_type;
begin
  temp_base_index := base_stack_index;
  index := top_stack_index - 1;

  while (index > 1) do
    begin
      {***********************}
      { write local variables }
      {***********************}
      limit := temp_base_index + 2;
      while (index >= limit) do
        begin
          write(index: 1, '        ');
          Write_data(Index_stack(index)^);
          writeln;
          index := index - 1;
        end;

      {********************}
      { write dynamic link }
      {********************}
      write(index: 1, '        ');
      dynamic_link := Index_stack(index)^.stack_index;
      writeln('dynamic link = ', dynamic_link: 1);
      temp_base_index := Index_stack(index)^.stack_index;
      index := index - 1;

      {*******************}
      { write static link }
      {*******************}
      write(index: 1, '        ');
      static_link := Index_stack(index)^.stack_index;
      writeln('static link = ', static_link: 1);
      index := index - 1;

      writeln('         ', '---');
    end; {while}
end; {procedure Write_stacks}


initialization
  stack := New_stack(256);
  Reset_stacks;
  max_stack_size := 0;
end.
