unit handles;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              handles                  3d       }
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
{ handle allocation routines }
{****************************}
function New_handle(size: heap_index_type): handle_type;
procedure Free_handle(var handle: handle_type);
function Clone_handle(handle: handle_type): handle_type;

{*********************************}
{ routines for sizing handle data }
{*********************************}
function Get_handle_size(handle: handle_type): heap_index_type;
procedure Resize_handle(handle: handle_type;
  size: heap_index_type);

{************************************}
{ routines to manipulate handle data }
{************************************}
procedure Set_handle_data(handle: handle_type;
  index: heap_index_type;
  data: data_type);
function Get_handle_data(handle: handle_type;
  index: heap_index_type): data_type;

{*****************************}
{ routines for handle tracing }
{*****************************}
procedure Touch_handle(handle: handle_type);


implementation
uses
  errors, new_memory, data_types, memrefs, stacks, heaps, interpreter;


const
  debug = false;
  verbose = false;
  memory_alert = false;
  free_list_checking = false;


var
  handle_heap_number: heap_index_type;

  handle_heap_array_ptr: heap_array_ptr_type;
  handle_array_ptr: handle_array_ptr_type;

  handle_free_list: heap_index_type;
  handle_free_store: heap_index_type;


{****************************}
{ handle allocation routines }
{****************************}


function Get_handle(heap_addr: heap_addr_type): handle_type;
var
  handle: handle_type;
begin
  if handle_free_list <> 0 then
    begin
      {***************************}
      { get handle from free list }
      {***************************}
      handle := handle_free_list;
      handle_free_list := handle_array_ptr^[handle].heap_index;
    end
  else
    begin
      {****************************}
      { get handle from free store }
      {****************************}
      if (handle_free_store < max_handles) then
        begin
          handle := handle_free_store;
          handle_free_store := handle_free_store + 1;
        end
      else
        begin
          Internal_error('ran out of handles!');
          handle := 0;
        end;
    end;

  {*******************}
  { initialize handle }
  {*******************}
  handle_array_ptr^[handle] := heap_addr;

  Get_handle := handle;
end; {function Get_handle}


procedure Put_handle(var handle: handle_type);
begin
  {****************************}
  { return handle to free list }
  {****************************}
  with handle_array_ptr^[handle] do
    begin
      heap_number := 0;
      heap_index := handle_free_list;
    end;
  handle_free_list := handle;
  handle := 0;
end; {procedure Put_handle}


{*************************************************}
{ routines to allocate and free handle heap space }
{*************************************************}


function Found_handle_space(size: heap_index_type;
  var heap_ptr: heap_ptr_type): heap_addr_type;
var
  heap_index: heap_index_type;
  heap_addr: heap_addr_type;
  found: boolean;
begin
  heap_index := handle_heap_number;
  found := false;

  {**************************************}
  { search for space among current heaps }
  {**************************************}
  while (heap_index > 0) and (not found) do
    begin
      heap_ptr := handle_heap_array_ptr^[heap_index];
      if (heap_ptr^.free_space >= size + 3) then
        found := true
      else
        heap_index := heap_index - 1;
    end;

  {*****************}
  { create new heap }
  {*****************}
  if not found then
    begin
      if verbose then
        writeln('creating new handle heap');

      if handle_heap_number >= max_heap_number then
        Internal_error('too many handle heaps')
      else
        begin
          heap_ptr := New_heap(handle_heap);
          handle_heap_number := handle_heap_number + 1;
          heap_index := handle_heap_number;
          handle_heap_array_ptr^[heap_index] := heap_ptr;
        end;
    end;

  {******************************************}
  { search heap for object with enough space }
  {******************************************}
  if not Found_free_space(heap_ptr, size) then
    begin
      Compact_heap(handle_heap_array_ptr^[heap_index], handle_array_ptr);
      if not Found_free_space(heap_ptr, size) then
        begin
          if (size > max_heap_size - 6) then
            Internal_error('new allocation exceeds heap size')
          else
            Internal_error('heap compaction failed');
        end;
    end;

  {******************************************************}
  { assign heap addr to first free node in selected heap }
  {******************************************************}
  heap_addr.heap_number := heap_index;
  heap_addr.heap_index := heap_ptr^.first_free;

  Found_handle_space := heap_addr;
end; {function Found_handle_space}


function New_handle(size: heap_index_type): handle_type;
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  handle: handle_type;
begin
  {************************************}
  { find heap object with enough space }
  {************************************}
  heap_addr := Found_handle_space(size, heap_ptr);

  {*******************}
  { create new handle }
  {*******************}
  handle := Get_handle(heap_addr);

  if verbose then
    writeln('New handle ', handle: 1, ' with size = ', size: 1);

  {*****************************************}
  { allocate space from the first heap node }
  {*****************************************}
  Allocate_heap_space(heap_ptr, handle, size);

  New_handle := handle;
end; {function New_handle}


procedure Free_handle(var handle: handle_type);
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  reference_count: integer_type;
begin
  if handle <> 0 then
    begin
      {*************************************}
      { get addr of heap object from handle }
      {*************************************}
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];

          {************************************}
          { get reference count of heap object }
          {************************************}
          reference_count :=
            Data_to_integer(heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1]);

          if verbose then
            begin
              write('freeing handle ', handle: 1, ' ');
              write('with reference count = ', reference_count: 1);
              writeln;
            end;

          {******************************************}
          { decrement reference count of heap object }
          {******************************************}
          reference_count := reference_count - 1;
          heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1] :=
            Integer_to_data(reference_count);

          if (reference_count = 0) then
            begin
              {*********************************}
              { return heap object to free list }
              {*********************************}
              Free_heap_node(heap_ptr, heap_addr.heap_index, true);

              if verbose and not debug then
                writeln('freeing handle ', handle: 1, ' ');

              {****************************}
              { return handle to free list }
              {****************************}
              Put_handle(handle);
            end;

          if free_list_checking then
            Check_heap_free_list(heap_ptr);

          handle := 0;
        end
      else
        Internal_error('invalid handle');
    end {if handle <> 0}
  else
    Internal_error('can not free nil handle');
