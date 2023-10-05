unit eval_references;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           eval_references             3d       }
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


{**********************************************}
{ routines to evaluate an reference expression }
{**********************************************}
procedure Eval_reference(expr_ptr: expr_ptr_type);
procedure Eval_proto(expr_ptr: expr_ptr_type);


implementation
uses
  stmts, type_decls, heaps, op_stacks, get_data, load_operands, eval_addrs,
  eval_arrays, eval_structs, exec_stmts;


{**********************************************}
{ routines to evaluate an reference expression }
{**********************************************}


procedure Eval_reference(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                      expression terminals        	      }
      {***************************************************************}

      {**********************}
      { addressing operators }
      {**********************}
      address_op:
        Eval_addr(operand_ptr);

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      reference_array_deref, reference_array_subrange,
        struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_addr_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_addr_operand;
        end;

      {*******************************************}
      { implicit references used in array assigns }
      {*******************************************}
      array_base:
        Eval_array(expr_ptr);

      {***********************************************}
      { implicit references used in structure assigns }
      {***********************************************}
      struct_base:
        Eval_struct(expr_ptr);
      static_struct_base:
        Push_addr_operand(Clone_addr(static_struct_base_addr));
      new_itself:
        with type_ptr_type(new_type_ref)^ do
          case kind of
            struct_type:
              Eval_reference(struct_base_ptr);
            class_type:
              Eval_reference(class_base_ptr);
          end; {case}

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_reference(element_expr_ref);

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
          Load_addr_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      nil_reference:
        Push_stack_index_operand(0);

    end; {case}
end; {procedure Eval_reference}


procedure Eval_proto(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      proto_array_deref, proto_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_proto_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_proto_operand;
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
          Load_proto_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}
      nil_proto:
        begin
          Push_code_operand(nil);
          Push_stack_index_operand(0);
        end;

    end; {case}
end; {procedure Eval_proto}


end.
