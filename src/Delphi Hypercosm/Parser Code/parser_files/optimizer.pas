unit optimizer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             optimizer                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides functions for optimizing           }
{       declarations.                                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decls, code_decls, type_decls, syntax_trees;


var
  {***************}
  { parsing flags }
  {***************}
  do_report_unused_decls: boolean;
  do_remove_unused_decls: boolean;


procedure Optimize_AST(syntax_tree_ptr: syntax_tree_ptr_type);

{********************************************}
{ routines for reporting unused declarations }
{********************************************}
procedure Report_unused_decls(decl_ptr: decl_ptr_type);
procedure Report_unused_code_decls(code_ptr: code_ptr_type);
procedure Report_unused_class_decls(class_type_ptr: type_ptr_type);
procedure Report_unused_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type);

{*******************************************}
{ routines for removing unused declarations }
{*******************************************}
procedure Remove_unused_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
procedure Remove_unused_code_decls(code_ptr: code_ptr_type;
  free_attributes: boolean);
procedure Remove_unused_class_decls(class_type_ptr: type_ptr_type;
  free_attributes: boolean);
procedure Remove_unused_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);

{********************************************}
{ routines for removing forward declarations }
{********************************************}
procedure Remove_forward_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
procedure Remove_forward_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);


implementation
uses
  chars, strings, decl_attributes, stmts, make_stmts, make_decls,
  make_syntax_trees, decl_unparser;


const
  verbose = false;


var
  used_decl_number: integer;
  unused_decl_number: integer;
  forward_decl_number: integer;


function Decl_always_unused(decl_ptr: decl_ptr_type): boolean;
var
  always_unused: boolean;
begin
  always_unused := false;
  if decl_ptr^.kind = null_decl then
    always_unused := true
  else if decl_ptr^.kind = type_decl then
    if type_ptr_type(decl_ptr^.type_ptr)^.kind in [enum_type, alias_type] then
      always_unused := true;

  Decl_always_unused := always_unused;
end; {function Decl_always_unused}


function Decl_always_used(decl_ptr: decl_ptr_type): boolean;
var
  always_used: boolean;
begin
  if decl_ptr^.kind in [boolean_decl..reference_decl] then
    always_used := decl_ptr^.data_decl.native
  else if decl_ptr^.kind in [code_decl..code_reference_decl] then
    always_used := decl_ptr^.code_data_decl.native
  else
    always_used := false;

  Decl_always_used := always_used;
end; {function Decl_always_used}


function Decl_used(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  var always_used, always_unused: boolean): boolean;
var
  used: boolean;
begin
  if Decl_always_used(decl_ptr) then
    begin
      used := true;
      always_used := true;
      always_unused := false;
    end
  else if Decl_always_unused(decl_ptr) then
    begin
      used := false;
      always_used := false;
      always_unused := true;
    end
  else
    begin
      always_used := false;
      always_unused := false;
      used := decl_attributes_ptr^.used;
    end;

  Decl_used := used;
end; {function Decl_used}


{********************************************}
{ routines for reporting unused declarations }
{********************************************}


