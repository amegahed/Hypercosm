unit hashtables;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             hashtables                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This is intended to be a generic hashtable module      }
{        which can be used anywhere a string needs to be        }
{        mapped to an integer value.                            }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings;


const
  {****************************************}
  { these constants make a 'perfect'       }
  { hashfunction for pascal reserved words }
  {****************************************}
  hashtable_size = 147;
  hashtable_constant = 64;


type
  hashtable_value_type = longint;
  hashtable_key_type = string_type;


  hashtable_entry_ptr_type = ^hashtable_entry_type;
  hashtable_entry_type = record
    value: hashtable_value_type;
    key: hashtable_key_type;
    next: hashtable_entry_ptr_type;
  end; {hashtable_entry_type}


  hashtable_ptr_type = ^hashtable_type;
  hashtable_type = record
    entries: integer;
    table: array[0..hashtable_size] of hashtable_entry_ptr_type;
    next: hashtable_ptr_type;
  end;


{************************************************}
{ routines for allocating and freeing hashtables }
{************************************************}
function New_hashtable: hashtable_ptr_type;
procedure Free_hashtable(var hashtable_ptr: hashtable_ptr_type;
  free_entries: boolean);

{*******************************************************}
{ routines for allocating and freeing hashtable entries }
{*******************************************************}
function New_hashtable_entry(key: hashtable_key_type;
  value: hashtable_value_type): hashtable_entry_ptr_type;
procedure Free_hashtable_entry(var hashtable_entry_ptr:
  hashtable_entry_ptr_type);

{***********************************************}
{ routines for retreiving hashtable information }
{***********************************************}
procedure Write_hashtable(hashtable_ptr: hashtable_ptr_type);
function Hashtable_entries(hashtable_ptr: hashtable_ptr_type): integer;

{*******************************************************}
{ routines for entering and retreiving hashtable values }
{*******************************************************}
procedure Enter_hashtable(hashtable_ptr: hashtable_ptr_type;
  key: hashtable_key_type;
  value: hashtable_value_type);
function Found_hashtable_value_by_key(hashtable_ptr: hashtable_ptr_type;
  var value: hashtable_value_type;
  key: hashtable_key_type): boolean;
function Found_hashtable_key_by_value(hashtable_ptr: hashtable_ptr_type;
  var key: hashtable_key_type;
  value: hashtable_value_type): boolean;

{********************************************************}
{ routines for entering and retreiving hashtable entries }
{********************************************************}
procedure Enter_hashtable_entry(hashtable_ptr: hashtable_ptr_type;
  hashtable_entry_ptr: hashtable_entry_ptr_type);
function Found_hashtable_entry_by_key(hashtable_ptr: hashtable_ptr_type;
  var hashtable_entry_ptr: hashtable_entry_ptr_type;
  key: hashtable_key_type): boolean;
function Found_hashtable_entry_by_value(hashtable_ptr: hashtable_ptr_type;
  var hashtable_entry_ptr: hashtable_entry_ptr_type;
  value: hashtable_value_type): boolean;

{***********************************}
{ miscillaneous hashtable functions }
{***********************************}
procedure Check_hashtables;
procedure Free_all_hashtables;


implementation


const
  hashtable_block_size = 16;
  hashtable_entry_block_size = 64;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  hashtable_block_ptr_type = ^hashtable_block_type;
  hashtable_block_type = record
    block: array[0..hashtable_block_size] of hashtable_type;
    next: hashtable_block_ptr_type;
  end;

  hashtable_entry_block_ptr_type = ^hashtable_entry_block_type;
  hashtable_entry_block_type = record
    block: array[0..hashtable_entry_block_size] of hashtable_entry_type;
    next: hashtable_entry_block_ptr_type;
  end;


var
  {************}
  { free lists }
  {************}
  hashtable_free_list: hashtable_ptr_type;
  hashtable_entry_free_list: hashtable_entry_ptr_type;


  {****************************}
  { block allocation variables }
  {****************************}
  hashtable_block_list: hashtable_block_ptr_type;
  hashtable_entry_block_list: hashtable_entry_block_ptr_type;

  hashtable_counter: longint;
  hashtable_entry_counter: longint;


