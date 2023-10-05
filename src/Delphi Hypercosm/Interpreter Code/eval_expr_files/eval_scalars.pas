unit eval_scalars;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_scalars               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       To evaluate the expression, we interpret the syntax     }
{       tree by traversing it and performing the indicated      }
{       operation at each node.                                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs;


{*******************************************}
{ routines to evaluate an scalar expression }
{*******************************************}
procedure Eval_scalar(expr_ptr: expr_ptr_type);
procedure Eval_double(expr_ptr: expr_ptr_type);
procedure Eval_complex(expr_ptr: expr_ptr_type);
procedure Eval_vector(expr_ptr: expr_ptr_type);


implementation
uses
  math_utils, complex_numbers, vectors, data_types, stmts, op_stacks,
  load_operands, eval_addrs, eval_integers, eval_references, exec_stmts,
  interpreter;


{*******************************************}
{ routines to evaluate an scalar expression }
{*******************************************}


procedure Eval_scalar(expr_ptr: expr_ptr_type);
var
  right_scalar, left_scalar: scalar_type;
  right_vector, left_vector: vector_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      scalar_negate:
        begin
          Eval_scalar(operand_ptr);
          Push_scalar_operand(-Pop_scalar_operand);
        end;

      integer_to_scalar:
        begin
          Eval_integer(operand_ptr);
          Push_scalar_operand(Pop_integer_operand);
        end;

      long_to_scalar:
        begin
          Eval_long(operand_ptr);
          Push_scalar_operand(Pop_long_operand);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      scalar_add:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_scalar_operand(left_scalar + right_scalar);
        end;

      scalar_subtract:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_scalar_operand(left_scalar - right_scalar);
        end;

      scalar_multiply:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_scalar_operand(left_scalar * right_scalar);
        end;

      scalar_divide:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          if (right_scalar <> 0) then
            Push_scalar_operand(left_scalar / right_scalar)
          else
            Runtime_error('Can not divide by zero.');
        end;

      scalar_exponent:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          if (left_scalar >= 0) or (right_scalar >= 1) then
            Push_scalar_operand(Scalar_power(left_scalar, right_scalar))
          else
            Runtime_error('Can not take roots of negative numbers.');
        end;

      vector_dot_product:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_scalar_operand(Dot_product(left_vector, right_vector));
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      scalar_array_deref, scalar_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_scalar_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_scalar_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_scalar(element_expr_ref);

      {*******************}
      { vector components }
      {*******************}
      vector_x, vector_y, vector_z:
        begin
          Eval_addr(expr_ptr);
          Load_scalar_operand;
        end;

      {************************}
      { user defined functions }
      {************************}
      user_fn:
        Interpret_stmt(stmt_ptr_type(fn_stmt_ptr));

      {***************************************************************}
      {                       expression terminals                    }
      {***************************************************************}

      global_identifier..nested_identifier, itself:
        begin
          Eval_addr(expr_ptr);
          Load_scalar_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      scalar_lit:
        Push_scalar_operand(scalar_val);

    end; {case}
end; {procedure Eval_scalar}


procedure Eval_double(expr_ptr: expr_ptr_type);
var
  right_double, left_double: double_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      double_negate:
        begin
          Eval_double(operand_ptr);
          Push_double_operand(-Pop_double_operand);
        end;

      long_to_double:
        begin
          Eval_long(operand_ptr);
          Push_double_operand(Pop_long_operand);
        end;

      scalar_to_double:
        begin
          Eval_scalar(operand_ptr);
          Push_double_operand(Pop_scalar_operand);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      double_add:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_double_operand(left_double + right_double);
        end;

      double_subtract:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_double_operand(left_double - right_double);
        end;

      double_multiply:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_double_operand(left_double * right_double);
        end;

      double_divide:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          if (right_double <> 0) then
            Push_double_operand(left_double / right_double)
          else
            Runtime_error('Can not divide by zero.');
        end;

      double_exponent:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_double_operand(Scalar_power(left_double, right_double));
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      double_array_deref, double_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_double_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_double_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_double(element_expr_ref);

      {************************}
      { user defined functions }
      {************************}
      user_fn:
        Interpret_stmt(stmt_ptr_type(fn_stmt_ptr));

      {***************************************************************}
      {                       expression terminals                    }
      {***************************************************************}

      global_identifier..nested_identifier, itself:
        begin
          Eval_addr(expr_ptr);
          Load_double_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      double_lit:
        Push_double_operand(double_val);

    end; {case}
end; {procedure Eval_double}


procedure Eval_complex(expr_ptr: expr_ptr_type);
var
  left_complex, right_complex: complex_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      complex_negate:
        begin
          Eval_complex(operand_ptr);
          Push_complex_operand(Complex_negation(Pop_complex_operand));
        end;

      scalar_to_complex:
        begin
          Eval_scalar(operand_ptr);
          Push_complex_operand(Complex(Pop_scalar_operand));
        end;

      complex_pair:
        begin
          Eval_scalar(a_expr_ptr);
          Eval_scalar(b_expr_ptr);
          left_complex.b := Pop_scalar_operand;
          left_complex.a := Pop_scalar_operand;
          Push_complex_operand(left_complex);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      complex_add:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_complex_operand(Complex_sum(left_complex, right_complex));
        end;

      complex_subtract:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_complex_operand(Complex_difference(left_complex, right_complex));
        end;

      complex_multiply:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_complex_operand(Complex_product(left_complex, right_complex));
        end;

      complex_divide:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_complex_operand(Complex_ratio(left_complex, right_complex));
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      complex_array_deref, complex_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_complex_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_complex_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_complex(element_expr_ref);

      {************************}
      { user defined functions }
      {************************}
      user_fn:
        Interpret_stmt(stmt_ptr_type(fn_stmt_ptr));

      {***************************************************************}
      {                       expression terminals                    }
      {***************************************************************}

      global_identifier..nested_identifier, itself:
        begin
          Eval_addr(expr_ptr);
          Load_complex_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      complex_lit:
        Push_complex_operand(complex_val);

    end; {case}
end; {procedure Eval_complex}


procedure Eval_vector(expr_ptr: expr_ptr_type);
var
  left_vector, right_vector: vector_type;
  right_scalar: scalar_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      vector_negate:
        begin
          Eval_vector(operand_ptr);
          Push_vector_operand(Vector_reverse(Pop_vector_operand));
        end;

      vector_triplet:
        begin
          Eval_scalar(x_expr_ptr);
          Eval_scalar(y_expr_ptr);
          Eval_scalar(z_expr_ptr);
          left_vector.z := Pop_scalar_operand;
          left_vector.y := Pop_scalar_operand;
          left_vector.x := Pop_scalar_operand;
          Push_vector_operand(left_vector);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      vector_add:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Vector_sum(left_vector, right_vector));
        end;

      vector_subtract:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Vector_difference(left_vector, right_vector));
        end;

      vector_scalar_multiply:
        begin
          Eval_vector(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Vector_scale(left_vector, right_scalar));
        end;

      vector_vector_multiply:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Vector_scale2(left_vector, right_vector));
        end;

      vector_scalar_divide:
        begin
          Eval_vector(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_vector := Pop_vector_operand;
          if (right_scalar <> 0) then
            Push_vector_operand(Vector_scale(left_vector, 1 / right_scalar))
          else
            Runtime_error('Can not divide by zero.');
        end;

      vector_vector_divide:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Vector_divide(left_vector, right_vector));
        end;

      vector_cross_product:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Cross_product(left_vector, right_vector));
        end;

      vector_parallel:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Parallel(left_vector, right_vector));
        end;

      vector_perpendicular:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_vector_operand(Perpendicular(left_vector, right_vector));
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      vector_array_deref, vector_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_vector_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_vector_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_vector(element_expr_ref);

      {************************}
      { user defined functions }
      {************************}
      user_fn:
        Interpret_stmt(stmt_ptr_type(fn_stmt_ptr));

      {***************************************************************}
      {                       expression terminals                    }
      {***************************************************************}

      global_identifier..nested_identifier, itself:
        begin
          Eval_addr(expr_ptr);
          Load_vector_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      vector_lit:
        Push_vector_operand(vector_val);

    end; {case}
end; {procedure Eval_vector}


end.
