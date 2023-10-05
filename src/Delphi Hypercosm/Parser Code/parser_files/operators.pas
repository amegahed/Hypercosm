unit operators;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             operators                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The casting module contains routines to cast            }
{       expressions from one type to another.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, exprs, tokens;


{*****************************************************}
{ relational operators for numeric and symbolic types }
{*****************************************************}
function Num_rel_operator_expr_kind(operator_kind: token_kind_type;
  operand_kind: type_kind_type): expr_kind_type;
function Sym_rel_operator_expr_kind(operator_kind: token_kind_type;
  operand_kind: type_kind_type): expr_kind_type;

{*****************************************************}
{ numerical or relational operators for numeric types }
{*****************************************************}
function Num_operator_expr_kind(operator_kind: token_kind_type;
  left_kind, right_kind: type_kind_type;
  return_kind: type_kind_type): expr_kind_type;


implementation


{*****************************************************}
{ relational operators for numeric and symbolic types }
{*****************************************************}


function Num_rel_operator_expr_kind(operator_kind: token_kind_type;
  operand_kind: type_kind_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  expr_kind := error_expr;

  case operand_kind of

    type_byte:
      case operator_kind of
        equal_tok:
          expr_kind := byte_equal;
        not_equal_tok:
          expr_kind := byte_not_equal;
        less_than_tok:
          expr_kind := byte_less_than;
        greater_than_tok:
          expr_kind := byte_greater_than;
        less_equal_tok:
          expr_kind := byte_less_equal;
        greater_equal_tok:
          expr_kind := byte_greater_equal;
      end; {case}

    type_short:
      case operator_kind of
        equal_tok:
          expr_kind := short_equal;
        not_equal_tok:
          expr_kind := short_not_equal;
        less_than_tok:
          expr_kind := short_less_than;
        greater_than_tok:
          expr_kind := short_greater_than;
        less_equal_tok:
          expr_kind := short_less_equal;
        greater_equal_tok:
          expr_kind := short_greater_equal;
      end; {case}

    type_integer:
      case operator_kind of
        equal_tok:
          expr_kind := integer_equal;
        not_equal_tok:
          expr_kind := integer_not_equal;
        less_than_tok:
          expr_kind := integer_less_than;
        greater_than_tok:
          expr_kind := integer_greater_than;
        less_equal_tok:
          expr_kind := integer_less_equal;
        greater_equal_tok:
          expr_kind := integer_greater_equal;
      end; {case}

    type_long:
      case operator_kind of
        equal_tok:
          expr_kind := long_equal;
        not_equal_tok:
          expr_kind := long_not_equal;
        less_than_tok:
          expr_kind := long_less_than;
        greater_than_tok:
          expr_kind := long_greater_than;
        less_equal_tok:
          expr_kind := long_less_equal;
        greater_equal_tok:
          expr_kind := long_greater_equal;
      end; {case}

    type_scalar:
      case operator_kind of
        equal_tok:
          expr_kind := scalar_equal;
        not_equal_tok:
          expr_kind := scalar_not_equal;
        less_than_tok:
          expr_kind := scalar_less_than;
        greater_than_tok:
          expr_kind := scalar_greater_than;
        less_equal_tok:
          expr_kind := scalar_less_equal;
        greater_equal_tok:
          expr_kind := scalar_greater_equal;
      end; {case}

    type_double:
      case operator_kind of
        equal_tok:
          expr_kind := double_equal;
        not_equal_tok:
          expr_kind := double_not_equal;
        less_than_tok:
          expr_kind := double_less_than;
        greater_than_tok:
          expr_kind := double_greater_than;
        less_equal_tok:
          expr_kind := double_less_equal;
        greater_equal_tok:
          expr_kind := double_greater_equal;
      end; {case}

    type_complex:
      case operator_kind of
        equal_tok:
          expr_kind := complex_equal;
        not_equal_tok:
          expr_kind := complex_not_equal;
      end; {case}

    type_vector:
      case operator_kind of
        equal_tok:
          expr_kind := vector_equal;
        not_equal_tok:
          expr_kind := vector_not_equal;
      end; {case}

  else
    expr_kind := error_expr;
  end; {case}

  Num_rel_operator_expr_kind := expr_kind;
end; {function Num_rel_operator_expr_kind}


function Sym_rel_operator_expr_kind(operator_kind: token_kind_type;
  operand_kind: type_kind_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  {******************************************************}
  { find expression type from operator and operand types }
  {******************************************************}
  expr_kind := error_expr;

  {****************}
  { boolean result }
  {****************}
  case operand_kind of

    type_boolean:
      case operator_kind of
        is_tok:
          expr_kind := boolean_equal;
        isnt_tok:
          expr_kind := boolean_not_equal;
      end; {case}

    type_char:
      case operator_kind of
        is_tok:
          expr_kind := char_equal;
        isnt_tok:
          expr_kind := char_not_equal;
      end; {case}

    type_enum:
      case operator_kind of
        is_tok:
          expr_kind := integer_equal;
        isnt_tok:
          expr_kind := integer_not_equal;
        less_than_tok:
          expr_kind := integer_less_than;
        greater_than_tok:
          expr_kind := integer_greater_than;
        less_equal_tok:
          expr_kind := integer_less_equal;
        greater_equal_tok:
          expr_kind := integer_greater_equal;
      end; {case}

    type_array:
      case operator_kind of
        is_tok:
          expr_kind := array_ptr_equal;
        isnt_tok:
          expr_kind := array_ptr_not_equal;
      end; {case}

    type_struct, type_class:
      case operator_kind of
        is_tok:
          expr_kind := struct_ptr_equal;
        isnt_tok:
          expr_kind := struct_ptr_not_equal;
      end; {case}

    type_code:
      case operator_kind of
        does_tok:
          expr_kind := proto_equal;
        doesnt_tok:
          expr_kind := proto_not_equal;
      end; {case}

  end; {case}

  Sym_rel_operator_expr_kind := expr_kind;
end; {function Sym_rel_operator_expr_kind}


{*****************************************************}
{ numerical or relational operators for numeric types }
{*****************************************************}


function Num_operator_expr_kind(operator_kind: token_kind_type;
  left_kind, right_kind: type_kind_type;
  return_kind: type_kind_type): expr_kind_type;
var
  expr_kind: expr_kind_type;
begin
  {******************************************************}
  { find expression type from operator and operand types }
  {******************************************************}
  expr_kind := error_expr;
  case return_kind of

    {****************}
    { boolean result }
    {****************}
    type_boolean:
      expr_kind := Num_rel_operator_expr_kind(operator_kind, left_kind);

    {*************}
    { byte result }
    {*************}
    type_byte:
      case operator_kind of
        plus_tok:
          expr_kind := byte_add;
        minus_tok:
          expr_kind := byte_subtract;
        times_tok:
          expr_kind := byte_multiply;
        div_tok:
          expr_kind := byte_divide;
        mod_tok:
          expr_kind := byte_mod;
      end; {case}

    {**********************}
    { short integer result }
    {**********************}
    type_short:
      case operator_kind of
        plus_tok:
          expr_kind := short_add;
        minus_tok:
          expr_kind := short_subtract;
        times_tok:
          expr_kind := short_multiply;
        div_tok:
          expr_kind := short_divide;
        mod_tok:
          expr_kind := short_mod;
      end; {case}

    {****************}
    { integer result }
    {****************}
    type_integer:
      case operator_kind of
        plus_tok:
          expr_kind := integer_add;
        minus_tok:
          expr_kind := integer_subtract;
        times_tok:
          expr_kind := integer_multiply;
        div_tok:
          expr_kind := integer_divide;
        mod_tok:
          expr_kind := integer_mod;
      end; {case}

    {*********************}
    { long integer result }
    {*********************}
    type_long:
      case operator_kind of
        plus_tok:
          expr_kind := long_add;
        minus_tok:
          expr_kind := long_subtract;
        times_tok:
          expr_kind := long_multiply;
        div_tok:
          expr_kind := long_divide;
        mod_tok:
          expr_kind := long_mod;
      end; {case}

    {***************}
    { scalar result }
    {***************}
    type_scalar:
      case operator_kind of
        plus_tok:
          expr_kind := scalar_add;
        minus_tok:
          expr_kind := scalar_subtract;
        times_tok:
          expr_kind := scalar_multiply;
        divide_tok:
          expr_kind := scalar_divide;
        up_arrow_tok:
          expr_kind := scalar_exponent;
      end; {case}

    {********************************}
    { double precision scalar result }
    {********************************}
    type_double:
      case operator_kind of
        plus_tok:
          expr_kind := double_add;
        minus_tok:
          expr_kind := double_subtract;
        times_tok:
          expr_kind := double_multiply;
        divide_tok:
          expr_kind := double_divide;
        up_arrow_tok:
          expr_kind := double_exponent;
      end; {case}

    {****************}
    { complex result }
    {****************}
    type_complex:
      case operator_kind of
        plus_tok:
          expr_kind := complex_add;
        minus_tok:
          expr_kind := complex_subtract;
        times_tok:
          expr_kind := complex_multiply;
        divide_tok:
          expr_kind := complex_divide;
      end; {case}

    {***************}
    { vector result }
    {***************}
    type_vector:
      case operator_kind of
        plus_tok:
          expr_kind := vector_add;
        minus_tok:
          expr_kind := vector_subtract;
        times_tok:
          case right_kind of
            type_scalar:
              expr_kind := vector_scalar_multiply;
            type_vector:
              expr_kind := vector_vector_multiply;
          end;
        divide_tok:
          case right_kind of
            type_scalar:
              expr_kind := vector_scalar_divide;
            type_vector:
              expr_kind := vector_vector_divide;
          end;
      end; {case}

    type_error: {do nothing}
  end; {case}

  Num_operator_expr_kind := expr_kind;
end; {function Num_operator_expr_kind}


end.
