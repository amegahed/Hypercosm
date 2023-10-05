unit typechecker;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            typechecker                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module checks to see if the types of operands      }
{       in an expression are compatible.                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, tokens;


function Result_type_kind(operator_kind: token_kind_type;
  left_kind, right_kind: type_kind_type): type_kind_type;


implementation
{***************************************************************}
{                      typechecker rules                        }
{***************************************************************}
{       1) No arithmetic operations on booleans                 }
{       2) No logical operations on non-booleans                }
{       3) No relational ops on vectors or booleans             }
{       4) Control expressions must be booleans                 }
{       5) Assigments' left, right sides must match type        }
{       6) No assignments to a constant                         }
{***************************************************************}

{***************************************************************}
{       The task of typechecking is shared by the typechecker   }
 {       and the parser modules . The typechecker will catch     }
 {       type errors within expressions (1, 2, 3) and the        }
 {       parser will catch the remaining type errors (4, 5, 6).  }
{																																}
{       example:                                                }
{       (foo + 2.0)             scalar                          }
{       (foo + 2.0) > 10        boolean                         }
{***************************************************************}


const
  math_kind_set = [type_byte..type_vector];
  math_operator_set = [plus_tok, minus_tok, times_tok, divide_tok, div_tok,
    mod_tok, up_arrow_tok];
  relational_operator_set = [equal_tok, not_equal_tok, less_than_tok,
    greater_than_tok, less_equal_tok, greater_equal_tok];


type
  truth_range = type_byte..type_vector;
  truth_table_type = array[truth_range, truth_range] of type_kind_type;


var
  sum_table, product_table: truth_table_type;
  quotient_table, div_mod_table: truth_table_type;
  power_table, rel_table: truth_table_type;
  equal_table: truth_table_type;


procedure Init_error_table(var truth_table: truth_table_type);
var
  left_kind, right_kind: type_kind_type;
