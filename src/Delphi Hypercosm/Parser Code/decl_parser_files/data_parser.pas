unit data_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            data_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse data             }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, type_attributes, decl_attributes, stmt_attributes, expr_attributes,
    exprs, stmts, decls;


type
  storage_class_type = (local_storage, const_storage, final_storage,
    static_storage);


  {*****************************************}
  { routines for creating data declarations }
  {*****************************************}
function New_data_decl(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type): decl_ptr_type;
function New_implicit_data_decl(id: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type): decl_ptr_type;

{*************************************}
{ routine for parsing assignment tail }
{*************************************}
procedure Parse_initializer(var stmt_ptr: stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);

{**************************************}
{ routines for parsing data attributes }
{**************************************}
procedure Parse_storage_class(var storage_class: storage_class_type);

{**************************************}
{ routines for setting data attributes }
{**************************************}
procedure Set_decl_storage_class(decl_attributes_ptr: decl_attributes_ptr_type;
  storage_class: storage_class_type);

{********************************}
{ routines for parsing data type }
{********************************}
procedure Parse_data_type(var type_attributes_ptr: type_attributes_ptr_type);
function Copy_base_decl_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type): decl_attributes_ptr_type;

{****************************************}
{ routines for parsing data declarations }
{****************************************}
procedure Parse_var_decls(var decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_var_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Parse_data_decl_tail(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  init_required: boolean);

{***************************************}
{ routines for writing enumerated types }
{***************************************}
procedure Write_storage_class(storage_class: storage_class_type);


implementation
uses
  prim_attributes, type_decls, make_type_decls, tokens, tokenizer, native_glue,
    parser, comment_parser, match_literals, match_terms, assign_parser,
    cons_parser, scope_stacks, scoping, array_parser, implicit_derefs;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                          declarations                         }
{***************************************************************}
{       <decl> ::= <include>                                    }
{       <decl> ::= <enum_decl>                                  }
{       <decl> ::= <struct_decl>                                }
{       <decl> ::= <class_decl>                                 }
{       <decl> ::= <simple_decl>                                }
{       <decl> ::= <complex_decl>                               }
{                                                               }
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}


{***************************************************************}
{                       type declarations                       }
{***************************************************************}
{       <enum_decl> ::= enum id = <enums> ;                     }
{       <enums> ::= <enums> <more_enums>                        }
{       <more_enums> ::= , <enums>                              }
{       <enum> ::= id                                           }
{***************************************************************}


{***************************************************************}
{                      simple declarations                      }
{***************************************************************}
{       <simple_decl> ::= <var_decl>                            }
{                                                               }
{       <data_decl> ::= <data_type> id <array_decls>            }
{                                                               }
{       <data_type> ::= boolean                                 }
{       <data_type> ::= char                                    }
{       <data_type> ::= integer                                 }
{       <data_type> ::= scalar                                  }
{       <data_type> ::= complex                                 }
{       <data_type> ::= vector                                  }
{                                                               }
{       <initializer> ::= = <unit>                              }
{                                                               }
{       <array_decls> ::= <array_decl> <array_decls>            }
{       <array_decls> ::=                                       }
{       <array_decl> ::= [ <ranges> ]                           }
{       <array_decl> ::=                                        }
{                                                               }
{       <ranges> ::= <range> <more_ranges>                      }
{       <more_ranges> ::= , <ranges>                            }
{       <more_ranges> ::=                                       }
{                                                               }
{       <range> ::= <min> .. <max>                              }
{       <range> ::=                                             }
{       <min> ::= <integer_expr>                                }
{       <max> ::= <integer_expr>                                }
{***************************************************************}


{***************************************************************}
{                      var declarations                         }
{***************************************************************}
{       <var_decl> ::= <access_level> <storage_class>           }
{                      <var_data> <more_vars> ;                 }
{                                                               }
{       <access_level> ::= public                               }
{       <access_level> ::= private                              }
{       <access_level> ::= protected                            }
{                                                               }
{       <storage_class> ::= const                               }
{       <storage_class> ::= final                               }
{       <storage_class> ::= static                              }
{       <storage_class> ::= reference                           }
{       <storage_class> ::=                                     }
{                                                               }
{       <var_data> ::= <data_decl> <var_decl_end>               }
{       <more_vars> ::= , <id> <var_decl_end> <more_vars>       }
{       <more_vars> ::=                                         }
{                                                               }
{       <var_decl_end> ::= <initializer>                        }
{       <var_decl_end> ::=                                      }
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


  {************************  productions  ************************}
  {       <initializer> ::= = <expr>                              }
  {       <initializer> ::= is <expr>                             }
 {       <initializer> ::= does <expr>                           }
 {       <initializer> ::= refers to <expr>                      }
  {***************************************************************}

