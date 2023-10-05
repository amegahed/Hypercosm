unit memrefs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              memref                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The heap is used to allocate variable sized blocks      }
{       of memory and return them after use.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, data;


{***************************************************************}
{       There are two distinct types of heap objects which      }
{       use different garbage collection schemes:               }
{                                                               }
{                                                               }
{ 1) handles - point to heap objects which are collected        }
{              by the reference count method - these are        }
{              restricted to non-circular structures and        }
{              are expensive to change - best used for arrays.  }
{                                                               }
{ 2) memrefs - point to heap objects which are collected by     }
{              the mark and sweep method - these are capable    }
{              of recovering circular structures and are        }
{              less expensive to change but may cause           }
{              periodic delays because they are collected       }
{              all at once - best used for dynamic structures.  }
{***************************************************************}


{****************************}
{ memref allocation routines }
{****************************}
function New_memref(size: heap_index_type): memref_type;
procedure Free_memref(var memref: memref_type);
function Clone_memref(memref: memref_type): memref_type;

{*********************************}
{ routines for sizing memref data }
{*********************************}
function Get_memref_size(memref: memref_type): heap_index_type;
procedure Resize_memref(memref: memref_type;
  size: heap_index_type);

{************************************}
{ routines to manipulate memref data }
{************************************}
procedure Set_memref_data(memref: memref_type;
  index: heap_index_type;
  data: data_type);
function Get_memref_data(memref: memref_type;
  index: heap_index_type): data_type;

{*****************************}
{ routines for memref tracing }
{*****************************}
procedure Touch_memref(memref: memref_type);
procedure Collect_garbage;


implementation
uses
  errors, new_memory, data_types, op_stacks, stacks, heaps, handles,
  exec_methods, type_decls, interpreter;


{*******************************************************}
{                    garbage collection                 }
{*******************************************************}
{       When an object is freed, it is up to the        }
{       garbage collector to free up all other objects  }
{       attached to this object with no other external  }
{       references.                                     }
{                                                       }
{       This can be done in two ways:                   }
{                                                       }
{       1) the reference count technique (handles)      }
{       When a data object is freed, check it for       }
{       other heap pointers and recursively free up     }
{       the data objects which are pointed to by        }
{       these pointers and have a reference count = 0.  }
{                                                       }
{       benefits:                                       }
{       - space is freed up incrementally as it is      }
{         returned to the heap instead of all at once   }
{       problems:                                       }
{       - high overhead in readjusting pointers because }
{         the reference counts must be maintained.      }
{                                                       }
{       2) the mark and sweep technique (memrefs)       }
{       Wait until we run out of space, then mark       }
{       recursively all heap objects pointed to from    }
{       the stack. Then sweep through all heap objects  }
{       and return the unused ones to the free list.    }
{                                                       }
{       benefits:                                       }
{       - can deal with circular structures             }
{       - low overhead in rearranging pointers          }
{       problems:                                       }
{       - garbage collection occurs all at once and can }
{         cause a noticable delay when it kicks in.     }
{                                                       }
{                          NOTE:                        }
{       For this technique to work, each data object    }
{       must be initialized when allocated so that      }
{       it contains no entries which may be mistakenly  }
{       interpreted as valid heap pointers.             }
{*******************************************************}


const
  debug = false;
  verbose = false;
  memory_alert = false;
  garbage_collection = true;
  gc_notify = true;
  gc_active = true;


var
  memref_heap_number: heap_index_type;

  memref_heap_array_ptr: heap_array_ptr_type;
  memref_array_ptr: handle_array_ptr_type;

  memref_free_list: heap_index_type;
  memref_free_store: heap_index_type;


  {****************************}
  { memref allocation routines }
  {****************************}


function Get_memref(heap_addr: heap_addr_type): memref_type;
var
  memref: memref_type;
