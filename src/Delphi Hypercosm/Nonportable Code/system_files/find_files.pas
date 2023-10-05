unit find_files;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            find_files                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides platform independent support  	}
{	for searching directories for files.			}
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings, string_structs;


type
  search_path_ptr_type = string_list_ptr_type;


var
  search_path_ptr: search_path_ptr_type;


{**********************************************}
{ routines to store and construct search paths }
{**********************************************}
procedure Add_path_to_search_path(path: string_type;
  var search_path_ptr: search_path_ptr_type);
procedure Free_search_path(var search_path_ptr: search_path_ptr_type);

{****************************************}
{ routines for manipulating path strings }
{****************************************}
function Get_path_of_file(file_name: string_type): string_type;
function Get_file_name_from_path(path: string_type): string_type;

{****************************************************}
{ routine to find a file in a particular search path }
{****************************************************}
function Found_file_in_directory(file_name: string_type;
  var directory_name: string_type): boolean;
function Found_file_in_directory_tree(file_name: string_type;
  var directory_name: string_type): boolean;
function Found_file_in_search_path(file_name: string_type; search_path_ptr:
  search_path_ptr_type; var directory_name: string_type): boolean;


implementation
uses
  SysUtils;


const
  forward_slash_char = '/';
  backslash_char = '\';
  slash_chars = [backslash_char, forward_slash_char];


{**********************************************}
{ routines to store and construct search paths }
{**********************************************}


procedure Add_path_to_search_path(path: string_type;
  var search_path_ptr: search_path_ptr_type);
begin
  if path <> '' then
    Add_string_to_list(Str_to_string(path), search_path_ptr);
end; {procedure Add_to_search_path}


procedure Free_search_path(var search_path_ptr: search_path_ptr_type);
begin
  Free_string_list(search_path_ptr);
end; {procedure Free_search_path}


{****************************************}
{ routines for manipulating path strings }
{****************************************}


function Get_path_of_file(file_name: string_type): string_type;
var
  counter: integer;
  found: boolean;
begin
  counter := Str_length(file_name);
  found := false;
  while (counter > 0) and not found do
    begin
      if file_name[counter] in slash_chars then
        found := true
      else
        counter := counter - 1;
    end;

  Get_path_of_file := Left_str(file_name, counter);
end; {function Get_path_of_file}


function Get_file_name_from_path(path: string_type): string_type;
var
  counter: integer;
  found: boolean;
begin
  counter := Str_length(path);
  found := false;
  while (counter > 0) and not found do
    begin
      if path[counter] in slash_chars then
        found := true
      else
        counter := counter - 1;
    end;

  Get_file_name_from_path := Right_str(path, Str_length(path) - counter);
end; {function Get_file_name_from_path}


{****************************************************}
{ routine to find a file in a particular search path }
{****************************************************}


function Found_file_in_directory(file_name: string_type;
  var directory_name: string_type): boolean;
var
  found: boolean;
begin
  if directory_name = '' then
    directory_name := '.';

  if directory_name[Str_length(directory_name)] <> backslash_char then
    directory_name := directory_name + backslash_char;

  file_name := directory_name + file_name;
  found := FileExists(file_name);

  Found_file_in_directory := found;
end; {function Found_file_in_directory}


function Found_file_in_directory_tree(file_name: string_type;
  var directory_name: string_type): boolean;
var
  found, done, searched: boolean;
  subdirectory_name: string_type;
  SearchRec: TSearchRec;
  errors: integer;
begin
  if directory_name = '' then
    directory_name := '.';

  // first, look for file in root level of directory
  //
  found := Found_file_in_directory(file_name, directory_name);

  // if not found, then look in subdirectories
  //
  if not found then
    begin
      if directory_name[Str_length(directory_name)] <> backslash_char then
        directory_name := directory_name + backslash_char;

      done := false;
      searched := false;
      while not done and not found do
        begin
          subdirectory_name := directory_name + '*';
          if not searched then
            begin
              errors := FindFirst(subdirectory_name, faDirectory, SearchRec);
              searched := true;
            end
          else
            errors := FindNext(SearchRec);

          if errors = 0 then
            begin
              if SearchRec.Attr = faDirectory then
                if SearchRec.name <> subdirectory_name then
                  if SearchRec.Name <> '.' then
                    if SearchRec.Name <> '..' then
                      begin
                        subdirectory_name := directory_name + SearchRec.Name;
                        found := Found_file_in_directory_tree(file_name,
                          subdirectory_name);
                        if found then
                          directory_name := subdirectory_name;
                      end;
            end
          else
            done := true;
        end;

      FindClose(SearchRec);
    end;

  Found_file_in_directory_tree := found;
end; {function Found_file_in_directory_tree}


function Found_file_in_search_path(file_name: string_type; search_path_ptr:
  search_path_ptr_type; var directory_name: string_type): boolean;
var
  found: boolean;
  follow: search_path_ptr_type;
begin
  found := false;

  // search for file in the specified directory
  //
  follow := search_path_ptr;
  while (follow <> nil) and not found do
    begin
      directory_name := String_to_str(follow^.string_ptr);
      found := Found_file_in_directory_tree(file_name, directory_name);

      if not found then
        follow := follow^.next;
    end;

  Found_file_in_search_path := found;
end; {procedure Found_file_in_search_path}


initialization
  search_path_ptr := nil;
  // Add_path_to_search_path('.', search_path_ptr);
end.

