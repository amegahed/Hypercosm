unit string_structs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           string_structs              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module implements the string functions.           }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings;


type
  {*********************}
  { string list structs }
  {*********************}
  string_list_ptr_type = ^string_list_type;
  string_list_type = record
    string_ptr: string_ptr_type;
    next: string_list_ptr_type;
  end; {string_list_type}


  {*********************}
  { string tree structs }
  {*********************}
  string_tree_ptr_type = ^string_tree_type;
  string_tree_node_ptr_type = ^string_tree_node_type;

  string_tree_node_type = record
    next: string_tree_node_ptr_type;
    case hierarchical: boolean of
      true: (
        string_tree_ptr: string_tree_ptr_type;
        );
      false: (
        string_ptr: string_ptr_type;
        );
  end; {string_tree_node_type}

  string_tree_type = record
    first, last: string_tree_node_ptr_type;
    next: string_tree_ptr_type;
  end; {string_tree_type}


{**********************}
{ string list routines }
{**********************}
procedure Add_string_to_list(string_ptr: string_ptr_type;
  var string_list_ptr: string_list_ptr_type);
procedure Free_string_list(var string_list_ptr: string_list_ptr_type);

{**********************}
{ string tree routines }
{**********************}
function New_string_tree: string_tree_ptr_type;
procedure Add_string_to_head(string_ptr: string_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
procedure Add_string_to_tail(string_ptr: string_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
procedure Add_string_tree_to_head(str_tree_ptr: string_tree_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
procedure Add_string_tree_to_tail(str_tree_ptr: string_tree_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);


implementation


const
  memory_alert = false;


{**********************}
{ string list routines }
{**********************}


function New_string_list(string_ptr: string_ptr_type): string_list_ptr_type;
var
  string_list_ptr: string_list_ptr_type;
begin
  new(string_list_ptr);
  string_list_ptr^.string_ptr := string_ptr;
  string_list_ptr^.next := nil;
  New_string_list := string_list_ptr;
end; {function New_string_list}


procedure Add_string_to_list(string_ptr: string_ptr_type;
  var string_list_ptr: string_list_ptr_type);
var
  new_string_list_ptr: string_list_ptr_type;
begin
  if string_ptr <> nil then
    begin
      new(new_string_list_ptr);
      new_string_list_ptr^.string_ptr := string_ptr;
      new_string_list_ptr^.next := string_list_ptr;
      string_list_ptr := new_string_list_ptr;
    end;
end; {procedure Add_string_to_list}


procedure Free_string_list(var string_list_ptr: string_list_ptr_type);
var
  temp: string_list_ptr_type;
begin
  while string_list_ptr <> nil do
    begin
      temp := string_list_ptr;
      string_list_ptr := string_list_ptr^.next;
      Free_string(string_list_ptr^.string_ptr);
      dispose(temp);
    end;
end; {procedure Free_string_list}


{**********************}
{ string tree routines }
{**********************}


function New_string_tree: string_tree_ptr_type;
var
  string_tree_ptr: string_tree_ptr_type;
begin
  new(string_tree_ptr);
  string_tree_ptr^.first := nil;
  string_tree_ptr^.last := nil;
  string_tree_ptr^.next := nil;
  New_string_tree := string_tree_ptr;
end; {function New_string_tree}


function New_string_tree_node: string_tree_node_ptr_type;
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  new(string_tree_node_ptr);
  string_tree_node_ptr^.hierarchical := false;
  string_tree_node_ptr^.string_ptr := nil;
  string_tree_node_ptr^.next := nil;
  New_string_tree_node := string_tree_node_ptr;
end; {function New_string_tree_node}


procedure Add_string_to_head(string_ptr: string_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  if string_ptr <> nil then
    begin
      new(string_tree_node_ptr);
      string_tree_node_ptr^.hierarchical := false;
      string_tree_node_ptr^.string_ptr := string_ptr;
      string_tree_node_ptr^.next := nil;

      if string_tree_ptr^.last <> nil then
        begin
          string_tree_node_ptr^.next := string_tree_ptr^.first;
          string_tree_ptr^.first := string_tree_node_ptr;
        end
      else
        begin
          string_tree_ptr^.first := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end;
    end;
end; {procedure Add_string_to_head}


procedure Add_string_to_tail(string_ptr: string_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  if string_ptr <> nil then
    begin
      new(string_tree_node_ptr);
      string_tree_node_ptr^.hierarchical := false;
      string_tree_node_ptr^.string_ptr := string_ptr;
      string_tree_node_ptr^.next := nil;

      if string_tree_ptr^.last <> nil then
        begin
          string_tree_ptr^.last^.next := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end
      else
        begin
          string_tree_ptr^.first := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end;
    end;
end; {procedure Add_string_to_tail}


procedure Add_string_tree_to_head(str_tree_ptr: string_tree_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  if str_tree_ptr <> nil then
    begin
      new(string_tree_node_ptr);
      string_tree_node_ptr^.hierarchical := true;
      string_tree_node_ptr^.string_tree_ptr := str_tree_ptr;

      if string_tree_ptr^.last <> nil then
        begin
          string_tree_node_ptr^.next := string_tree_ptr^.first;
          string_tree_ptr^.first := string_tree_node_ptr;
        end
      else
        begin
          string_tree_ptr^.first := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end;
    end;
end; {procedure Add_string_tree_to_head}


procedure Add_string_tree_to_tail(str_tree_ptr: string_tree_ptr_type;
  var string_tree_ptr: string_tree_ptr_type);
var
  string_tree_node_ptr: string_tree_node_ptr_type;
begin
  if str_tree_ptr <> nil then
    begin
      new(string_tree_node_ptr);
      string_tree_node_ptr^.hierarchical := true;
      string_tree_node_ptr^.string_tree_ptr := str_tree_ptr;

      if string_tree_ptr^.last <> nil then
        begin
          string_tree_ptr^.last^.next := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end
      else
        begin
          string_tree_ptr^.first := string_tree_node_ptr;
          string_tree_ptr^.last := string_tree_node_ptr;
        end;
    end;
end; {procedure Add_string_tree_to_tail}


end.