procedure Parse_initializer(var stmt_ptr: stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  temp: boolean;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in initializer_predict_set then
      begin
        temp := static_mode;
        static_mode := decl_attributes_ptr^.static;

        {*********************************}
        { create unique reference to data }
        {*********************************}
        {expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);}
        {Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);}

        expr_ptr := New_expr(itself);
        expr_attributes_ptr :=
          New_variable_expr_attributes(decl_attributes_ptr);
        Set_expr_attributes(expr_ptr, expr_attributes_ptr);

        if next_token.kind <> refers_tok then
          begin
            {*****************}
            { primitive types }
            {*****************}
            if not (expr_attributes_ptr^.type_attributes_ptr^.kind in
              reference_type_kinds) then
              Parse_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr)

              {*****************}
              { reference types }
              {*****************}
            else
              case next_token.kind of
                equal_tok, does_tok:
                  Parse_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);

                is_tok:
                  Parse_ptr_assign_tail(stmt_ptr, expr_ptr,
                    expr_attributes_ptr);
              end;
          end

            {***********************}
            { reference assignments }
            {***********************}
        else
          Parse_ref_assign_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);

        static_mode := temp;
      end
    else
      begin
        Parse_error;
        writeln('Expected an intializer here.');
        error_reported := true;
      end;
end; {procedure Parse_initializer}


{************************  productions  ************************}
{       <storage_class> ::= const                               }
{       <storage_class> ::= final                               }
{       <storage_class> ::= static                              }
{       <storage_class> ::= reference                           }
{       <storage_class> ::=                                     }
{***************************************************************}

procedure Parse_storage_class(var storage_class: storage_class_type);
begin
  if parsing_ok then
    if next_token.kind in storage_class_predict_set then
      begin
        case next_token.kind of

          {***************************************}
          { constant (static, final) declarations }
          {***************************************}
          const_tok:
            begin
              if parsing_return_decls then
                begin
                  Parse_error;
                  writeln('Return values may not be constant.');
                  error_reported := true;
                end;
              storage_class := const_storage;
            end;

          {******************}
          { static variables }
          {******************}
          static_tok:
            begin
              if parsing_param_decls then
                begin
                  Parse_error;
                  writeln('Static variables may not be declared as parameters.');
                  error_reported := true;
                end
              else if parsing_return_decls then
                begin
                  Parse_error;
                  writeln('Return values may not be static.');
                  error_reported := true;
                end
              else if (Get_static_scope_level <= 1) then
                begin
                  Parse_error;
                  writeln('Static variables may not be declared');
                  writeln('outside of a subprogram declaration.');
                  error_reported := true;
                end;
              storage_class := static_storage;
            end;

          {********************************}
          { final (nonstatic) declarations }
          {********************************}
          final_tok:
            begin
              if parsing_return_decls then
                begin
                  Parse_error;
                  writeln('Return values may not be final.');
                  error_reported := true;
                end;
              storage_class := final_storage;
            end;

        end; {case}

        Get_next_token;
      end
    else
      storage_class := local_storage;
end; {procedure Parse_storage_class}


procedure Set_decl_storage_class(decl_attributes_ptr: decl_attributes_ptr_type;
  storage_class: storage_class_type);
begin
  {***********************************}
   { const, static, and reference vars }
   {***********************************}
  if storage_class <> local_storage then
    case storage_class of
      const_storage:
        begin
          decl_attributes_ptr^.static := true;
          decl_attributes_ptr^.final := true;
        end;
      final_storage:
        decl_attributes_ptr^.final := true;
      static_storage:
        decl_attributes_ptr^.static := true;
    end;
end; {procedure Set_decl_storage_class}


