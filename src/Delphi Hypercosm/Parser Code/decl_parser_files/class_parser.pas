unit class_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            class_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse class            }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decls;


procedure Init_base_class(var decl_ptr: decl_ptr_type);
procedure Parse_class_decl(var decl_ptr: decl_ptr_type);


implementation
uses
  strings, hashtables, code_types, symbol_tables, type_attributes,
  code_attributes, decl_attributes, stmt_attributes, expr_attributes,
  compare_types, exprs, code_decls, type_decls, make_decls, make_type_decls,
  tokens, tokenizer, struct_assigns, parser, comment_parser, match_literals,
  match_terms, scoping, member_parser, method_parser, data_parser,
  stmt_parser, struct_parser, type_parser, decl_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                        class declarations                     }
{***************************************************************}
{       <class_decl> ::= class id <methods> with <fields>       }
{                        is <decls> end;                        }
{                                                               }
{       <methods> ::= <complex_decl> <more_methods>             }
{       <more_methods> ::= <methods>                            }
{       <more_methods> ::=                                      }
{                                                               }
{       <fields> ::= <simple_decl> <more_fields>                }
{       <more_fields> ::= <fields>                              }
{       <more_fields> ::=                                       }
{***************************************************************}


const
  memory_alert = false;


var
  base_class_decl_ptr: decl_ptr_type;
  base_class_type_attributes_ptr: type_attributes_ptr_type;


function Found_method(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  class_type_ptr: type_ptr_type): boolean;
var
  class_decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  found: boolean;
begin
  if (class_type_ptr <> nil) then
    begin
      {****************************}
      { push method scope of class }
      {****************************}
      class_decl_attributes_ptr :=
        Get_decl_attributes(class_type_ptr^.type_decl_ref);
      Push_local_scope(class_decl_attributes_ptr);

      {**********************************}
      { push method scopes of superclass }
      {**********************************}
      type_attributes_ptr :=
        class_decl_attributes_ptr^.type_attributes_ptr^.parent_type_attributes_ptr;
      while (type_attributes_ptr <> nil) do
        begin
          Push_post_scope(type_attributes_ptr^.public_table_ptr);
          Push_post_scope(type_attributes_ptr^.protected_table_ptr);

          {***********************************************}
          { push method scopes of superclasses interfaces }
          {***********************************************}
          type_attributes_ref_ptr :=
            type_attributes_ptr^.interface_type_attributes_ptr;
          while (type_attributes_ref_ptr <> nil) do
            begin
              Push_interface_method_scopes(type_attributes_ref_ptr^.type_attributes_ptr);
              type_attributes_ref_ptr := type_attributes_ref_ptr^.next;
            end;

          type_attributes_ptr :=
            type_attributes_ptr^.parent_type_attributes_ptr;
        end;

      {**********************************}
      { push method scopes of interfaces }
      {**********************************}
      type_attributes_ref_ptr :=
        class_decl_attributes_ptr^.type_attributes_ptr^.interface_type_attributes_ptr;
      while (type_attributes_ref_ptr <> nil) do
        begin
          Push_interface_method_scopes(type_attributes_ref_ptr^.type_attributes_ptr);
          type_attributes_ref_ptr := type_attributes_ref_ptr^.next;
        end;

      found := Found_id(name, decl_attributes_ptr, stmt_attributes_ptr);

      {***********************************}
      { pop method scopes of superclasses }
      {***********************************}
      Pop_local_scope;
    end
  else
    found := false;

  Found_method := found;
end; {function Found_method}


procedure Check_method_decl(decl_attributes_ptr1, decl_attributes_ptr2:
  decl_attributes_ptr_type);
