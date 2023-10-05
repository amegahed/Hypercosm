unit code_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          code_attributes              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of primitive code types which are used by the           }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  new_memory, strings, symbol_tables, code_types;


type
  {*******************************************************}
  { keywords are extra identifiers which are used in the  }
  { procedure call to make it more readable or to signify }
  { that an optional parameter is being assigned.         }
  {*******************************************************}
  keyword_ptr_type = ^keyword_type;
  keyword_type = record
    keyword: string_type;
    next: keyword_ptr_type;
  end; {keyword_type}


  parameter_ptr_type = ^parameter_type;
  parameter_type = record
    id_ptr: id_ptr_type;
    next: parameter_ptr_type;
  end; {parameter_type}


  {********************************************************}
  { Each procedure has a signature, which is the list of   }
  { parameters and keywords following the name. This tells }
  { how it is called and functions like a prototype. The   }
  { signature is made up of parameters and keywords.       }
  {********************************************************}
  signature_ptr_type = ^signature_type;
  signature_type = record
    optional: boolean;
    keyword_ptr: keyword_ptr_type;
    parameter_ptr, last_parameter_ptr: parameter_ptr_type;
    next: signature_ptr_type;
  end; {signature_type}


  forward_expr_attributes_ptr_type = ptr_type;


  {*********************************************************}
  { record of each subroutine's signature and symbol tables }
  {*********************************************************}
  code_attributes_ptr_type = ^code_attributes_type;
  code_attributes_type = record
    kind: code_kind_type;

    {****************************************************}
    { symbol tables used for interface (parameter) decls }
    {****************************************************}

    // used for exported consts, types
    public_param_table_ptr: symbol_table_ptr_type;

    // used for mandatory params
    private_param_table_ptr: symbol_table_ptr_type;

    // used for optional params
    protected_param_table_ptr: symbol_table_ptr_type;

    {********************************************************}
    { symbol tables used for optional return interface decls }
    {********************************************************}

    // used for exported consts, types
    public_return_table_ptr: symbol_table_ptr_type;

    // used for mandatory return params
    private_return_table_ptr: symbol_table_ptr_type;

    // used for optional return params
    protected_return_table_ptr: symbol_table_ptr_type;

    {*****************************************************}
    { symbol tables used for parameter indicator keywords }
    {*****************************************************}
    keyword_table_ptr: symbol_table_ptr_type;
    keyword_return_table_ptr: symbol_table_ptr_type;

    {*****************************************************}
    { symbol tables used for implementation (local) decls }
    {*****************************************************}
    implicit_table_ptr: symbol_table_ptr_type;
    local_table_ptr: symbol_table_ptr_type;
    label_table_ptr: symbol_table_ptr_type;

    {********************************************************}
    { signatures storing a subprogram's parameter formatting }
    {********************************************************}
    implicit_signature_ptr: signature_ptr_type;
    signature_ptr: signature_ptr_type;
    return_signature_ptr: signature_ptr_type;
    return_value_attributes_ptr: forward_expr_attributes_ptr_type;

    next: code_attributes_ptr_type;
  end; {code_attributes_type}


{************************************************}
{ routines for allocating and freeing code types }
{************************************************}
function New_code_attributes(kind: code_kind_type): code_attributes_ptr_type;
procedure Free_code_attributes(var code_attributes_ptr:
  code_attributes_ptr_type);

{*********************************************}
{ functions for creating and initializing the }
{ signature structure which is used to store  }
{ the list of parameters and keywords.        }
{*********************************************}
function New_keyword(keyword: string_type): keyword_ptr_type;
function New_parameter(id_ptr: id_ptr_type): parameter_ptr_type;
function New_signature: signature_ptr_type;

procedure Free_keyword(var keyword_ptr: keyword_ptr_type);
procedure Free_parameter(var parameter_ptr: parameter_ptr_type);
procedure Free_signature(var signature_ptr: signature_ptr_type);

{***************************************}
{ miscillaneous code attribute routines }
{***************************************}
procedure Free_all_code_attributes;


implementation
uses
  errors;


const
  block_size = 64;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  code_attributes_block_ptr_type = ^code_attributes_block_type;
  code_attributes_block_type = record
    block: array[0..block_size] of code_attributes_type;
    next: code_attributes_block_ptr_type;
  end;

  parameter_block_ptr_type = ^parameter_block_type;
  parameter_block_type = record
    block: array[0..block_size] of parameter_type;
    next: parameter_block_ptr_type;
  end;

  keyword_block_ptr_type = ^keyword_block_type;
  keyword_block_type = record
    block: array[0..block_size] of keyword_type;
    next: keyword_block_ptr_type;
  end;

  signature_block_ptr_type = ^signature_block_type;
  signature_block_type = record
    block: array[0..block_size] of signature_type;
    next: signature_block_ptr_type;
  end;


var
  {************}
  { free lists }
  {************}
  code_attributes_free_list: code_attributes_ptr_type;
  parameter_free_list: parameter_ptr_type;
  keyword_free_list: keyword_ptr_type;
  signature_free_list: signature_ptr_type;


  {****************************}
  { block allocation variables }
  {****************************}
  code_attributes_block_list: code_attributes_block_ptr_type;
  parameter_block_list: parameter_block_ptr_type;
  keyword_block_list: keyword_block_ptr_type;
  signature_block_list: signature_block_ptr_type;

  code_attributes_counter: longint;
  parameter_counter: longint;
  keyword_counter: longint;
  signature_counter: longint;


procedure Dispose_code_attributes_blocks(var code_attributes_block_ptr:
  code_attributes_block_ptr_type);
var
  temp: code_attributes_block_ptr_type;
begin
  while (code_attributes_block_ptr <> nil) do
    begin
      temp := code_attributes_block_ptr;
      code_attributes_block_ptr := code_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_code_attributes_blocks}


procedure Dispose_parameter_blocks(var parameter_block_ptr:
  parameter_block_ptr_type);
var
  temp: parameter_block_ptr_type;
begin
  while (parameter_block_ptr <> nil) do
    begin
      temp := parameter_block_ptr;
      parameter_block_ptr := parameter_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_parameter_blocks}