procedure Parse_data_dims(var type_attributes_ptr: type_attributes_ptr_type);
var
  dimensions: integer;
begin
  if parsing_ok then
    if next_token.kind = left_bracket_tok then
      begin
        Get_next_token;
        dimensions := 1;

        while next_token.kind = comma_tok do
          begin
            Get_next_token;
            dimensions := dimensions + 1;
          end;

        Match(right_bracket_tok);
        Dim_type_attributes(type_attributes_ptr, dimensions);

        Parse_data_dims(type_attributes_ptr);
      end;
end; {procedure Parse_data_dims}


procedure Parse_data_reference(var type_attributes_ptr:
  type_attributes_ptr_type);
begin
  if parsing_ok then
    if next_token.kind = reference_tok then
      begin
        if type_attributes_ptr^.kind <> type_reference then
          begin
            Get_next_token;
            type_attributes_ptr :=
              New_reference_type_attributes(type_attributes_ptr);
          end
        else
          begin
            Parse_error;
            writeln('Can not create a reference to a reference.');
            error_reported := true;
          end;
      end;
end; {procedure Parse_data_reference}


procedure Parse_derived_type(var type_attributes_ptr: type_attributes_ptr_type);
begin
  while next_token.kind in [reference_tok, left_bracket_tok] do
    case next_token.kind of

      reference_tok:
        Parse_data_reference(type_attributes_ptr);

      left_bracket_tok:
        Parse_data_dims(type_attributes_ptr);

    end;
end; {procedure Parse_derived_type}


{************************  productions  ************************}
{       <data_type> ::= boolean                                 }
{       <data_type> ::= char                                    }
{       <data_type> ::= byte                                    }
{       <data_type> ::= short                                   }
{       <data_type> ::= integer                                 }
{       <data_type> ::= long                                    }
{       <data_type> ::= scalar                                  }
{       <data_type> ::= double                                  }
{       <data_type> ::= complex                                 }
{       <data_type> ::= vector                                  }
{       <data_type> ::= type <type name>                        }
{***************************************************************}

