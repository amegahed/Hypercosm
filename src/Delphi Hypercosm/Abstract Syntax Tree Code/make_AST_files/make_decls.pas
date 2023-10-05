unit make_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             make_decls                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on the declaration syntax trees.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, decls;


{****************************************************}
{ routines for recursively copying declaration trees }
{****************************************************}
function Clone_decl(decl_ptr: decl_ptr_type;
  copy_attributes: boolean): decl_ptr_type;
function Clone_decls(decl_ptr: decl_ptr_type;
  copy_attributes: boolean): decl_ptr_type;

{****************************************************}
{ routines for recursively freeing declaration trees }
{****************************************************}
procedure Destroy_decl(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
procedure Destroy_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);

{****************************************************}
{ routines for recursively marking declaration trees }
{****************************************************}
procedure Mark_decl(decl_ptr: decl_ptr_type;
  touched: boolean);
procedure Mark_decls(decl_ptr: decl_ptr_type;
  touched: boolean);
procedure Mark_native_decl(decl_ptr: decl_ptr_type;
  touched: boolean);
procedure Mark_native_decls(decl_ptr: decl_ptr_type;
  touched: boolean);
procedure Mark_decl_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  touched: boolean);
procedure Mark_decls_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  touched: boolean);

{******************************************************}
{ routines for recursively comparing declaration trees }
{******************************************************}
function Equal_decls(decl_ptr1, decl_ptr2: decl_ptr_type): boolean;
function Same_decls(decl_ptr1, decl_ptr2: decl_ptr_type): boolean;


implementation
uses
  code_decls, type_decls, make_exprs, make_stmts, make_type_decls,
  make_code_decls;


const
  verbose = false;


  {****************************************************}
  { routines for recursively copying declaration trees }
  {****************************************************}


function Clone_data_decl(data_decl: data_decl_type;
  copy_attributes: boolean): data_decl_type;
var
  data_decl2: data_decl_type;
begin
  data_decl2.data_expr_ptr := Clone_expr(data_decl.data_expr_ptr,
    copy_attributes);
  data_decl2.init_expr_ptr := Clone_expr(data_decl.init_expr_ptr,
    copy_attributes);
  data_decl2.init_stmt_ptr := Clone_stmt(data_decl.init_stmt_ptr,
    copy_attributes);

  Clone_data_decl := data_decl2;
end; {procedure Clone_data_decl}


function Clone_decl(decl_ptr: decl_ptr_type;
  copy_attributes: boolean): decl_ptr_type;
var
  new_decl_ptr: decl_ptr_type;
begin
  if (decl_ptr <> nil) then
    begin
      new_decl_ptr := Copy_decl(decl_ptr);

      {***************************}
      { copy auxilliary decl info }
      {***************************}
      if decl_ptr^.decl_info_ptr <> nil then
        begin
          new_decl_ptr^.decl_info_ptr := Copy_decl_info(decl_ptr^.decl_info_ptr,
            copy_attributes);
          Set_decl_info(new_decl_ptr, new_decl_ptr^.decl_info_ptr);
        end;

      with new_decl_ptr^ do
        case kind of

          {*************************}
          { null or nop declaration }
          {*************************}
          null_decl:
            ;

          {********************************}
          { user defined type declarations }
          {********************************}
          type_decl:
            type_ptr :=
              forward_type_ptr_type(Clone_type(type_ptr_type(type_ptr),
              copy_attributes));

          {*******************}
          { data declarations }
          {*******************}
          boolean_decl..reference_decl:
            data_decl := Clone_data_decl(data_decl, copy_attributes);

          {*************************}
          { subprogram declarations }
          {*************************}
          code_decl..code_reference_decl:
            begin
              code_data_decl := Clone_data_decl(code_data_decl,
                copy_attributes);
              code_ptr :=
                forward_code_ptr_type(Clone_code(code_ptr_type(code_ptr),
                copy_attributes));
            end;

        end; {case}
    end
  else
    new_decl_ptr := nil;

  Clone_decl := new_decl_ptr;
end; {function Clone_decl}


function Clone_decls(decl_ptr: decl_ptr_type;
  copy_attributes: boolean): decl_ptr_type;
var
  new_decl_ptr: decl_ptr_type;
  first_decl_ptr, last_decl_ptr: decl_ptr_type;
begin
  first_decl_ptr := nil;
  last_decl_ptr := nil;

  while decl_ptr <> nil do
    begin
      new_decl_ptr := Clone_decl(decl_ptr, copy_attributes);

      {**********************************}
      { add new decl node to end of list }
      {**********************************}
      if (last_decl_ptr <> nil) then
        begin
          last_decl_ptr^.next := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end
      else
        begin
          first_decl_ptr := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end;

      decl_ptr := decl_ptr^.next;
    end;

  Clone_decls := first_decl_ptr;
end; {function Clone_decls}


{****************************************************}
{ routines for recursively freeing declaration trees }
{****************************************************}


procedure Destroy_data_decl(var data_decl: data_decl_type;
  free_attributes: boolean);
begin
  with data_decl do
    begin
      Destroy_expr(data_expr_ptr, free_attributes);
      Destroy_expr(init_expr_ptr, free_attributes);
      Destroy_stmt(init_stmt_ptr, free_attributes);
    end;
end; {procedure Destroy_data_decl}


