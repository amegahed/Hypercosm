unit addr_types;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             addr_types                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of primitive data types which are used by the           }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


type
  {******************************************}
  { definition of non standard address types }
  {******************************************}
  stack_index_type = longint;
  heap_index_type = longint;

  handle_type = integer;
  memref_type = integer;


type
  addr_kind_type = (stack_index_addr, heap_index_addr, handle_heap_addr,
    memref_heap_addr);


  addr_type = record
    case kind: addr_kind_type of

      {*****************}
      { stack addresses }
      {*****************}
      stack_index_addr: (
        stack_index: stack_index_type;
        );

      {*************************}
      { relative heap addresses }
      {*************************}
      heap_index_addr: (
        heap_index: heap_index_type;
        );

      {*************************}
      { absolute heap addresses }
      {*************************}
      handle_heap_addr: (
        handle: handle_type;
        handle_index: heap_index_type;
        );
      memref_heap_addr: (
        memref: memref_type;
        memref_index: heap_index_type;
        );
  end; {addr_type}


  {**********************************}
  { routine to initialize an address }
  {**********************************}
procedure Init_addr(var addr: addr_type;
  kind: addr_kind_type);

{******************************}
{ routine to compare addresses }
{******************************}
function Equal_addrs(addr1, addr2: addr_type): boolean;
function Get_offset_addr(addr: addr_type;
  offset: integer): addr_type;

{**********************************}
{ routines to convert to addresses }
{**********************************}
function Stack_index_to_addr(stack_index: stack_index_type): addr_type;
function Heap_index_to_addr(heap_index: heap_index_type): addr_type;

function Handle_to_addr(handle: handle_type): addr_type;
function Memref_to_addr(memref: memref_type): addr_type;

function Handle_addr_to_addr(handle: handle_type;
  handle_index: heap_index_type): addr_type;
function Memref_addr_to_addr(memref: memref_type;
  memref_index: heap_index_type): addr_type;

{************************************}
{ routines to convert from addresses }
{************************************}
function Addr_to_stack_index(addr: addr_type): stack_index_type;
function Addr_to_heap_index(addr: addr_type): heap_index_type;

function Addr_to_handle(addr: addr_type): handle_type;
function Addr_to_memref(addr: addr_type): memref_type;

function Addr_to_handle_addr(addr: addr_type;
  var handle_index: heap_index_type): handle_type;
function Addr_to_memref_addr(addr: addr_type;
  var memref_index: heap_index_type): memref_type;

{*****************************}
{ routines to write addresses }
{*****************************}
procedure Write_addr(addr: addr_type);
procedure Write_addr_kind(kind: addr_kind_type);


implementation
uses
  errors;


{**********************************}
{ routine to initialize an address }
{**********************************}


procedure Init_addr(var addr: addr_type;
  kind: addr_kind_type);
begin
  addr.kind := kind;
  with addr do
    case kind of

      {*****************}
      { stack addresses }
      {*****************}
      stack_index_addr:
        begin
          stack_index := 0;
        end;

      {*************************}
      { relative heap addresses }
      {*************************}
      heap_index_addr:
        begin
          heap_index := 0;
        end;

      {*************************}
      { absolute heap addresses }
      {*************************}
      handle_heap_addr:
        begin
          handle := 0;
          handle_index := 0;
        end;
      memref_heap_addr:
        begin
          memref := 0;
          memref_index := 0;
        end;

    end; {case}
end; {procedure Init_addr}


{******************************}
{ routine to compare addresses }
{******************************}


function Equal_addrs(addr1, addr2: addr_type): boolean;
var
  equal: boolean;
begin
  equal := false;
  
  if addr1.kind = addr2.kind then
    case addr1.kind of

      {*****************}
      { stack addresses }
      {*****************}
      stack_index_addr:
        equal := addr1.stack_index = addr2.stack_index;

      {*************************}
      { relative heap addresses }
      {*************************}
      heap_index_addr:
        equal := addr1.heap_index = addr2.heap_index;

      {*************************}
      { absolute heap addresses }
      {*************************}
      handle_heap_addr:
        begin
          if addr1.handle <> addr2.handle then
            equal := false
          else
            equal := addr1.handle_index = addr2.handle_index;
        end;
      memref_heap_addr:
        begin
          if addr1.memref <> addr2.memref then
            equal := false
          else
            equal := addr1.memref_index = addr2.memref_index;
        end;

    end {case}
  else
    equal := false;

  Equal_addrs := equal;
end; {function Equal_addrs}


function Get_offset_addr(addr: addr_type;
  offset: integer): addr_type;
begin
  case addr.kind of

    stack_index_addr:
      addr.stack_index := addr.stack_index + offset;

    heap_index_addr:
      addr.heap_index := addr.heap_index + offset;

    handle_heap_addr:
      addr.handle_index := addr.handle_index + offset;

    memref_heap_addr:
      addr.memref_index := addr.memref_index + offset;

  end; {case}

  Get_offset_addr := addr;