function Free_hashtable_number: integer;
var
  hashtable_ptr: hashtable_ptr_type;
  hashtable_number: integer;
begin
  hashtable_ptr := hashtable_free_list;
  hashtable_number := 0;
  while hashtable_ptr <> nil do
    begin
      hashtable_number := hashtable_number + 1;
      hashtable_ptr := hashtable_ptr^.next;
    end;

  Free_hashtable_number := hashtable_number;
end; {function Free_hashtable_number}


function Free_hashtable_entry_number: integer;
var
  hashtable_entry_ptr: hashtable_entry_ptr_type;
  hashtable_entry_number: integer;
begin
  hashtable_entry_ptr := hashtable_entry_free_list;
  hashtable_entry_number := 0;
  while hashtable_entry_ptr <> nil do
    begin
      hashtable_entry_number := hashtable_entry_number + 1;
      hashtable_entry_ptr := hashtable_entry_ptr^.next;
    end;

  Free_hashtable_entry_number := hashtable_entry_number;
end; {function Free_hashtable_entry_number}


{*************************************************}
{ routines to allocate and free hashtable entries }
{*************************************************}


function New_hashtable_entry(key: hashtable_key_type;
  value: hashtable_value_type): hashtable_entry_ptr_type;
var
  hashtable_entry_ptr: hashtable_entry_ptr_type;
  hashtable_entry_block_ptr: hashtable_entry_block_ptr_type;
  index: integer;
begin
  {************************************}
  { get hashtable entry from free list }
  {************************************}
  if hashtable_entry_free_list <> nil then
    begin
      hashtable_entry_ptr := hashtable_entry_free_list;
      hashtable_entry_free_list := hashtable_entry_free_list^.next;
    end
  else
    begin
      index := hashtable_entry_counter mod hashtable_entry_block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new hashtable entry block');
          new(hashtable_entry_block_ptr);
          hashtable_entry_block_ptr^.next := hashtable_entry_block_list;
          hashtable_entry_block_list := hashtable_entry_block_ptr;
        end;
      hashtable_entry_ptr := @hashtable_entry_block_list^.block[index];
      hashtable_entry_counter := hashtable_entry_counter + 1;
    end;

  {****************************}
  { initialize hashtable entry }
  {****************************}
  hashtable_entry_ptr^.value := value;
  hashtable_entry_ptr^.key := key;
  hashtable_entry_ptr^.next := nil;

  New_hashtable_entry := hashtable_entry_ptr;
end; {function New_hashtable_entry}


procedure Free_hashtable_entry(var hashtable_entry_ptr:
  hashtable_entry_ptr_type);
begin
  {**********************************}
  { add hashtable entry to free list }
  {**********************************}
  hashtable_entry_ptr^.next := hashtable_entry_free_list;
  hashtable_entry_free_list := hashtable_entry_ptr;
  hashtable_entry_ptr := nil;
end; {procedure Free_hashtable_entry}


{******************************************}
{ routines to allocate and free hashtables }
{******************************************}


function New_hashtable: hashtable_ptr_type;
var
  hashtable_ptr: hashtable_ptr_type;
  hashtable_block_ptr: hashtable_block_ptr_type;
  index, counter: integer;
begin
  {******************************}
  { get hashtable from free list }
  {******************************}
  if hashtable_free_list <> nil then
    begin
      hashtable_ptr := hashtable_free_list;
      hashtable_free_list := hashtable_free_list^.next;
    end
  else
    begin
      index := hashtable_counter mod hashtable_block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new hashtable block');
          new(hashtable_block_ptr);
          hashtable_block_ptr^.next := hashtable_block_list;
          hashtable_block_list := hashtable_block_ptr;
        end;
      hashtable_ptr := @hashtable_block_list^.block[index];
      hashtable_counter := hashtable_counter + 1;
    end;

  {**********************}
  { initialize hashtable }
  {**********************}
  with hashtable_ptr^ do
    begin
      entries := 0;
      for counter := 0 to hashtable_size do
        table[counter] := nil;
    end;

  New_hashtable := hashtable_ptr;
end; {function New_hashtable}