procedure Dispose_keyword_blocks(var keyword_block_ptr: keyword_block_ptr_type);
var
  temp: keyword_block_ptr_type;
begin
  while (keyword_block_ptr <> nil) do
    begin
      temp := keyword_block_ptr;
      keyword_block_ptr := keyword_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_keyword_blocks}


procedure Dispose_signature_blocks(var signature_block_ptr:
  signature_block_ptr_type);
var
  temp: signature_block_ptr_type;
begin
  while (signature_block_ptr <> nil) do
    begin
      temp := signature_block_ptr;
      signature_block_ptr := signature_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_signature_blocks}


{************************************************}
{ routines for allocating and freeing code types }
{************************************************}


function New_code_attributes(kind: code_kind_type): code_attributes_ptr_type;
var
  code_attributes_ptr: code_attributes_ptr_type;
  code_attributes_block_ptr: code_attributes_block_ptr_type;
  index: integer;
begin
  {************************************}
  { get code attributes from free list }
  {************************************}
  if code_attributes_free_list <> nil then
    begin
      code_attributes_ptr := code_attributes_free_list;
      code_attributes_free_list := code_attributes_free_list^.next;
    end
  else
    begin
      index := code_attributes_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new code info block');
          new(code_attributes_block_ptr);
          code_attributes_block_ptr^.next := code_attributes_block_list;
          code_attributes_block_list := code_attributes_block_ptr;
        end;
      code_attributes_ptr := @code_attributes_block_list^.block[index];
      code_attributes_counter := code_attributes_counter + 1;
    end;

  {****************************}
  { initialize code attributes }
  {****************************}
  code_attributes_ptr^.kind := kind;

  with code_attributes_ptr^ do
    begin
      {****************************************************}
      { symbol tables used for interface (parameter) decls }
      {****************************************************}
      public_param_table_ptr := New_symbol_table;
      private_param_table_ptr := New_symbol_table;
      protected_param_table_ptr := New_symbol_table;

      {********************************************************}
      { symbol tables used for optional return interface decls }
      {********************************************************}
      public_return_table_ptr := New_symbol_table;
      private_return_table_ptr := New_symbol_table;
      protected_return_table_ptr := New_symbol_table;

      {*****************************************************}
      { symbol tables used for parameter indicator keywords }
      {*****************************************************}
      keyword_table_ptr := New_symbol_table;
      keyword_return_table_ptr := New_symbol_table;

      {*****************************************************}
      { symbol tables used for implementation (local) decls }
      {*****************************************************}
      implicit_table_ptr := New_symbol_table;
      local_table_ptr := New_symbol_table;
      label_table_ptr := New_symbol_table;

      {********************************************************}
      { signatures storing a subprogram's parameter formatting }
      {********************************************************}
      implicit_signature_ptr := nil;
      signature_ptr := nil;
      return_signature_ptr := nil;

      next := nil;
    end;

  New_code_attributes := code_attributes_ptr;
end; {function New_code_attributes}


procedure Free_code_attributes(var code_attributes_ptr:
  code_attributes_ptr_type);
begin
  if code_attributes_ptr <> nil then
    begin
      with code_attributes_ptr^ do
        begin
          {****************************************************}
          { symbol tables used for interface (parameter) decls }
          {****************************************************}
          Free_symbol_table(public_param_table_ptr, false);
          Free_symbol_table(private_param_table_ptr, false);
          Free_symbol_table(protected_param_table_ptr, false);

          {********************************************************}
          { symbol tables used for optional return interface decls }
          {********************************************************}
          Free_symbol_table(public_return_table_ptr, false);
          Free_symbol_table(private_return_table_ptr, false);
          Free_symbol_table(protected_return_table_ptr, false);

          {*****************************************************}
          { symbol tables used for parameter indicator keywords }
          {*****************************************************}
          Free_symbol_table(keyword_table_ptr, true);
          Free_symbol_table(keyword_return_table_ptr, true);

          {*****************************************************}
          { symbol tables used for implementation (local) decls }
          {*****************************************************}
          Free_symbol_table(implicit_table_ptr, false);
          Free_symbol_table(local_table_ptr, false);
          Free_symbol_table(label_table_ptr, true);

          {********************************************************}
          { signatures storing a subprogram's parameter formatting }
          {********************************************************}
          Free_signature(implicit_signature_ptr);
          Free_signature(signature_ptr);
          Free_signature(return_signature_ptr);
        end;

      {**********************************}
      { add code attributes to free list }
      {**********************************}
      code_attributes_ptr^.next := code_attributes_free_list;
      code_attributes_free_list := code_attributes_ptr;
      code_attributes_ptr := nil;
    end;
end; {procedure Free_code_attributes}


{*********************************************}
{ functions for creating and initializing the }
{ signature structure which is used to store  }
{ the list of parameters and keywords.        }
{*********************************************}


function New_keyword(keyword: string_type): keyword_ptr_type;
var
  keyword_ptr: keyword_ptr_type;
  keyword_block_ptr: keyword_block_ptr_type;
  index: integer;
begin
  {****************************}
  { get keyword from free list }
  {****************************}
  if keyword_free_list <> nil then
    begin
      keyword_ptr := keyword_free_list;
      keyword_free_list := keyword_free_list^.next;
    end
  else
    begin
      index := keyword_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new keyword block');
          new(keyword_block_ptr);
          keyword_block_ptr^.next := keyword_block_list;
          keyword_block_list := keyword_block_ptr;
        end;
      keyword_ptr := @keyword_block_list^.block[index];
      keyword_counter := keyword_counter + 1;
    end;

  {********************}
  { initialize keyword }
  {********************}
  keyword_ptr^.keyword := keyword;
  keyword_ptr^.next := nil;

  New_keyword := keyword_ptr;
end; {function New_keyword}


function New_parameter(id_ptr: id_ptr_type): parameter_ptr_type;
var
  parameter_ptr: parameter_ptr_type;
  parameter_block_ptr: parameter_block_ptr_type;
  index: integer;
begin
  {******************************}
  { get parameter from free list }
  {******************************}
  if parameter_free_list <> nil then
    begin
      parameter_ptr := parameter_free_list;
      parameter_free_list := parameter_free_list^.next;
    end
  else
    begin
      index := parameter_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new parameter block');
          new(parameter_block_ptr);
          parameter_block_ptr^.next := parameter_block_list;
          parameter_block_list := parameter_block_ptr;
        end;
      parameter_ptr := @parameter_block_list^.block[index];
      parameter_counter := parameter_counter + 1;
    end;

  {**********************}
  { initialize parameter }
  {**********************}
  parameter_ptr^.id_ptr := id_ptr;
  parameter_ptr^.next := nil;

  New_parameter := parameter_ptr;
end; {function New_parameter}


function New_signature: signature_ptr_type;
var
  signature_ptr: signature_ptr_type;
  signature_block_ptr: signature_block_ptr_type;
  index: integer;
begin
  {******************************}
  { get signature from free list }
  {******************************}
  if signature_free_list <> nil then
    begin
      signature_ptr := signature_free_list;
      signature_free_list := signature_free_list^.next;
    end
  else
    begin
      index := signature_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new signature block');
          new(signature_block_ptr);
          signature_block_ptr^.next := signature_block_list;
          signature_block_list := signature_block_ptr;
        end;
      signature_ptr := @signature_block_list^.block[index];
      signature_counter := signature_counter + 1;
    end;

  {**********************}
  { initialize signature }
  {**********************}
  signature_ptr^.optional := false;
  signature_ptr^.keyword_ptr := nil;
  signature_ptr^.parameter_ptr := nil;
  signature_ptr^.last_parameter_ptr := nil;
  signature_ptr^.next := nil;

  New_signature := signature_ptr;
end; {function New_signature}


procedure Free_keyword(var keyword_ptr: keyword_ptr_type);
begin
  {**************************}
  { add keyword to free list }
  {**************************}
  keyword_ptr^.next := keyword_free_list;
  keyword_free_list := keyword_ptr;
  keyword_ptr := nil;
end; {procedure Free_keyword}


procedure Free_parameter(var parameter_ptr: parameter_ptr_type);
begin
  {****************************}
  { add parameter to free list }
  {****************************}
  parameter_ptr^.next := parameter_free_list;
  parameter_free_list := parameter_ptr;
  parameter_ptr := nil;
end; {procedure Free_parameter}


procedure Free_signature(var signature_ptr: signature_ptr_type);
var
  parameter_ptr, last_parameter_ptr: parameter_ptr_type;
  keyword_ptr, last_keyword_ptr: keyword_ptr_type;
begin
  {****************}
  { free paramters }
  {****************}
  if (signature_ptr^.parameter_ptr <> nil) then
    begin
      parameter_ptr := signature_ptr^.parameter_ptr;
      last_parameter_ptr := nil;
      while (parameter_ptr <> nil) do
        begin
          last_parameter_ptr := parameter_ptr;
          parameter_ptr := parameter_ptr^.next;
        end;
      last_parameter_ptr^.next := parameter_free_list;
      parameter_free_list := signature_ptr^.parameter_ptr;
    end;

  {***************}
  { free keywords }
  {***************}
  if (signature_ptr^.keyword_ptr <> nil) then
    begin
      keyword_ptr := signature_ptr^.keyword_ptr;
      last_keyword_ptr := nil;
      while (keyword_ptr <> nil) do
        begin
          last_keyword_ptr := keyword_ptr;
          keyword_ptr := keyword_ptr^.next;
        end;
      last_keyword_ptr^.next := keyword_free_list;
      keyword_free_list := signature_ptr^.keyword_ptr;
    end;

  {****************************}
  { add signature to free list }
  {****************************}
  signature_ptr^.next := signature_free_list;
  signature_free_list := signature_ptr;
  signature_ptr := nil;
end; {procedure Free_signature}


{***************************************}
{ miscillaneous code attribute routines }
{***************************************}


procedure Free_all_code_attributes;
begin
  {***********************}
  { initialize free lists }
  {***********************}
  code_attributes_free_list := nil;
  parameter_free_list := nil;
  keyword_free_list := nil;
  signature_free_list := nil;

  {************************************}
  { dispose block allocation variables }
  {************************************}
  Dispose_code_attributes_blocks(code_attributes_block_list);
  Dispose_parameter_blocks(parameter_block_list);
  Dispose_keyword_blocks(keyword_block_list);
  Dispose_signature_blocks(signature_block_list);

  code_attributes_counter := 0;
  parameter_counter := 0;
  keyword_counter := 0;
  signature_counter := 0;
end; {procedure Free_all_code_attributes}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  code_attributes_free_list := nil;
  parameter_free_list := nil;
  keyword_free_list := nil;
  signature_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  code_attributes_block_list := nil;
  parameter_block_list := nil;
  keyword_block_list := nil;
  signature_block_list := nil;

  code_attributes_counter := 0;
  parameter_counter := 0;
  keyword_counter := 0;
  signature_counter := 0;
end.