procedure Report_unused_decl(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  write('Warning in line #', decl_ptr^.decl_info_ptr^.line_number: 1);
  write(' of ', Quotate_str(Get_include(decl_ptr^.decl_info_ptr^.file_number)));
  writeln(':');

  {*************************************}
  { issue a warning if in pedantic mode }
  {*************************************}
  with decl_attributes_ptr^ do
    if scope_decl_attributes_ptr <> nil then
      begin
        write('in ');
        write(Decl_kind_to_str(decl_ptr_type(scope_decl_attributes_ptr^.decl_ref)), ' ');
        write(Quotate_str(Get_decl_attributes_name(scope_decl_attributes_ptr)),
          ', ');
      end;

  if decl_attributes_ptr^.forward then
    write('forward ');

  write(Decl_kind_to_str(decl_ptr), ' ');
  write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
  writeln(' is unused.');
  writeln;
end; {procedure Report_unused_decl}


procedure Report_unused_code_decls(code_ptr: code_ptr_type);
begin
  with code_ptr^ do
    if decl_kind = actual_decl then
      begin
        Report_unused_decls(initial_param_decls_ptr);
        Report_unused_decls(optional_param_decls_ptr);
        Report_unused_decls(return_param_decls_ptr);
        Report_unused_decls(local_decls_ptr);
      end;
end; {procedure Report_unused_code_decls}


procedure Report_unused_class_decls(class_type_ptr: type_ptr_type);
begin
  with class_type_ptr^ do
    begin
      {*************************************}
      { class method interface declarations }
      {*************************************}
      Report_unused_decls(method_decls_ptr);

      {***********************************}
      { class implementation declarations }
      {***********************************}
      {Report_unused_decls(class_decls_ptr);}
    end;
end; {procedure Report_unused_class_decls}


procedure Report_unused_decls(decl_ptr: decl_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  used, always_used, always_unused: boolean;
begin
  if do_report_unused_decls then
    begin
      {*******************************}
      { check for unused declarations }
      {*******************************}
      while (decl_ptr <> nil) do
        begin
          decl_attributes_ptr := Get_decl_attributes(decl_ptr);
          used := Decl_used(decl_ptr, decl_attributes_ptr, always_used,
            always_unused);

          {********************************}
          { report the declaration, itself }
          {********************************}
          if not used and not always_unused then
            if decl_attributes_ptr <> nil then
              if not decl_attributes_ptr^.reported then
                if not decl_attributes_ptr^.forward then
                  begin
                    Report_unused_decl(decl_ptr, decl_attributes_ptr);

                    {***************************************************}
                    { avoid reporting unused decls on each pass of the  }
                    { optimizer (if unused decls are not to be removed) }
                    {***************************************************}
                    decl_attributes_ptr^.reported := true;
                  end;

          {*************************************************}
          { report unused declarations belonging to a class }
          {*************************************************}
          if decl_ptr^.kind = type_decl then
            if type_ptr_type(decl_ptr^.type_ptr)^.kind = class_type then
              Report_unused_class_decls(type_ptr_type(decl_ptr^.type_ptr));

          decl_ptr := decl_ptr^.next;
        end;
    end;
end; {procedure Report_unused_decls}


procedure Report_unused_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if do_report_unused_decls then
    begin
      {*******************************}
      { check for unused declarations }
      {*******************************}
      while (syntax_tree_ptr <> nil) do
        begin
          with syntax_tree_ptr^ do
            case kind of

              root_tree:
                begin
                  Report_unused_tree_decls(implicit_includes_ptr);
                  Report_unused_tree_decls(root_includes_ptr);
                  Report_unused_decls(decls_ptr);
                end;

              include_tree:
                begin
                  {**********************************************}
                  { don't report top level unused variables from }
                  { includes (even though they are removed also) }
                  {**********************************************}
                  if false then
                    begin
                      Report_unused_tree_decls(includes_ptr);
                      Report_unused_decls(include_decls_ptr);
                    end;
                end;

            end; {case}

          syntax_tree_ptr := syntax_tree_ptr^.next;
        end;
    end;
end; {procedure Report_unused_tree_decls}


{*******************************************}
{ routines for removing unused declarations }
{*******************************************}


procedure Report_free_decl(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  write('freeing ');

  with decl_attributes_ptr^ do
    if scope_decl_attributes_ptr <> nil then
      begin
        write(Decl_kind_to_str(decl_ptr_type(scope_decl_attributes_ptr^.decl_ref)), ' ');
        write(Quotate_str(Get_decl_attributes_name(scope_decl_attributes_ptr)));
        write(single_quote, 's ');
      end;

  if decl_attributes_ptr^.forward then
    write('forward ');
  write(Decl_kind_to_str(decl_ptr), ' ');
  write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
  writeln;
end; {procedure Report_free_decl}


procedure Remove_unused_code_decls(code_ptr: code_ptr_type;
  free_attributes: boolean);
begin
  with code_ptr^ do
    if decl_kind = actual_decl then
      Remove_unused_decls(local_decls_ptr, free_attributes);
end; {procedure Remove_unused_code_decls}


procedure Remove_unused_class_decls(class_type_ptr: type_ptr_type;
  free_attributes: boolean);
begin
  with class_type_ptr^ do
    begin
      {*************************************}
      { class method interface declarations }
      {*************************************}
      Remove_unused_decls(method_decls_ptr, free_attributes);

      {***********************************}
      { class implementation declarations }
      {***********************************}
      {Remove_unused_decls(class_decls_ptr, free_attributes);}
    end;
end; {procedure Remove_unused_class_decls}


procedure Remove_unused_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  prev, current: decl_ptr_type;
  used, always_used, always_unused: boolean;
begin
  if do_remove_unused_decls then
    begin
      prev := nil;
      current := decl_ptr;

      while (current <> nil) do
        begin
          decl_attributes_ptr := Get_decl_attributes(current);
          used := Decl_used(current, decl_attributes_ptr, always_used,
            always_unused);

          if not used then
            begin
              if verbose then
                if decl_attributes_ptr <> nil then
                  Report_free_decl(current, decl_attributes_ptr);

              if prev <> nil then
                begin
                  prev^.next := current^.next;
                  current^.next := nil;
                  Destroy_decl(current, free_attributes);
                  current := prev^.next;
                end
              else
                begin
                  decl_ptr := current^.next;
                  current^.next := nil;
                  Destroy_decl(current, free_attributes);
                  current := decl_ptr;
                end;

              unused_decl_number := unused_decl_number + 1;
            end
          else
            begin
              {*************************************************}
              { remove unused declarations belonging to a class }
              {*************************************************}
              if current^.kind = type_decl then
                if type_ptr_type(current^.type_ptr)^.kind = class_type then
                  Remove_unused_class_decls(type_ptr_type(current^.type_ptr),
                    free_attributes);

              prev := current;
              current := current^.next;
              used_decl_number := used_decl_number + 1;
            end;

        end; {while}
    end; {if do_remove}
end; {procedure Remove_unused_decls}


procedure Remove_unused_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);
begin
  if do_remove_unused_decls then
    begin
      while (syntax_tree_ptr <> nil) do
        begin
          with syntax_tree_ptr^ do
            case kind of

              root_tree:
                begin
                  used_decl_number := 0;
                  unused_decl_number := 0;
                  Remove_unused_tree_decls(implicit_includes_ptr,
                    free_attributes);
                  Remove_unused_tree_decls(root_includes_ptr, free_attributes);
                  Remove_unused_decls(implicit_decls_ptr, free_attributes);
                  Remove_unused_decls(decls_ptr, free_attributes);

                  if verbose then
                    begin
                      writeln('Number of decls used = ', used_decl_number: 1,
                        '.');
                      writeln('Number of unused decls = ', unused_decl_number:
                        1,
                        '.');
                    end;
                end;

              include_tree:
                begin
                  Remove_unused_tree_decls(includes_ptr, free_attributes);
                  Remove_unused_decls(include_decls_ptr, free_attributes);
                end;

            end; {case}

          syntax_tree_ptr := syntax_tree_ptr^.next;
        end; {while}
    end; {if do_remove}
end; {procedure Remove_unused_tree_decls}


{********************************************}
{ routines for removing forward declarations }
{********************************************}


procedure Remove_forward_code_decls(code_ptr: code_ptr_type;
  free_attributes: boolean);
begin
  with code_ptr^ do
    if decl_kind = actual_decl then
      Remove_forward_decls(local_decls_ptr, free_attributes);
end; {procedure Remove_forward_code_decls}


procedure Remove_forward_class_decls(class_type_ptr: type_ptr_type;
  free_attributes: boolean);
begin
  with class_type_ptr^ do
    begin
      {*************************************}
      { class method interface declarations }
      {*************************************}
      Remove_forward_decls(method_decls_ptr, free_attributes);

      {***********************************}
      { class implementation declarations }
      {***********************************}
      Remove_forward_decls(class_decls_ptr, free_attributes);
    end;
end; {procedure Remove_forward_class_decls}


procedure Remove_forward_decls(var decl_ptr: decl_ptr_type;
  free_attributes: boolean);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  prev, current: decl_ptr_type;
begin
  if do_remove_unused_decls then
    begin
      prev := nil;
      current := decl_ptr;

      while (current <> nil) do
        begin
          decl_attributes_ptr := Get_decl_attributes(current);

          if decl_attributes_ptr <> nil then
            if decl_attributes_ptr^.forward and not decl_attributes_ptr^.abstract
              then
              begin
                if verbose then
                  Report_free_decl(current, decl_attributes_ptr);

                if prev <> nil then
                  begin
                    prev^.next := current^.next;
                    current^.next := nil;
                    Destroy_decl(current, free_attributes);
                    current := prev^.next;
                  end
                else
                  begin
                    decl_ptr := current^.next;
                    current^.next := nil;
                    Destroy_decl(current, free_attributes);
                    current := decl_ptr;
                  end;

                forward_decl_number := forward_decl_number + 1;
              end
            else
              begin
                {*************************************************}
                { remove unused declarations belonging to a class }
                {*************************************************}
                if current^.kind = type_decl then
                  if type_ptr_type(current^.type_ptr)^.kind = class_type then
                    Remove_forward_class_decls(type_ptr_type(current^.type_ptr),
                      free_attributes);

                prev := current;
                current := current^.next;
              end;

        end; {while}
    end; {if do_remove}
end; {procedure Remove_forward_decls}


procedure Remove_forward_tree_decls(syntax_tree_ptr: syntax_tree_ptr_type;
  free_attributes: boolean);
begin
  if do_remove_unused_decls then
    begin
      while (syntax_tree_ptr <> nil) do
        begin
          with syntax_tree_ptr^ do
            case kind of

              root_tree:
                begin
                  forward_decl_number := 0;
                  Remove_forward_tree_decls(implicit_includes_ptr,
                    free_attributes);
                  Remove_forward_tree_decls(root_includes_ptr, free_attributes);
                  Remove_forward_decls(decls_ptr, free_attributes);

                  if verbose then
                    writeln('Number of forward decls = ', forward_decl_number:
                      1,
                      '.');
                end;

              include_tree:
                begin
                  Remove_forward_tree_decls(includes_ptr, free_attributes);
                  Remove_forward_decls(include_decls_ptr, free_attributes);
                end;

            end; {case}

          syntax_tree_ptr := syntax_tree_ptr^.next;
        end; {while}
    end; {if do_remove}
end; {procedure Remove_forward_tree_decls}


procedure Optimize_AST(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  {*********************************************}
  { report and remove unreferenced declarations }
  {*********************************************}
  { (nested declarations are reported at the    }
  { end of their enclosing subprogram's scope)  }
  {*********************************************}
  Report_unused_tree_decls(syntax_tree_ptr);
  Remove_unused_tree_decls(syntax_tree_ptr, false);

  {*******************************************************}
  { free remaining unused declarations by mark and sweep. }
  {*******************************************************}
  { this method catches declarations which are referenced }
  { only by other unrefereced declarations. These decls   }
  { are not caught by the first pass which only catches   }
  { completely unreferenced declarations.                 }
  {*******************************************************}
  Mark_decls_attributes(active_decl_attributes_list, false);
  Mark_stmts(syntax_tree_ptr^.stmts_ptr, true);
  Mark_native_syntax_trees(syntax_tree_ptr, true);
  Report_unused_tree_decls(syntax_tree_ptr);
  Remove_unused_tree_decls(syntax_tree_ptr, false);
end; {procedure Optimize_AST}


initialization
  {***********************************}
  { initialize optimizer static flags }
  {***********************************}
  do_report_unused_decls := true;
  do_remove_unused_decls := true;
end.

