unit params;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               params                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The params module provides a means of finding if        }
{       the geometry for an object having certain parameter     }
{       values has already been created.                        }
{                                                               }
{       If the object has already been made with these          }
{       params, then we can simply make a reference to          }
{       that object instead of actually rebuilding it.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  data;


type
  method_inst_data_ptr_type = Pointer;


  param_ptr_type = ^param_type;
  param_type = record
    data: data_type;
    next: param_ptr_type;
  end; {param_type}


{*******************************}
{ routines for snatching params }
{*******************************}
function Get_params(param_number: integer): param_ptr_type;
procedure Free_params(var param_ptr: param_ptr_type);

{**********************************}
{ routines for querying parameters }
{**********************************}
function Found_externalities(param_ptr: param_ptr_type): boolean;

{**************************************************}
{ routines for adding new records of method params }
{**************************************************}
procedure Add_method_inst_data(param_ptr: param_ptr_type;
  method_inst_data_ptr: method_inst_data_ptr_type;
  method_decl_id: integer);
procedure Free_method_inst_data(method_inst_data_ptr: method_inst_data_ptr_type;
  method_decl_id: integer);
procedure Free_method_decl_data(method_decl_id: integer);
function Find_method_inst_data(method_decl_id, param_number: integer):
  method_inst_data_ptr_type;


implementation
uses
  new_memory, stacks, interpreter;


{*******************************************************}
{                 parameter data structs                }
{*******************************************************}
{                                                       }
{       decl block                                      }
{       /-------------------\  /-------------------\    }
{       | 1 | 2 | 3 | 4 | 5 |->| 6 | 7 | 8 | 9 |10 |    }
{       \-------------------/  \-------------------/    }
{                 |                                     }
{                 v               parameters            }
{  complex   /---------\   /-----\  /-----\  /-----\    }
{  method <--|instance |-->|1 1 0|->| 5.0 |->|false|    }
{  ptr       \---------/   \-----/  \-----/  \-----/    }
{                 |                                     }
{                 v                                     }
{            /---------\   /-----\  /-----\  /-----\    }
{            |instance |-->|1 0 0|->| 2.0 |->|true |    }
{            \---------/   \-----/  \-----/  \-----/    }
{                                                       }
{*******************************************************}


const
  inst_block_size = 64;
  memory_alert = false;


type
  inst_ptr_type = ^inst_type;
  inst_type = record
    param_ptr: param_ptr_type;
    method_inst_data_ptr: method_inst_data_ptr_type;
    next: inst_ptr_type;
  end; {inst_type}

  inst_block_ptr_type = ^inst_block_type;
  inst_block_type = record
    ptr_array: array[1..inst_block_size] of inst_ptr_type;
    next: inst_block_ptr_type;
  end; {inst_block_type}


var
  number_of_entries: integer;
  first_inst_block_ptr, last_inst_block_ptr: inst_block_ptr_type;

  {************}
  { free lists }
  {************}
  inst_free_list: inst_ptr_type;
  param_free_list: param_ptr_type;


function New_inst_block: inst_block_ptr_type;
var
  inst_block_ptr: inst_block_ptr_type;
  counter: integer;
begin
  if memory_alert then
    writeln('allocating new inst block');
  new(inst_block_ptr);

  with inst_block_ptr^ do
    begin
      for counter := 1 to inst_block_size do
        ptr_array[counter] := nil;
      next := nil;
    end;

  New_inst_block := inst_block_ptr;
end; {function New_inst_block}


function New_inst(method_inst_data_ptr: method_inst_data_ptr_type):
  inst_ptr_type;
var
  inst_ptr: inst_ptr_type;
begin
  if (inst_free_list <> nil) then
    begin
      inst_ptr := inst_free_list;
      inst_free_list := inst_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new inst');
      new(inst_ptr);
    end;

  inst_ptr^.method_inst_data_ptr := method_inst_data_ptr;
  with inst_ptr^ do
    begin
      param_ptr := nil;
      next := nil;
    end;

  New_inst := inst_ptr;
end; {function New_inst}


procedure Index_inst_list(index: integer;
  var inst_block_ptr: inst_block_ptr_type;
  var block_index: integer);
var
  blocks: integer;
begin
  if (index > number_of_entries) then
    begin
      {***********************************************}
      { no instance params are stored for this method }
      {***********************************************}
      inst_block_ptr := nil;
      block_index := 0;
    end
  else
    begin
      if (index = number_of_entries) then
        begin
          {**************************************}
          { accessing the last entry in the list }
          {**************************************}
          inst_block_ptr := last_inst_block_ptr;
          block_index := (index - 1) mod inst_block_size + 1;
        end
      else
        begin
          inst_block_ptr := first_inst_block_ptr;
          blocks := (index - 1) div inst_block_size;
          block_index := (index - 1) mod inst_block_size + 1;

          while (blocks >= 1) do
            begin
              inst_block_ptr := inst_block_ptr^.next;
              blocks := blocks - 1;
            end;
        end;
    end;
end; {procedure Index_inst_list}


function New_param: param_ptr_type;
var
  param_ptr: param_ptr_type;
begin
  {**************************}
  { get param from free list }
  {**************************}
  if (param_free_list <> nil) then
    begin
      param_ptr := param_free_list;
      param_free_list := param_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new param');
      new(param_ptr);
    end;

  {**********************}
  { initialize new param }
  {**********************}
  param_ptr^.next := nil;

  New_param := param_ptr;
end; {function New_param}


function Get_params(param_number: integer): param_ptr_type;
var
  param_ptr, last_param_ptr, new_param_ptr: param_ptr_type;
  counter: integer;
begin
  {********************************}
  { add parameters to new instance }
  {********************************}
  counter := 0;
  param_ptr := nil;
  last_param_ptr := nil;

  while (param_number > 0) do
    begin
      counter := counter + 1;

      {******************************}
      { get value of param off stack }
      {******************************}
      new_param_ptr := New_param;
      new_param_ptr^.data := Get_local_stack(counter);

      {**************************}
      { add to end of param list }
      {**************************}
      if (last_param_ptr <> nil) then
        begin
          last_param_ptr^.next := new_param_ptr;
          last_param_ptr := new_param_ptr;
        end
      else
        begin
          param_ptr := new_param_ptr;
          last_param_ptr := new_param_ptr;
        end;

      param_number := param_number - 1;
    end; {while}

  Get_params := param_ptr;
end; {function Get_params}


procedure Free_params(var param_ptr: param_ptr_type);
var
  temp_param_ptr: param_ptr_type;
begin
  {****************************}
  {* dispose of list of params }
  {****************************}
  while (param_ptr <> nil) do
    begin
      temp_param_ptr := param_ptr;
      param_ptr := param_ptr^.next;

      {************************}
      { add param to free list }
      {************************}
      temp_param_ptr^.next := param_free_list;
      param_free_list := temp_param_ptr;
    end;
end; {procedure Free_params}


function Found_externalities(param_ptr: param_ptr_type): boolean;
var
  found: boolean;
begin
  {********************************}
  { add parameters to new instance }
  {********************************}
  found := false;
  while (param_ptr <> nil) and not found do
    begin
      {******************************}
      { get value of param off stack }
      {******************************}
      if param_ptr^.data.kind in [stack_index_data, handle_data, memref_data]
        then
        found := true
      else
        param_ptr := param_ptr^.next;
    end; {while}

  Found_externalities := found;
end; {function Found_externalities}


procedure Add_method_inst_data(param_ptr: param_ptr_type;
  method_inst_data_ptr: method_inst_data_ptr_type;
  method_decl_id: integer);
var
  inst_ptr: inst_ptr_type;
  inst_block_ptr: inst_block_ptr_type;
  block_index: integer;
begin
  while (method_decl_id > number_of_entries) do
    begin
      {************************}
      { create new inst blocks }
      {************************}
      if (first_inst_block_ptr = nil) then
        begin
          first_inst_block_ptr := New_inst_block;
          last_inst_block_ptr := first_inst_block_ptr;
        end
      else
        begin
          last_inst_block_ptr^.next := New_inst_block;
          last_inst_block_ptr := last_inst_block_ptr^.next;
        end;
      number_of_entries := number_of_entries + inst_block_size;
    end;

  {*********************}
  { create new instance }
  {*********************}
  inst_ptr := New_inst(method_inst_data_ptr);
  inst_ptr^.param_ptr := param_ptr;

  {************************}
  { store instance in list }
  {************************}
  Index_inst_list(method_decl_id, inst_block_ptr, block_index);
  inst_ptr^.next := inst_block_ptr^.ptr_array[block_index];
  inst_block_ptr^.ptr_array[block_index] := inst_ptr;
end; {procedure Add_method_inst_data}


function Same_params(param_ptr: param_ptr_type;
  param_number: integer): boolean;
var
  data1, data2: data_type;
  counter: integer;
  stack_addr: stack_addr_type;
  same: boolean;
begin
  {*****************************************}
  { compare params of the desired instance  }
  { with params of this particular instance }
  {*****************************************}
  same := true;
  counter := 1;
  stack_addr.static_links := 0;
  stack_addr.dynamic_links := 0;
  while (counter <= param_number) and same do
    begin
      stack_addr.stack_index := counter;
      data1 := Get_stack(stack_addr);
      data2 := param_ptr^.data;

      if (data1.kind = error_data) or (data2.kind = error_data) then
        Runtime_error('Can not compare uninitialized data.')
      else if (data1.kind <> data2.kind) then
        same := false
      else if (data1.kind in [stack_index_data, handle_data, memref_data]) then
        same := false
      else
        same := Equal_data(data1, data2);

      counter := counter + 1;
      param_ptr := param_ptr^.next;
    end; {while}

  Same_params := same;
end; {function Same_params}


function Count_insts(inst_ptr: inst_ptr_type): integer;
var
  counter: integer;
begin
  counter := 0;
  while (inst_ptr <> nil) do
    begin
      counter := counter + 1;
      inst_ptr := inst_ptr^.next;
    end;
  Count_insts := counter;
end; {function Count_insts}


function Find_method_inst_data(method_decl_id, param_number: integer):
  method_inst_data_ptr_type;
var
  method_inst_data_ptr: method_inst_data_ptr_type;
  inst_list_ptr: inst_ptr_type;
  found: boolean;
  inst_block_ptr: inst_block_ptr_type;
  block_index: integer;
begin
  if (method_decl_id > number_of_entries) or (method_decl_id = 0) then
    begin
      method_inst_data_ptr := nil;
    end
  else
    begin
      {****************************}
      { find correct instance list }
      {****************************}
      Index_inst_list(method_decl_id, inst_block_ptr, block_index);
      inst_list_ptr := inst_block_ptr^.ptr_array[block_index];

      if (param_number = 0) then
        begin
          if inst_list_ptr <> nil then
            method_inst_data_ptr := inst_list_ptr^.method_inst_data_ptr
          else
            method_inst_data_ptr := nil;
        end
      else
        begin
          {**************************}
          { search list for an entry }
          { with the same parameters }
          {**************************}
          found := false;
          while (inst_list_ptr <> nil) and not found do
            begin
              if Same_params(inst_list_ptr^.param_ptr, param_number) then
                found := true
              else
                inst_list_ptr := inst_list_ptr^.next;
            end; {while}

          if found then
            method_inst_data_ptr := inst_list_ptr^.method_inst_data_ptr
          else
            method_inst_data_ptr := nil;
        end;
    end;

  Find_method_inst_data := method_inst_data_ptr;
end; {function Find_method_inst_data}


procedure Free_inst(var inst_ptr: inst_ptr_type);
begin
  Free_params(inst_ptr^.param_ptr);

  {***************************}
  { add instance to free list }
  {***************************}
  inst_ptr^.next := inst_free_list;
  inst_free_list := inst_ptr;
  inst_ptr := nil;
end; {procedure Free_inst}


procedure Free_method_decl_data(method_decl_id: integer);
var
  inst_block_ptr: inst_block_ptr_type;
  block_index: integer;
  inst_ptr, temp_inst_ptr: inst_ptr_type;
begin
  {*****************************************}
  { free all instances of a particular decl }
  {*****************************************}

  {****************************}
  { find correct instance list }
  {****************************}
  Index_inst_list(method_decl_id, inst_block_ptr, block_index);

  if (inst_block_ptr <> nil) then
    begin
      inst_ptr := inst_block_ptr^.ptr_array[block_index];
      while (inst_ptr <> nil) do
        begin
          temp_inst_ptr := inst_ptr;
          inst_ptr := inst_ptr^.next;
          Free_inst(temp_inst_ptr);
        end;
      inst_block_ptr^.ptr_array[block_index] := nil;
    end;
end; {procedure Free_method_decl_data}


procedure Free_method_inst_data(method_inst_data_ptr: method_inst_data_ptr_type;
  method_decl_id: integer);
var
  fore, aft, temp_inst_ptr: inst_ptr_type;
  inst_block_ptr: inst_block_ptr_type;
  block_index: integer;
begin
  if (method_inst_data_ptr <> nil) then
    begin
      {****************************}
      { find correct instance list }
      {****************************}
      Index_inst_list(method_decl_id, inst_block_ptr, block_index);

      if (block_index >= 1) and (block_index <= inst_block_size) then
        begin
          fore := inst_block_ptr^.ptr_array[block_index];
          aft := fore;
        end
      else
        begin
          fore := nil;
          aft := fore;
        end;

      while (fore <> nil) do
        begin
          if (fore^.method_inst_data_ptr = method_inst_data_ptr) then
            begin
              {***********************}
              { remove inst from list }
              {***********************}
              if (fore = aft) then
                inst_block_ptr^.ptr_array[block_index] := fore^.next
              else
                aft^.next := fore^.next;

              temp_inst_ptr := fore;
              fore := nil;

              Free_inst(temp_inst_ptr);
            end
          else
            begin
              {*****************}
              { advance pointer }
              {*****************}
              if (fore <> aft) then
                aft := fore;
              fore := fore^.next;
            end;
        end;
    end;
end; {procedure Free_method_inst_data}


initialization
  number_of_entries := 0;
  first_inst_block_ptr := nil;
  last_inst_block_ptr := nil;

  {***********************}
  { initialize free lists }
  {***********************}
  inst_free_list := nil;
  param_free_list := nil;
end.
