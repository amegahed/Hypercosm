unit eval_structs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_structs               3d       }
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
{ routines to evaluate an struct expression }
{*******************************************}
procedure Eval_struct(expr_ptr: expr_ptr_type);


implementation
uses
  addr_types, type_decls, stmts, memrefs, op_stacks, load_operands,
  get_heap_data, get_data, eval_addrs, eval_references, exec_structs,
  exec_stmts, interpreter;


{*******************************************}
{ routines to evaluate an struct expression }
{*******************************************}


procedure Eval_struct(expr_ptr: expr_ptr_type);
var
  type_ptr, family_type_ptr: type_ptr_type;
  memref: memref_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                   structure expression terms                  }
      {***************************************************************}

      {**********************}
      { structure allocation }
      {**********************}
      struct_new:
        begin
          type_ptr := type_ptr_type(new_struct_type_ref);

          if type_ptr^.static then
            begin
              {**************************}
              { initialize static fields }
              {**************************}
              Init_static_struct_fields(Pop_addr_operand, type_ptr);
            end
          else
            begin
              {*********************}
              { allocate heap space }
              {*********************}
              memref := New_memref(type_ptr^.size);
              Push_memref_operand(memref);

              {*******************}
              { initialize fields }
              {*******************}
              Init_struct_fields(memref, type_ptr);
            end;

          {***********************}
          { interpret constructor }
          {***********************}
          if new_struct_init_stmt_ptr <> nil then
            Interpret_stmt(stmt_ptr_type(new_struct_init_stmt_ptr));
        end; {struct_new}

      {*************************}
      { explicit ptr conversion }
      {*************************}
      ptr_cast:
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

              if not Member_class(type_ptr, family_type_ptr) then
                Runtime_error('Invalid type assignment.');
            end;

          Push_memref_operand(memref);
        end;

      {***********************************************}
      { implicit references used in structure assigns }
      {***********************************************}
      struct_base:
        Push_memref_operand(Clone_memref(struct_base_memref));
      new_itself:
        with type_ptr_type(new_type_ref)^ do
          case kind of
            struct_type:
              Eval_struct(struct_base_ptr);
            class_type:
              Eval_struct(class_base_ptr);
          end; {case}

      {***************************************************************}
      {                         expression terms        	      }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      struct_array_deref, struct_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_memref_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_memref_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_struct(element_expr_ref);

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
          Load_memref_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      nil_struct:
        Push_memref_operand(0);

    end; {case}
end; {procedure Eval_struct}


end.
