unit make_syntax_trees;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          make_syntax_trees            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on syntax trees.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


{***********************************************}
{ routines for recursively copying syntax trees }
{***********************************************}
function Clone_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  copy_attributes: boolean): syntax_tree_ptr_type;
function Clone_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  copy_attributes: boolean): syntax_tree_ptr_type;

{***********************************************}
{ routines for recursively freeing syntax trees }
{***********************************************}
procedure Destroy_syntax_tree(var syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);
procedure Destroy_syntax_trees(var syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);

{***********************************************}
{ routines for recursively marking syntax trees }
{***********************************************}
procedure Mark_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
procedure Mark_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
procedure Mark_native_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
procedure Mark_native_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);

{*************************************************}
{ routines for recursively comparing syntax trees }
{*************************************************}
function Equal_syntax_trees(syntax_tree_ptr1, syntax_tree_ptr2:
  syntax_tree_ptr_type): boolean;
function Same_syntax_trees(syntax_tree_ptr1, syntax_tree_ptr2:
  syntax_tree_ptr_type): boolean;


implementation
uses
  make_stmts, make_decls;


{***********************************************}
{ routines for recursively copying syntax trees }
{***********************************************}


function Clone_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  copy_attributes: boolean): syntax_tree_ptr_type;
var
  new_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  if (syntax_tree_ptr <> nil) then
    begin
      new_syntax_tree_ptr := Copy_syntax_tree(syntax_tree_ptr);

      with new_syntax_tree_ptr^ do
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              implicit_decls_ptr := Clone_decls(implicit_decls_ptr,
                copy_attributes);
              implicit_includes_ptr := Clone_syntax_trees(implicit_includes_ptr,
                copy_attributes);
              root_includes_ptr := Clone_syntax_trees(root_includes_ptr,
                copy_attributes);
              decls_ptr := Clone_decls(decls_ptr, copy_attributes);
              stmts_ptr := Clone_stmts(stmts_ptr, copy_attributes);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              includes_ptr := Clone_syntax_trees(includes_ptr, copy_attributes);
              include_decls_ptr := Clone_decls(include_decls_ptr,
                copy_attributes);
            end;

        end; {case}
    end
  else
    new_syntax_tree_ptr := nil;

  Clone_syntax_tree := new_syntax_tree_ptr;
end; {function Clone_syntax_tree}


function Clone_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  copy_attributes: boolean): syntax_tree_ptr_type;
var
  new_syntax_tree_ptr: syntax_tree_ptr_type;
  first_syntax_tree_ptr, last_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  first_syntax_tree_ptr := nil;
  last_syntax_tree_ptr := nil;

  while syntax_tree_ptr <> nil do
    begin
      new_syntax_tree_ptr := Clone_syntax_tree(syntax_tree_ptr,
        copy_attributes);

      {*****************************************}
      { add new syntax tree node to end of list }
      {*****************************************}
      if (last_syntax_tree_ptr <> nil) then
        begin
          last_syntax_tree_ptr^.next := new_syntax_tree_ptr;
          last_syntax_tree_ptr := new_syntax_tree_ptr;
        end
      else
        begin
          first_syntax_tree_ptr := new_syntax_tree_ptr;
          last_syntax_tree_ptr := new_syntax_tree_ptr;
        end;

      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;

  Clone_syntax_trees := first_syntax_tree_ptr;
end; {function Clone_syntax_trees}


{***********************************************}
{ routines for recursively freeing syntax trees }
{***********************************************}


procedure Destroy_syntax_tree(var syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);
begin
  if (syntax_tree_ptr <> nil) then
    begin
      with syntax_tree_ptr^ do
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              Destroy_decls(implicit_decls_ptr, free_attributes);
              Destroy_syntax_trees(implicit_includes_ptr, free_attributes);
              Destroy_syntax_trees(root_includes_ptr, free_attributes);
              Destroy_decls(decls_ptr, free_attributes);
              Destroy_stmts(stmts_ptr, free_attributes);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              Destroy_syntax_trees(includes_ptr, free_attributes);
              Destroy_decls(include_decls_ptr, free_attributes);
            end;

        end; {case}

      {******************************}
      { add syntax tree to free list }
      {******************************}
      Free_syntax_tree(syntax_tree_ptr);
    end;
end; {procedure Destroy_syntax_tree}


procedure Destroy_syntax_trees(var syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);
var
  temp: syntax_tree_ptr_type;
begin
  while (syntax_tree_ptr <> nil) do
    begin
      temp := syntax_tree_ptr;
      syntax_tree_ptr := syntax_tree_ptr^.next;
      Destroy_syntax_tree(temp, free_attributes);
    end;
end; {procedure Destroy_syntax_trees}


{***********************************************}
{ routines for recursively marking syntax trees }
{***********************************************}


procedure Mark_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
begin
  if (syntax_tree_ptr <> nil) then
    begin
      with syntax_tree_ptr^ do
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              Mark_decls(implicit_decls_ptr, touched);
              Mark_syntax_trees(implicit_includes_ptr, touched);
              Mark_syntax_trees(root_includes_ptr, touched);
              Mark_decls(decls_ptr, touched);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              Mark_syntax_trees(includes_ptr, touched);
              Mark_decls(include_decls_ptr, touched);
            end;

        end; {case}
    end; {if}
end; {procedure Mark_syntax_tree}


procedure Mark_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
begin
  while (syntax_tree_ptr <> nil) do
    begin
      Mark_syntax_tree(syntax_tree_ptr, touched);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Mark_syntax_trees}


procedure Mark_native_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
begin
  if (syntax_tree_ptr <> nil) then
    begin
      with syntax_tree_ptr^ do
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              Mark_native_decls(implicit_decls_ptr, touched);
              Mark_native_syntax_trees(implicit_includes_ptr, touched);
              Mark_native_syntax_trees(root_includes_ptr, touched);
              Mark_native_decls(decls_ptr, touched);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              Mark_native_syntax_trees(includes_ptr, touched);
              Mark_native_decls(include_decls_ptr, touched);
            end;

        end; {case}
    end;
end; {procedure Mark_native_syntax_tree}


procedure Mark_native_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type;
  touched: boolean);
begin
  while (syntax_tree_ptr <> nil) do
    begin
      Mark_native_syntax_tree(syntax_tree_ptr, touched);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Mark_native_syntax_trees}


{*************************************************}
{ routines for recursively comparing syntax trees }
{*************************************************}


function Equal_syntax_trees(syntax_tree_ptr1, syntax_tree_ptr2:
  syntax_tree_ptr_type): boolean;
begin
  Equal_syntax_trees := syntax_tree_ptr1 = syntax_tree_ptr2;
end; {function Equal_syntax_trees}


function Same_syntax_trees(syntax_tree_ptr1, syntax_tree_ptr2:
  syntax_tree_ptr_type): boolean;
begin
  Same_syntax_trees := syntax_tree_ptr1 = syntax_tree_ptr2;
end; {function Same_syntax_trees}


end.