procedure Free_hashtable(var hashtable_ptr: hashtable_ptr_type;
  free_entries: boolean);
var
  counter: integer;
  follow, temp: hashtable_entry_ptr_type;
begin
  {************************}
  { free hashtable entries }
  {************************}
  if free_entries then
    for counter := 1 to hashtable_size do
      begin
        follow := hashtable_ptr^.table[counter];
        while follow <> nil do
          begin
            temp := follow;
            follow := follow^.next;
            Free_hashtable_entry(temp);
          end;
      end;

  {****************************}
  { add hashtable to free list }
  {****************************}
  hashtable_ptr^.next := hashtable_free_list;
  hashtable_free_list := hashtable_ptr;
  hashtable_ptr := nil;
end; {procedure Free_hashtable}


function Hash_function(key: hashtable_key_type): integer;
var
  str_length: integer;
  index: integer;
begin
  str_length := length(key);

  if str_length < 1 then
    index := 0
  else
    index := (ord(key[1]) * hashtable_constant + ord(key[str_length]) +
      str_length) mod hashtable_size;

  Hash_function := index;
end; {function Hash_function}


function Found_hashtable_value_by_key(hashtable_ptr: hashtable_ptr_type;
  var value: hashtable_value_type;
  key: hashtable_key_type): boolean;
var
  follow: hashtable_entry_ptr_type;
  index: integer;
  found: boolean;
begin
  found := false;
  index := Hash_function(key);

  follow := hashtable_ptr^.table[index];
  while (follow <> nil) do
    if (follow^.key = key) then
      begin
        value := follow^.value;
        found := true;
        follow := nil;
      end
    else
      follow := follow^.next;

  Found_hashtable_value_by_key := found;
end; {function Found_hashtable_value_by_key}


function Found_hashtable_key_by_value(hashtable_ptr: hashtable_ptr_type;
  var key: hashtable_key_type;
  value: hashtable_value_type): boolean;
var
  follow: hashtable_entry_ptr_type;
  index: integer;
  found: boolean;
begin
  index := 0;
  found := false;

  if hashtable_ptr^.entries > 0 then
    while (index < hashtable_size) and not found do
      begin
        follow := hashtable_ptr^.table[index];
        while (follow <> nil) do
          if (follow^.value = value) then
            begin
              key := follow^.key;
              found := true;
              follow := nil;
            end
          else
            follow := follow^.next;

        if not found then
          index := index + 1;
      end;

  Found_hashtable_key_by_value := found;
end; {function Found_hashtable_key_by_value}


function Found_hashtable_entry_by_key(hashtable_ptr: hashtable_ptr_type;
  var hashtable_entry_ptr: hashtable_entry_ptr_type;
  key: hashtable_key_type): boolean;
var
  follow: hashtable_entry_ptr_type;
  index: integer;
  found: boolean;
begin
  found := false;
  index := Hash_function(key);
  hashtable_entry_ptr := nil;

  follow := hashtable_ptr^.table[index];
  while (follow <> nil) do
    if (follow^.key = key) then
      begin
        found := true;
        hashtable_entry_ptr := follow;
        follow := nil;
      end
    else
      follow := follow^.next;

  Found_hashtable_entry_by_key := found;
end; {function Found_hashtable_entry_by_key}


function Found_hashtable_entry_by_value(hashtable_ptr: hashtable_ptr_type;
  var hashtable_entry_ptr: hashtable_entry_ptr_type;
  value: hashtable_value_type): boolean;
var
  follow: hashtable_entry_ptr_type;
  index: integer;
  found: boolean;
begin
  index := 0;
  found := false;
  hashtable_entry_ptr := nil;

  if hashtable_ptr^.entries > 0 then
    while (index < hashtable_size) and not found do
      begin
        follow := hashtable_ptr^.table[index];
        while (follow <> nil) do
          if (follow^.value = value) then
            begin
              found := true;
              hashtable_entry_ptr := follow;
              follow := nil;
            end
          else
            follow := follow^.next;

        if not found then
          index := index + 1;
      end;

  Found_hashtable_entry_by_value := found;
end; {function Found_hashtable_entry_by_value}


