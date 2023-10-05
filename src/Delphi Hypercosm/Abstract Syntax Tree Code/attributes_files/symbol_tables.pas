unit symbol_tables;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           symbol_tables               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The identifiers and symbol tables module provides       }
{       a method of associating identifiers with their          }
{       attributes.                                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, hashtables;


type
  symbol_table_ptr_type = ^symbol_table_type;
  id_ptr_type = hashtable_entry_ptr_type;
  id_name_type = hashtable_key_type;
  id_value_type = hashtable_value_type;


  symbol_table_type = record
    locked: boolean;
    id_number: integer;
    id_list: id_ptr_type;
    hashtable_ptr: hashtable_ptr_type;
    next: symbol_table_ptr_type;
  end; {symbol_table_type}


{***************************************************}
{ routines for allocating and freeing symbol tables }
{***************************************************}
function New_symbol_table: symbol_table_ptr_type;
procedure Free_symbol_table(var symbol_table_ptr: symbol_table_ptr_type;
  free_entries: boolean);

{**************************************************}
{ routines for locking and unlocking symbol tables }
{**************************************************}
procedure Lock_symbol_table(symbol_table_ptr: symbol_table_ptr_type);
procedure Unlock_symbol_table(symbol_table_ptr: symbol_table_ptr_type);

{**********************************}
{ identifier storage and retreival }
{**********************************}
function Enter_id(symbol_table_ptr: symbol_table_ptr_type;
  name: id_name_type;
  value: id_value_type): id_ptr_type;
function Found_id_by_name(symbol_table_ptr: symbol_table_ptr_type;
  var id_ptr: id_ptr_type;
  name: id_name_type): boolean;
function Found_id_by_value(symbol_table_ptr: symbol_table_ptr_type;
  var id_ptr: id_ptr_type;
  value: id_value_type): boolean;

{***************************************}
{ routines to set identifier attributes }
{***************************************}
procedure Set_id_name(id_ptr: id_ptr_type;
  name: id_name_type);
procedure Set_id_value(id_ptr: id_ptr_type;
  value: hashtable_value_type);

{********************************************}
{ routines to retreive identifier attributes }
{********************************************}
function Get_id_name(id_ptr: id_ptr_type): id_name_type;
function Get_id_value(id_ptr: id_ptr_type): id_value_type;

{*************************************}
{ miscillaneous symbol table routines }
{*************************************}
function Symbol_table_size(symbol_table_ptr: symbol_table_ptr_type): integer;
function Equal_symbol_tables(symbol_table_ptr1: symbol_table_ptr_type;
  symbol_table_ptr2: symbol_table_ptr_type): boolean;
procedure Write_symbol_table(symbol_table_ptr: symbol_table_ptr_type);
procedure Free_all_symbol_tables;


implementation
uses
  errors, new_memory;


{*********************************************}
{ the symbol tables are implemented as either }
{ an unordered linked list or as a hashtable. }
{ If the number of identifiers in a given     }
{ tables is small then a list is used. If     }
{ the number exceeds a certain amount, then   }
{ the list is converted into a hashtable.     }
{*********************************************}
const
  max_list_size = 8;
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  symbol_table_block_ptr_type = ^symbol_table_block_type;
  symbol_table_block_type = record
    block: array[0..block_size] of symbol_table_type;
    next: symbol_table_block_ptr_type;
  end;


var
  {************}
  { free lists }
  {************}
  symbol_table_free_list: symbol_table_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  symbol_table_block_list: symbol_table_block_ptr_type;
  symbol_table_counter: longint;


{***************************************************}
{ routines for allocating and freeing symbol tables }
{***************************************************}


function New_symbol_table: symbol_table_ptr_type;
var
  symbol_table_ptr: symbol_table_ptr_type;
  symbol_table_block_ptr: symbol_table_block_ptr_type;
  index: integer;
begin
  {*********************************}
  { get symbol table from free list }
  {*********************************}
  if symbol_table_free_list <> nil then
    begin
      symbol_table_ptr := symbol_table_free_list;
      symbol_table_free_list := symbol_table_free_list^.next;
    end
  else
    begin
      index := symbol_table_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new symbol table block');
          new(symbol_table_block_ptr);
          symbol_table_block_ptr^.next := symbol_table_block_list;
          symbol_table_block_list := symbol_table_block_ptr;
        end;
      symbol_table_ptr := @symbol_table_block_list^.block[index];
      symbol_table_counter := symbol_table_counter + 1;
    end;

  {*************************}
  { initialize symbol table }
  {*************************}
  with symbol_table_ptr^ do
    begin
      id_number := 0;
      locked := false;
      id_list := nil;
      hashtable_ptr := nil;
      next := nil;
    end;

  New_symbol_table := symbol_table_ptr;
end; {function New_symbol_table}


procedure Free_symbol_table(var symbol_table_ptr: symbol_table_ptr_type;
  free_entries: boolean);
var
  follow, temp: id_ptr_type;
begin
  {******************}
  { free identifiers }
  {******************}
  with symbol_table_ptr^ do
    begin
      if (hashtable_ptr = nil) then
        begin
          if free_entries then
            begin
              follow := id_list;
              while (follow <> nil) do
                begin
                  temp := follow;
                  follow := follow^.next;
                  Free_hashtable_entry(temp);
                end;
            end;
        end
      else
        Free_hashtable(hashtable_ptr, free_entries);
    end;

  {*******************************}
  { add symbol table to free list }
  {*******************************}
  symbol_table_ptr^.next := symbol_table_free_list;
  symbol_table_free_list := symbol_table_ptr;
  symbol_table_ptr := nil;
end; {procedure Free_symbol_table}


{**************************************************}
{ routines for locking and unlocking symbol tables }
{**************************************************}


procedure Lock_symbol_table(symbol_table_ptr: symbol_table_ptr_type);
begin
  symbol_table_ptr^.locked := true;
end; {procedure Lock_symbol_table}


procedure Unlock_symbol_table(symbol_table_ptr: symbol_table_ptr_type);
begin
  symbol_table_ptr^.locked := false;
end; {procedure Unlock_symbol_table}


{**********************************}
{ identifier storage and retreival }
{**********************************}


function Enter_id(symbol_table_ptr: symbol_table_ptr_type;
  name: id_name_type;
  value: id_value_type): id_ptr_type;
var
  id_ptr, temp: id_ptr_type;
begin
  id_ptr := nil;

  with symbol_table_ptr^ do
    if not locked then
      begin
        id_number := id_number + 1;
        id_ptr := New_hashtable_entry(name, value);

        if (id_number > max_list_size) then
          begin
            {*********************}
            { insert in hashtable }
            {*********************}
            Enter_hashtable_entry(hashtable_ptr, id_ptr);
          end
        else
          begin
            {****************}
            { insert in list }
            {****************}
            id_ptr^.next := id_list;
            id_list := id_ptr;

            {***************************}
            { convert list to hashtable }
            {***************************}
            if (id_number = max_list_size) then
              begin
                hashtable_ptr := New_hashtable;
                while (id_list <> nil) do
                  begin
                    temp := id_list;
                    id_list := id_list^.next;
                    temp^.next := nil;
                    Enter_hashtable_entry(hashtable_ptr, temp);
                  end;
              end;
          end;
      end
    else
      Error('can not store ids in a locked symbol table');

  Enter_id := id_ptr;
end; {function Enter_id}


function Found_id_by_name(symbol_table_ptr: symbol_table_ptr_type;
  var id_ptr: id_ptr_type;
  name: string_type): boolean;
var
  found: boolean;
begin
  with symbol_table_ptr^ do
    if not locked then
      begin
        if id_number < max_list_size then
          begin
            {***************}
            { serial search }
            {***************}
            id_ptr := id_list;
            found := false;
            while (id_ptr <> nil) and (not found) do
              if (name = id_ptr^.key) then
                found := true
              else
                id_ptr := id_ptr^.next;
          end
        else
          begin
            {******************}
            { hashtable search }
            {******************}
            found := Found_hashtable_entry_by_key(hashtable_ptr, id_ptr, name);
          end;
      end
    else
      found := false;

  Found_id_by_name := found;
end; {function Found_id_by_name}


function Found_id_by_value(symbol_table_ptr: symbol_table_ptr_type;
  var id_ptr: id_ptr_type;
  value: id_value_type): boolean;
var
  found: boolean;
begin
  with symbol_table_ptr^ do
    if not locked then
      begin
        if id_number < max_list_size then
          begin
            {***************}
            { serial search }
            {***************}
            id_ptr := id_list;
            found := false;
            while (id_ptr <> nil) and (not found) do
              if (value = id_ptr^.value) then
                found := true
              else
                id_ptr := id_ptr^.next;
          end
        else
          begin
            {******************}
            { hashtable search }
            {******************}
            found := Found_hashtable_entry_by_value(hashtable_ptr, id_ptr,
              value);
          end;
      end
    else
      found := false;

  Found_id_by_value := found;
end; {function Found_id_by_value}


{***************************************}
{ routines to set identifier attributes }
{***************************************}


procedure Set_id_name(id_ptr: id_ptr_type;
  name: id_name_type);
begin
  id_ptr^.key := name;
end; {procedure Set_id_name}


procedure Set_id_value(id_ptr: id_ptr_type;
  value: hashtable_value_type);
begin
  id_ptr^.value := value;
end; {procedure Set_id_value}


{********************************************}
{ routines to retreive identifier attributes }
{********************************************}


function Get_id_name(id_ptr: id_ptr_type): id_name_type;
begin
  Get_id_name := id_ptr^.key;
end; {function Get_id_name}


function Get_id_value(id_ptr: id_ptr_type): id_value_type;
begin
  Get_id_value := id_ptr^.value;
end; {function Get_id_value}


{*************************************}
{ miscillaneous symbol table routines }
{*************************************}


function Symbol_table_size(symbol_table_ptr: symbol_table_ptr_type): integer;
begin
  Symbol_table_size := symbol_table_ptr^.id_number;
end; {function Symbol_table_size}


function Equal_symbol_tables(symbol_table_ptr1: symbol_table_ptr_type;
  symbol_table_ptr2: symbol_table_ptr_type): boolean;
var
  id_ptr1, id_ptr2: id_ptr_type;
  equal: boolean;
begin
  equal := symbol_table_ptr1^.id_number = symbol_table_ptr2^.id_number;
  if equal then
    begin
      id_ptr1 := symbol_table_ptr1^.id_list;
      id_ptr2 := symbol_table_ptr2^.id_list;
      while equal and (id_ptr1 <> nil) do
        begin
          equal := id_ptr1^.key = id_ptr2^.key;
          id_ptr1 := id_ptr1^.next;
          id_ptr2 := id_ptr2^.next;
        end;
    end;

  Equal_symbol_tables := equal;
end; {function Equal_symbol_tables}


procedure Write_symbol_table(symbol_table_ptr: symbol_table_ptr_type);
var
  id_ptr: id_ptr_type;
begin
  id_ptr := symbol_table_ptr^.id_list;
  while (id_ptr <> nil) do
    begin
      writeln(id_ptr^.key);
      id_ptr := id_ptr^.next;
    end;
end; {procedure Write_symbol_table}


procedure Dispose_symbol_table_blocks(symbol_table_block_ptr:
  symbol_table_block_ptr_type);
var
  temp: symbol_table_block_ptr_type;
begin
  while (symbol_table_block_ptr <> nil) do
    begin
      temp := symbol_table_block_ptr;
      symbol_table_block_ptr := symbol_table_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_symbol_table_blocks}


procedure Free_all_symbol_tables;
begin
  symbol_table_free_list := nil;
  Dispose_symbol_table_blocks(symbol_table_block_list);
  symbol_table_counter := 0;
end; {procedure Free_all_symbol_tables}


initialization
  symbol_table_free_list := nil;
  symbol_table_block_list := nil;
  symbol_table_counter := 0;
end.