procedure Parse_data_type(var type_attributes_ptr: type_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  type_ptr: type_ptr_type;
  name: string;
begin
  if parsing_ok then
    if next_token.kind in data_predict_set then
      begin
        decl_attributes_ptr := nil;

        case next_token.kind of

          {**********************}
          { primitive data types }
          {**********************}
          boolean_tok:
            type_attributes_ptr := boolean_type_attributes_ptr;
          char_tok:
            type_attributes_ptr := char_type_attributes_ptr;

          byte_tok:
            type_attributes_ptr := byte_type_attributes_ptr;
          short_tok:
            type_attributes_ptr := short_type_attributes_ptr;

          integer_tok:
            type_attributes_ptr := integer_type_attributes_ptr;
          long_tok:
            type_attributes_ptr := long_type_attributes_ptr;

          scalar_tok:
            type_attributes_ptr := scalar_type_attributes_ptr;
          double_tok:
            type_attributes_ptr := double_type_attributes_ptr;

          complex_tok:
            type_attributes_ptr := complex_type_attributes_ptr;
          vector_tok:
            type_attributes_ptr := vector_type_attributes_ptr;

          string_tok:
            type_attributes_ptr := string_type_attributes_ptr;

          {*************************}
          { user defined data types }
          {*************************}
          type_id_tok:
            begin
              name := Token_to_id(next_token);
              if Found_type_id(name, decl_attributes_ptr, stmt_attributes_ptr)
                then
                begin
                  if decl_attributes_ptr^.kind <> type_decl_attributes then
                    begin
                      Parse_error;
                      writeln('This identifier is not the name of a type.');
                      error_reported := true;
                    end
                  else
                    begin
                      {*******************************}
                      { mark type declaration as used }
                      {*******************************}
                      type_attributes_ptr :=
                        decl_attributes_ptr^.type_attributes_ptr;
                      type_ptr := Get_type_decl(type_attributes_ptr);
                      Mark_type(type_ptr, true);
                    end;
                end
              else
                begin
                  Parse_error;
                  writeln('Type ', Quotate_str(next_token.id),
                    ' has not been declared.');
                  error_reported := true;
                end;
            end;
        end; {case}

        Get_next_token;

        {******************************************}
        { parse type reference or array dimensions }
        {******************************************}
        Parse_derived_type(type_attributes_ptr);
      end
    else
      begin
        Parse_error;
        writeln('Expected the name of a type here.');
        error_reported := true;
      end;
end; {procedure Parse_data_type}


function Get_data_decl_kind(type_attributes_ptr: type_attributes_ptr_type):
  decl_kind_type;
var
  kind: decl_kind_type;
begin
  case type_attributes_ptr^.kind of

    {****************************}
    { primitive enumerated types }
    {****************************}
    type_boolean:
      kind := boolean_decl;
    type_char:
      kind := char_decl;

    {**************************}
    { primitive integral types }
    {**************************}
    type_byte:
      kind := byte_decl;
    type_short:
      kind := short_decl;
    type_integer, type_enum:
      kind := integer_decl;
    type_long:
      kind := long_decl;

    {************************}
    { primitive scalar types }
    {************************}
    type_scalar:
      kind := scalar_decl;
    type_double:
      kind := double_decl;
    type_complex:
      kind := complex_decl;
    type_vector:
      kind := vector_decl;

    {********************}
    { user defined types }
    {********************}
    type_array:
      kind := array_decl;

    type_struct:
      begin
        if type_attributes_ptr^.static then
          kind := static_struct_decl
        else
          kind := struct_decl;
      end;

    type_class:
      begin
        if type_attributes_ptr^.class_alias_type_attributes_ptr <> nil then
          kind :=
            Get_data_decl_kind(type_attributes_ptr^.class_alias_type_attributes_ptr)
        else if type_attributes_ptr^.static then
          kind := static_struct_decl
        else
          kind := struct_decl;
      end;

    {*************************}
    { user defined code types }
    {*************************}
    type_code:
      kind := code_decl;

    {********************************}
    { aliased type data declarations }
    {********************************}
    type_alias, type_class_alias:
      kind := Get_data_decl_kind(Unalias_type_attributes(type_attributes_ptr));

    {*************************}
    { references to all types }
    {*************************}
    type_reference:
      begin
        if type_attributes_ptr^.reference_type_attributes_ptr^.kind <> type_code
          then
          kind := reference_decl
        else
          kind := code_reference_decl;
      end;

  else
    kind := null_decl;
  end; {case}

  Get_data_decl_kind := kind;
end; {function Get_data_decl_kind}


{************************  productions  ************************}
{       <data_decl> ::= <data_type> id                          }
{***************************************************************}

function New_data_decl(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type): decl_ptr_type;
var
  decl_ptr: decl_ptr_type;
  type_ptr: type_ptr_type;
begin
  {*****************************}
  { create new data declaration }
  {*****************************}
  decl_ptr :=
    New_decl(Get_data_decl_kind(expr_attributes_ptr^.type_attributes_ptr));
  if decl_ptr^.kind = static_struct_decl then
    begin
      type_ptr := Get_type_decl(expr_attributes_ptr^.type_attributes_ptr);
      decl_ptr^.static_struct_type_ref := forward_type_ptr_type(type_ptr);
    end;

  {*****************************}
  { initialize data declaration }
  {*****************************}
  Set_decl_info(decl_ptr, decl_info_ptr);
  decl_ptr^.data_decl.data_expr_ptr := expr_ptr;

  {**********************************}
  { set links to and from attributes }
  {**********************************}
  Set_decl_attributes(decl_ptr, expr_attributes_ptr^.decl_attributes_ptr);
  Set_expr_attributes(expr_ptr_type(expr_attributes_ptr^.expr_ref),
    expr_attributes_ptr);

  {********************************}
  { set decl flags from attributes }
  {********************************}
  Set_decl_properties(decl_ptr, expr_attributes_ptr^.decl_attributes_ptr);

  New_data_decl := decl_ptr;
end; {function New_data_decl}


function New_implicit_data_decl(id: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type): decl_ptr_type;
var
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_ptr: decl_ptr_type;
begin
  {*****************************}
  { initialize data declaration }
  {*****************************}
  Make_implicit_new_id(id, expr_ptr, expr_attributes_ptr, decl_attributes_ptr);

  if parsing_ok then
    decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr, nil)
  else
    decl_ptr := nil;

  New_implicit_data_decl := decl_ptr;
