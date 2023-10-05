unit make_code_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           make_code_decls             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on code declaration syntax trees.         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  code_decls;


{*********************************************************}
{ routines for recursively copying code declaration trees }
{*********************************************************}
function Clone_code(code_ptr: code_ptr_type;
  copy_attributes: boolean): code_ptr_type;
function Clone_codes(code_ptr: code_ptr_type;
  copy_attributes: boolean): code_ptr_type;

{*********************************************************}
{ routines for recursively freeing code declaration trees }
{*********************************************************}
procedure Destroy_code(var code_ptr: code_ptr_type;
  free_attributes: boolean);
procedure Destroy_codes(var code_ptr: code_ptr_type;
  free_attributes: boolean);

{*********************************************************}
{ routines for recursively marking code declaration trees }
{*********************************************************}
procedure Mark_code(code_ptr: code_ptr_type;
  touched: boolean);
procedure Mark_codes(code_ptr: code_ptr_type;
  touched: boolean);
procedure Mark_code_decl(code_ptr: code_ptr_type;
  touched: boolean);
procedure Mark_code_decls(code_ptr: code_ptr_type;
  touched: boolean);

{***********************************************************}
{ routines for recursively comparing code declaration trees }
{***********************************************************}
function Equal_codes(code_ptr1, code_ptr2: code_ptr_type): boolean;
function Same_codes(code_ptr1, code_ptr2: code_ptr_type): boolean;


implementation
uses
  decls, type_decls, make_stmts, make_decls, make_type_decls;


{*********************************************************}
{ routines for recursively copying code declaration trees }
{*********************************************************}


function Clone_code(code_ptr: code_ptr_type;
  copy_attributes: boolean): code_ptr_type;
var
  new_code_ptr: code_ptr_type;
begin
  if (code_ptr <> nil) then
    begin
      new_code_ptr := Copy_code(code_ptr);

      with new_code_ptr^ do
        begin
          {********************}
          { initial parameters }
          {********************}
          implicit_param_decls_ptr := Clone_decls(implicit_param_decls_ptr,
            copy_attributes);
          initial_param_decls_ptr := Clone_decls(initial_param_decls_ptr,
            copy_attributes);

          {*********************}
          { optional parameters }
          {*********************}
          optional_param_decls_ptr := Clone_decls(optional_param_decls_ptr,
            copy_attributes);
          optional_param_stmts_ptr := Clone_stmts(optional_param_stmts_ptr,
            copy_attributes);

          {*******************}
          { return parameters }
          {*******************}
          return_param_decls_ptr := Clone_decls(return_param_decls_ptr,
            copy_attributes);
          param_free_stmts_ptr := Clone_stmts(param_free_stmts_ptr,
            copy_attributes);

          {****************}
          { implementation }
          {****************}
          if code_ptr^.decl_kind = actual_decl then
            begin
              local_decls_ptr := Clone_decls(local_decls_ptr, copy_attributes);
              local_stmts_ptr := Clone_stmts(local_stmts_ptr, copy_attributes);
            end;
        end;
    end
  else
    new_code_ptr := nil;

  Clone_code := new_code_ptr;
end; {function Clone_code}


function Clone_codes(code_ptr: code_ptr_type;
  copy_attributes: boolean): code_ptr_type;
var
  new_code_ptr: code_ptr_type;
  first_code_ptr, last_code_ptr: code_ptr_type;
begin
  first_code_ptr := nil;
  last_code_ptr := nil;

  while code_ptr <> nil do
    begin
      new_code_ptr := Clone_code(code_ptr, copy_attributes);

      {**********************************}
      { add new code node to end of list }
      {**********************************}
      if (last_code_ptr <> nil) then
        begin
          last_code_ptr^.next := new_code_ptr;
          last_code_ptr := new_code_ptr;
        end
      else
        begin
          first_code_ptr := new_code_ptr;
          last_code_ptr := new_code_ptr;
        end;

      code_ptr := code_ptr^.next;
    end;

  Clone_codes := first_code_ptr;
end; {function Clone_codes}


{*********************************************************}
{ routines for recursively freeing code declaration trees }
{*********************************************************}