begin
  if memref_free_list <> 0 then
    begin
      {***************************}
      { get memref from free list }
      {***************************}
      memref := memref_free_list;
      memref_free_list := memref_array_ptr^[memref].heap_index;
    end
  else
    begin
      {****************************}
      { get memref from free store }
      {****************************}
      if (memref_free_store < max_handles) then
        begin
          memref := memref_free_store;
          memref_free_store := memref_free_store + 1;
        end
      else
        begin
          Internal_error('ran out of memrefs!');
          memref := 0;
        end;
    end;

  {*******************}
  { initialize memref }
  {*******************}
  memref_array_ptr^[memref] := heap_addr;

  Get_memref := memref;
end; {function Get_memref}


procedure Put_memref(var memref: memref_type);
begin
  {****************************}
  { return memref to free list }
  {****************************}
  with memref_array_ptr^[memref] do
    begin
      heap_number := 0;
      heap_index := memref_free_list;
    end;
  memref_free_list := memref;
  memref := 0;
end; {procedure Put_memref}


{*****************************}
{ garbage collection routines }
{*****************************}


procedure Touch_memref(memref: memref_type);
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  reference_count: integer_type;
  min_index, max_index: heap_index_type;
  size, index: heap_index_type;
  data: data_type;
begin
  if (memref <> 0) then
    begin
      heap_addr := memref_array_ptr^[memref];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := memref_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);
          reference_count :=
            Data_to_integer(heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1]);

          if reference_count <> 1 then
            begin
              {**************************}
              { set reference count to 1 }
              {**************************}
              heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1] :=
                Integer_to_data(1);

              {*******************************************}
              { look through data for memrefs and handles }
              {*******************************************}
              min_index := heap_addr.heap_index + 2;
              max_index := heap_addr.heap_index + size + 1;
              for index := min_index to max_index do
                begin
                  data := heap_ptr^.heap_data_ptr^[index];
                  if data.kind = handle_data then
                    Touch_handle(data.handle)
                  else if data.kind = memref_data then
                    Touch_memref(data.memref);
                end;
            end;
        end
      else
        Error('invalid memref');
    end;
end; {procedure Touch_memref}


procedure Mark_garbage;
var
  counter: stack_index_type;
  next, size: heap_index_type;
  heap_ptr: heap_ptr_type;
begin
  {**************************************************}
  { first, set the reference count of all nodes to 0 }
  {**************************************************}
  for counter := 1 to memref_heap_number do
    begin
      heap_ptr := memref_heap_array_ptr^[counter];
      next := 1;
      while (next < max_heap_size) do
        begin
          size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[next]);

          if debug then
            writeln('marking node with size = ', size);

          {*********************}
          { set reference count }
          {*********************}
          heap_ptr^.heap_data_ptr^[next + 1] := Integer_to_data(0);

          next := next + size + 3;
        end;
    end;

  {***************************************************}
  { next, find all nodes accessable through the stack }
  { and recursively set their reference counts = to 1 }
  {***************************************************}
  Touch_stack;
  Touch_operand_stacks;
end; {procedure Mark_garbage}


procedure Sweep_garbage;
var
  counter, next, size: heap_index_type;
  reference_count: integer_type;
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  type_ptr: abstract_type_ptr_type;
  code_ptr: abstract_code_ptr_type;
  memref: memref_type;
  data: data_type;
begin
  {*************************************************}
  { sweep through the heap space and move the nodes }
  { with a reference count = 0 on to the free list  }
  {*************************************************}
  for counter := 1 to memref_heap_number do
    begin
      heap_ptr := memref_heap_array_ptr^[counter];
      next := 1;

      {**********************************}
      { initialize pointers to free list }
      {**********************************}
      with heap_ptr^ do
        begin
          first_free := 0;
          last_free := 0;
          free_space := 0;
        end;

      while (next < max_heap_size) do
        begin
          size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[next]);
          reference_count := Data_to_integer(heap_ptr^.heap_data_ptr^[next +
            1]);

          {****************************}
          { add heap node to free list }
          {****************************}
          if reference_count = 0 then
            begin
              {*******************************}
              { call destructor, if necessary }
              {*******************************}
              data := heap_ptr^.heap_data_ptr^[next + 2];
              if data.kind = type_data then
                begin
                  type_ptr := Data_to_type(data);
                  code_ptr := Get_abstract_type_destructor(type_ptr);

                  if code_ptr <> nil then
                    begin
                      {*************************}
                      { create temporary memref }
                      {*************************}
                      heap_addr.heap_number := counter;
                      heap_addr.heap_index := next;
                      memref := Get_memref(heap_addr);
                      Interpret_abstract_destructor_stmt(code_ptr, memref);
                    end;
                end;

              {*******************************}
              { return heap node to free list }
              {*******************************}
              Free_heap_node(heap_ptr, next, false);

              {****************************}
              { return memref to free list }
              {****************************}
              data := heap_ptr^.heap_data_ptr^[next + size + 2];
              memref := Data_to_heap_index(data);
              Put_memref(memref);
            end;

          next := next + size + 3;
        end; {while}

      Compact_heap(heap_ptr, memref_array_ptr);
    end; {for}