end; {function New_implicit_data_decl}


function Copy_base_decl_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type): decl_attributes_ptr_type;
var
  base_decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  base_decl_attributes_ptr := Copy_decl_attributes(decl_attributes_ptr);

  type_attributes_ptr := decl_attributes_ptr^.base_type_attributes_ref;
  base_decl_attributes_ptr^.dimensions :=
    Get_data_abs_dims(type_attributes_ptr);
  base_decl_attributes_ptr^.base_type_attributes_ref := type_attributes_ptr;
  base_decl_attributes_ptr^.type_attributes_ptr := type_attributes_ptr;

  Copy_base_decl_attributes := base_decl_attributes_ptr;
end; {function Copy_base_decl_attributes}


procedure Parse_data_decl_tail(decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  init_required: boolean);
var
  type_attributes_ptr: type_attributes_ptr_type;
  struct_type_ptr: type_ptr_type;
begin
  if parsing_ok then
    begin
      if next_token.kind in initializer_predict_set then
        init_required := true;

      {***********************************}
      { find base data type of expression }
      {***********************************}
      type_attributes_ptr :=
        Base_type_attributes(decl_attributes_ptr^.type_attributes_ptr);

      {****************************************}
      { parse explicit or implicit constructor }
      {****************************************}
      if type_attributes_ptr^.kind in structured_type_kinds then
        if next_token.kind <> is_tok then
          begin
            struct_type_ptr := Get_type_decl(type_attributes_ptr);

            if not decl_attributes_ptr^.abstract then
              begin
                case decl_ptr^.kind of

                  struct_decl:
                    Parse_implicit_struct_new(decl_ptr^.data_decl.init_expr_ptr,
                      struct_type_ptr);

                  static_struct_decl:
                    begin
                      if not (next_token.kind in initializer_predict_set) then
                        if type_attributes_ptr^.kind = type_class then
                          Parse_constructor_stmt(decl_ptr^.data_decl.init_stmt_ptr, struct_type_ptr);
                    end;

                  array_decl:
                    Parse_struct_array_new(decl_ptr^.data_decl.init_expr_ptr,
                      struct_type_ptr)

                end; {case}
              end; {if}

            {************************************************************}
            { if constructor is present, then no initializer is required }
            {************************************************************}
            with decl_ptr^.data_decl do
              if (init_expr_ptr <> nil) or (init_stmt_ptr <> nil) then
                init_required := false;
          end;

      {******************************}
      { check reference initializers }
      {******************************}
      if parsing_ok then
        if next_token.kind = is_tok then
          if (decl_ptr^.data_decl.init_expr_ptr <> nil) then
            with decl_ptr^.data_decl.init_expr_ptr^ do
              case kind of

                boolean_array_dim..reference_array_dim:
                  if dim_bounds_list_ptr^.first <> nil then
                    begin
                      Parse_error;
                      writeln('A reference initializer is not allowed here');
                      writeln('because this array has already been dimensioned.');
                      error_reported := true;
                    end;

                struct_new:
                  begin
                    Parse_error;
                    writeln('A reference initializer is not allowed here');
                    writeln('because this structure has already been allocated.');
                    error_reported := true;
                  end;

              end; {case}

      {****************************}
      { parse explicit initializer }
      {****************************}
      if init_required then
        Parse_initializer(decl_ptr^.data_decl.init_stmt_ptr,
          decl_attributes_ptr);
    end;
end; {procedure Parse_data_decl_tail}


