unit data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                data                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines the structure of the runtime        }
{       data used by the interpreter.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  errors, data_types, addr_types;


type
  abstract_type_ptr_type = Pointer;
  abstract_code_ptr_type = Pointer;


type
  data_kind_type = (

    {*************************}
    { uninitialized data type }
    {*************************}
    error_data,

    {***********************}
    { enumerated data types }
    {***********************}
    boolean_data, char_data,

    {*********************}
    { integral data_types }
    {*********************}
    byte_data, short_data, integer_data, long_data,

    {***************************}
    { floating point data types }
    {***************************}
    scalar_data, double_data,

    {***************}
    { address types }
    {***************}
    stack_index_data, heap_index_data, handle_data, memref_data,

    {********************}
    { code pointer types }
    {********************}
    type_data, code_data);


  data_type = record
    case kind: data_kind_type of

      {*************************}
      { uninitialized data type }
      {*************************}
      error_data: (
        );

      {***********************}
      { enumerated data types }
      {***********************}
      boolean_data: (
        boolean_val: boolean_type;
        );
      char_data: (
        char_val: char_type;
        );

      {*********************}
      { integral data types }
      {*********************}
      byte_data: (
        byte_val: byte_type;
        );
      short_data: (
        short_val: short_type;
        );
      integer_data: (
        integer_val: integer_type;
        );
      long_data: (
        long_val: long_type;
        );

      {***************************}
      { floating point data types }
      {***************************}
      scalar_data: (
        scalar_val: scalar_type;
        );
      double_data: (
        double_val: double_type;
        );

      {***************}
      { address types }
      {***************}
      stack_index_data: (
        stack_index: stack_index_type
        );
      heap_index_data: (
        heap_index: heap_index_type
        );
      handle_data: (
        handle: handle_type;
        );
      memref_data: (
        memref: memref_type;
        );

      {********************}
      { code pointer types }
      {********************}
      type_data: (
        type_ptr: abstract_type_ptr_type;
        );
      code_data: (
        code_ptr: abstract_code_ptr_type;
        );
  end; {data_type}


  {*************************}
  { routine to compare data }
  {*************************}
function Equal_data(data1, data2: data_type): boolean;
function Get_error_data: data_type;

{*********************************************}
{ routines to convert primitive types to data }
{*********************************************}
function Boolean_to_data(boolean_val: boolean_type): data_type;
function Char_to_data(char_val: char_type): data_type;

function Byte_to_data(byte_val: byte_type): data_type;
function Short_to_data(short_val: short_type): data_type;

function Integer_to_data(integer_val: integer_type): data_type;
function Long_to_data(long_val: long_type): data_type;

function Scalar_to_data(scalar_val: scalar_type): data_type;
function Double_to_data(double_val: double_type): data_type;

{*******************************************}
{ routines to convert address types to data }
{*******************************************}
function Stack_index_to_data(stack_index: stack_index_type): data_type;
function Heap_index_to_data(heap_index: heap_index_type): data_type;

function Handle_to_data(handle: handle_type): data_type;
function Memref_to_data(memref: memref_type): data_type;

{*******************************************}
{ routines to convert pointer types to data }
{*******************************************}
function Type_to_data(type_ptr: abstract_type_ptr_type): data_type;
function Code_to_data(code_ptr: abstract_code_ptr_type): data_type;

{*********************************************}
{ routines to convert data to primitive types }
{*********************************************}
function Data_to_boolean(data: data_type): boolean_type;
function Data_to_char(data: data_type): char_type;

function Data_to_byte(data: data_type): byte_type;
function Data_to_short(data: data_type): short_type;

function Data_to_integer(data: data_type): integer_type;
function Data_to_long(data: data_type): long_type;

function Data_to_scalar(data: data_type): scalar_type;
function Data_to_double(data: data_type): double_type;

{*******************************************}
{ routines to convert data to address types }
{*******************************************}
function Data_to_stack_index(data: data_type): stack_index_type;
function Data_to_heap_index(data: data_type): heap_index_type;

function Data_to_handle(data: data_type): handle_type;
function Data_to_memref(data: data_type): memref_type;

{*******************************************}
{ routines to convert data to pointer types }
{*******************************************}
function Data_to_type(data: data_type): abstract_type_ptr_type;
function Data_to_code(data: data_type): abstract_code_ptr_type;

{************************}
{ routines to write data }
{************************}
procedure Write_data_kind(data_kind: data_kind_type);
procedure Write_data(data: data_type);


implementation


function Equal_data(data1, data2: data_type): boolean;
var
  equal: boolean;
begin
  equal := false;

  if (data1.kind = error_data) or (data2.kind = error_data) then
    Error('Can not compare uninitialized data.')

  else if (data1.kind <> data2.kind) then
    equal := false
  else
    case data1.kind of

      {***********************}
      { enumerated data types }
      {***********************}
      boolean_data:
        equal := (data1.boolean_val = data2.boolean_val);
      char_data:
        equal := (data1.char_val = data2.char_val);

      {*********************}
      { integral data types }
      {*********************}
      byte_data:
        equal := (data1.byte_val = data2.byte_val);
      short_data:
        equal := (data1.short_val = data2.short_val);
      integer_data:
        equal := (data1.integer_val = data2.integer_val);
      long_data:
        equal := (data1.long_val = data2.long_val);

      {***************************}
      { floating point data types }
      {***************************}
      scalar_data:
        equal := (data1.scalar_val = data2.scalar_val);
      double_data:
        equal := (data1.double_val = data2.double_val);

      {***************}
      { address types }
      {***************}
      stack_index_data:
        equal := data1.stack_index = data2.stack_index;
      heap_index_data:
        equal := data1.heap_index = data2.heap_index;
      handle_data:
        equal := data1.handle = data2.handle;
      memref_data:
        equal := data1.memref = data2.memref;

      {********************}
      { code pointer types }
      {********************}
      type_data:
        equal := (data1.type_ptr = data2.type_ptr);
      code_data:
        equal := (data1.code_ptr = data2.code_ptr);
    end; {case}

  Equal_data := equal;
end; {function Equal_data}


function Get_error_data: data_type;
var
  data: data_type;
begin
  data.kind := error_data;
  Get_error_data := data;
end; {function Get_error_data}


{*********************************************}
{ routines to convert primitive types to data }
{*********************************************}


function Boolean_to_data(boolean_val: boolean_type): data_type;
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Boolean_to_data := data;
end; {function Boolean_to_data}


function Char_to_data(char_val: char_type): data_type;
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Char_to_data := data;
end; {function Char_to_data}


function Byte_to_data(byte_val: byte_type): data_type;
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Byte_to_data := data;
end; {function Byte_to_data}


function Short_to_data(short_val: short_type): data_type;
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Short_to_data := data;
end; {function Short_to_data}


function Integer_to_data(integer_val: integer_type): data_type;
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Integer_to_data := data;
end; {function Integer_to_data}


function Long_to_data(long_val: long_type): data_type;
var
  data: data_type;
begin
  data.kind := integer_data;
  data.long_val := long_val;
  Long_to_data := data;
end; {function Long_to_data}


function Scalar_to_data(scalar_val: scalar_type): data_type;
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Scalar_to_data := data;
end; {function Scalar_to_data}


function Double_to_data(double_val: double_type): data_type;
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Double_to_data := data;
end; {function Double_to_data}


{*******************************************}
{ routines to convert address types to data }
{*******************************************}


function Stack_index_to_data(stack_index: stack_index_type): data_type;
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Stack_index_to_data := data;
end; {function Stack_index_to_data}


function Heap_index_to_data(heap_index: heap_index_type): data_type;
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Heap_index_to_data := data;
end; {function Heap_index_to_data}


function Handle_to_data(handle: handle_type): data_type;
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Handle_to_data := data;
end; {function Handle_to_data}


function Memref_to_data(memref: memref_type): data_type;
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Memref_to_data := data;
end; {function Memref_to_data}


{*******************************************}
{ routines to convert pointer types to data }
{*******************************************}


function Type_to_data(type_ptr: abstract_type_ptr_type): data_type;
var
  data: data_type;
begin
  data.kind := type_data;
  data.type_ptr := type_ptr;
  Type_to_data := data;
end; {function Type_to_data}


function Code_to_data(code_ptr: abstract_code_ptr_type): data_type;
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Code_to_data := data;
end; {function Code_to_data}


{*********************************************}
{ routines to convert data to primitive types }
{*********************************************}


function Data_to_boolean(data: data_type): boolean_type;
begin
  if data.kind <> boolean_data then
    Error('Found invalid boolean value.');
  Data_to_boolean := data.boolean_val;
end; {function Data_to_boolean}


function Data_to_char(data: data_type): char_type;
begin
  if data.kind <> char_data then
    Error('Found invalid char value.');
  Data_to_char := data.char_val;
end; {function Data_to_char}


function Data_to_byte(data: data_type): byte_type;
begin
  if data.kind <> byte_data then
    Error('Found invalid byte value.');
  Data_to_byte := data.byte_val;
end; {function Data_to_byte}


function Data_to_short(data: data_type): short_type;
begin
  if data.kind <> short_data then
    Error('Found invalid short value.');
  Data_to_short := data.short_val;
end; {function Data_to_short}


function Data_to_integer(data: data_type): integer_type;
begin
  if data.kind <> integer_data then
    Error('Found invalid integer value.');
  Data_to_integer := data.integer_val;
end; {function Data_to_integer}


function Data_to_long(data: data_type): long_type;
begin
  if data.kind <> long_data then
    Error('Found invalid long value.');
  Data_to_long := data.long_val;
end; {function Data_to_long}


function Data_to_scalar(data: data_type): scalar_type;
begin
  if data.kind <> scalar_data then
    Error('Found invalid scalar value.');
  Data_to_scalar := data.scalar_val;
end; {function Data_to_scalar}


function Data_to_double(data: data_type): double_type;
begin
  if data.kind <> double_data then
    Error('Found invalid double value.');
  Data_to_double := data.double_val;
end; {function Data_to_double}


{*******************************************}
{ routines to convert data to address types }
{*******************************************}


function Data_to_stack_index(data: data_type): stack_index_type;
begin
  if data.kind <> stack_index_data then
    Error('Found invalid stack index.');
  Data_to_stack_index := data.stack_index;
end; {function Data_to_stack_index}


function Data_to_heap_index(data: data_type): heap_index_type;
begin
  if data.kind <> heap_index_data then
    Error('Found invalid heap index.');
  Data_to_heap_index := data.heap_index;
end; {function Data_to_heap_index}


function Data_to_handle(data: data_type): handle_type;
begin
  if data.kind <> handle_data then
    Error('Found invalid handle.');
  Data_to_handle := data.handle;
end; {function Data_to_handle}


function Data_to_memref(data: data_type): memref_type;
begin
  if data.kind <> memref_data then
    Error('Found invalid memref.');
  Data_to_memref := data.memref;
end; {function Data_to_memref}


{*******************************************}
{ routines to convert data to pointer types }
{*******************************************}


function Data_to_type(data: data_type): abstract_type_ptr_type;
begin
  if data.kind <> type_data then
    Error('Found invalid type.');
  Data_to_type := data.type_ptr;
end; {function Data_to_type}


function Data_to_code(data: data_type): abstract_code_ptr_type;
begin
  if data.kind <> code_data then
    Error('Found invalid code.');
  Data_to_code := data.code_ptr;
end; {function Data_to_code}


{************************}
{ routines to write data }
{************************}


procedure Write_data_kind(data_kind: data_kind_type);
begin
  case data_kind of

    {*************************}
    { uninitialized data type }
    {*************************}
    error_data:
      write('error_data');

    {***********************}
    { enumerated data types }
    {***********************}
    boolean_data:
      write('boolean_data');
    char_data:
      write('char_data');

    {*********************}
    { integral data types }
    {*********************}
    byte_data:
      write('byte_data');
    short_data:
      write('short_data');
    integer_data:
      write('integer_data');
    long_data:
      write('long_data');

    {***************************}
    { floating point data types }
    {***************************}
    scalar_data:
      write('scalar_data');
    double_data:
      write('double_data');

    {***************}
    { address types }
    {***************}
    stack_index_data:
      write('stack_index_data');
    heap_index_data:
      write('heap_index_data');
    handle_data:
      write('handle_data');
    memref_data:
      write('memref_data');

    {*********************}
    { code pointers types }
    {*********************}
    type_data:
      write('type_data');
    code_data:
      write('code_data');

  end; {case}
end; {procedure Write_data_kind}


procedure Write_data(data: data_type);
begin
  with data do
    if kind in [error_data..code_data] then
      case kind of

        {*************************}
        { uninitialized data type }
        {*************************}
        error_data:
          write('?');

        {***********************}
        { enumerated data types }
        {***********************}
        boolean_data:
          if (boolean_val = true) then
            write('true')
          else
            write('false');
        char_data:
          write(char_val);

        {*********************}
        { integral data types }
        {*********************}
        byte_data:
          write(byte_val: 1);
        short_data:
          write('short_val:1');
        integer_data:
          write(integer_val: 1);
        long_data:
          write(long_val: 1);

        {***************************}
        { floating point data types }
        {***************************}
        scalar_data:
          write(scalar_val: 3: 3);
        double_data:
          write(double_val: 6: 6);

        {***************}
        { address types }
        {***************}
        stack_index_data:
          write(stack_index: 1);
        heap_index_data:
          write(heap_index: 1);
        handle_data:
          write(handle: 1);
        memref_data:
          write(memref: 1);

        {********************}
        { code pointer types }
        {********************}
        type_data:
          write('<type reference>');
        code_data:
          write('<code reference>');

      end {case}
    else
      write('???');
end; {procedure Write_data}


end.
