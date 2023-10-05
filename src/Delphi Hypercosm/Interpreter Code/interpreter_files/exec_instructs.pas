unit exec_instructs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           exec_instructs              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to interpret the          }
{       built in instructions.                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  instructs;


procedure Exec_instruct(instruct_ptr: instruct_ptr_type);


implementation
uses
  strings, complex_numbers, vectors, data_types, exprs, op_stacks, set_data,
  deref_arrays, eval_references, eval_booleans, eval_chars, eval_integers,
  eval_scalars, eval_arrays, addr_types, handles, interpreter;


procedure Exec_write_instruct(instruct_ptr: instruct_ptr_type);
var
  expr_ptr: expr_ptr_type;
  handle: handle_type;
begin
  with instruct_ptr^ do
    case kind of

      {***************************************************************}
      {                       output instructions                     }
      {***************************************************************}

      {******************}
      { enumerated types }
      {******************}
      boolean_write:
        begin
          Eval_boolean(argument_ptr);
          write(Pop_boolean_operand);
        end;
      char_write:
        begin
          Eval_char(argument_ptr);
          write(Pop_char_operand);
        end;

      {****************}
      { integral types }
      {****************}
      byte_write:
        begin
          Eval_byte(argument_ptr);
          write(Pop_byte_operand);
        end;
      short_write:
        begin
          Eval_short(argument_ptr);
          write(Pop_short_operand);
        end;
      integer_write:
        begin
          Eval_integer(argument_ptr);
          write(Pop_integer_operand: 1);
        end;
      long_write:
        begin
          Eval_long(argument_ptr);
          write(Pop_long_operand: 1);
        end;

      {**************}
      { scalar types }
      {**************}
      scalar_write:
        begin
          Eval_scalar(argument_ptr);
          write(Pop_scalar_operand: 4: 4);
        end;
      double_write:
        begin
          Eval_double(argument_ptr);
          write(Pop_double_operand: 8: 8);
        end;
      complex_write:
        begin
          Eval_complex(argument_ptr);
          Write_complex(Pop_complex_operand);
        end;
      vector_write:
        begin
          Eval_vector(argument_ptr);
          Write_vector(Pop_vector_operand);
        end;

      {**************}
      { string types }
      {**************}
      string_write:
        begin
          if argument_ptr^.kind = char_array_expr then
            begin
              {*****************}
              { string literals }
              {*****************}
              expr_ptr := argument_ptr^.array_element_exprs_ptr;
              while expr_ptr <> nil do
                begin
                  Eval_char(expr_ptr);
                  write(Pop_char_operand);
                  expr_ptr := expr_ptr^.next;
                end;
            end
          else
            begin
              {***************}
              { string arrays }
              {***************}
              Eval_array(argument_ptr);
              handle := Pop_handle_operand;
              write(Get_string_from_handle(handle));
              Free_handle(handle);
            end;
        end;

      {*************************}
      { new line (no arguments) }
      {*************************}
      write_newline:
        writeln;
    end; {case}
end; {procedure Exec_write_instruct}


procedure Exec_read_instruct(instruct_ptr: instruct_ptr_type);
var
  boolean_val: boolean_type;
  char_val: char_type;
  byte_val: byte_type;
  short_val: short_type;
  integer_val: integer_type;
  long_val: long_type;
  scalar_val: scalar_type;
  double_val: double_type;
  complex_val: complex_type;
  vector_val: vector_type;
  str: string_type;
begin
  with instruct_ptr^ do
    case kind of

      {***************************************************************}
      {                        input instructions                     }
      {***************************************************************}

      {******************}
      { enumerated types }
      {******************}
      boolean_read:
        begin
          read(str);
          if (str = 'true') or (str = 'True') then
            boolean_val := true
          else if (str = 'false') or (str = 'False') then
            boolean_val := false
          else
            begin
              Runtime_error('Unable to read boolean value');
              boolean_val := false;
            end;
          Eval_reference(argument_ptr);
          Set_addr_boolean(Pop_addr_operand, boolean_val);
        end;
      char_read:
        begin
          read(char_val);
          Eval_reference(argument_ptr);
          Set_addr_char(Pop_addr_operand, char_val);
        end;

      {****************}
      { integral types }
      {****************}
      byte_read:
        begin
          read(byte_val);
          Eval_reference(argument_ptr);
          Set_addr_byte(Pop_addr_operand, byte_val);
        end;
      short_read:
        begin
          read(short_val);
          Eval_reference(argument_ptr);
          Set_addr_short(Pop_addr_operand, short_val);
        end;
      integer_read:
        begin
          read(integer_val);
          Eval_reference(argument_ptr);
          Set_addr_integer(Pop_addr_operand, integer_val);
        end;
      long_read:
        begin
          read(long_val);
          Eval_reference(argument_ptr);
          Set_addr_long(Pop_addr_operand, long_val);
        end;

      {**************}
      { scalar types }
      {**************}
      scalar_read:
        begin
          read(scalar_val);
          Eval_reference(argument_ptr);
          Set_addr_scalar(Pop_addr_operand, scalar_val);
        end;
      double_read:
        begin
          read(double_val);
          Eval_reference(argument_ptr);
          Set_addr_double(Pop_addr_operand, double_val);
        end;
      complex_read:
        begin
          read(complex_val.a);
          read(complex_val.b);
          Eval_reference(argument_ptr);
          Set_addr_complex(Pop_addr_operand, complex_val);
        end;
      vector_read:
        begin
          read(vector_val.x);
          read(vector_val.y);
          read(vector_val.z);
          Eval_reference(argument_ptr);
          Set_addr_vector(Pop_addr_operand, vector_val);
        end;

      {**************}
      { string types }
      {**************}
      string_read:
        ;

      {*************************}
      { new line (no arguments) }
      {*************************}
      read_newline:
        readln;

    end; {case}
end; {procedure Exec_read_instruct}


procedure Exec_instruct(instruct_ptr: instruct_ptr_type);
begin
  if instruct_ptr^.kind in output_instruct_set then
    Exec_write_instruct(instruct_ptr)
  else if instruct_ptr^.kind in input_instruct_set then
    Exec_read_instruct(instruct_ptr);
end; {procedure Exec_instruct}


end.