var
  type_attributes_ptr1, type_attributes_ptr2: type_attributes_ptr_type;
  class_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr1 := decl_attributes_ptr1^.type_attributes_ptr;
      type_attributes_ptr2 := decl_attributes_ptr2^.type_attributes_ptr;

      {*********************************}
      { check for logical compatability }
      {*********************************}
      if not Same_type_attributes(type_attributes_ptr1, type_attributes_ptr2)
        then
        begin
          Parse_error;
          write('Overriding ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr2)));
          writeln(' declaration does not');
          writeln('match its inherited declaration.');
          writeln;

          class_decl_attributes_ptr :=
            decl_attributes_ptr1^.scope_decl_attributes_ptr;
          write('This method can be found in class ');
          write(Quotate_str(Get_decl_attributes_name(class_decl_attributes_ptr)),
            '.');
          writeln;

          error_reported := true;
        end;

    end;
end; {procedure Check_method_decl}


procedure Reset_interface_methods(class_type_ptr: type_ptr_type);
var
  type_ref_ptr: type_reference_ptr_type;
  dispatch_table_ptr: dispatch_table_ptr_type;
  method_code_ptr: code_ptr_type;
  counter: integer;
begin
  {**************************************************}
  { reset method id offsets to their original values }
  {**************************************************}
  type_ref_ptr := class_type_ptr^.interface_class_ptr;
  while (type_ref_ptr <> nil) do
    begin
      dispatch_table_ptr := type_ref_ptr^.type_ref^.dispatch_table_ptr;
      for counter := 1 to dispatch_table_ptr^.entries do
        begin
          method_code_ptr := dispatch_table_ptr^.dispatch_table[counter];
          method_code_ptr^.method_id := counter;
        end;

      {**********************}
      { reset sub interfaces }
      {**********************}
      Reset_interface_methods(type_ref_ptr^.type_ref);

      type_ref_ptr := type_ref_ptr^.next;
    end;
end; {procedure Reset_interface_methods}


procedure Check_abstract_decls(class_type_ptr: type_ptr_type);
var
  decl_ptr: decl_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  dispatch_table_ptr: dispatch_table_ptr_type;
  method_code_ptr: code_ptr_type;
  counter: integer;
begin
  counter := 1;
  dispatch_table_ptr := class_type_ptr^.dispatch_table_ptr;
  while (counter <= dispatch_table_ptr^.entries) and parsing_ok do
    begin
      method_code_ptr := dispatch_table_ptr^.dispatch_table[counter];
      if (method_code_ptr^.method_kind = abstract_method) then
        begin
          expr_ptr :=
            method_code_ptr^.code_decl_ref^.code_data_decl.data_expr_ptr;
          expr_attributes_ptr := Get_expr_attributes(expr_ptr);

          Parse_error;
          write('The inherited abstract method, ');
          write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr)));
          write(', is undefined.');
          writeln;

          decl_ptr :=
            type_ptr_type(method_code_ptr^.class_type_ref)^.type_decl_ref;
          decl_attributes_ptr := Get_decl_attributes(decl_ptr);

          write('This method can be found in class ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)),
            '.');
          writeln;

          error_reported := true;
        end
      else
        counter := counter + 1;
    end;
end; {procedure Check_abstract_decls}


procedure Lock_protected_tables(type_attributes_ptr: type_attributes_ptr_type);
begin
  while (type_attributes_ptr <> nil) do
    begin
      Lock_symbol_table(type_attributes_ptr^.protected_table_ptr);
      type_attributes_ptr := type_attributes_ptr^.parent_type_attributes_ptr;
    end;
end; {procedure Lock_protected_tables}


procedure Unlock_protected_tables(type_attributes_ptr:
  type_attributes_ptr_type);
begin
  while (type_attributes_ptr <> nil) do
    begin
      Unlock_symbol_table(type_attributes_ptr^.protected_table_ptr);
      type_attributes_ptr := type_attributes_ptr^.parent_type_attributes_ptr;
    end;
end; {procedure Unlock_protected_tables}


procedure Add_new_method(method_code_ptr: code_ptr_type;
  class_type_ptr: type_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  method_decl_attributes_ptr: decl_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
  name: string_type;
  found: boolean;
begin
  method_decl_attributes_ptr :=
    Get_decl_attributes(method_code_ptr^.code_decl_ref);
  name := Get_decl_attributes_name(method_decl_attributes_ptr);

  if class_type_ptr^.parent_class_ref <> nil then
    found := Found_method(name, decl_attributes_ptr, class_type_ptr)
  else
    found := false;

  if found then
    begin
      {****************************************}
      { get method declaration from attributes }
      {****************************************}
      decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);

      if not (code_ptr^.method_kind in overrideable_method_set) then
        begin
          Parse_error;
          writeln('The inherited method, ', Quotate_str(name),
            ', can not be overridden.');
          error_reported := true;
        end
      else
        begin
          {**************************************}
          { check that parameters are compatible }
          {**************************************}
          Check_method_decl(decl_attributes_ptr, method_decl_attributes_ptr);
        end;

      if parsing_ok then
        Override_virtual_method(code_ptr, method_code_ptr, class_type_ptr);
    end
  else
    begin
      {******************************************}
      { add new virtual method to dispatch table }
      {******************************************}
      if method_code_ptr^.method_kind in overrideable_method_set then
        Add_virtual_method(class_type_ptr, method_code_ptr);
    end;
end; {procedure Add_new_method}


procedure Parse_interface_method_kind(var method_kind: method_kind_type);
begin
  {**********************************************************}
  { methods of interface classes are all implicitly abstract }
  {**********************************************************}
  if next_token.kind <> abstract_tok then
    begin
      method_kind := abstract_method;
    end
  else
    begin
      Parse_error;
      writeln('Methods of interface classes are implicitly abstract.');
      error_reported := true;
    end;
end; {procedure Parse_interface_method_kind}