begin
  {|-----------------------------------------------------------------------|}
  {|                            Error truth table                          |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer| error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex| error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  for left_kind := type_byte to type_vector do
    for right_kind := type_byte to type_vector do
      truth_table[left_kind, right_kind] := type_error;
end; {procedure Init_error_table}


procedure Init_sum_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                    Addition / Subtraction truth table                 |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  | byte  | short |integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short | short | short |integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|integer|integer|integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  | long  | long  | long  | long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |double |double |double |double |double |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex|complex|complex|complex|complex|complex|complex|complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error |vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(sum_table);

  sum_table[type_byte, type_byte] := type_byte;
  sum_table[type_byte, type_short] := type_short;
  sum_table[type_byte, type_integer] := type_integer;
  sum_table[type_byte, type_long] := type_long;
  sum_table[type_byte, type_scalar] := type_scalar;
  sum_table[type_byte, type_double] := type_double;
  sum_table[type_byte, type_complex] := type_complex;

  sum_table[type_short, type_byte] := type_short;
  sum_table[type_short, type_short] := type_short;
  sum_table[type_short, type_integer] := type_integer;
  sum_table[type_short, type_long] := type_long;
  sum_table[type_short, type_scalar] := type_scalar;
  sum_table[type_short, type_double] := type_double;
  sum_table[type_short, type_complex] := type_complex;

  sum_table[type_integer, type_byte] := type_integer;
  sum_table[type_integer, type_short] := type_integer;
  sum_table[type_integer, type_integer] := type_integer;
  sum_table[type_integer, type_long] := type_long;
  sum_table[type_integer, type_scalar] := type_scalar;
  sum_table[type_integer, type_double] := type_double;
  sum_table[type_integer, type_complex] := type_complex;

  sum_table[type_long, type_byte] := type_long;
  sum_table[type_long, type_short] := type_long;
  sum_table[type_long, type_integer] := type_long;
  sum_table[type_long, type_long] := type_long;
  sum_table[type_long, type_scalar] := type_scalar;
  sum_table[type_long, type_double] := type_double;
  sum_table[type_long, type_complex] := type_complex;

  sum_table[type_scalar, type_byte] := type_scalar;
  sum_table[type_scalar, type_short] := type_scalar;
  sum_table[type_scalar, type_integer] := type_scalar;
  sum_table[type_scalar, type_long] := type_scalar;
  sum_table[type_scalar, type_scalar] := type_scalar;
  sum_table[type_scalar, type_double] := type_double;
  sum_table[type_scalar, type_complex] := type_complex;

  sum_table[type_double, type_byte] := type_double;
  sum_table[type_double, type_short] := type_double;
  sum_table[type_double, type_integer] := type_double;
  sum_table[type_double, type_long] := type_double;
  sum_table[type_double, type_scalar] := type_double;
  sum_table[type_double, type_double] := type_double;

  sum_table[type_complex, type_byte] := type_complex;
  sum_table[type_complex, type_short] := type_complex;
  sum_table[type_complex, type_integer] := type_complex;
  sum_table[type_complex, type_long] := type_complex;
  sum_table[type_complex, type_scalar] := type_complex;
  sum_table[type_complex, type_complex] := type_complex;

  sum_table[type_vector, type_vector] := type_vector;
end; {procedure Init_sum_table}


procedure Init_product_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                        Multiplication truth table                     |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  | byte  | short |integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short | short | short |integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|integer|integer|integer| long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  | long  | long  | long  | long  |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |double |double |double |double |double |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex|complex|complex|complex|complex|complex|complex|complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector |vector |vector |vector |vector |vector |vector |vector |vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(product_table);

  product_table[type_byte, type_byte] := type_byte;
  product_table[type_byte, type_short] := type_short;
  product_table[type_byte, type_integer] := type_integer;
  product_table[type_byte, type_long] := type_long;
  product_table[type_byte, type_scalar] := type_scalar;
  product_table[type_byte, type_double] := type_double;
  product_table[type_byte, type_complex] := type_complex;

  product_table[type_short, type_byte] := type_short;
  product_table[type_short, type_short] := type_short;
  product_table[type_short, type_integer] := type_integer;
  product_table[type_short, type_long] := type_long;
  product_table[type_short, type_scalar] := type_scalar;
  product_table[type_short, type_double] := type_double;
  product_table[type_short, type_complex] := type_complex;

  product_table[type_integer, type_byte] := type_integer;
  product_table[type_integer, type_short] := type_integer;
  product_table[type_integer, type_integer] := type_integer;
  product_table[type_integer, type_long] := type_long;
  product_table[type_integer, type_scalar] := type_scalar;
  product_table[type_integer, type_double] := type_double;
  product_table[type_integer, type_complex] := type_complex;

  product_table[type_long, type_byte] := type_long;
  product_table[type_long, type_short] := type_long;
  product_table[type_long, type_integer] := type_long;
  product_table[type_long, type_long] := type_long;
  product_table[type_long, type_scalar] := type_scalar;
  product_table[type_long, type_double] := type_double;
  product_table[type_long, type_complex] := type_complex;

  product_table[type_scalar, type_byte] := type_scalar;
  product_table[type_scalar, type_short] := type_scalar;
  product_table[type_scalar, type_integer] := type_scalar;
  product_table[type_scalar, type_long] := type_scalar;
  product_table[type_scalar, type_scalar] := type_scalar;
  product_table[type_scalar, type_double] := type_double;
  product_table[type_scalar, type_complex] := type_complex;

  product_table[type_double, type_byte] := type_double;
  product_table[type_double, type_short] := type_double;
  product_table[type_double, type_integer] := type_double;
  product_table[type_double, type_long] := type_double;
  product_table[type_double, type_scalar] := type_double;
  product_table[type_double, type_double] := type_double;

  product_table[type_complex, type_byte] := type_complex;
  product_table[type_complex, type_short] := type_complex;
  product_table[type_complex, type_integer] := type_complex;
  product_table[type_complex, type_long] := type_complex;
  product_table[type_complex, type_scalar] := type_complex;
  product_table[type_complex, type_complex] := type_complex;

  product_table[type_vector, type_byte] := type_vector;
  product_table[type_vector, type_short] := type_vector;
  product_table[type_vector, type_integer] := type_vector;
  product_table[type_vector, type_long] := type_vector;
  product_table[type_vector, type_scalar] := type_vector;
  product_table[type_vector, type_vector] := type_vector;
end; {procedure Init_product_table}


procedure Init_quotient_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                           Division truth table                        |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |scalar |scalar |scalar |scalar |scalar |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |double |double |double |double |double |double |complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex|complex|complex|complex|complex|complex|complex|complex| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector |vector |vector |vector |vector |vector |vector |vector |vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(quotient_table);

  quotient_table[type_byte, type_byte] := type_scalar;
  quotient_table[type_byte, type_short] := type_scalar;
  quotient_table[type_byte, type_integer] := type_scalar;
  quotient_table[type_byte, type_long] := type_scalar;
  quotient_table[type_byte, type_scalar] := type_scalar;
  quotient_table[type_byte, type_double] := type_double;
  quotient_table[type_byte, type_complex] := type_complex;

  quotient_table[type_short, type_byte] := type_scalar;
  quotient_table[type_short, type_short] := type_scalar;
  quotient_table[type_short, type_integer] := type_scalar;
  quotient_table[type_short, type_long] := type_scalar;
  quotient_table[type_short, type_scalar] := type_scalar;
  quotient_table[type_short, type_double] := type_double;
  quotient_table[type_short, type_complex] := type_complex;

  quotient_table[type_integer, type_byte] := type_scalar;
  quotient_table[type_integer, type_short] := type_scalar;
  quotient_table[type_integer, type_integer] := type_scalar;
  quotient_table[type_integer, type_long] := type_scalar;
  quotient_table[type_integer, type_scalar] := type_scalar;
  quotient_table[type_integer, type_double] := type_double;
  quotient_table[type_integer, type_complex] := type_complex;

  quotient_table[type_long, type_byte] := type_scalar;
  quotient_table[type_long, type_short] := type_scalar;
  quotient_table[type_long, type_integer] := type_scalar;
  quotient_table[type_long, type_long] := type_scalar;
  quotient_table[type_long, type_scalar] := type_scalar;
  quotient_table[type_long, type_double] := type_double;
  quotient_table[type_long, type_complex] := type_complex;

  quotient_table[type_scalar, type_byte] := type_scalar;
  quotient_table[type_scalar, type_short] := type_scalar;
  quotient_table[type_scalar, type_integer] := type_scalar;
  quotient_table[type_scalar, type_long] := type_scalar;
  quotient_table[type_scalar, type_scalar] := type_scalar;
  quotient_table[type_scalar, type_double] := type_double;
  quotient_table[type_scalar, type_complex] := type_complex;

  quotient_table[type_double, type_byte] := type_double;
  quotient_table[type_double, type_short] := type_double;
  quotient_table[type_double, type_integer] := type_double;
  quotient_table[type_double, type_long] := type_double;
  quotient_table[type_double, type_scalar] := type_double;
  quotient_table[type_double, type_double] := type_double;

  quotient_table[type_complex, type_byte] := type_complex;
  quotient_table[type_complex, type_short] := type_short;
  quotient_table[type_complex, type_integer] := type_complex;
  quotient_table[type_complex, type_long] := type_complex;
  quotient_table[type_complex, type_scalar] := type_complex;
  quotient_table[type_complex, type_complex] := type_complex;

  quotient_table[type_vector, type_byte] := type_vector;
  quotient_table[type_vector, type_short] := type_vector;
  quotient_table[type_vector, type_integer] := type_vector;
  quotient_table[type_vector, type_long] := type_vector;
  quotient_table[type_vector, type_scalar] := type_vector;
  quotient_table[type_vector, type_vector] := type_vector;
end; {procedure Init_quotient_table}


procedure Init_div_mod_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                            Div / Mod truth table                      |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  | byte  | short |integer| long  | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short | short | short |integer| long  | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|integer|integer|integer| long  | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  | long  | long  | long  | long  | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex| error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(div_mod_table);

  div_mod_table[type_byte, type_byte] := type_byte;
  div_mod_table[type_byte, type_short] := type_short;
  div_mod_table[type_byte, type_integer] := type_integer;
  div_mod_table[type_byte, type_long] := type_long;

  div_mod_table[type_short, type_byte] := type_short;
  div_mod_table[type_short, type_short] := type_short;
  div_mod_table[type_short, type_integer] := type_integer;
  div_mod_table[type_short, type_long] := type_long;

  div_mod_table[type_integer, type_byte] := type_integer;
  div_mod_table[type_integer, type_short] := type_integer;
  div_mod_table[type_integer, type_integer] := type_integer;
  div_mod_table[type_integer, type_long] := type_long;

  div_mod_table[type_long, type_byte] := type_long;
  div_mod_table[type_long, type_short] := type_long;
  div_mod_table[type_long, type_integer] := type_long;
  div_mod_table[type_long, type_long] := type_long;
end; {procedure Init_div_mod_table}


procedure Init_power_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                         Exponentiation truth table                    |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  | byte  | short |integer| long  |scalar |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short | short | short |integer| long  |scalar |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|integer|integer|integer| long  |scalar |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  | long  | long  | long  | long  |scalar |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |scalar |scalar |scalar |scalar |scalar |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |double |double |double |double |double |double | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex| error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(power_table);

  power_table[type_byte, type_byte] := type_byte;
  power_table[type_byte, type_short] := type_short;
  power_table[type_byte, type_integer] := type_integer;
  power_table[type_byte, type_long] := type_long;
  power_table[type_byte, type_scalar] := type_scalar;
  power_table[type_byte, type_double] := type_double;

  power_table[type_short, type_byte] := type_short;
  power_table[type_short, type_short] := type_short;
  power_table[type_short, type_integer] := type_integer;
  power_table[type_short, type_long] := type_long;
  power_table[type_short, type_scalar] := type_scalar;
  power_table[type_short, type_double] := type_double;

  power_table[type_integer, type_byte] := type_integer;
  power_table[type_integer, type_short] := type_integer;
  power_table[type_integer, type_integer] := type_integer;
  power_table[type_integer, type_long] := type_long;
  power_table[type_integer, type_scalar] := type_scalar;
  power_table[type_integer, type_double] := type_double;

  power_table[type_long, type_byte] := type_long;
  power_table[type_long, type_short] := type_long;
  power_table[type_long, type_integer] := type_long;
  power_table[type_long, type_long] := type_long;
  power_table[type_long, type_scalar] := type_scalar;
  power_table[type_long, type_double] := type_double;

  power_table[type_scalar, type_byte] := type_scalar;
  power_table[type_scalar, type_short] := type_scalar;
  power_table[type_scalar, type_integer] := type_scalar;
  power_table[type_scalar, type_long] := type_scalar;
  power_table[type_scalar, type_scalar] := type_scalar;
  power_table[type_scalar, type_double] := type_double;

  power_table[type_double, type_byte] := type_double;
  power_table[type_double, type_short] := type_double;
  power_table[type_double, type_integer] := type_double;
  power_table[type_double, type_long] := type_double;
  power_table[type_double, type_scalar] := type_double;
  power_table[type_double, type_double] := type_double;
end; {procedure Init_power_table}


procedure Init_rel_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                          Relational truth table                       |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  |boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short |boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  |boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |boolean|boolean|boolean|boolean|boolean|boolean| error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex| error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error | error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(rel_table);

  rel_table[type_byte, type_byte] := type_boolean;
  rel_table[type_byte, type_short] := type_boolean;
  rel_table[type_byte, type_integer] := type_boolean;
  rel_table[type_byte, type_long] := type_boolean;
  rel_table[type_byte, type_scalar] := type_boolean;
  rel_table[type_byte, type_double] := type_boolean;

  rel_table[type_short, type_byte] := type_boolean;
  rel_table[type_short, type_short] := type_boolean;
  rel_table[type_short, type_integer] := type_boolean;
  rel_table[type_short, type_long] := type_boolean;
  rel_table[type_short, type_scalar] := type_boolean;
  rel_table[type_short, type_double] := type_boolean;

  rel_table[type_integer, type_byte] := type_boolean;
  rel_table[type_integer, type_short] := type_boolean;
  rel_table[type_integer, type_integer] := type_boolean;
  rel_table[type_integer, type_long] := type_boolean;
  rel_table[type_integer, type_scalar] := type_boolean;
  rel_table[type_integer, type_double] := type_boolean;

  rel_table[type_long, type_byte] := type_boolean;
  rel_table[type_long, type_short] := type_boolean;
  rel_table[type_long, type_integer] := type_boolean;
  rel_table[type_long, type_long] := type_boolean;
  rel_table[type_long, type_scalar] := type_boolean;
  rel_table[type_long, type_double] := type_boolean;

  rel_table[type_scalar, type_byte] := type_boolean;
  rel_table[type_scalar, type_short] := type_boolean;
  rel_table[type_scalar, type_integer] := type_boolean;
  rel_table[type_scalar, type_long] := type_boolean;
  rel_table[type_scalar, type_scalar] := type_boolean;
  rel_table[type_scalar, type_double] := type_boolean;

  rel_table[type_double, type_byte] := type_boolean;
  rel_table[type_double, type_short] := type_boolean;
  rel_table[type_double, type_integer] := type_boolean;
  rel_table[type_double, type_long] := type_boolean;
  rel_table[type_double, type_scalar] := type_boolean;
  rel_table[type_double, type_double] := type_boolean;
end; {procedure Init_rel_table}


procedure Init_equal_table;
begin
  {|-----------------------------------------------------------------------|}
  {|                             Equal truth table                         |}
  {|-----------------------------------------------------------------------|}
  {| left: |                             right:                            |}
  {|-------|---------------------------------------------------------------|}
  {|       | byte  | short |integer| long  |scalar |double |complex|vector |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| byte  |boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| short |boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|integer|boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {| long  |boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|scalar |boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|double |boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|complex|boolean|boolean|boolean|boolean|boolean|boolean|boolean| error |}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}
  {|vector | error | error | error | error | error | error | error |boolean|}
  {|-------|-------|-------|-------|-------|-------|-------|-------|-------|}

  Init_error_table(equal_table);

  equal_table[type_byte, type_byte] := type_boolean;
  equal_table[type_byte, type_short] := type_boolean;
  equal_table[type_byte, type_integer] := type_boolean;
  equal_table[type_byte, type_long] := type_boolean;
  equal_table[type_byte, type_scalar] := type_boolean;
  equal_table[type_byte, type_double] := type_boolean;

  equal_table[type_short, type_byte] := type_boolean;
  equal_table[type_short, type_short] := type_boolean;
  equal_table[type_short, type_integer] := type_boolean;
  equal_table[type_short, type_long] := type_boolean;
  equal_table[type_short, type_scalar] := type_boolean;
  equal_table[type_short, type_double] := type_boolean;

  equal_table[type_integer, type_byte] := type_boolean;
  equal_table[type_integer, type_short] := type_boolean;
  equal_table[type_integer, type_integer] := type_boolean;
  equal_table[type_integer, type_long] := type_boolean;
  equal_table[type_integer, type_scalar] := type_boolean;
  equal_table[type_integer, type_double] := type_boolean;

  equal_table[type_long, type_byte] := type_boolean;
  equal_table[type_long, type_short] := type_boolean;
  equal_table[type_long, type_integer] := type_boolean;
  equal_table[type_long, type_long] := type_boolean;
  equal_table[type_long, type_scalar] := type_boolean;
  equal_table[type_long, type_double] := type_boolean;

  equal_table[type_scalar, type_byte] := type_boolean;
  equal_table[type_scalar, type_short] := type_boolean;
  equal_table[type_scalar, type_integer] := type_boolean;
  equal_table[type_scalar, type_long] := type_boolean;
  equal_table[type_scalar, type_scalar] := type_boolean;
  equal_table[type_scalar, type_double] := type_boolean;

  equal_table[type_double, type_byte] := type_boolean;
  equal_table[type_double, type_short] := type_boolean;
  equal_table[type_double, type_integer] := type_boolean;
  equal_table[type_double, type_long] := type_boolean;
  equal_table[type_double, type_scalar] := type_boolean;
  equal_table[type_double, type_double] := type_boolean;

  equal_table[type_complex, type_byte] := type_boolean;
  equal_table[type_complex, type_short] := type_boolean;
  equal_table[type_complex, type_integer] := type_boolean;
  equal_table[type_complex, type_long] := type_boolean;
  equal_table[type_complex, type_scalar] := type_boolean;

  equal_table[type_vector, type_vector] := type_boolean;
end; {procedure Init_equal_table}


function Result_type_kind(operator_kind: token_kind_type;
  left_kind, right_kind: type_kind_type): type_kind_type;
var
  type_kind: type_kind_type;
begin
  {********************************************}
  { check typechecker tables for the resulting }
  { type for this type of operation with these }
  { types of operands.                         }
  {********************************************}

  {************************}
  { mathematical operators }
  {************************}

  if operator_kind in math_operator_set + relational_operator_set then
    begin
      if (left_kind in math_kind_set) and (right_kind in math_kind_set) then
        case operator_kind of
          plus_tok, minus_tok:
            type_kind := sum_table[left_kind, right_kind];
          times_tok:
            type_kind := product_table[left_kind, right_kind];
          divide_tok:
            type_kind := quotient_table[left_kind, right_kind];
          div_tok, mod_tok:
            type_kind := div_mod_table[left_kind, right_kind];
          up_arrow_tok:
            type_kind := power_table[left_kind, right_kind];
          less_than_tok, greater_than_tok, less_equal_tok, greater_equal_tok:
            type_kind := rel_table[left_kind, right_kind];
          equal_tok, not_equal_tok:
            type_kind := equal_table[left_kind, right_kind];

        else
          type_kind := type_error;
        end {case}
      else
        type_kind := type_error;
    end

      {********************}
      { symbolic operators }
      {********************}
  else if (left_kind = right_kind) and (left_kind <> type_error) then
    begin
      {******************************}
      { symbolic equality comparison }
      {******************************}
      if operator_kind in [is_tok, isnt_tok, does_tok, doesnt_tok, refers_tok]
        then
        type_kind := type_boolean

        {***************************}
        { symbolic order comparison }
        {***************************}
      else if operator_kind in [less_than_tok, greater_than_tok, less_equal_tok,
        greater_equal_tok] then
        begin
          if left_kind = type_enum then
            type_kind := type_boolean
          else
            type_kind := type_error;
        end
      else
        type_kind := type_error;
    end

      {**********************}
      { mismatched operators }
      {**********************}
  else
    type_kind := type_error;

  Result_type_kind := type_kind;
end; {function Result_type_kind}


initialization
  Init_sum_table;
  Init_product_table;
  Init_quotient_table;
  Init_div_mod_table;
  Init_power_table;
  Init_rel_table;
  Init_equal_table;
end.