end; {procedure Free_handle}


function Clone_handle(handle: handle_type): handle_type;
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  reference_count: integer_type;
begin
  if handle <> 0 then
    begin
      {*************************************}
      { get addr of heap object from handle }
      {*************************************}
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];

          {************************************}
          { get reference count of heap object }
          {************************************}
          reference_count :=
            Data_to_integer(heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1]);

          if verbose then
            begin
              write('cloning handle ', handle: 1, ' ');
              write('with reference count = ', reference_count: 1);
              writeln;
            end;

          {*************************************}
          { increment reference count of object }
          {*************************************}
          reference_count := reference_count + 1;
          heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1] :=
            Integer_to_data(reference_count);
        end
      else
        Internal_error('invalid handle');
    end; {if handle <> 0}

  Clone_handle := handle;
end; {function Clone_handle}


{*********************************}
{ routines for sizing handle data }
{*********************************}


function Get_handle_size(handle: handle_type): heap_index_type;
var
  size: heap_index_type;
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
begin
  if handle <> 0 then
    begin
      {*************************************}
      { get addr of heap object from handle }
      {*************************************}
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];

          {***************************}
          { get size from heap object }
          {***************************}
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);
        end
      else
        begin
          Internal_error('invalid handle');
          size := 0;
        end;
    end {if handle <> 0}
  else
    size := 0;

  Get_handle_size := size;
end; {function Get_handle_size}


procedure Resize_handle(handle: handle_type;
  size: heap_index_type);
var
  heap_ptr: heap_ptr_type;
  heap_addr: heap_addr_type;
  reference_count: integer_type;
begin
  if handle <> 0 then
    begin
      {*************************************}
      { get addr of heap object from handle }
      {*************************************}
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];

          {***********************************************}
          { get reference count from previous heap object }
          {***********************************************}
          reference_count :=
            Data_to_integer(heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1]);

          {*******************************}
          { return heap node to free list }
          {*******************************}
          Free_heap_node(heap_ptr, heap_addr.heap_index, true);

          {****************************************}
          { find new heap object with enough space }
          {****************************************}
          heap_addr := Found_handle_space(size, heap_ptr);

          {**************}
          { reset handle }
          {**************}
          handle_array_ptr^[handle] := heap_addr;

          {*************************************}
          { allocate space from first heap node }
          {*************************************}
          Allocate_heap_space(heap_ptr, handle, size);

          {*************************************************}
          { set reference count of new, resized heap object }
          {*************************************************}
          heap_ptr^.heap_data_ptr^[heap_addr.heap_index + 1] :=
            Integer_to_data(reference_count);
        end
      else
        Internal_error('invalid handle');
    end; {if handle <> 0}
end; {procedure Resize_handle}


{************************************}
{ routines to manipulate handle data }
{************************************}


procedure Set_handle_data(handle: handle_type;
  index: heap_index_type;
  data: data_type);
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  size: heap_index_type;
begin
  if handle <> 0 then
    begin
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);

          if (index > 0) and (index <= size) then
            heap_ptr^.heap_data_ptr^[heap_addr.heap_index + index + 1] := data
          else
            Internal_error('tried to set heap data outside of block');
        end
      else
        Internal_error('invalid handle');
    end
  else
    Internal_error('tried to dereference nil handle');
end; {procedure Set_handle_data}


function Get_handle_data(handle: handle_type;
  index: heap_index_type): data_type;
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  size: heap_index_type;
  data: data_type;
begin
  if handle <> 0 then
    begin
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);

          if (index > 0) and (index <= size) then
            data := heap_ptr^.heap_data_ptr^[heap_addr.heap_index + index + 1]
          else
            Internal_error('tried to get heap data outside of block');
        end
      else
        Internal_error('invalid handle');
    end
  else
    Internal_error('tried to dereference nil handle');

  Get_handle_data := data;
end; {function Get_handle_data}


{*****************************}
{ routines for handle tracing }
{*****************************}


procedure Touch_handle(handle: handle_type);
var
  heap_addr: heap_addr_type;
  heap_ptr: heap_ptr_type;
  size, index: heap_index_type;
  min_index, max_index: heap_index_type;
  data: data_type;
begin
  if handle <> 0 then
    begin
      heap_addr := handle_array_ptr^[handle];
      if heap_addr.heap_number <> 0 then
        begin
          heap_ptr := handle_heap_array_ptr^[heap_addr.heap_number];
          size :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[heap_addr.heap_index]);

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
        end
      else
        Internal_error('invalid handle');
    end;
end; {procedure Touch_handle}


initialization
  handle_heap_number := 0;

  {*****************}
  { allocate arrays }
  {*****************}
  if memory_alert then
    writeln('allocating new handle heap array');
  new(handle_heap_array_ptr);

  if memory_alert then
    writeln('allocating new handle array');
  new(handle_array_ptr);

  {*****************************}
  { initialize handle free list }
  {*****************************}
  handle_free_store := 1;
  handle_free_list := 0;
end.
