unit eval_chars;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             eval_chars                3d       }
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


{*********************************************}
{ routines to evaluate a character expression }
{*********************************************}
procedure Eval_char(expr_ptr: expr_ptr_type);


implementation
uses
  stmts, op_stacks, load_operands, eval_addrs, eval_references, exec_stmts;


{*********************************************}
{ routines to evaluate a character expression }
{*********************************************}


procedure Eval_char(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      char_array_deref, char_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_char_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_char_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_char(element_expr_ref);

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
          Load_char_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      char_lit:
        Push_char_operand(char_val);

    end; {case}
end; {procedure Eval_char}


end.
