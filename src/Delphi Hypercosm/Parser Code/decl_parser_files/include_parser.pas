unit include_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           include_parser              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse include          }
{       directives into an abstract syntax tree                 }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, find_files, syntax_trees;


var
  system_path_ptr: search_path_ptr_type;


{****************************}
{ routines to parse includes }
{****************************}
procedure Parse_include(var syntax_tree_ptr: syntax_tree_ptr_type);
procedure Parse_includes(var syntax_tree_ptr: syntax_tree_ptr_type);
procedure Parse_include_file(var syntax_tree_ptr: syntax_tree_ptr_type;
  file_name: string_type;
  optional: boolean);

{*********************************}
{ routines to parse include lists }
{*********************************}
procedure Parse_include_list(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);
procedure Parse_includes_list(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);
procedure Parse_more_includes(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);


implementation
uses
  file_stack, hashtables, decls, type_decls, scanner, tokens,
  tokenizer, parser, match_literals, comment_parser, decl_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                          declarations                         }
{***************************************************************}
{       <decl> ::= <include>                                    }
{                                                               }
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}


{***************************************************************}
{                            includes                           }
{***************************************************************}
{       <include> ::= include <file_names> ;                    }
{       <file_names> ::= <file_name> <more_file_names>          }
{       <more_file_names> ::= , <file_name> <more_file_names>   }
{       <more_file_names> ::=                                   }
{       <file_name> ::= string_lit                              }
{***************************************************************}


{****************************}
{ routines to parse includes }
{****************************}


procedure Parse_include(var syntax_tree_ptr: syntax_tree_ptr_type);
var
  last_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  Parse_include_list(syntax_tree_ptr, last_syntax_tree_ptr);
end; {procedure Parse_include}


procedure Parse_includes(var syntax_tree_ptr: syntax_tree_ptr_type);
var
  last_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  Parse_includes_list(syntax_tree_ptr, last_syntax_tree_ptr);
end; {procedure Parse_includes}


procedure Parse_include_file(var syntax_tree_ptr: syntax_tree_ptr_type;
  file_name: string_type;
  optional: boolean);
var
  include_path_ptr: search_path_ptr_type;
  last_file_index: hashtable_value_type;
  directory_name: string_type;
begin
  syntax_tree_ptr := nil;

  if Left_str(file_name, 7) = 'system/' then
    begin
      include_path_ptr := system_path_ptr;
      file_name := Right_str(file_name, Str_length(file_name) - 7);
    end
  else
    include_path_ptr := search_path_ptr;

  if parsing_ok then
    begin
      if not Found_include(file_name) then
        begin
          {************************************}
          { file has not already been included }
          {************************************}
          Push_scanner_state;
          Push_tokenizer_state;

          if not Found_file_in_search_path(file_name, include_path_ptr,
            directory_name) then
            begin
              {****************}
              { file not found }
              {****************}
              Parse_error;
              writeln('The file, ', Quotate_str(file_name),
                ', could not be found.');
              error_reported := true;
            end
          else if Open_next_file(directory_name + file_name) then
            begin
              writeln('Reading ', Quotate_str(file_name), '.');
              Get_next_token;

              {**********************}
              { add to include table }
              {**********************}
              include_file_count := Add_include(file_name);

              {***************************}
              { Parse past header section }
              {***************************}
              if (next_token.kind = do_tok) then
                begin
                  Get_next_token;
                  while (next_token.kind = id_tok) do
                    begin
                      Get_next_token;
                      if (next_token.kind <> semi_colon_tok) then
                        Match(comma_tok);
                    end;
                  Match(semi_colon_tok);
                end;

              if parsing_ok then
                begin
                  {********************************}
                  { create new include syntax tree }
                  {********************************}
                  syntax_tree_ptr := New_syntax_tree(include_tree);
                  syntax_tree_ptr^.include_index := include_file_count;

                  last_file_index := current_file_index;
                  current_file_index := include_file_count;

                  Parse_includes(syntax_tree_ptr^.includes_ptr);
                  Parse_decls(syntax_tree_ptr^.include_decls_ptr, nil);
                  current_file_index := last_file_index;
                end;

              Match(eof_tok);
              Close_current_file;
            end
          else if not optional then
            begin
              {****************}
              { file not found }
              {****************}
              Parse_error;
              writeln('The file, ', Quotate_str(file_name),
                ', could not be opened.');
              error_reported := true;
            end;

          Pop_scanner_state;
          Pop_tokenizer_state;
        end; {if not already included}
    end; {if parsing_ok}
end; {procedure Parse_include_file}


procedure Parse_include_name(var syntax_tree_ptr: syntax_tree_ptr_type);
var
  file_name: string_type;
begin
  if parsing_ok then
    if next_token.kind = string_lit_tok then
      begin
        file_name := String_to_str(next_token.string_ptr);
        Get_next_token;
        Parse_include_file(syntax_tree_ptr, file_name, false);
      end
    else
      begin
        Parse_error;
        writeln('Expected a file name here.');
        error_reported := true;
      end;
end; {procedure Parse_include_name}


{*********************************}
{ routines to parse include lists }
{*********************************}


{************************  productions  ************************}
{       <include> ::= include <file_names> ;                    }
{       <file_names> ::= <file_name> <more_file_names>          }
{       <more_file_names> ::= , <file_name> <more_file_names>   }
{       <more_file_names> ::=                                   }
{       <file_name> ::= string_lit                              }
{***************************************************************}

procedure Parse_include_list(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);
begin
  syntax_tree_ptr := nil;
  last_syntax_tree_ptr := nil;

  if next_token.kind = include_tok then
    begin
      Get_next_token;
      Parse_include_name(syntax_tree_ptr);
      last_syntax_tree_ptr := syntax_tree_ptr;

      while (next_token.kind = comma_tok) do
        begin
          Get_next_token;
          Parse_include_name(last_syntax_tree_ptr^.next);
          last_syntax_tree_ptr := last_syntax_tree_ptr^.next;
        end;

      Match(semi_colon_tok);
    end;
end; {procedure Parse_include_list}


procedure Parse_includes_list(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);
begin
  syntax_tree_ptr := nil;
  last_syntax_tree_ptr := nil;

  if parsing_ok then
    begin
      Parse_include_list(syntax_tree_ptr, last_syntax_tree_ptr);
      Parse_more_includes(syntax_tree_ptr, last_syntax_tree_ptr);
    end;
end; {procedure Parse_includes_list}


procedure Parse_more_includes(var syntax_tree_ptr, last_syntax_tree_ptr:
  syntax_tree_ptr_type);
var
  new_last_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  if next_token.kind = include_tok then
    begin
      if last_syntax_tree_ptr <> nil then
        begin
          Parse_includes_list(last_syntax_tree_ptr^.next,
            new_last_syntax_tree_ptr);
          if new_last_syntax_tree_ptr <> nil then
            last_syntax_tree_ptr := new_last_syntax_tree_ptr;
        end
      else
        Parse_includes_list(syntax_tree_ptr, last_syntax_tree_ptr);
    end;
end; {procedure Parse_more_includes}


initialization
  system_path_ptr := nil;
end.

