unit eval_integers;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_integers              3d       }
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


{********************************************}
{ routines to evaluate an integer expression }
{********************************************}
procedure Eval_byte(expr_ptr: expr_ptr_type);
procedure Eval_short(expr_ptr: expr_ptr_type);
procedure Eval_integer(expr_ptr: expr_ptr_type);
procedure Eval_long(expr_ptr: expr_ptr_type);


implementation
uses
  data_types, stmts, op_stacks, load_operands, eval_limits, eval_addrs,
  eval_references, exec_stmts, interpreter;


{********************************************}
{ routines to evaluate an integer expression }
{********************************************}


procedure Eval_byte(expr_ptr: expr_ptr_type);
var
  right_byte, left_byte: byte_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      byte_negate:
        begin
          Eval_byte(operand_ptr);
          Push_byte_operand(-Pop_byte_operand);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      byte_add:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_byte_operand(left_byte + right_byte);
        end;

      byte_subtract:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_byte_operand(left_byte - right_byte);
        end;

      byte_multiply:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_byte_operand(left_byte * right_byte);
        end;

      byte_divide:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          if (right_byte <> 0) then
            Push_byte_operand(left_byte div right_byte)
          else
            Runtime_error('Can not divide by zero.');
        end;

      byte_mod:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_byte_operand(left_byte mod right_byte);
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      byte_array_deref, byte_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_byte_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_byte_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_byte(element_expr_ref);

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
          Load_byte_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      byte_lit:
        Push_byte_operand(byte_val);

    end; {case}
end; {procedure Eval_byte}


procedure Eval_short(expr_ptr: expr_ptr_type);
var
  right_short, left_short: short_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      short_negate:
        begin
          Eval_short(operand_ptr);
          Push_short_operand(-Pop_short_operand);
        end;

      byte_to_short:
        begin
          Eval_byte(operand_ptr);
          Push_short_operand(Pop_byte_operand);
        end;


      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      short_add:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_short_operand(left_short + right_short);
        end;

      short_subtract:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_short_operand(left_short - right_short);
        end;

      short_multiply:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_short_operand(left_short * right_short);
        end;

      short_divide:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          if (right_short <> 0) then
            Push_short_operand(left_short div right_short)
          else
            Runtime_error('Can not divide by zero.');
        end;

      short_mod:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_short_operand(left_short mod right_short);
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      short_array_deref, short_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_short_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_short_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_short(element_expr_ref);

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
          Load_short_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      short_lit:
        Push_short_operand(short_val);

    end; {case}
end; {procedure Eval_short}


procedure Eval_integer(expr_ptr: expr_ptr_type);
var
  right_integer, left_integer: integer_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      integer_negate:
        begin
          Eval_integer(operand_ptr);
          Push_integer_operand(-Pop_integer_operand);
        end;

      short_to_integer:
        begin
          Eval_short(operand_ptr);
          Push_integer_operand(Pop_short_operand);
        end;

      {***************************}
      { special integer functions }
      {***************************}
      min_fn:
        Push_integer_operand(Eval_array_min(operand_ptr, 0));
      max_fn:
        Push_integer_operand(Eval_array_max(operand_ptr, 0));
      num_fn:
        Push_integer_operand(Eval_array_num(operand_ptr, 0));

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      integer_add:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_integer_operand(left_integer + right_integer);
        end;

      integer_subtract:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_integer_operand(left_integer - right_integer);
        end;

      integer_multiply:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_integer_operand(left_integer * right_integer);
        end;

      integer_divide:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          if (right_integer <> 0) then
            Push_integer_operand(left_integer div right_integer)
          else
            Runtime_error('Can not divide by zero.');
        end;

      integer_mod:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_integer_operand(left_integer mod right_integer);
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      integer_array_deref, integer_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_integer_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_integer_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_integer(element_expr_ref);

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
          Load_integer_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      integer_lit:
        Push_integer_operand(integer_val);

      enum_lit:
        Push_integer_operand(enum_val);

    end; {case}
end; {procedure Eval_integer}


procedure Eval_long(expr_ptr: expr_ptr_type);
var
  right_long, left_long: long_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      long_negate:
        begin
          Eval_long(operand_ptr);
          Push_long_operand(-Pop_long_operand);
        end;

      integer_to_long:
        begin
          Eval_integer(operand_ptr);
          Push_long_operand(Pop_integer_operand);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      long_add:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_long_operand(left_long + right_long);
        end;

      long_subtract:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_long_operand(left_long - right_long);
        end;

      long_multiply:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_long_operand(left_long * right_long);
        end;

      long_divide:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          if (right_long <> 0) then
            Push_long_operand(left_long div right_long)
          else
            Runtime_error('Can not divide by zero.');
        end;

      long_mod:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_long_operand(left_long mod right_long);
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      long_array_deref, long_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_long_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_long_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_long(element_expr_ref);

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
          Load_long_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      long_lit:
        Push_long_operand(long_val);

    end; {case}
end; {procedure Eval_long}


end.