procedure Parse_var_decl(var decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  expr_ptr, dim_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  native_index: integer;
  decl_info_ptr: decl_info_ptr_type;
  scope_ptr: scope_ptr_type;
  init_required: boolean;
  name: string_type;
begin
  {******************}
  { parse identifier }
  {******************}
  Get_prev_decl_info(decl_info_ptr);
  Match_unique_id(name);

  if parsing_ok then
    begin
      expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
      Set_scope_decl_attributes(decl_attributes_ptr, scope_ptr);
      Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);

      {************************}
      { parse array dimensions }
      {************************}
      Parse_array_decl_dims(dim_expr_ptr, expr_attributes_ptr,
        decl_attributes_ptr, false);

      if parsing_ok then
        begin
          {*****************************}
          { create new data declaration }
          {*****************************}
          decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr,
            decl_info_ptr);
          decl_ptr^.data_decl.init_expr_ptr := dim_expr_ptr;

          {********************}
          { check native decls }
          {********************}
          if decl_attributes_ptr^.native then
            if not Found_native_data_by_name(name, native_index) then
              begin
                Parse_error;
                error_reported := true;
                writeln('Unrecognized native declaration.');
              end
            else
              decl_ptr^.data_decl.native_index := native_index;

          {******************************************}
          { parse implicit and explicit initializers }
          {******************************************}
          init_required := decl_attributes_ptr^.final;
          if parsing_optional_param_decls then
            if (decl_attributes_ptr^.dimensions = 0) then
              init_required := true;
          Parse_data_decl_tail(decl_ptr, decl_attributes_ptr, init_required);

          {***************************}
          { activate data declaration }
          {***************************}
          Enter_scope(scope_ptr, name, decl_attributes_ptr);
        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_var_decl}


{************************  productions  ************************}
{       <var_decl> ::= <storage_class> <var_data> <more_vars> ; }
{                                                               }
{       <storage_class> ::= const                               }
{       <storage_class> ::= final                               }
{       <storage_class> ::= static                              }
{       <storage_class> ::= reference                           }
{       <storage_class> ::=                                     }
{                                                               }
{       <var_data> ::= <data_decl> <var_decl_end>               }
{       <more_vars> ::= , <id> <var_decl_end> <more_vars>       }
{       <more_vars> ::=                                         }
{                                                               }
{       <var_decl_end> ::= <initializer>                        }
{       <var_decl_end> ::=                                      }
{***************************************************************}

procedure Parse_var_decl_list(var decl_ptr, last_decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  storage_class: storage_class_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      {********************************************}
      { parse variable storage class and base type }
      {********************************************}
      if decl_attributes_ptr = nil then
        begin
          Parse_storage_class(storage_class);
          Parse_data_type(type_attributes_ptr);
          decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
            type_attributes_ptr, nil);
          Set_decl_storage_class(decl_attributes_ptr, storage_class);
        end;

      if parsing_ok then
        begin
          {*************************}
          { set variable attributes }
          {*************************}
          decl_attributes_ptr^.native := parsing_native_decls and not
            parsing_param_decls;

          {**********************************}
          { parse first variable declaration }
          {**********************************}
          Parse_var_decl(decl_ptr, decl_attributes_ptr);

          if parsing_ok then
            begin
              {*****************************************}
              { parse additional variables in same decl }
              {*****************************************}
              last_decl_ptr := decl_ptr;
              while (next_token.kind = comma_tok) and parsing_ok do
                begin
                  Get_next_token;

                  {*************************************}
                  { save comments at end of declaration }
                  {*************************************}
                  Get_post_decl_info(last_decl_ptr^.decl_info_ptr);

                  decl_attributes_ptr :=
                    Copy_base_decl_attributes(decl_attributes_ptr);
                  Parse_var_decl(last_decl_ptr^.next, decl_attributes_ptr);

                  last_decl_ptr^.next^.decl_info_ptr^.decl_number :=
                    last_decl_ptr^.decl_info_ptr^.decl_number + 1;
                  last_decl_ptr := last_decl_ptr^.next;
                end; {while}

              Match(semi_colon_tok);

              {*************************************}
              { save comments at end of declaration }
              {*************************************}
              Get_post_decl_info(last_decl_ptr^.decl_info_ptr);
            end;
        end;
    end;
end; {procedure Parse_var_decl_list}


procedure Parse_var_decls(var decl_ptr: decl_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  last_decl_ptr: decl_ptr_type;
begin
  Parse_var_decl_list(decl_ptr, last_decl_ptr, decl_attributes_ptr);
end; {procedure Parse_var_decls}


{***************************************************}
{ routines for parsing structured type declarations }
{***************************************************}


procedure Write_storage_class(storage_class: storage_class_type);
begin
  case storage_class of
    local_storage:
      write('local_storage');
    const_storage:
      write('const_storage');
    static_storage:
      write('static_storage');
    final_storage:
      write('final_storage');
  end; {case}
end; {procedure Write_storage_class}


end.