end; {function Get_offset_addr}


{**********************************}
{ routines to convert to addresses }
{**********************************}


function Stack_index_to_addr(stack_index: stack_index_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := stack_index_addr;
  addr.stack_index := stack_index;
  Stack_index_to_addr := addr;
end; {function Stack_index_to_addr}


function Heap_index_to_addr(heap_index: heap_index_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := heap_index_addr;
  addr.heap_index := heap_index;
  Heap_index_to_addr := addr;
end; {function Heap_index_to_addr}


function Handle_to_addr(handle: handle_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := handle_heap_addr;
  addr.handle := handle;
  addr.handle_index := 0;
  Handle_to_addr := addr;
end; {function Handle_to_addr}


function Memref_to_addr(memref: memref_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := memref_heap_addr;
  addr.memref := memref;
  addr.memref_index := 0;
  Memref_to_addr := addr;
end; {function Memref_to_addr}


function Handle_addr_to_addr(handle: handle_type;
  handle_index: heap_index_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := handle_heap_addr;
  addr.handle := handle;
  addr.handle_index := handle_index;
  Handle_addr_to_addr := addr;
end; {function Handle_addr_to_addr}


function Memref_addr_to_addr(memref: memref_type;
  memref_index: heap_index_type): addr_type;
var
  addr: addr_type;
begin
  addr.kind := memref_heap_addr;
  addr.memref := memref;
  addr.memref_index := memref_index;
  Memref_addr_to_addr := addr;
end; {function Memref_addr_to_addr}


{************************************}
{ routines to convert from addresses }
{************************************}


function Addr_to_stack_index(addr: addr_type): stack_index_type;
var
  stack_index: stack_index_type;
begin
  if addr.kind <> stack_index_addr then
    begin
      Error('Can not convert addr to stack index.');
      stack_index := 0;
    end
  else
    stack_index := addr.stack_index;

  Addr_to_stack_index := stack_index;
end; {function Addr_to_stack_index}


function Addr_to_heap_index(addr: addr_type): heap_index_type;
var
  heap_index: heap_index_type;
begin
  if addr.kind <> heap_index_addr then
    begin
      Error('Can not convert addr to heap index.');
      heap_index := 0;
    end
  else
    heap_index := addr.heap_index;

  Addr_to_heap_index := heap_index;
end; {function Addr_to_heap_index}


function Addr_to_handle(addr: addr_type): handle_type;
var
  handle: handle_type;
begin
  if addr.kind <> handle_heap_addr then
    begin
      Error('Can not convert addr to handle.');
      handle := 0;
    end
  else
    handle := addr.handle;

  Addr_to_handle := handle;
end; {function Addr_to_handle}


function Addr_to_memref(addr: addr_type): memref_type;
var
  memref: memref_type;
begin
  if addr.kind <> memref_heap_addr then
    begin
      Error('Can not convert addr to memref.');
      memref := 0;
    end
  else
    memref := addr.memref;

  Addr_to_memref := memref;
end; {function Addr_to_memref}


function Addr_to_handle_addr(addr: addr_type;
  var handle_index: heap_index_type): handle_type;
var
  handle: handle_type;
begin
  if addr.kind <> handle_heap_addr then
    begin
      Error('Can not convert addr to handle heap addr.');
      handle_index := 0;
      handle := 0;
    end
  else
    begin
      handle_index := addr.handle_index;
      handle := addr.handle;
    end;

  Addr_to_handle_addr := handle;
end; {function Addr_to_handle_addr}


function Addr_to_memref_addr(addr: addr_type;
  var memref_index: heap_index_type): memref_type;
var
  memref: memref_type;
begin
  if addr.kind <> memref_heap_addr then
    begin
      Error('Can not convert addr to memref heap addr.');
      memref_index := 0;
      memref := 0;
    end
  else
    begin
      memref_index := addr.memref_index;
      memref := addr.memref;
    end;

  Addr_to_memref_addr := memref;
end; {function Addr_to_memref_addr}


{*****************************}
{ routines to write addresses }
{*****************************}


procedure Write_addr(addr: addr_type);
begin
  with addr do
    case kind of

      stack_index_addr:
        write('stack index = ', stack_index: 1);
      heap_index_addr:
        write('heap index = ', heap_index: 1);
      handle_heap_addr:
        write('handle_heap_addr with handle = ', handle: 1, ', index = ',
          handle_index: 1);
      memref_heap_addr:
        write('memref_heap_addr with handle = ', memref: 1, ', index = ',
          memref_index: 1);

    end; {case}
end; {procedure Write_addr}


procedure Write_addr_kind(kind: addr_kind_type);
begin
  case kind of

    stack_index_addr:
      write('stack_index_addr');
    heap_index_addr:
      write('heap_index_addr');
    handle_heap_addr:
      write('handle_heap_addr');
    memref_heap_addr:
      write('memref_heap_addr');

  end; {case}
end; {procedure Write_addr_kind}


end.