end; {procedure Sweep_garbage}


procedure Collect_garbage;
begin
  if gc_active then
    begin
      if gc_notify then
        writeln('collecting garbage');

      Mark_garbage;
      Sweep_garbage;
    end;
end; {procedure Collect_garbage}


{*************************************************}
{ routines to allocate and free memref heap space }
{*************************************************}


function Found_memref_space(size: heap_index_type;
  var heap_ptr: heap_ptr_type): heap_addr_type;
var
  heap_index: heap_index_type;
  heap_addr: heap_addr_type;
  found: boolean;
begin
  {**************************************}
  { search for space among current heaps }
  {**************************************}
  heap_index := 1;
  found := false;
  while (heap_index <= memref_heap_number) and (not found) do
    begin
      heap_ptr := memref_heap_array_ptr^[heap_index];
      if (heap_ptr^.free_space >= size + 3) then
        found := true
      else
        heap_index := heap_index + 1;
    end;

  {******************************************}
  { invoke mark and sweep garbage collection }
  {******************************************}
  if not found then
    begin
      if garbage_collection then
        Collect_garbage;

      {**************************************}
      { search for space among current heaps }
      {**************************************}
      heap_index := 1;
      found := false;
      while (heap_index <= memref_heap_number) and (not found) do
        begin
          heap_ptr := memref_heap_array_ptr^[heap_index];
          if (heap_ptr^.free_space >= size + 3) then
            found := true
          else
            heap_index := heap_index + 1;
        end;

      {*****************}
      { create new heap }
      {*****************}
      if not found then
        begin
          if verbose then
            writeln('creating new memref heap');

          if memref_heap_number >= max_heap_number then
            Error('too many memref heaps')
          else
            begin
              heap_ptr := New_heap(memref_heap);
              memref_heap_number := memref_heap_number + 1;
              heap_index := memref_heap_number;
              memref_heap_array_ptr^[heap_index] := heap_ptr;
            end;
        end;
    end;

  {******************************************}
  { search heap for object with enough space }
  {******************************************}
  if not Found_free_space(heap_ptr, size) then
    begin
      Compact_heap(memref_heap_array_ptr^[heap_index], memref_array_ptr);
      if not Found_free_space(heap_ptr, size) then
        begin
          if (size > max_heap_size - 6) then
            Internal_error('new allocation exceeds heap size')
          else
            Error('heap compaction failed');
        end;
    end;

  {******************************************************}
  { assign heap addr to first free node in selected heap }
  {******************************************************}
  heap_addr.heap_number := heap_index;
  heap_addr.heap_index := heap_ptr^.first_free;

  Found_memref_space := heap_addr;
end; {function Found_memref_space}


function New_memref(size: heap_index_type): memref_type;
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  memref: memref_type;
begin
  {************************************}
  { find heap object with enough space }
  {************************************}
  heap_addr := Found_memref_space(size, heap_ptr);

  {*******************}
  { create new memref }
  {*******************}
  memref := Get_memref(heap_addr);

  if verbose then
    writeln('New memref ', memref: 1, ' with size = ', size: 1);

  {*************************************}
  { allocate space from first heap node }
  {*************************************}
  Allocate_heap_space(heap_ptr, memref, size);

  New_memref := memref;
end; {function New_memref}


