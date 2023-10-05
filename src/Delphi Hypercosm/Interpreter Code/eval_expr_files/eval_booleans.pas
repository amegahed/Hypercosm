unit eval_booleans;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_booleans              3d       }
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
{ routines to evaluate a boolean expression }
{*******************************************}
procedure Eval_boolean(expr_ptr: expr_ptr_type);


implementation
uses
  complex_numbers, vectors, data_types, addr_types, stmts, type_decls,
  code_decls, op_stacks, handles, memrefs, load_operands, get_heap_data,
  eval_addrs, eval_chars, eval_integers, eval_scalars, eval_arrays,
  eval_structs, eval_references, exec_stmts;


{*******************************************}
{ routines to evaluate a boolean expression }
{*******************************************}


procedure Eval_boolean(expr_ptr: expr_ptr_type);
var
  memref: memref_type;
  type_ptr, family_type_ptr: type_ptr_type;
  left_boolean, right_boolean: boolean_type;
  left_char, right_char: char_type;
  left_byte, right_byte: byte_type;
  left_short, right_short: short_type;
  left_integer, right_integer: integer_type;
  left_long, right_long: long_type;
  left_scalar, right_scalar: scalar_type;
  left_double, right_double: double_type;
  left_complex, right_complex: complex_type;
  left_vector, right_vector: vector_type;
  left_handle, right_handle: handle_type;
  left_memref, right_memref: memref_type;
  left_code_ptr, right_code_ptr: code_ptr_type;
  left_addr, right_addr: addr_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      not_op:
        begin
          Eval_boolean(operand_ptr);
          Push_boolean_operand(not Pop_boolean_operand);
        end;

      {*****************************}
      { type query boolean operator }
      {*****************************}
      type_query:
        begin
          Eval_struct(class_expr_ptr);
          memref := Pop_memref_operand;

          {************************}
          { check validity of cast }
          {************************}
          if memref <> 0 then
            begin
              type_ptr := type_ptr_type(Get_memref_type(memref, 1));
              family_type_ptr := type_ptr_type(desired_subclass_ref);
              Push_boolean_operand(Member_class(type_ptr, family_type_ptr));
            end
          else
            Push_boolean_operand(true);
        end;

      {***************************************************************}
      {                        binary operators                       }
      {***************************************************************}

      {*************************************}
      { boolean operators (short circuited) }
      {*************************************}

      and_op:
        begin
          Eval_boolean(left_operand_ptr);
          left_boolean := Pop_boolean_operand;
          if left_boolean then
            Eval_boolean(right_operand_ptr)
          else
            Push_boolean_operand(false);
        end;

      or_op:
        begin
          Eval_boolean(left_operand_ptr);
          left_boolean := Pop_boolean_operand;
          if not left_boolean then
            Eval_boolean(right_operand_ptr)
          else
            Push_boolean_operand(true);
        end;

      {*****************************************}
      { boolean operators (non short circuited) }
      {*****************************************}

      and_if_op:
        begin
          Eval_boolean(left_operand_ptr);
          Eval_boolean(right_operand_ptr);
          right_boolean := Pop_boolean_operand;
          left_boolean := Pop_boolean_operand;
          Push_boolean_operand(left_boolean and right_boolean);
        end;

      or_if_op:
        begin
          Eval_boolean(left_operand_ptr);
          Eval_boolean(right_operand_ptr);
          right_boolean := Pop_boolean_operand;
          left_boolean := Pop_boolean_operand;
          Push_boolean_operand(left_boolean or right_boolean);
        end;

      {******************************}
      { boolean relational operators }
      {******************************}

      boolean_equal:
        begin
          Eval_boolean(left_operand_ptr);
          Eval_boolean(right_operand_ptr);
          right_boolean := Pop_boolean_operand;
          left_boolean := Pop_boolean_operand;
          Push_boolean_operand(left_boolean = right_boolean);
        end;

      boolean_not_equal:
        begin
          Eval_boolean(left_operand_ptr);
          Eval_boolean(right_operand_ptr);
          right_boolean := Pop_boolean_operand;
          left_boolean := Pop_boolean_operand;
          Push_boolean_operand(left_boolean <> right_boolean);
        end;

      {***************************}
      { char relational operators }
      {***************************}

      char_equal:
        begin
          Eval_char(left_operand_ptr);
          Eval_char(right_operand_ptr);
          right_char := Pop_char_operand;
          left_char := Pop_char_operand;
          Push_boolean_operand(left_char = right_char);
        end;

      char_not_equal:
        begin
          Eval_char(left_operand_ptr);
          Eval_char(right_operand_ptr);
          right_char := Pop_char_operand;
          left_char := Pop_char_operand;
          Push_boolean_operand(left_char <> right_char);
        end;

      {***************************}
      { byte relational operators }
      {***************************}

      byte_equal:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte = right_byte);
        end;

      byte_not_equal:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte <> right_byte);
        end;

      byte_less_than:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte < right_byte);
        end;

      byte_greater_than:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte > right_byte);
        end;

      byte_less_equal:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte <= right_byte);
        end;

      byte_greater_equal:
        begin
          Eval_byte(left_operand_ptr);
          Eval_byte(right_operand_ptr);
          right_byte := Pop_byte_operand;
          left_byte := Pop_byte_operand;
          Push_boolean_operand(left_byte >= right_byte);
        end;

      {************************************}
      { short integer relational operators }
      {************************************}

      short_equal:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short = right_short);
        end;

      short_not_equal:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short <> right_short);
        end;

      short_less_than:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short < right_short);
        end;

      short_greater_than:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short > right_short);
        end;

      short_less_equal:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short <= right_short);
        end;

      short_greater_equal:
        begin
          Eval_short(left_operand_ptr);
          Eval_short(right_operand_ptr);
          right_short := Pop_short_operand;
          left_short := Pop_short_operand;
          Push_boolean_operand(left_short >= right_short);
        end;

      {******************************}
      { integer relational operators }
      {******************************}

      integer_equal:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer = right_integer);
        end;

      integer_not_equal:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer <> right_integer);
        end;

      integer_less_than:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer < right_integer);
        end;

      integer_greater_than:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer > right_integer);
        end;

      integer_less_equal:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer <= right_integer);
        end;

      integer_greater_equal:
        begin
          Eval_integer(left_operand_ptr);
          Eval_integer(right_operand_ptr);
          right_integer := Pop_integer_operand;
          left_integer := Pop_integer_operand;
          Push_boolean_operand(left_integer >= right_integer);
        end;

      {***********************************}
      { long integer relational operators }
      {***********************************}

      long_equal:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long = right_long);
        end;

      long_not_equal:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long <> right_long);
        end;

      long_less_than:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long < right_long);
        end;

      long_greater_than:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long > right_long);
        end;

      long_less_equal:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long <= right_long);
        end;

      long_greater_equal:
        begin
          Eval_long(left_operand_ptr);
          Eval_long(right_operand_ptr);
          right_long := Pop_long_operand;
          left_long := Pop_long_operand;
          Push_boolean_operand(left_long >= right_long);
        end;

      {*****************************}
      { scalar relational operators }
      {*****************************}

      scalar_equal:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar = right_scalar);
        end;

      scalar_not_equal:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar <> right_scalar);
        end;

      scalar_less_than:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar < right_scalar);
        end;

      scalar_greater_than:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar > right_scalar);
        end;

      scalar_less_equal:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar <= right_scalar);
        end;

      scalar_greater_equal:
        begin
          Eval_scalar(left_operand_ptr);
          Eval_scalar(right_operand_ptr);
          right_scalar := Pop_scalar_operand;
          left_scalar := Pop_scalar_operand;
          Push_boolean_operand(left_scalar >= right_scalar);
        end;

      {**********************************************}
      { double precision scalar relational operators }
      {**********************************************}

      double_equal:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double = right_double);
        end;

      double_not_equal:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double <> right_double);
        end;

      double_less_than:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double < right_double);
        end;

      double_greater_than:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double > right_double);
        end;

      double_less_equal:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double <= right_double);
        end;

      double_greater_equal:
        begin
          Eval_double(left_operand_ptr);
          Eval_double(right_operand_ptr);
          right_double := Pop_double_operand;
          left_double := Pop_double_operand;
          Push_boolean_operand(left_double >= right_double);
        end;

      {******************************}
      { complex relational operators }
      {******************************}

      complex_equal:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_boolean_operand(Equal_complex(left_complex, right_complex));
        end;

      complex_not_equal:
        begin
          Eval_complex(left_operand_ptr);
          Eval_complex(right_operand_ptr);
          right_complex := Pop_complex_operand;
          left_complex := Pop_complex_operand;
          Push_boolean_operand(not Equal_complex(left_complex, right_complex));
        end;

      {*****************************}
      { vector relational operators }
      {*****************************}

      vector_equal:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_boolean_operand(Equal_vector(left_vector, right_vector));
        end;

      vector_not_equal:
        begin
          Eval_vector(left_operand_ptr);
          Eval_vector(right_operand_ptr);
          right_vector := Pop_vector_operand;
          left_vector := Pop_vector_operand;
          Push_boolean_operand(not Equal_vector(left_vector, right_vector));
        end;

      {****************************}
      { array relational operators }
      {****************************}

      array_ptr_equal:
        begin
          Eval_array(left_operand_ptr);
          Eval_array(right_operand_ptr);
          right_handle := Pop_handle_operand;
          left_handle := Pop_handle_operand;
          Push_boolean_operand(right_handle = left_handle);
          if left_handle <> 0 then
            Free_handle(left_handle);
          if right_handle <> 0 then
            Free_handle(right_handle);
        end;

      array_ptr_not_equal:
        begin
          Eval_array(left_operand_ptr);
          Eval_array(right_operand_ptr);
          right_handle := Pop_handle_operand;
          left_handle := Pop_handle_operand;
          Push_boolean_operand(right_handle <> left_handle);
          if left_handle <> 0 then
            Free_handle(left_handle);
          if right_handle <> 0 then
            Free_handle(right_handle);
        end;

      {********************************}
      { structure relational operators }
      {********************************}

      struct_ptr_equal:
        begin
          Eval_struct(left_operand_ptr);
          Eval_struct(right_operand_ptr);
          right_memref := Pop_memref_operand;
          left_memref := Pop_memref_operand;
          Push_boolean_operand(right_memref = left_memref);
          if left_memref <> 0 then
            Free_memref(left_memref);
          if right_memref <> 0 then
            Free_memref(right_memref);
        end;

      struct_ptr_not_equal:
        begin
          Eval_struct(left_operand_ptr);
          Eval_struct(right_operand_ptr);
          right_memref := Pop_memref_operand;
          left_memref := Pop_memref_operand;
          Push_boolean_operand(right_memref <> left_memref);
          if left_memref <> 0 then
            Free_memref(left_memref);
          if right_memref <> 0 then
            Free_memref(right_memref);
        end;

      {********************************}
      { prototype relational operators }
      {********************************}

      proto_equal:
        begin
          Eval_proto(left_operand_ptr);
          Pop_stack_index_operand;
          left_code_ptr := code_ptr_type(Pop_code_operand);
          Eval_proto(right_operand_ptr);
          Pop_stack_index_operand;
          right_code_ptr := code_ptr_type(Pop_code_operand);
          Push_boolean_operand((right_code_ptr = left_code_ptr));
        end;

      proto_not_equal:
        begin
          Eval_proto(left_operand_ptr);
          Pop_stack_index_operand;
          left_code_ptr := code_ptr_type(Pop_code_operand);
          Eval_proto(right_operand_ptr);
          Pop_stack_index_operand;
          right_code_ptr := code_ptr_type(Pop_code_operand);
          Push_boolean_operand((right_code_ptr <> left_code_ptr));
        end;

      {********************************}
      { reference relational operators }
      {********************************}

      reference_equal:
        begin
          Eval_reference(left_operand_ptr);
          Eval_reference(right_operand_ptr);
          left_addr := Pop_addr_operand;
          right_addr := Pop_addr_operand;
          Push_boolean_operand(Equal_addrs(left_addr, right_addr));
        end;

      reference_not_equal:
        begin
          Eval_reference(left_operand_ptr);
          Eval_reference(right_operand_ptr);
          left_addr := Pop_addr_operand;
          right_addr := Pop_addr_operand;
          Push_boolean_operand(not Equal_addrs(left_addr, right_addr));
        end;

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      boolean_array_deref, boolean_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_boolean_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_boolean_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_boolean(element_expr_ref);

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
          Load_boolean_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      true_val:
        Push_boolean_operand(true);
      false_val:
        Push_boolean_operand(false);

    end; {case}
end; {procedure Eval_boolean}


end.
