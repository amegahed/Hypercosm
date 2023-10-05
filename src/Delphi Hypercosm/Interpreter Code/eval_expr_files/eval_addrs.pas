unit eval_addrs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             eval_addrs                3d       }
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
  addr_types, exprs;


{**********************************************************}
{ routines for evaluating expressions from the syntax tree }
{**********************************************************}
procedure Eval_addr(expr_ptr: expr_ptr_type);


implementation
uses
  errors, type_decls, stacks, op_stacks, get_data, set_data, deref_arrays,
  eval_subranges, eval_references, eval_arrays, eval_structs;


procedure Eval_addr(expr_ptr: expr_ptr_type);
var
  addr: addr_type;
  handle: handle_type;
  memref: memref_type;
  element_size: integer;
  offset_index: heap_index_type;
  stack_addr: stack_addr_type;
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      {**********************}
      { addressing operators }
      {**********************}

      deref_op:
        Eval_reference(operand_ptr);

      {***************************************************************}
      {                       array dereferencing                     }
      {***************************************************************}

      {*******************************}
      { primitive array dereferencing }
      {*******************************}

      boolean_array_deref..double_array_deref:
        begin
          Eval_array(deref_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(deref_index_list_ptr);
          offset_index := Deref_array(handle, deref_index_list_ptr, 1);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {******************************}
      { compound array dereferencing }
      {******************************}

      complex_array_deref:
        begin
          Eval_array(deref_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(deref_index_list_ptr);
          offset_index := Deref_array(handle, deref_index_list_ptr, 2);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      vector_array_deref:
        begin
          Eval_array(deref_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(deref_index_list_ptr);
          offset_index := Deref_array(handle, deref_index_list_ptr, 3);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {*******************************}
      { reference array dereferencing }
      {*******************************}

      array_array_deref, struct_array_deref, proto_array_deref,
        reference_array_deref:
        begin
          Eval_array(deref_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(deref_index_list_ptr);
          offset_index := Deref_array(handle, deref_index_list_ptr, 1);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {**************************************}
      { static structure array dereferencing }
      {**************************************}

      static_struct_array_deref:
        begin
          Eval_array(deref_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(deref_index_list_ptr);
          element_size := type_ptr_type(deref_static_struct_type_ref)^.size;
          offset_index := Deref_array(handle, deref_index_list_ptr,
            element_size);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {***************************************************************}
      {                   array subrange expressions                  }
      {***************************************************************}

      {***************************}
      { primitive array subranges }
      {***************************}

      boolean_array_subrange..double_array_subrange:
        begin
          Eval_array(subrange_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(subrange_index_list_ptr);
          offset_index := Deref_array(handle, subrange_index_list_ptr, 1);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {**************************}
      { compound array subranges }
      {**************************}

      complex_array_subrange:
        begin
          Eval_array(subrange_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(subrange_index_list_ptr);
          offset_index := Deref_array(handle, subrange_index_list_ptr, 2);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      vector_array_subrange:
        begin
          Eval_array(subrange_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(subrange_index_list_ptr);
          offset_index := Deref_array(handle, subrange_index_list_ptr, 3);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {***************************}
      { reference array subranges }
      {***************************}

      array_array_subrange, struct_array_subrange, proto_array_subrange,
        reference_array_subrange:
        begin
          Eval_array(subrange_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(subrange_index_list_ptr);
          offset_index := Deref_array(handle, subrange_index_list_ptr, 1);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {**********************************}
      { static structure array subranges }
      {**********************************}

      static_struct_array_subrange:
        begin
          Eval_array(subrange_base_ptr);
          handle := Pop_handle_operand;
          Eval_array_index_list(subrange_index_list_ptr);
          element_size := type_ptr_type(subrange_static_struct_type_ref)^.size;
          offset_index := Deref_array(handle, subrange_index_list_ptr,
            element_size);
          Push_addr_operand(Handle_addr_to_addr(handle, offset_index));
        end;

      {***************************************************************}
      {                   structure expression terms                  }
      {***************************************************************}

      {*************************}
      { structure dereferencing }
      {*************************}

      struct_deref:
        begin
          Eval_struct(base_expr_ptr);
          memref := Pop_memref_operand;
          Eval_addr(field_expr_ptr);
          offset_index := Pop_heap_index_operand;
          Push_addr_operand(Memref_addr_to_addr(memref, offset_index));
        end;

      struct_offset:
        begin
          Eval_addr(base_expr_ptr);
          addr := Pop_addr_operand;
          Eval_addr(field_expr_ptr);
          offset_index := Pop_heap_index_operand;
          Push_addr_operand(Get_offset_addr(addr, offset_index - 1));
        end;

      field_deref:
        begin
          Eval_struct(base_expr_ref);
          memref := Pop_memref_operand;
          Eval_addr(field_name_ptr);
          offset_index := Pop_heap_index_operand;
          Push_addr_operand(Memref_addr_to_addr(memref, offset_index));
        end;

      field_offset:
        begin
          Eval_reference(base_expr_ptr);
          addr := Pop_addr_operand;
          Eval_addr(field_name_ptr);
          offset_index := Pop_heap_index_operand;
          Push_addr_operand(Get_offset_addr(addr, offset_index - 1));
        end;

      {*******************}
      { vector components }
      {*******************}

      vector_x:
        begin
          Eval_addr(operand_ptr);
          addr := Pop_addr_operand;
          Push_addr_operand(addr);
        end;

      vector_y:
        begin
          Eval_addr(operand_ptr);
          addr := Pop_addr_operand;
          Push_addr_operand(Get_offset_addr(addr, 1));
        end;

      vector_z:
        begin
          Eval_addr(operand_ptr);
          addr := Pop_addr_operand;
          Push_addr_operand(Get_offset_addr(addr, 2));
        end;

      {***************************************************************}
      {                      expression terminals        	      }
      {***************************************************************}

      {***********************************}
      { user defined variables and fields }
      {***********************************}

      global_identifier:
        Push_stack_index_operand(stack_index);

      local_identifier:
        Push_stack_index_operand(Local_index_to_global(stack_index));

      nested_identifier:
        begin
          stack_addr.stack_index := nested_id_expr_ptr^.stack_index;
          stack_addr.static_links := static_links;
          stack_addr.dynamic_links := dynamic_links;
          Push_stack_index_operand(Stack_addr_to_index(stack_addr));
        end;

      field_identifier:
        Push_heap_index_operand(field_index);

      {*************************}
      { most recent addr caches }
      {*************************}
      itself:
        Push_addr_operand(Clone_addr(addr_cache));

    end; {case}
end; {procedure Eval_addr}


end.