procedure Enter_hashtable(hashtable_ptr: hashtable_ptr_type;
  key: hashtable_key_type;
  value: hashtable_value_type);
var
  hashtable_entry_ptr: hashtable_entry_ptr_type;
  index: integer;
begin
  index := Hash_function(key);
  hashtable_entry_ptr := New_hashtable_entry(key, value);

  {************************}
  { insert at head of list }
  {************************}
  hashtable_ptr^.entries := hashtable_ptr^.entries + 1;
  hashtable_entry_ptr^.next := hashtable_ptr^.table[index];
  hashtable_ptr^.table[index] := hashtable_entry_ptr;
end; {procedure Enter_hashtable}


procedure Enter_hashtable_entry(hashtable_ptr: hashtable_ptr_type;
  hashtable_entry_ptr: hashtable_entry_ptr_type);
var
  index: integer;
begin
  index := Hash_function(hashtable_entry_ptr^.key);

  {************************}
  { insert at head of list }
  {************************}
  hashtable_ptr^.entries := hashtable_ptr^.entries + 1;
  hashtable_entry_ptr^.next := hashtable_ptr^.table[index];
  hashtable_ptr^.table[index] := hashtable_entry_ptr;
end; {procedure Enter_hashtable_entry}


procedure Write_hashtable(hashtable_ptr: hashtable_ptr_type);
var
  counter: integer;
  follow: hashtable_entry_ptr_type;
  temp, digits: integer;
begin
  temp := hashtable_size;
  digits := 1;
  while (temp > 10) do
    begin
      digits := digits + 1;
      temp := temp div 10;
    end;

  for counter := 1 to digits + 2 do
    write('-');
  writeln;
  for counter := 1 to hashtable_size do
    begin
      follow := hashtable_ptr^.table[counter];
      if (follow <> nil) then
        begin
          write('|', counter: digits, '|', '->');
          while (follow <> nil) do
            begin
              write(follow^.key);
              follow := follow^.next;
              if (follow <> nil) then
                write('->')
              else
                writeln('-II');
            end;
        end;
    end;
  for counter := 1 to digits + 2 do
    write('-');
  writeln;
end; {procedure Write_hashtable}


function Hashtable_entries(hashtable_ptr: hashtable_ptr_type): integer;
begin
  Hashtable_entries := hashtable_ptr^.entries;
end; {function Hashtable_entries}


{***********************************}
{ miscillaneous hashtable functions }
{***********************************}


procedure Check_hashtables;
begin
  writeln('number of free hashtables = ', Free_hashtable_number: 1);
  writeln('number of free hashtable entries = ', Free_hashtable_entry_number:
    1);
end; {procedure Check_hashtables}


procedure Dispose_hashtable_blocks(var hashtable_block_ptr:
  hashtable_block_ptr_type);
var
  temp: hashtable_block_ptr_type;
begin
  while (hashtable_block_ptr <> nil) do
    begin
      temp := hashtable_block_ptr;
      hashtable_block_ptr := hashtable_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_hashtable_blocks}


procedure Dispose_hashtable_entry_blocks(var hashtable_entry_block_ptr:
  hashtable_entry_block_ptr_type);
var
  temp: hashtable_entry_block_ptr_type;
begin
  while (hashtable_entry_block_ptr <> nil) do
    begin
      temp := hashtable_entry_block_ptr;
      hashtable_entry_block_ptr := hashtable_entry_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_hashtable_entry_blocks}


procedure Free_all_hashtables;
begin
  {***********************}
  { initialize free lists }
  {***********************}
  hashtable_free_list := nil;
  hashtable_entry_free_list := nil;

  {************************************}
  { dispose block allocation variables }
  {************************************}
  Dispose_hashtable_blocks(hashtable_block_list);
  Dispose_hashtable_entry_blocks(hashtable_entry_block_list);

  hashtable_counter := 0;
  hashtable_entry_counter := 0;
end; {procedure Free_all_hashtables}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  hashtable_free_list := nil;
  hashtable_entry_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  hashtable_block_list := nil;
  hashtable_entry_block_list := nil;

  hashtable_counter := 0;
  hashtable_entry_counter := 0;
end.