procedure Destroy_decl(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
begin
  if (decl_ptr <> nil) then
    begin
      {*****************************************}
      { free auxilliary declaration information }
      {*****************************************}
      Free_decl_info(decl_ptr^.decl_info_ptr, free_attributes);

      with decl_ptr^ do
        case kind of

          {*************************}
          { null or nop declaration }
          {*************************}
          null_decl:
            ;

          {********************************}
          { user defined type declarations }
          {********************************}
          type_decl:
            Destroy_type(type_ptr_type(type_ptr), free_attributes);

          {*******************}
          { data declarations }
          {*******************}
          boolean_decl..reference_decl:
            Destroy_data_decl(data_decl, free_attributes);

          {*************************}
          { subprogram declarations }
          {*************************}
          code_decl..code_reference_decl:
            begin
              Destroy_data_decl(code_data_decl, free_attributes);
              Destroy_code(code_ptr_type(code_ptr), free_attributes);
            end;

        end; {case}

      {***********************}
      { add decl to free list }
      {***********************}
      Free_decl(decl_ptr);
    end;
end; {procedure Destroy_decl}


procedure Destroy_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
var
  temp: decl_ptr_type;
begin
  while (decl_ptr <> nil) do
    begin
      temp := decl_ptr;
      decl_ptr := decl_ptr^.next;
      Destroy_decl(temp, free_attributes);
    end;
end; {procedure Destroy_decls}


{****************************************************}
{ routines for recursively marking declaration trees }
{****************************************************}


procedure Mark_data_decl(data_decl: data_decl_type;
  touched: boolean);
begin
  with data_decl do
    begin
      Mark_expr(data_expr_ptr, touched);
      Mark_expr(init_expr_ptr, touched);
      Mark_stmt(init_stmt_ptr, touched);
    end;
end; {procedure Mark_data_decl}


procedure Mark_decl(decl_ptr: decl_ptr_type;
  touched: boolean);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if (decl_ptr <> nil) then
    if decl_ptr^.kind <> null_decl then
      begin
        decl_attributes_ptr := Get_decl_attributes(decl_ptr);
        if decl_attributes_ptr <> nil then
          if decl_attributes_ptr^.used <> touched then
            begin
              if verbose then
                writeln('marking ',
                  Get_decl_attributes_name(decl_attributes_ptr));
              Mark_decl_attributes(decl_attributes_ptr, touched);

              with decl_ptr^ do
                case kind of

                  {********************************}
                  { user defined type declarations }
                  {********************************}
                  type_decl:
                    Mark_type(type_ptr_type(type_ptr), touched);

                  {*******************}
                  { data declarations }
                  {*******************}
                  boolean_decl..reference_decl:
                    Mark_data_decl(data_decl, touched);

                  {*************************}
                  { subprogram declarations }
                  {*************************}
                  code_decl..code_reference_decl:
                    begin
                      Mark_data_decl(code_data_decl, touched);
                      Mark_code(code_ptr_type(code_ptr), touched);
                    end;

                end; {case}

            end; {if used <> touched}
      end; {if kind <> null_decl}
end; {procedure Mark_decl}


procedure Mark_decls(decl_ptr: decl_ptr_type;
  touched: boolean);
begin
  while (decl_ptr <> nil) do
    begin
      Mark_decl(decl_ptr, touched);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Mark_decls}


{***************************************************************}
{ routines for marking native declarations and associated nodes }
{***************************************************************}


procedure Mark_native_decl(decl_ptr: decl_ptr_type;
  touched: boolean);
begin
  if (decl_ptr <> nil) then
    with decl_ptr^ do
      if kind <> null_decl then
        begin
          if Get_decl_attributes(decl_ptr)^.native then
            Mark_decl(decl_ptr, touched);
        end;
end; {procedure Mark_native_decl}


procedure Mark_native_decls(decl_ptr: decl_ptr_type;
  touched: boolean);
begin
  while (decl_ptr <> nil) do
    begin
      Mark_native_decl(decl_ptr, touched);
      decl_ptr := decl_ptr^.next;
    end;
end; {procedure Mark_native_decls}


{*********************************************}
{ routines for marking declaration attributes }
{*********************************************}


procedure Mark_decl_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  touched: boolean);
begin
  decl_attributes_ptr^.used := touched;
  if decl_attributes_ptr^.scope_decl_attributes_ptr <> nil then
    Mark_decl(decl_ptr_type(decl_attributes_ptr^.scope_decl_attributes_ptr^.decl_ref), touched);
end; {procedure Mark_decl_attributes}


procedure Mark_decls_attributes(decl_attributes_ptr: decl_attributes_ptr_type;
  touched: boolean);
begin
  while decl_attributes_ptr <> nil do
    begin
      if verbose then
        begin
          write('marking ', Get_decl_attributes_name(decl_attributes_ptr));
          if decl_attributes_ptr^.kind = type_decl_attributes then
            write(' type ');
          write(' as ');
          if touched then
            writeln('touched.')
          else
            writeln('untouched.');
        end;

      decl_attributes_ptr^.used := touched;
      decl_attributes_ptr := decl_attributes_ptr^.next;
    end;
end; {procedure Mark_decls_attributes}


{******************************************************}
{ routines for recursively comparing declaration trees }
{******************************************************}


function Equal_decls(decl_ptr1, decl_ptr2: decl_ptr_type): boolean;
begin
  Equal_decls := decl_ptr1 = decl_ptr2;
end; {function Equal_decls}


function Same_decls(decl_ptr1, decl_ptr2: decl_ptr_type): boolean;
begin
  Same_decls := decl_ptr1 = decl_ptr2;
end; {function Same_decls}


end.