procedure Destroy_code(var code_ptr: code_ptr_type;
  free_attributes: boolean);
begin
  if (code_ptr <> nil) then
    begin
      with code_ptr^ do
        begin
          {********************}
          { initial parameters }
          {********************}
          Destroy_decls(implicit_param_decls_ptr, free_attributes);
          Destroy_decls(initial_param_decls_ptr, free_attributes);

          {*********************}
          { optional parameters }
          {*********************}
          Destroy_decls(optional_param_decls_ptr, free_attributes);
          Destroy_stmts(optional_param_stmts_ptr, free_attributes);

          {*******************}
          { return parameters }
          {*******************}
          Destroy_decls(return_param_decls_ptr, free_attributes);
          Destroy_stmts(param_free_stmts_ptr, free_attributes);

          {****************}
          { implementation }
          {****************}
          if code_ptr^.decl_kind = actual_decl then
            begin
              Destroy_decls(local_decls_ptr, free_attributes);
              Destroy_stmts(local_stmts_ptr, free_attributes);
            end;
        end;

      {***********************}
      { add code to free list }
      {***********************}
      Free_code(code_ptr);
    end;
end; {procedure Destroy_code}


procedure Destroy_codes(var code_ptr: code_ptr_type;
  free_attributes: boolean);
var
  temp: code_ptr_type;
begin
  while (code_ptr <> nil) do
    begin
      temp := code_ptr;
      code_ptr := code_ptr^.next;
      Destroy_code(temp, free_attributes);
    end;
end; {procedure Destroy_codes}


{*********************************************************}
{ routines for recursively marking code declaration trees }
{*********************************************************}


procedure Mark_code(code_ptr: code_ptr_type;
  touched: boolean);
begin
  if (code_ptr <> nil) then
    with code_ptr^ do
      begin
        {********************}
        { initial parameters }
        {********************}
        Mark_decls(implicit_param_decls_ptr, touched);
        Mark_decls(initial_param_decls_ptr, touched);

        {*********************}
        { optional parameters }
        {*********************}
        Mark_decls(optional_param_decls_ptr, touched);
        Mark_stmts(optional_param_stmts_ptr, touched);

        {*******************}
        { return parameters }
        {*******************}
        Mark_decls(return_param_decls_ptr, touched);
        Mark_stmts(param_free_stmts_ptr, touched);

        {****************}
        { implementation }
        {****************}
        Mark_decls(local_decls_ptr, touched);
        Mark_stmts(local_stmts_ptr, touched);

        {************************}
        { declaration references }
        {************************}
        Mark_type(type_ptr_type(class_type_ref), touched);
      end;
end; {procedure Mark_code}


procedure Mark_codes(code_ptr: code_ptr_type;
  touched: boolean);
begin
  while (code_ptr <> nil) do
    begin
      Mark_code(code_ptr, touched);
      code_ptr := code_ptr^.next;
    end;
end; {procedure Mark_codes}


procedure Mark_code_decl(code_ptr: code_ptr_type;
  touched: boolean);
var
  decl_ptr: decl_ptr_type;
begin
  if (code_ptr <> nil) then
    begin
      decl_ptr := decl_ptr_type(code_ptr^.code_decl_ref);
      Mark_decl(decl_ptr, touched);
    end;
end; {procedure Mark_code_decl}


procedure Mark_code_decls(code_ptr: code_ptr_type;
  touched: boolean);
begin
  while (code_ptr <> nil) do
    begin
      Mark_code_decl(code_ptr, touched);
      code_ptr := code_ptr^.next;
    end;
end; {procedure Mark_code_decls}


{***********************************************************}
{ routines for recursively comparing code declaration trees }
{***********************************************************}


function Equal_codes(code_ptr1, code_ptr2: code_ptr_type): boolean;
begin
  Equal_codes := code_ptr1 = code_ptr2;
end; {function Equal_codes}


function Same_codes(code_ptr1, code_ptr2: code_ptr_type): boolean;
begin
  Same_codes := code_ptr1 = code_ptr2;
end; {function Same_codes}


end.
