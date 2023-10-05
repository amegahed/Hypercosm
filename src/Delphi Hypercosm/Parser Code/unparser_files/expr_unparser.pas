unit expr_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           expr_unparser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program expressions from it.               }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, stmt_attributes, comments, exprs;


{**********************************}
{ routine to unparse an expression }
{**********************************}
procedure Unparse_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
procedure Unparse_exprs(var outfile: text;
  expr_ptr: expr_ptr_type);
procedure Unparse_subexprs(var outfile: text;
  expr_ptr: expr_ptr_type);

{******************************}
{ diagnostic unparser routines }
{******************************}
procedure Unparse_expr_addr(var outfile: text;
  expr_ptr: expr_ptr_type);
procedure Unparse_decl_addr(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Unparse_static_level(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Unparse_dynamic_level(var outfile: text;
  stmt_attributes_ptr: stmt_attributes_ptr_type);

{*********************************************}
{ routines to get comments from an expression }
{*********************************************}
function Get_prev_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;
function Get_post_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;


implementation
uses
  chars, strings, string_io, symbol_tables, type_attributes, expr_attributes,
  value_attributes, stmts, decls, type_decls, compare_exprs, unparser,
  term_unparser, array_unparser, stmt_unparser, type_unparser, assign_unparser;


{*********************************************}
{ routines to get comments from an expression }
{*********************************************}


function Get_prev_sub_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if expr_ptr <> nil then
    with expr_ptr^ do

      {***************************************************************}
      {                      expression operators       	            }
      {***************************************************************}

      {*****************}
      { unary operators }
      {*****************}
      if kind in unary_operator_set then
        comment_ptr := Get_prev_expr_comments(operand_ptr)

        {******************}
        { binary operators }
        {******************}
      else if kind in binary_operator_set then
        comment_ptr := Get_prev_expr_comments(left_operand_ptr)

        {***************************************************************}
        {                    array expression terms                     }
        {***************************************************************}
      else if kind in array_expr_set then
        case kind of

          {*******************}
          { array expressions }
          {*******************}
          boolean_array_expr..reference_array_expr, subarray_expr, element_expr:
            ;

          {********************}
          { array dimensioning }
          {********************}
          boolean_array_dim..reference_array_dim:
            ;

          {*********************}
          { array dereferencing }
          {*********************}
          boolean_array_deref..reference_array_deref:
            ;

          {****************************}
          { array subrange expressions }
          {****************************}
          boolean_array_subrange..reference_array_subrange:
            ;

        end {case}

          {***************************************************************}
          {                   structure expression terms                  }
          {***************************************************************}
      else if kind in struct_expr_set then
        case kind of

          {********************}
          { struct expressions }
          {********************}
          struct_expr:
            ;

          {**********************}
          { structure allocation }
          {**********************}
          struct_new:
            ;

          {*************************}
          { structure dereferencing }
          {*************************}
          struct_offset, struct_deref:
            begin
              if implicit_field then
                comment_ptr := Get_prev_expr_comments(field_expr_ptr)
              else
                comment_ptr := Get_prev_expr_comments(base_expr_ptr);
            end;
          field_offset, field_deref:
            begin
              comment_ptr := Get_prev_expr_comments(field_name_ptr);
            end;

        end {case}

          {***************************************************************}
          {                        expression terms                       }
          {***************************************************************}
      else if not (kind in terminal_set) then
        case kind of

          {*************************}
          { explicit ptr conversion }
          {*************************}
          ptr_cast, type_query:
            ;

          {********************}
          { tuplet expressions }
          {********************}
          complex_pair, vector_triplet:
            ;

          {************************}
          { functional expressions }
          {************************}
          user_fn:
            ;

        end; {case}

  Get_prev_sub_expr_comments := comment_ptr;
end; {function Get_prev_sub_expr_comments}


function Get_post_sub_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if expr_ptr <> nil then
    with expr_ptr^ do

      {***************************************************************}
      {                      expression operators       	            }
      {***************************************************************}

      {*****************}
      { unary operators }
      {*****************}
      if kind in unary_operator_set then
        comment_ptr := Get_post_expr_comments(operand_ptr)

        {******************}
        { binary operators }
        {******************}
      else if kind in binary_operator_set then
        comment_ptr := Get_post_expr_comments(right_operand_ptr)

        {***************************************************************}
        {                    array expression terms                     }
        {***************************************************************}
      else if kind in array_expr_set then
        case kind of

          {*******************}
          { array expressions }
          {*******************}
          boolean_array_expr..reference_array_expr, subarray_expr, element_expr:
            ;

          {********************}
          { array dimensioning }
          {********************}
          boolean_array_dim..reference_array_dim:
            ;

          {*********************}
          { array dereferencing }
          {*********************}
          boolean_array_deref..reference_array_deref:
            ;

          {****************************}
          { array subrange expressions }
          {****************************}
          boolean_array_subrange..reference_array_subrange:
            ;

        end {case}

          {***************************************************************}
          {                  structure expression terms                   }
          {***************************************************************}
      else if kind in struct_expr_set then
        case kind of

          {********************}
          { struct expressions }
          {********************}
          struct_expr:
            ;

          {**********************}
          { structure allocation }
          {**********************}
          struct_new:
            ;

          {*************************}
          { structure dereferencing }
          {*************************}
          struct_deref, struct_offset:
            comment_ptr := Get_post_expr_comments(field_expr_ptr);
          field_deref, field_offset:
            comment_ptr := Get_post_expr_comments(field_name_ptr);

        end {case}

          {***************************************************************}
          {                        expression terms                       }
          {***************************************************************}
      else if not (kind in terminal_set) then
        case kind of

          {*************************}
          { explicit ptr conversion }
          {*************************}
          ptr_cast, type_query:
            ;

          {********************}
          { tuplet expressions }
          {********************}
          complex_pair, vector_triplet:
            ;

          {************************}
          { functional expressions }
          {************************}
          user_fn:
            ;
        end; {case}

  Get_post_sub_expr_comments := comment_ptr;
end; {function Get_post_sub_expr_comments}


function Get_prev_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if expr_ptr <> nil then
    begin
      {*****************************}
      { get comments from expr node }
      {*****************************}
      if expr_ptr^.expr_info_ptr <> nil then
        comment_ptr := Get_prev_comments(expr_ptr^.expr_info_ptr^.comments_ptr);

      {***********************************************}
      { if no comments and expression is nonterminal, }
      { then get comments from its subexpression.     }
      {***********************************************}
      if comment_ptr = nil then
        comment_ptr := Get_prev_sub_expr_comments(expr_ptr);
    end; {if}

  Get_prev_expr_comments := comment_ptr;
end; {function Get_prev_expr_comments}


function Get_post_expr_comments(expr_ptr: expr_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  comment_ptr := nil;

  if expr_ptr <> nil then
    begin
      {*****************************}
      { get comments from expr node }
      {*****************************}
      if expr_ptr^.expr_info_ptr <> nil then
        comment_ptr := Get_post_comments(expr_ptr^.expr_info_ptr^.comments_ptr);

      {***********************************************}
      { if no comments and expression is nonterminal, }
      { then get comments from its subexpression.     }
      {***********************************************}
      if comment_ptr = nil then
        comment_ptr := Get_post_sub_expr_comments(expr_ptr);
    end;

  Get_post_expr_comments := comment_ptr;
end; {function Get_post_expr_comments}


{***********************}
{ unparsing expressions }
{***********************}


procedure Unparse_unary_operator(var outfile: text;
  kind: expr_kind_type);
begin
  case kind of

    {********************}
    { negation operators }
    {********************}

    not_op:
      Unparse_str(outfile, 'not');

    byte_negate, short_negate, integer_negate, long_negate, scalar_negate,
      double_negate, complex_negate, vector_negate:
      Unparse_str(outfile, '-');

    {**********************}
    { addressing operators }
    {**********************}

    address_op:
      if show_implicit then
        Unparse_str(outfile, '&');

    deref_op:
      if show_implicit then
        Unparse_str(outfile, '*');

    {***************************}
    { implicit type conversions }
    {***************************}

    byte_to_short:
      if show_implicit then
        Unparse_str(outfile, '(short)');

    short_to_integer:
      if show_implicit then
        Unparse_str(outfile, '(integer)');

    integer_to_long:
      if show_implicit then
        Unparse_str(outfile, '(scalar)');

    integer_to_scalar, long_to_scalar:
      if show_implicit then
        Unparse_str(outfile, '(scalar)');

    long_to_double, scalar_to_double:
      if show_implicit then
        Unparse_str(outfile, '(double)');

    scalar_to_complex:
      if show_implicit then
        Unparse_str(outfile, '(complex)');

    {*******************}
    { vector components }
    {*******************}

    vector_x:
      write('.x');
    vector_y:
      write('.y');
    vector_z:
      write('.z');

    {*****************************}
    { memory allocation functions }
    {*****************************}

    new_struct_fn:
      Unparse_str(outfile, 'new');

    dim_array_fn:
      Unparse_str(outfile, 'dim');

    {*******************}
    { special functions }
    {*******************}

    min_fn:
      Unparse_str(outfile, 'min');

    max_fn:
      Unparse_str(outfile, 'max');

    num_fn:
      Unparse_str(outfile, 'num');

  end; {case}
end; {procedure Unparse_unary_operator}


procedure Unparse_binary_operator(var outfile: text;
  kind: expr_kind_type);
begin
  case kind of

    {*******************}
    { logical operators }
    {*******************}
    and_op:
      Unparse_str(outfile, 'and');
    or_op:
      Unparse_str(outfile, 'or');

    and_if_op:
      Unparse_str(outfile, 'and if');
    or_if_op:
      Unparse_str(outfile, 'or if');

    {**********************}
    { enumerated operators }
    {**********************}
    boolean_equal, char_equal:
      Unparse_str(outfile, 'is');
    boolean_not_equal, char_not_equal:
      Unparse_str(outfile, concat(concat('isn', Char_to_str(single_quote)),
        't'));

    {**********************************}
    { array / struct pointer operators }
    {**********************************}
    array_ptr_equal, struct_ptr_equal:
      Unparse_str(outfile, 'is');
    array_ptr_not_equal, struct_ptr_not_equal:
      Unparse_str(outfile, concat(concat('isn', Char_to_str(single_quote)),
        't'));

    {*****************}
    { proto operators }
    {*****************}
    proto_equal:
      Unparse_str(outfile, 'does');
    proto_not_equal:
      Unparse_str(outfile, concat(concat('doesn', Char_to_str(single_quote)),
        't'));

    {*********************}
    { reference operators }
    {*********************}
    reference_equal:
      Unparse_str(outfile, 'refers to');
    reference_not_equal:
      Unparse_str(outfile, 'refers not to');

    {*******************}
    { integer operators }
    {*******************}
    byte_equal, short_equal, integer_equal, long_equal:
      Unparse_str(outfile, '=');
    byte_not_equal, short_not_equal, integer_not_equal, long_not_equal:
      Unparse_str(outfile, '<>');
    byte_less_than, short_less_than, integer_less_than, long_less_than:
      Unparse_str(outfile, '<');
    byte_greater_than, short_greater_than, integer_greater_than,
      long_greater_than:
      Unparse_str(outfile, '>');
    byte_less_equal, short_less_equal, integer_less_equal, long_less_equal:
      Unparse_str(outfile, '<=');
    byte_greater_equal, short_greater_equal, integer_greater_equal,
      long_greater_equal:
      Unparse_str(outfile, '>=');
    byte_add, short_add, integer_add, long_add:
      Unparse_str(outfile, '+');
    byte_subtract, short_subtract, integer_subtract, long_subtract:
      Unparse_str(outfile, '-');
    byte_multiply, short_multiply, integer_multiply, long_multiply:
      Unparse_str(outfile, '*');
    byte_divide, short_divide, integer_divide, long_divide:
      Unparse_str(outfile, 'div');
    byte_mod, short_mod, integer_mod, long_mod:
      Unparse_str(outfile, 'mod');

    {******************}
    { scalar operators }
    {******************}
    scalar_equal, double_equal:
      Unparse_str(outfile, '=');
    scalar_not_equal, double_not_equal:
      Unparse_str(outfile, '<>');
    scalar_less_than, double_less_than:
      Unparse_str(outfile, '<');
    scalar_greater_than, double_greater_than:
      Unparse_str(outfile, '>');
    scalar_less_equal, double_less_equal:
      Unparse_str(outfile, '<=');
    scalar_greater_equal, double_greater_equal:
      Unparse_str(outfile, '>=');
    scalar_add, double_add:
      Unparse_str(outfile, '+');
    scalar_subtract, double_subtract:
      Unparse_str(outfile, '-');
    scalar_multiply, double_multiply:
      Unparse_str(outfile, '*');
    scalar_divide, double_divide:
      Unparse_str(outfile, '/');
    scalar_exponent, double_exponent:
      Unparse_str(outfile, '^');

    {*******************}
    { complex operators }
    {*******************}
    complex_equal:
      Unparse_str(outfile, '=');
    complex_not_equal:
      Unparse_str(outfile, '<>');
    complex_add:
      Unparse_str(outfile, '+');
    complex_subtract:
      Unparse_str(outfile, '-');
    complex_multiply:
      Unparse_str(outfile, '*');
    complex_divide:
      Unparse_str(outfile, '/');

    {******************}
    { vector operators }
    {******************}
    vector_equal:
      Unparse_str(outfile, '=');
    vector_not_equal:
      Unparse_str(outfile, '<>');
    vector_add:
      Unparse_str(outfile, '+');
    vector_subtract:
      Unparse_str(outfile, '-');
    vector_scalar_multiply:
      Unparse_str(outfile, '*');
    vector_scalar_divide:
      Unparse_str(outfile, '/');
    vector_vector_multiply:
      Unparse_str(outfile, '*');
    vector_vector_divide:
      Unparse_str(outfile, '/');
    vector_mod:
      Unparse_str(outfile, 'mod');
    vector_dot_product:
      Unparse_str(outfile, 'dot');
    vector_cross_product:
      Unparse_str(outfile, 'cross');
    vector_parallel:
      Unparse_str(outfile, 'parallel');
    vector_perpendicular:
      Unparse_str(outfile, 'perpendicular');

  end; {case}
end; {procedure Unparse_binary_operator}


procedure Unparse_literal_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  id_ptr: id_ptr_type;
begin
  with expr_ptr^ do
    case kind of

      {*********************}
      { enumerated literals }
      {*********************}

      true_val:
        Unparse_str(outfile, 'true');

      false_val:
        Unparse_str(outfile, 'false');

      char_lit:
        begin
          Unparse_str(outfile, double_quote);
          Unparse_str(outfile, char_val);
          Unparse_str(outfile, double_quote);
        end;

      {******************}
      { integer literals }
      {******************}

      byte_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(byte)');
          Unparse_str(outfile, Integer_to_str(byte_val));
        end;

      short_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(short)');
          Unparse_str(outfile, Integer_to_str(short_val));
        end;

      integer_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(integer)');
          Unparse_str(outfile, Integer_to_str(integer_val));
        end;

      long_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(long)');
          Unparse_str(outfile, Integer_to_str(long_val));
        end;

      enum_lit:
        begin
          if enum_val <> 0 then
            begin
              expr_attributes_ptr := Get_expr_attributes(expr_ptr);
              symbol_table_ptr :=
                expr_attributes_ptr^.type_attributes_ptr^.enum_table_ptr;
              if Found_id_by_value(symbol_table_ptr, id_ptr, enum_val) then
                Unparse_str(outfile, Get_id_name(id_ptr));
            end
          else
            Unparse_str(outfile, 'none');
        end;

      {*****************}
      { scalar literals }
      {*****************}

      scalar_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(scalar)');
          with scalar_attributes_ptr^ do
            Unparse_str(outfile, Scalar_to_str(scalar_val,
              scalar_decimal_places, scalar_exponential_notation));
        end;

      double_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(double)');
          with double_attributes_ptr^ do
            Unparse_str(outfile, Double_to_str(double_val,
              double_decimal_places, double_exponential_notation));
        end;

      {*******************}
      { compound literals }
      {*******************}

      complex_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(complex');
          with complex_attributes_ptr^ do
            begin
              Check_line_break(outfile);
              Unparse_str(outfile, '<');
              Unparse_str(outfile, Scalar_to_str(complex_val.a,
                a_decimal_places, a_exponential_notation));
              Unparse_space(outfile);
              Unparse_str(outfile, Scalar_to_str(complex_val.b,
                b_decimal_places, b_exponential_notation));
              Unparse_char(outfile, '>');
            end;
        end;

      vector_lit:
        begin
          if show_types then
            Unparse_str(outfile, '(vector)');
          with vector_attributes_ptr^ do
            begin
              Check_line_break(outfile);
              Unparse_str(outfile, '<');
              Unparse_str(outfile, Scalar_to_str(vector_val.x, x_decimal_places,
                x_exponential_notation));
              Unparse_space(outfile);
              Unparse_str(outfile, Scalar_to_str(vector_val.y, y_decimal_places,
                y_exponential_notation));
              Unparse_space(outfile);
              Unparse_str(outfile, Scalar_to_str(vector_val.z, z_decimal_places,
                z_exponential_notation));
              Unparse_char(outfile, '>');
            end;
        end;

      {**************}
      { nil literals }
      {**************}
      nil_array, nil_struct, nil_proto, nil_reference:
        Unparse_str(outfile, 'none');

    end; {case}
end; {procedure Unparse_literal_expr}


{*****************************************}
{ routine to unparse a general expression }
{*****************************************}


procedure Unparse_expr_addr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if (expr_ptr <> nil) then
    begin
      expr_attributes_ptr := Get_expr_attributes(expr_ptr);
      decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;

      if decl_attributes_ptr^.kind <> type_decl_attributes then
        with expr_ptr^ do
          case kind of

            global_identifier:
              begin
                if show_expr_addrs then
                  begin
                    Unparse_char(outfile, '(');
                    Unparse_str(outfile, 'g');
                    Unparse_str(outfile, Integer_to_str(stack_index));
                    Unparse_char(outfile, ')');
                  end;
              end;

            local_identifier:
              begin
                if show_expr_addrs then
                  begin
                    Unparse_char(outfile, '(');
                    Unparse_str(outfile, 'l');
                    Unparse_str(outfile, Integer_to_str(stack_index));
                    Unparse_char(outfile, ')');
                  end;
              end;

            nested_identifier:
              begin
                if show_expr_addrs then
                  begin
                    Unparse_char(outfile, '(');
                    Unparse_str(outfile, 'i');
                    Unparse_str(outfile,
                      Integer_to_str(nested_id_expr_ptr^.stack_index));

                    Unparse_str(outfile, ',s');
                    Unparse_str(outfile, Integer_to_str(static_links));

                    Unparse_str(outfile, ',d');
                    Unparse_str(outfile, Integer_to_str(dynamic_links));
                    Unparse_char(outfile, ')');
                  end;
              end;

            field_identifier:
              begin
                if show_expr_addrs then
                  begin
                    Unparse_char(outfile, '(');
                    Unparse_str(outfile, 'f');
                    Unparse_str(outfile, Integer_to_str(field_index));
                    Unparse_char(outfile, ')');
                  end;
              end;

          end; {case}
    end;
end; {procedure Unparse_expr_addr}


procedure Unparse_decl_addr(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  if show_decl_addrs then
    with decl_attributes_ptr^ do
      if not decl_attributes_ptr^.forward then
        case kind of

          data_decl_attributes:
            begin
              Unparse_char(outfile, '(');
              Unparse_str(outfile, 'i');
              Unparse_str(outfile, Integer_to_str(stack_index));

              if show_static_levels then
                begin
                  Unparse_space(outfile);
                  Unparse_str(outfile, 's');
                  Unparse_str(outfile, Integer_to_str(static_level));
                end;

              Unparse_char(outfile, ')');
            end;

          field_decl_attributes:
            begin
              Unparse_char(outfile, '(');
              Unparse_str(outfile, 'f');
              Unparse_str(outfile, Integer_to_str(field_index));

              if show_static_levels then
                begin
                  Unparse_space(outfile);
                  Unparse_str(outfile, 's');
                  Unparse_str(outfile, Integer_to_str(static_level));
                end;

              Unparse_char(outfile, ')');
            end;

        end; {case}
end; {procedure Unparse_decl_addr}


procedure Unparse_static_level(var outfile: text;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  if show_static_levels then
    begin
      Unparse_char(outfile, '(');
      Unparse_str(outfile, 's');
      with decl_attributes_ptr^ do
        Unparse_str(outfile, Integer_to_str(static_level));
      Unparse_char(outfile, ')');
    end;
end; {procedure Unparse_static_level}


procedure Unparse_dynamic_level(var outfile: text;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
begin
  if show_dynamic_levels then
    begin
      Unparse_char(outfile, '(');
      Unparse_str(outfile, 'd');
      with stmt_attributes_ptr^ do
        Unparse_str(outfile, Integer_to_str(dynamic_level));
      Unparse_char(outfile, ')');
    end;
end; {procedure Unparse_dynamic_level}


procedure Unparse_scope_name(var outfile: text;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  scope_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  Unparse_str(outfile, Get_decl_attributes_name(scope_decl_attributes_ptr));
end; {procedure Unparse_scope_name}


function Found_some_operator(expr_ptr: expr_ptr_type): boolean;
var
  found: boolean;
begin
  with expr_ptr^ do
    if kind in [integer_not_equal, array_ptr_not_equal, struct_ptr_not_equal,
      proto_not_equal] then
      case kind of

        integer_not_equal:
          begin
            found := false;
            if right_operand_ptr^.kind = enum_lit then
              if right_operand_ptr^.enum_val = 0 then
                found := true;
          end;

        array_ptr_not_equal:
          found := right_operand_ptr^.kind = nil_array;

        struct_ptr_not_equal:
          found := right_operand_ptr^.kind = nil_struct;

        proto_not_equal:
          found := right_operand_ptr^.kind = nil_proto;

      else
        found := false;
      end {case}
    else
      found := false;

  Found_some_operator := found;
end; {function Found_some_operator}


procedure Unparse_unary_operator_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    begin
      {******************}
      { suffix operators }
      {******************}
      if kind in [vector_x..vector_z] then
        begin
          Unparse_expr(outfile, operand_ptr);
          Unparse_unary_operator(outfile, kind);
        end

          {******************}
          { prefix operators }
          {******************}
      else
        begin
          Unparse_unary_operator(outfile, kind);
          if not (kind in [address_op, deref_op]) then
            if not (kind in [byte_negate..vector_negate]) then
              if not (kind in [byte_to_short..scalar_to_complex]) then
                Unparse_space(outfile);
          Unparse_expr(outfile, operand_ptr);
        end;
    end;
end; {procedure Unparse_unary_operator_expr}


procedure Unparse_binary_operator_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  expr_kind: type_kind_type;
begin
  with expr_ptr^ do
    begin
      if implicit_and then
        begin
          if show_implicit then
            begin
              Unparse_expr(outfile, left_operand_ptr^.left_operand_ptr);
              Unparse_space(outfile);
              Unparse_binary_operator(outfile, left_operand_ptr^.kind);
              Unparse_space(outfile);
              Unparse_expr(outfile, left_operand_ptr^.right_operand_ptr);
              Unparse_space(outfile);
            end;

          Unparse_binary_operator(outfile, right_operand_ptr^.kind);
          Unparse_space(outfile);
          Unparse_expr(outfile, right_operand_ptr^.right_operand_ptr);
        end
      else if Found_some_operator(expr_ptr) then
        begin
          Unparse_str(outfile, 'some');
          Unparse_space(outfile);
          Unparse_expr(outfile, left_operand_ptr);
        end
      else
        begin
          expr_attributes_ptr := Get_expr_attributes(left_operand_ptr);
          if expr_attributes_ptr <> nil then
            expr_kind := expr_attributes_ptr^.type_attributes_ptr^.kind
          else
            expr_kind := type_error;

          if (expr_kind <> type_enum) then
            begin
              Unparse_expr(outfile, left_operand_ptr);
              Unparse_space(outfile);
              Unparse_binary_operator(outfile, kind);
              Unparse_space(outfile);
              Unparse_expr(outfile, right_operand_ptr);
            end
          else
            begin
              {*********************************}
              { enumerated comparison operators }
              {*********************************}
              case kind of
                integer_equal:
                  Unparse_str(outfile, 'is');
                integer_not_equal:
                  Unparse_str(outfile, concat(concat('isn',
                    Char_to_str(single_quote)), 't'));
              end;
            end;
        end;
    end;
end; {procedure Unparse_binary_operator_expr}


procedure Unparse_tuplet_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of
      complex_pair:
        begin
          Check_line_break(outfile);
          Unparse_str(outfile, '<');
          Unparse_expr(outfile, a_expr_ptr);
          Unparse_space(outfile);
          Unparse_expr(outfile, b_expr_ptr);
          Unparse_char(outfile, '>');
        end;
      vector_triplet:
        begin
          Check_line_break(outfile);
          Unparse_str(outfile, '<');
          Unparse_expr(outfile, x_expr_ptr);
          Unparse_space(outfile);
          Unparse_expr(outfile, y_expr_ptr);
          Unparse_space(outfile);
          Unparse_expr(outfile, z_expr_ptr);
          Unparse_char(outfile, '>');
        end;
    end; {case}
end; {procedure Unparse_tuplet_expr}


procedure Unparse_identifier_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  with expr_ptr^ do
    case kind of

      {***********************************}
      { user defined variable identifiers }
      {***********************************}
      global_identifier, local_identifier, nested_identifier:
        begin
          expr_attributes_ptr := Get_expr_attributes(expr_ptr);
          if expr_attributes_ptr <> nil then
            if expr_attributes_ptr^.explicit_member then
              begin
                Unparse_scope_name(outfile, expr_attributes_ptr);
                Unparse_space(outfile);
                Unparse_str(outfile, 'type');
                Unparse_str(outfile, concat(Char_to_str(single_quote), 's'));
                Unparse_space(outfile);
              end
            else if expr_attributes_ptr^.explicit_static then
              begin
                Unparse_str(outfile, 'static');
                Unparse_space(outfile);
              end
            else if expr_attributes_ptr^.explicit_global then
              begin
                Unparse_str(outfile, 'global');
                Unparse_space(outfile);
              end;

          {*************************}
          { unparse expr identifier }
          {*************************}
          Unparse_str(outfile, Get_expr_attributes_name(expr_attributes_ptr));

          {*****************************}
          { show diagnostic information }
          {*****************************}
          Unparse_expr_addr(outfile, expr_ptr);
        end;

      {*******************************}
      { user defined type identifiers }
      {*******************************}
      field_identifier:
        begin
          expr_attributes_ptr := Get_expr_attributes(expr_ptr);
          if expr_attributes_ptr <> nil then
            if expr_attributes_ptr^.explicit_member then
              begin
                Unparse_scope_name(outfile, expr_attributes_ptr);
                Unparse_str(outfile, concat(Char_to_str(single_quote), 's'));
                Unparse_space(outfile);
              end;

          {*************************}
          { unparse expr identifier }
          {*************************}
          Unparse_str(outfile, Get_expr_attributes_name(expr_attributes_ptr));

          {*****************************}
          { show diagnostic information }
          {*****************************}
          Unparse_expr_addr(outfile, expr_ptr);
        end;
    end; {case}
end; {procedure Unparse_identifier_expr}


procedure Unparse_terminal_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  with expr_ptr^ do
    case kind of

      {************************}
      { user defined variables }
      {************************}

      global_identifier..field_identifier:
        Unparse_identifier_expr(outfile, expr_ptr);

      {**********************************************}
      { references to previously mentioned variables }
      {**********************************************}

      itself:
        Unparse_str(outfile, 'itself');

      new_itself:
        begin
          Unparse_str(outfile, 'new');
          Unparse_space(outfile);

          type_ptr := type_ptr_type(new_type_ref);
          decl_attributes_ptr := Get_decl_attributes(type_ptr^.type_decl_ref);
          Unparse_str(outfile, Get_decl_attributes_name(decl_attributes_ptr));
        end;

      implicit_expr:
        if show_implicit then
          Unparse_expr(outfile, implicit_expr_ref);

    end; {case}
end; {procedure Unparse_terminal_expr}


procedure Unparse_array_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  with expr_ptr^ do
    case kind of

      {*****************************************************}
      { array expressions - list of exprs or subarray exprs }
      {*****************************************************}
      boolean_array_expr..reference_array_expr:
        begin
          expr_attributes_ptr := Get_expr_attributes(expr_ptr);
          if Equal_expr_attributes(expr_attributes_ptr,
            string_value_attributes_ptr) then
            begin
              Unparse_char(outfile, '"');
              expr_ptr := array_element_exprs_ptr;
              while (expr_ptr <> nil) do
                begin
                  Unparse_str(outfile, Char_to_str(expr_ptr^.char_val));
                  expr_ptr := expr_ptr^.next;
                end;
              Unparse_char(outfile, '"');
            end
          else
            begin
              Check_line_break(outfile);
              Unparse_str(outfile, '[');
              Unparse_exprs(outfile, array_element_exprs_ptr);
              Unparse_char(outfile, ']');
            end;
        end;
      subarray_expr:
        begin
          Check_line_break(outfile);
          Unparse_str(outfile, '[');
          Unparse_subexprs(outfile, subarray_element_exprs_ptr);
          Unparse_char(outfile, ']');
        end;
      element_expr:
        Unparse_expr(outfile, element_array_expr_ptr);

      {********************}
      { array dimensioning }
      {********************}
      boolean_array_dim..reference_array_dim:
        begin
          Unparse_array_bounds_list(outfile, dim_bounds_list_ptr);
          if dim_element_expr_ptr <> nil then
            Unparse_expr(outfile, dim_element_expr_ptr);
        end;

      {*********************}
      { array dereferencing }
      {*********************}
      boolean_array_deref..reference_array_deref:
        begin
          Unparse_expr(outfile, deref_base_ptr);
          Unparse_array_index_list(outfile, deref_index_list_ptr);
        end;

      {****************************}
      { array subrange expressions }
      {****************************}
      boolean_array_subrange..reference_array_subrange:
        begin
          Unparse_expr(outfile, subrange_base_ptr);
          if (not implicit_subrange) or show_implicit then
            Unparse_array_index_list(outfile, subrange_index_list_ptr);
        end;

      {*******************************************}
      { implicit references used in array assigns }
      {*******************************************}
      array_base:
        if show_implicit then
          Unparse_str(outfile, 'array base')
        else
          Unparse_expr(outfile, array_base_expr_ref);

    end; {case}
end; {procedure Unparse_array_expr}


procedure Unparse_struct_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of

      {***********************************************************}
      { structure expressions - list of exprs or sub struct exprs }
      {***********************************************************}
      struct_expr:
        begin
          Check_line_break(outfile);
          Unparse_str(outfile, '<');
          Unparse_exprs(outfile, field_exprs_ptr);
          Unparse_char(outfile, '>');
        end;

      {**********************}
      { structure allocation }
      {**********************}
      struct_new:
        begin
          {**************}
          { explicit new }
          {**************}
          if expr_info_ptr <> nil then
            begin
              Unparse_str(outfile, 'new');
              Unparse_space(outfile);
              Unparse_type_name(outfile, type_ptr_type(new_struct_type_ref));
              Unparse_space(outfile);
              Unparse_str(outfile, 'type');
            end;

          {**************************}
          { unparse constructor tail }
          {**************************}
          Unparse_initializer(outfile,
            stmt_ptr_type(expr_ptr^.new_struct_init_stmt_ptr));
        end;

      {*************************}
      { structure dereferencing }
      {*************************}
      struct_deref, struct_offset:
        begin
          if show_implicit or (not implicit_field) then
            begin
              if base_expr_ptr^.kind <> itself then
                begin
                  Unparse_expr(outfile, base_expr_ptr);
                  Unparse_str(outfile, concat(Char_to_str(single_quote), 's'));
                  Unparse_space(outfile);
                end;
            end
          else if antecedent_field then
            begin
              Unparse_str(outfile, 'its');
              Unparse_space(outfile);
            end;

          Unparse_expr(outfile, field_expr_ptr);
        end;

      {*********************}
      { field dereferencing }
      {*********************}
      field_deref, field_offset:
        Unparse_expr(outfile, field_name_ptr);

      {***********************************************}
      { implicit references used in structure assigns }
      {***********************************************}
      struct_base, static_struct_base:
        if show_implicit then
          Unparse_str(outfile, 'self');

    end; {case}
end; {procedure Unparse_struct_expr}


procedure Unparse_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  comment_ptr: comment_ptr_type;
  type_ptr: type_ptr_type;
begin
  if expr_ptr <> nil then
    with expr_ptr^ do
      begin
        {******************************}
        { unparse implicit parentheses }
        {******************************}
        if show_precedence then
          if not (expr_ptr^.kind in literal_set) then
            Unparse_char(outfile, '(');

        if expr_info_ptr <> nil then
          with expr_info_ptr^ do
            begin
              {*********************************************}
              { unparse comments at beginning of expression }
              {*********************************************}
              comment_ptr := Get_prev_comments(comments_ptr);
              if comment_ptr <> nil then
                begin
                  Unparse_comments(outfile, Get_prev_comments(comments_ptr));
                  Indent(outfile);
                end;

              {******************************}
              { unparse explicit parentheses }
              {******************************}
              if explicit_expr and not show_precedence then
                if not (expr_ptr^.kind in literal_set) then
                  Unparse_char(outfile, '(');
            end; {with}

        {***************************************************************}
        {                        unary operators                        }
        {***************************************************************}
        if kind in unary_operator_set then
          Unparse_unary_operator_expr(outfile, expr_ptr)

          {***************************************************************}
          {                       binary operators                        }
          {***************************************************************}
        else if kind in binary_operator_set then
          Unparse_binary_operator_expr(outfile, expr_ptr)

          {***************************************************************}
          {                       array expressions                       }
          {***************************************************************}
        else if kind in array_expr_set then
          Unparse_array_expr(outfile, expr_ptr)

          {***************************************************************}
          {                       struct expressions                      }
          {***************************************************************}
        else if kind in struct_expr_set then
          Unparse_struct_expr(outfile, expr_ptr)

          {***************************************************************}
          {                         expression terms                      }
          {***************************************************************}
        else if (kind in expr_term_set) then
          case kind of

            {***************************}
            { explicit type conversions }
            {***************************}
            ptr_cast, type_query:
              begin
                type_ptr := type_ptr_type(desired_subclass_ref);
                decl_attributes_ptr :=
                  Get_decl_attributes(type_ptr^.type_decl_ref);
                Unparse_str(outfile,
                  Get_decl_attributes_name(decl_attributes_ptr));
                Unparse_space(outfile);
                Unparse_str(outfile, 'type');
                Unparse_space(outfile);
                Unparse_expr(outfile, class_expr_ptr);
              end;

            {********************************************}
            { complex pairs and vector triplets of exprs }
            {********************************************}
            complex_pair, vector_triplet:
              Unparse_tuplet_expr(outfile, expr_ptr);

            {************************}
            { user defined functions }
            {************************}
            user_fn:
              Unparse_stmt(outfile, stmt_ptr_type(fn_stmt_ptr));

          end {case}

            {***************************************************************}
            {                      expression terminals                     }
            {***************************************************************}
        else if (kind in terminal_set) and not (kind in literal_set) then
          Unparse_terminal_expr(outfile, expr_ptr)

          {***************************************************************}
          {                      expression literals        	            }
          {***************************************************************}
        else if kind in literal_set then
          Unparse_literal_expr(outfile, expr_ptr);

        {******************************}
        { unparse implicit parentheses }
        {******************************}
        if show_precedence then
          if not (expr_ptr^.kind in literal_set) then
            Unparse_char(outfile, ')');

        if expr_info_ptr <> nil then
          with expr_info_ptr^ do
            begin
              {******************************}
              { unparse explicit parentheses }
              {******************************}
              if explicit_expr and not show_precedence then
                if not (expr_ptr^.kind in literal_set) then
                  Unparse_char(outfile, ')');

              {**************************************}
              { unparse comment at end of expression }
              {**************************************}
              comment_ptr := Get_post_comments(comments_ptr);
              if comment_ptr <> nil then
                begin
                  Unparse_tab(outfile);
                  Unparse_comments(outfile, comment_ptr);
                end;
            end; {with}
      end; {with}
end; {procedure Unparse_expr}


procedure Unparse_exprs(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  while (expr_ptr <> nil) do
    begin
      Unparse_expr(outfile, expr_ptr);
      expr_ptr := expr_ptr^.next;

      {***************************************}
      { unparse seperator for next expression }
      {***************************************}
      if Get_prev_expr_comments(expr_ptr) <> nil then
        begin
          Unparseln(outfile, '');
          Unparseln(outfile, '');
          Indent(outfile);
        end
      else if expr_ptr <> nil then
        Unparse_space(outfile);
    end;
end; {procedure Unparse_exprs}


procedure Unparse_subexprs(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  while (expr_ptr <> nil) do
    begin
      Check_line_break(outfile);
      Unparse_expr(outfile, expr_ptr);
      expr_ptr := expr_ptr^.next;

      {***************************************}
      { unparse seperator for next expression }
      {***************************************}
      if Get_prev_expr_comments(expr_ptr) <> nil then
        begin
          Unparseln(outfile, '');
          Unparseln(outfile, '');
          Indent(outfile);
        end
      else if expr_ptr <> nil then
        Unparse_space(outfile);
    end;

end; {procedure Unparse_subexprs}


end.