procedure Parse_method_kind(var method_kind: method_kind_type;
  class_type_ptr: type_ptr_type);
begin
  {*****************************************************}
  { non interface classes: regular, abstract, and final }
  {*****************************************************}
  if next_token.kind = abstract_tok then
    begin
      {******************************}
      { abstract method declarations }
      {******************************}
      if class_type_ptr^.class_kind = abstract_class then
        begin
          method_kind := abstract_method;
          Get_next_token;
        end
      else
        begin
          Parse_error;
          writeln('Abstract methods may only be declared in abstract classes.');
          error_reported := true;
        end;
    end
  else if (next_token.kind = final_tok) then
    begin
      {***************************************}
      { explicitly static method declarations }
      {***************************************}
      method_kind := final_method;
      Get_next_token;
    end
  else if (next_token.kind = void_tok) then
    begin
      {***************************************}
      { static or 'class' method declarations }
      {***************************************}
      method_kind := void_method;
      Get_next_token;
    end
  else
    begin
      {*************************************************}
      { implicitly virtual or final method declarations }
      {*************************************************}
      if class_type_ptr^.class_kind = final_class then
        method_kind := final_method
      else
        method_kind := virtual_method;
    end;
end; {procedure Parse_method_kind}


procedure Parse_method_decls(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  new_decl_ptr, last_decl_ptr: decl_ptr_type;
  decl_kind: code_decl_kind_type;
  method_kind: method_kind_type;
  reference_method: boolean;
  code_ptr: code_ptr_type;
begin
  if parsing_ok then
    begin
      parsing_method_decls := true;
      parsing_native_decls := false;
      last_decl_ptr := nil;
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;

      while (next_token.kind in forward_method_predict_set + data_predict_set)
        and parsing_ok do
        begin
          {*************************************}
          { default interface method attributes }
          {*************************************}
          decl_kind := forward_decl;
          method_kind := virtual_method;
          reference_method := false;

          if next_token.kind = protected_tok then
            begin
              {*******************************}
              { override default access level }
              {*******************************}
              Get_next_token;
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
              Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
            end
          else
            begin
              {*******************************}
              { methods are public by default }
              {*******************************}
              Push_post_scope(type_attributes_ptr^.protected_table_ptr);
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
            end;

          if class_type_ptr^.class_kind = interface_class then
            Parse_interface_method_kind(method_kind)
          else if class_type_ptr^.class_kind = alias_class then
            method_kind := static_method
          else
            Parse_method_kind(method_kind, class_type_ptr);

          {****************}
          { native methods }
          {****************}
          if next_token.kind = native_tok then
            begin
              Get_next_token;
              decl_kind := native_decl;
            end;

          {*******************}
          { reference methods }
          {*******************}
          if class_type_ptr^.static then
            begin
              if next_token.kind = reference_tok then
                begin
                  Parse_error;
                  writeln('Static class methods are implicitly reference methods.');
                  error_reported := true;
                end
              else
                reference_method := true;
            end
          else if method_kind <> void_method then
            if next_token.kind = reference_tok then
              begin
                Get_next_token;
                reference_method := true;
              end;

          {**********************************}
          { parse method forward declaration }
          {**********************************}
          Parse_method_decl(new_decl_ptr, decl_kind, method_kind, false,
            reference_method, nil, class_type_ptr);

          {******************************}
          { update method dispatch table }
          {******************************}
          if parsing_ok then
            begin
              code_ptr := code_ptr_type(new_decl_ptr^.code_ptr);
              if not (code_ptr^.kind in special_code_kinds) then
                Add_new_method(code_ptr_type(new_decl_ptr^.code_ptr),
                  class_type_ptr);
            end;

          if (last_decl_ptr = nil) then
            begin
              class_type_ptr^.method_decls_ptr := new_decl_ptr;
              last_decl_ptr := new_decl_ptr;
            end
          else
            begin
              last_decl_ptr^.next := new_decl_ptr;
              last_decl_ptr := new_decl_ptr;
            end;

          Pop_prev_scope;
          Pop_prev_scope;
        end; {while}

      parsing_method_decls := false;
      parsing_native_decls := false;
    end;
end; {procedure Parse_method_decls}


procedure Parse_interface_method_decls(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  new_decl_ptr, last_decl_ptr: decl_ptr_type;
  reference_method: boolean;
begin
  if parsing_ok then
    begin
      parsing_method_decls := true;
      last_decl_ptr := nil;
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;

      while (next_token.kind in forward_method_predict_set + data_predict_set)
        and parsing_ok do
        begin
          if next_token.kind = protected_tok then
            begin
              {*******************************}
              { override default access level }
              {*******************************}
              Get_next_token;
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
              Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
            end
          else
            begin
              {*******************************}
              { methods are public by default }
              {*******************************}
              Push_post_scope(type_attributes_ptr^.protected_table_ptr);
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
            end;

          if next_token.kind = reference_tok then
            begin
              Get_next_token;
              reference_method := true;
            end
          else
            reference_method := false;

          {**********************************}
          { parse method forward declaration }
          {**********************************}
          Parse_method_decl(new_decl_ptr, forward_decl, abstract_method, false,
            reference_method, nil, class_type_ptr);

          {******************************}
          { update method dispatch table }
          {******************************}
          if parsing_ok then
            Add_new_method(code_ptr_type(new_decl_ptr^.code_ptr),
              class_type_ptr);

          if (last_decl_ptr = nil) then
            begin
              class_type_ptr^.method_decls_ptr := new_decl_ptr;
              last_decl_ptr := new_decl_ptr;
            end
          else
            begin
              last_decl_ptr^.next := new_decl_ptr;
              last_decl_ptr := new_decl_ptr;
            end;

          Pop_prev_scope;
          Pop_prev_scope;
        end; {while}

      if next_token.kind = abstract_tok then
        begin
          Parse_error;
          writeln('All interface methods are implicitly abstract.');
          error_reported := true;
        end;

      parsing_method_decls := false;
    end;
end; {procedure Parse_interface_method_decls}


procedure Parse_member_decls(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  var nonpublic_members: boolean);
var
  type_attributes_ptr: type_attributes_ptr_type;
  last_decl_ptr: decl_ptr_type;
begin
  if parsing_ok then
    begin
      last_decl_ptr := nil;
      parsing_member_decls := true;
      nonpublic_members := false;

      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
      Push_static_scope(decl_attributes_ptr);

      {*************************}
      { parse member type decls }
      {*************************}
      Push_prev_scope(type_attributes_ptr^.public_table_ptr);
      Parse_type_decls(class_type_ptr^.member_decls_ptr, last_decl_ptr);
      Pop_prev_scope;

      {******************************************}
      { parse public and protected member fields }
      {******************************************}
      while not (next_token.kind in [is_tok, end_tok, private_tok]) and
        parsing_ok do
        begin
          if next_token.kind = public_tok then
            begin
              {*******************************}
              { override default access level }
              {*******************************}
              Get_next_token;
              Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
            end
          else
            begin
              {****************************************}
              { member fields are protected by default }
              {****************************************}
              nonpublic_members := true;
              Push_prev_scope(type_attributes_ptr^.public_table_ptr);
              Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
            end;

          {*************************}
          { parse field declaration }
          {*************************}
          if next_token.kind = const_tok then
            begin
              if last_decl_ptr <> nil then
                Parse_var_decl_list(last_decl_ptr^.next, last_decl_ptr, nil)
              else
                Parse_var_decl_list(class_type_ptr^.member_decls_ptr,
                  last_decl_ptr, nil);
            end
          else
            begin
              if last_decl_ptr <> nil then
                Parse_field_decl_list(last_decl_ptr^.next, last_decl_ptr,
                  decl_attributes_ptr)
              else
                Parse_field_decl_list(class_type_ptr^.member_decls_ptr,
                  last_decl_ptr, decl_attributes_ptr);
            end;

          Pop_prev_scope;
          Pop_prev_scope;
        end; {while}

      {*****************************}
      { parse private member fields }
      {*****************************}
      if next_token.kind = private_tok then
        begin
          Get_next_token;
          Push_prev_scope(type_attributes_ptr^.public_table_ptr);
          Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
          Push_prev_scope(type_attributes_ptr^.private_table_ptr);
          nonpublic_members := true;

          {*********************************}
          { parse private member type decls }
          {*********************************}
          last_decl_ptr := nil;
          Parse_type_decls(class_type_ptr^.private_member_decls_ptr,
            last_decl_ptr);

          while not (next_token.kind in [is_tok, end_tok, public_tok,
            protected_tok, private_tok]) and parsing_ok do
            begin
              {*************************}
              { parse field declaration }
              {*************************}
              if next_token.kind = const_tok then
                begin
                  if last_decl_ptr <> nil then
                    Parse_var_decl_list(last_decl_ptr^.next, last_decl_ptr, nil)
                  else
                    Parse_var_decl_list(class_type_ptr^.member_decls_ptr,
                      last_decl_ptr, nil);
                end
              else
                begin
                  if last_decl_ptr <> nil then
                    Parse_field_decl_list(last_decl_ptr^.next, last_decl_ptr,
                      decl_attributes_ptr)
                  else
                    Parse_field_decl_list(class_type_ptr^.private_member_decls_ptr, last_decl_ptr, decl_attributes_ptr);
                end;
            end;
        end;

      Pop_static_scope;
      parsing_member_decls := false;
    end;
end; {procedure Parse_member_decls}


procedure Parse_const_member_decls(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  last_decl_ptr: decl_ptr_type;
begin
  if parsing_ok then
    begin
      last_decl_ptr := nil;
      type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;

      Push_static_scope(decl_attributes_ptr);
      Push_prev_scope(type_attributes_ptr^.public_table_ptr);
      Push_prev_scope(type_attributes_ptr^.protected_table_ptr);

      while (next_token.kind <> end_tok) and parsing_ok do
        begin
          if next_token.kind = const_tok then
            begin
              if last_decl_ptr <> nil then
                Parse_var_decl_list(last_decl_ptr^.next, last_decl_ptr, nil)
              else
                Parse_var_decl_list(class_type_ptr^.member_decls_ptr,
                  last_decl_ptr, nil);
            end
          else
            begin
              Parse_error;
              writeln('Only constants are allowed as interface members.');
              error_reported := true;
            end;
        end;

      Pop_static_scope;
    end;
end; {procedure Parse_const_member_decls}


procedure Set_superclass(name: string_type;
  class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if Found_type_id(name, type_decl_attributes_ptr, stmt_attributes_ptr) then
    begin
      if type_decl_attributes_ptr^.kind <> type_decl_attributes then
        begin
          Parse_error;
          writeln('This identifier is not the name of a type.');
          error_reported := true;
        end
      else if type_decl_attributes_ptr^.type_attributes_ptr^.kind <>
        type_class then
        begin
          Parse_error;
          writeln('This identifier is not the name of a class.');
          error_reported := true;
        end
      else if type_decl_attributes_ptr^.final then
        begin
          Parse_error;
          writeln('Final classes may not be subclassed.');
          error_reported := true;
        end
      else
        begin
          {**********************************************}
          { get parent class declaration from attributes }
          {**********************************************}
          decl_ptr := decl_ptr_type(type_decl_attributes_ptr^.decl_ref);
          class_type_ptr^.parent_class_ref :=
            type_ptr_type(decl_ptr^.type_ptr);

          if class_type_ptr^.static <>
            class_type_ptr^.parent_class_ref^.static then
            begin
              if class_type_ptr^.static then
                begin
                  Parse_error;
                  writeln('Static classes may not extend non static classes.');
                  error_reported := true;
                end
              else
                begin
                  Parse_error;
                  writeln('Non static classes may not extend static classes.');
                  error_reported := true;
                end;
            end
          else
            begin
              {***************************}
              { mark parent class as used }
              {***************************}
              Mark_type(class_type_ptr^.parent_class_ref, true);

              if (class_type_ptr^.parent_class_ref^.class_kind <>
                interface_class) then
                begin
                  {********************************************}
                  { add superclass's methods to dispatch table }
                  {********************************************}
                  decl_attributes_ptr^.type_attributes_ptr^.parent_type_attributes_ptr := type_decl_attributes_ptr^.type_attributes_ptr;
                  Add_virtual_methods(class_type_ptr,
                    class_type_ptr^.parent_class_ref);
                end
              else
                begin
                  Parse_error;
                  writeln('Interface classes belong in the ',
                    Quotate_str('implements'), ' list.');
                  error_reported := true;
                end;
            end;
        end;
    end
  else
    begin
      Parse_error;
      writeln('Type ', Quotate_str(name),
        ' has not been declared.');
      error_reported := true;
    end;
end; {procedure Set_superclass}


procedure Add_interface(name: string_type;
  class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  interface_type_ptr: type_ptr_type;
  type_ref_ptr: type_reference_ptr_type;
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
begin
  if Found_type_id(name, type_decl_attributes_ptr, stmt_attributes_ptr) then
    begin
      if type_decl_attributes_ptr^.kind <> type_decl_attributes then
        begin
          Parse_error;
          writeln(Quotate_str(name), ' is not the name of a type.');
          error_reported := true;
        end
      else if type_decl_attributes_ptr^.type_attributes_ptr^.kind <>
        type_class then
        begin
          Parse_error;
          writeln(Quotate_str(name), ' is not the name of a class.');
          error_reported := true;
        end
      else
        begin
          {**********************************************}
          { get parent class declaration from attributes }
          {**********************************************}
          decl_ptr :=
            decl_ptr_type(type_decl_attributes_ptr^.decl_ref);
          interface_type_ptr := type_ptr_type(decl_ptr^.type_ptr);
          type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;

          {************************}
          { mark interface as used }
          {************************}
          Mark_type(interface_type_ptr, true);

          if (interface_type_ptr^.class_kind = interface_class) then
            begin
              type_ref_ptr := New_type_ref(interface_type_ptr);
              type_ref_ptr^.index :=
                class_type_ptr^.dispatch_table_ptr^.entries;
              type_attributes_ref_ptr :=
                New_type_attributes_ref(type_decl_attributes_ptr^.type_attributes_ptr);

              {****************************************}
              { add interface type ref to head of list }
              {****************************************}
              type_ref_ptr^.next := class_type_ptr^.interface_class_ptr;
              class_type_ptr^.interface_class_ptr := type_ref_ptr;

              {*********************************************}
              { add interface data info ref to head of list }
              {*********************************************}
              type_attributes_ref_ptr^.next :=
                type_attributes_ptr^.interface_type_attributes_ptr;
              type_attributes_ptr^.interface_type_attributes_ptr :=
                type_attributes_ref_ptr;

              {*******************************************}
              { add interface's methods to dispatch table }
              {*******************************************}
              Add_virtual_methods(class_type_ptr, interface_type_ptr);

              {************************************}
              { add interface's constants to scope }
              {************************************}
              Push_interface_member_scopes(type_attributes_ptr);
            end
          else
            begin
              Parse_error;
              writeln('Only interface classes are allowed here.');
              error_reported := true;
            end;
        end;
    end
  else
    begin
      Parse_error;
      writeln('Type ', Quotate_str(next_token.id),
        ' has not been declared.');
      error_reported := true;
    end;
end; {procedure Add_interface}


procedure Parse_interfaces(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  name: string_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          next_token.kind := type_id_tok;
          name := Token_to_id(next_token);
          Get_next_token;

          if next_token.kind = id_tok then
            Parse_interfaces(class_type_ptr, decl_attributes_ptr);

          Add_interface(name, class_type_ptr, decl_attributes_ptr);
        end
      else
        begin
          Parse_error;
          writeln('Expected the name of an interface here.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_interfaces}


procedure Parse_superclass(class_type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  name: string_type;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          next_token.kind := type_id_tok;
          name := Token_to_id(next_token);
          Get_next_token;

          if next_token.kind = id_tok then
            begin
              Parse_superclass(class_type_ptr, decl_attributes_ptr);
              Add_interface(name, class_type_ptr, decl_attributes_ptr);
            end
          else
            Set_superclass(name, class_type_ptr, decl_attributes_ptr);
        end
      else
        begin
          {***************}
          { alias classes }
          {***************}
          class_type_ptr^.class_kind := alias_class;
          decl_attributes_ptr^.type_attributes_ptr^.kind := type_class_alias;
          Parse_data_type(decl_attributes_ptr^.type_attributes_ptr^.class_alias_type_attributes_ptr);
          decl_attributes_ptr^.dimensions :=
            Get_data_abs_dims(decl_attributes_ptr^.type_attributes_ptr);
        end;
    end;
end; {procedure Parse_superclass}


procedure Init_base_class(var decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  {************************************************}
  { make base class type descriptor and attributes }
  {************************************************}
  base_class_type_attributes_ptr := New_type_attributes(type_class, false);
  decl_attributes_ptr := New_decl_attributes(type_decl_attributes,
    base_class_type_attributes_ptr, nil);
  base_class_type_attributes_ptr^.id_ptr := New_hashtable_entry('subject type',
    hashtable_value_type(decl_attributes_ptr));

  {****************************}
  { init base class attributes }
  {****************************}
  decl_attributes_ptr^.native := false;
  decl_attributes_ptr^.decl_ref := forward_decl_ref_type(decl_ptr);
  decl_attributes_ptr^.abstract := true;

  {*******************************}
  { create base class declaration }
  {*******************************}
  decl_ptr := New_decl(type_decl);
  type_ptr := New_type(class_type, decl_ptr);
  base_class_decl_ptr := decl_ptr;

  {************************}
  { init base object class }
  {************************}
  type_ptr^.class_base_ptr := New_expr(struct_base);
  type_ptr^.class_kind := abstract_class;
  type_ptr^.dispatch_table_ptr := New_dispatch_table;
  type_ptr^.copyable := false;
  type_ptr^.subclass_copyable := true;

  {*********************}
  { set base class name }
  {*********************}
  Make_implicit_new_type_id('object type', decl_attributes_ptr);

  {**********************************}
  { set links to and from attributes }
  {**********************************}
  Set_decl_attributes(decl_ptr, decl_attributes_ptr);

  {*****************************}
  { space for ptr to class decl }
  {*****************************}
  base_class_type_attributes_ptr^.size := 1;

  {******************************}
  { create symbol tables (empty) }
  {******************************}
  base_class_type_attributes_ptr^.public_table_ptr := New_symbol_table;
  base_class_type_attributes_ptr^.private_table_ptr := New_symbol_table;
  base_class_type_attributes_ptr^.protected_table_ptr := New_symbol_table;
end; {procedure Init_base_class}


function Found_nonprivate_class_members(type_ptr: type_ptr_type): boolean;
var
  found: boolean;
begin
  if type_ptr = nil then
    found := false
  else if type_ptr^.member_decls_ptr <> nil then
    found := true
  else
    found := Found_nonprivate_class_members(type_ptr^.parent_class_ref);

  Found_nonprivate_class_members := found;
end; {function Found_nonprivate_class_members}


procedure Set_copyable_class(type_ptr: type_ptr_type;
  nonpublic_members: boolean);
begin
  if type_ptr^.class_kind = interface_class then
    begin
      type_ptr^.copyable := false;
      type_ptr^.subclass_copyable := false;
    end
  else if nonpublic_members then
    begin
      type_ptr^.copyable := false;
      type_ptr^.subclass_copyable := false;
    end
  else if type_ptr^.class_kind = abstract_class then
    begin
      type_ptr^.copyable := false;
      type_ptr^.subclass_copyable := true;
    end

      {*****************}
      { derived classes }
      {*****************}
  else if type_ptr^.parent_class_ref <> nil then
    begin
      if not type_ptr^.parent_class_ref^.subclass_copyable then
        begin
          type_ptr^.copyable := false;
          type_ptr^.subclass_copyable := false;
        end
      else
        begin
          type_ptr^.copyable := Found_nonprivate_class_members(type_ptr);
          type_ptr^.subclass_copyable := true;
        end;
    end

      {**************}
      { base classes }
      {**************}
  else
    begin
      type_ptr^.copyable := Found_nonprivate_class_members(type_ptr);
      type_ptr^.subclass_copyable := true;
    end;
end; {procedure Set_copyable_class}


{***************************************************************}
{                        class declarations                     }
{***************************************************************}
{       <class_decl> ::= class id <methods> with <fields>       }
{                        is <decls> end;                        }
{                                                               }
{       <methods> ::= <complex_decl> <more_methods>             }
{       <more_methods> ::= <methods>                            }
{       <more_methods> ::=                                      }
{                                                               }
{       <fields> ::= <simple_decl> <more_fields>                }
{       <more_fields> ::= <fields>                              }
{       <more_fields> ::=                                       }
{***************************************************************}

procedure Parse_class_decl(var decl_ptr: decl_ptr_type);
var
  type_ptr: type_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  static, nonpublic_members: boolean;
  temp: boolean;
begin
  if parsing_ok then
    if next_token.kind in class_decl_predict_set then
      begin
        Get_prev_decl_info(decl_info_ptr);

        if next_token.kind = static_tok then
          begin
            Get_next_token;
            static := true;
          end
        else
          static := false;

        {***********************************************}
        { make new class type descriptor and attributes }
        {***********************************************}
        type_attributes_ptr := New_type_attributes(type_class, static);
        decl_attributes_ptr := New_decl_attributes(type_decl_attributes,
          type_attributes_ptr, nil);

        {***********************}
        { init class attributes }
        {***********************}
        decl_attributes_ptr^.native := parsing_native_decls and not
          parsing_param_decls;

        {****************************}
        { make new class declaration }
        {****************************}
        decl_ptr := New_decl(type_decl);
        type_ptr := New_type(class_type, decl_ptr);
        Set_decl_info(decl_ptr, decl_info_ptr);

        {****************************}
        { init new class declaration }
        {****************************}
        type_ptr^.static := static;
        if static then
          type_ptr^.class_base_ptr := New_expr(static_struct_base)
        else
          type_ptr^.class_base_ptr := New_expr(struct_base);

        {******************}
        { parse class kind }
        {******************}
        case next_token.kind of
          class_tok:
            begin
              Get_next_token;
              type_ptr^.class_kind := normal_class;
            end;

          abstract_tok:
            begin
              Get_next_token;
              type_ptr^.class_kind := abstract_class;
              decl_attributes_ptr^.abstract := true;
              Match(class_tok);
            end;

          interface_tok:
            begin
              Get_next_token;
              type_ptr^.class_kind := interface_class;
              decl_attributes_ptr^.abstract := true;
            end;

          final_tok:
            begin
              Get_next_token;
              type_ptr^.class_kind := final_class;
              decl_attributes_ptr^.final := true;
              Match(class_tok);
            end;
        end; {case}

        {******************}
        { match class name }
        {******************}
        Match_new_type_id(decl_attributes_ptr);

        if parsing_ok then
          begin
            {**********************************}
            { set links to and from attributes }
            {**********************************}
            Set_decl_attributes(decl_ptr, decl_attributes_ptr);

            {**************************}
            { make new scope for class }
            {**************************}
            type_attributes_ptr^.public_table_ptr := New_symbol_table;
            type_attributes_ptr^.private_table_ptr := New_symbol_table;
            type_attributes_ptr^.protected_table_ptr := New_symbol_table;

            type_ptr^.dispatch_table_ptr := New_dispatch_table;
            Push_static_scope(decl_attributes_ptr);

            {************************************}
            { parse class interface declarations }
            {************************************}
            if not (next_token.kind in [extends_tok, has_tok,
              does_tok]) then
              begin
                Parse_error;
                writeln('Expected class interface declarations here.');
                error_reported := true;
              end;

            if type_ptr^.class_kind <> interface_class then
              begin
                {****************************}
                { parse class's parent class }
                {****************************}
                if next_token.kind = extends_tok then
                  begin
                    Get_next_token;
                    Parse_superclass(type_ptr, decl_attributes_ptr)
                  end
                else if not type_ptr^.static then
                  begin
                    {*******************************************************}
                    { if no parent class, then create implicit parent class }
                    {*******************************************************}
                    type_ptr^.parent_class_ref :=
                      type_ptr_type(base_class_decl_ptr^.type_ptr);
                    decl_attributes_ptr^.type_attributes_ptr^.parent_type_attributes_ptr := base_class_type_attributes_ptr;
                    Mark_decl_attributes(Get_decl_attributes(base_class_decl_ptr), true);
                  end;
              end
            else
              begin
                {******************************}
                { parse interface's interfaces }
                {******************************}
                if next_token.kind = extends_tok then
                  begin
                    Get_next_token;
                    Parse_interfaces(type_ptr, decl_attributes_ptr);
                  end;
              end;

            if parsing_ok then
              begin
                if next_token.kind in [does_tok, has_tok, is_tok] then
                  begin
                    {***************}
                    { parse methods }
                    {***************}
                    temp := parsing_native_decls;
                    parsing_native_decls := false;
                    nonpublic_members := false;

                    if (next_token.kind = does_tok) then
                      begin
                        Get_next_token;
                        if type_ptr^.class_kind <> interface_class then
                          Parse_method_decls(type_ptr, decl_attributes_ptr)
                        else
                          Parse_interface_method_decls(type_ptr,
                            decl_attributes_ptr);
                      end;

                    {*******************************************}
                    { check for undefined abstract declarations }
                    {*******************************************}
                    if parsing_ok then
                      if next_token.kind in [has_tok, is_tok] then
                        begin
                          Push_prev_scope(type_attributes_ptr^.public_table_ptr);
                          Push_prev_scope(type_attributes_ptr^.protected_table_ptr);
                          Push_prev_scope(type_attributes_ptr^.private_table_ptr);

                          if not decl_attributes_ptr^.abstract then
                            Check_abstract_decls(type_ptr);
                          Reset_interface_methods(type_ptr);

                          if (next_token.kind = has_tok) and parsing_ok then
                            begin
                              Get_next_token;
                              if type_ptr^.class_kind <> interface_class then
                                Parse_member_decls(type_ptr,
                                  decl_attributes_ptr, nonpublic_members)
                              else
                                Parse_const_member_decls(type_ptr,
                                  decl_attributes_ptr);
                            end;

                          {**************************************}
                          { find if class objects are assignable }
                          {**************************************}
                          Set_copyable_class(type_ptr, nonpublic_members);

                          {**********************}
                          { parse implementation }
                          {**********************}
                          if type_ptr^.class_kind <> interface_class then
                            if next_token.kind = is_tok then
                              begin
                                Get_next_token;
                                Unlock_protected_tables(type_attributes_ptr);
                                Unlock_symbol_table(type_attributes_ptr^.private_table_ptr);

                                {****************************}
                                { parse private declarations }
                                {****************************}
                                Parse_decls(type_ptr^.class_decls_ptr,
                                  type_ptr);

                                {**************************}
                                { parse static initializer }
                                {**************************}
                                Parse_stmts(type_ptr^.class_init_ptr);

                                Lock_protected_tables(type_attributes_ptr);
                                Lock_symbol_table(type_attributes_ptr^.private_table_ptr);
                              end;
                        end
                      else if type_ptr^.class_kind <> interface_class then
                        begin
                          if type_ptr^.class_kind <> abstract_class then
                            begin
                              Parse_error;
                              writeln('Expected class members or implementation here.');
                              error_reported := true;
                            end;
                        end;

                    {***********************************************************}
                    { check class for unimplemented forward method declarations }
                    {***********************************************************}
                    if parsing_ok then
                      if type_ptr^.class_kind <> interface_class then
                        Check_forward_decls(type_ptr^.method_decls_ptr);

                    parsing_native_decls := temp;
                    Match(end_tok);
                  end;

                Match(semi_colon_tok);

                {************************************}
                { get comments at end of declaration }
                {************************************}
                Get_post_decl_info(decl_info_ptr);
              end; {if interfaces parsed_ok}

            Pop_static_scope;
          end; {if class name parsed_ok}
      end {if in predict_set}
    else
      parsing_ok := false;
end; {procedure Parse_class_decl}


end.