procedure Free_memref(var memref: memref_type);
begin
  if memref <> 0 then
    begin
      if verbose then
        writeln('Free memref ', memref: 1);

      memref := 0;
    end
  else
    Internal_error('can not free nil memref');
end; {procedure Free_memref}


function Clone_memref(memref: memref_type): memref_type;
begin
  if verbose then
    writeln('cloning memref ', memref: 1);

  Clone_memref := memref;
end; {function Clone_memref}


function Get_memref_size(memref: memref_type): heap_index_type;
var
  size: heap_index_type;
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
begin
  if memref <> 0 then
    begin
      {*************************************}
      { get addr of heap object from memref }
      {*************************************}
      heap_addr := memref_array_ptr^[memref];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := memref_heap_array_ptr^[heap_addr.heap_number];

          {***************************}
          { get size from heap object }
          {***************************}
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);
        end
      else
        begin
          Internal_error('invalid memref');
          size := 0;
        end;
    end
  else
    size := 0;

  Get_memref_size := size;
end; {function Get_memref_size}


procedure Resize_memref(memref: memref_type;
  size: heap_index_type);
const
  call_resize_destructor = true;
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  reference_count: integer_type;
begin
  if memref <> 0 then
    begin
      {*************************************}
      { get addr of heap object from memref }
      {*************************************}
      heap_addr := memref_array_ptr^[memref];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := memref_heap_array_ptr^[heap_addr.heap_number];

          {***********************************************}
          { get reference count from previous heap object }
          {***********************************************}
          reference_count :=
            Data_to_integer(heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1]);

          {*******************************}
          { return heap node to free list }
          {*******************************}
          if not call_resize_destructor then
            Free_heap_node(heap_ptr, heap_addr.heap_index, true);

          {****************************************}
          { find new heap object with enough space }
          {****************************************}
          heap_addr := Found_memref_space(size, heap_ptr);

          {**************}
          { reset memref }
          {**************}
          memref_array_ptr^[memref] := heap_addr;

          {*************************************}
          { allocate space from first heap node }
          {*************************************}
          Allocate_heap_space(heap_ptr, memref, size);

          {*************************************************}
          { set reference count of new, resized heap object }
          {*************************************************}
          heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1] :=
            Integer_to_data(reference_count);
        end
      else
        Internal_error('invalid memref');
    end {if memref <> 0}
  else
    Internal_error('can not resize nil memref');
end; {procedure Resize_memref}


{************************************}
{ routines to manipulate memref data }
{************************************}


procedure Set_memref_data(memref: memref_type;
  index: heap_index_type;
  data: data_type);
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  size: heap_index_type;
begin
  if memref <> 0 then
    begin
      heap_addr := memref_array_ptr^[memref];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := memref_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);

          if (index > 0) and (index <= size) then
            heap_ptr^.heap_data_ptr^[heap_addr.heap_index + index + 1] := data
          else
            Internal_error('tried to set heap data outside of block');
        end
      else
        Internal_error('invalid memref');
    end
  else
    Internal_error('tried to dereference nil memref');
end; {procedure Set_memref_data}


function Get_memref_data(memref: memref_type;
  index: heap_index_type): data_type;
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  size: heap_index_type;
  data: data_type;
begin
  if memref <> 0 then
    begin
      heap_addr := memref_array_ptr^[memref];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := memref_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);

          if (index > 0) and (index <= size) then
            data := heap_ptr^.heap_data_ptr^[heap_addr.heap_index + index + 1]
          else
            Internal_error('tried to get heap data outside of block');
        end
      else
        Internal_error('invalid memref');
    end
  else
    Internal_error('tried to dereference nil memref');

  Get_memref_data := data;
end; {function Get_memref_data}


initialization
  memref_heap_number := 0;

  {*****************}
  { allocate arrays }
  {*****************}
  if memory_alert then
    writeln('allocating new memref heap array');
  new(memref_heap_array_ptr);

  if memory_alert then
    writeln('allocating new memref array');
  new(memref_array_ptr);

  {*****************************}
  { initialize handle free list }
  {*****************************}
  memref_free_store := 1;
  memref_free_list := 0;
end.

