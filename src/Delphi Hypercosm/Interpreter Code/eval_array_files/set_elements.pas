unit set_elements;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            set_elements               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module controls the way that arrays are            }
{       handled by the interpreter. It is responsible           }
{       for the layout of the array structures on the           }
{       run-time stack.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, exprs;


{*******************************}
{ set enumerated array elements }
{*******************************}
procedure Set_boolean_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_char_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);

{*****************************}
{ set integral array elements }
{*****************************}
procedure Set_byte_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_short_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_integer_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_long_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);

{***************************}
{ set scalar array elements }
{***************************}
procedure Set_scalar_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_double_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);

{*****************************}
{ set compound array elements }
{*****************************}
procedure Set_complex_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_vector_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);

{******************************}
{ set reference array elements }
{******************************}
procedure Set_array_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_struct_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_static_struct_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_code_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
procedure Set_reference_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);


implementation
uses
  op_stacks, set_heap_data, eval_booleans, eval_chars, eval_integers,
  eval_scalars, eval_arrays, eval_structs, eval_references;


{*******************************}
{ set enumerated array elements }
{*******************************}


procedure Set_boolean_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_boolean(element_exprs_ptr);
          Set_handle_boolean(handle, index, Pop_boolean_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_boolean_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_boolean_elements}


procedure Set_char_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_char(element_exprs_ptr);
          Set_handle_char(handle, index, Pop_char_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_char_elements(element_exprs_ptr^.subarray_element_exprs_ptr, handle,
          index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_char_elements}


{*****************************}
{ set integral array elements }
{*****************************}


procedure Set_byte_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_byte(element_exprs_ptr);
          Set_handle_byte(handle, index, Pop_byte_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_char_elements(element_exprs_ptr^.subarray_element_exprs_ptr, handle,
          index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_byte_elements}


procedure Set_short_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_short(element_exprs_ptr);
          Set_handle_short(handle, index, Pop_short_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_short_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_short_elements}


procedure Set_integer_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_integer(element_exprs_ptr);
          Set_handle_integer(handle, index, Pop_integer_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_integer_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_integer_elements}


procedure Set_long_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_long(element_exprs_ptr);
          Set_handle_long(handle, index, Pop_long_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_long_elements(element_exprs_ptr^.subarray_element_exprs_ptr, handle,
          index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_long_elements}


{***************************}
{ set scalar array elements }
{***************************}


procedure Set_scalar_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_scalar(element_exprs_ptr);
          Set_handle_scalar(handle, index, Pop_scalar_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_scalar_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_scalar_elements}


procedure Set_double_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_double(element_exprs_ptr);
          Set_handle_double(handle, index, Pop_double_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_double_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_double_elements}


{*****************************}
{ set compound array elements }
{*****************************}


procedure Set_complex_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_scalar(element_exprs_ptr);
          Set_handle_complex(handle, index, Pop_complex_operand);
          index := index + 2;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_complex_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_complex_elements}


procedure Set_vector_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_vector(element_exprs_ptr);
          Set_handle_vector(handle, index, Pop_vector_operand);
          index := index + 3;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_vector_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_vector_elements}


{******************************}
{ set reference array elements }
{******************************}


procedure Set_array_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_array(element_exprs_ptr);
          Set_handle_handle(handle, index, Pop_handle_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_array_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_array_elements}


procedure Set_struct_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_struct(element_exprs_ptr);
          Set_handle_memref(handle, index, Pop_memref_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_struct_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_struct_elements}


procedure Set_static_struct_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_struct(element_exprs_ptr);
          Set_handle_memref(handle, index, Pop_memref_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_static_struct_elements(element_exprs_ptr^.subarray_element_exprs_ptr, handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_static_struct_elements}


procedure Set_code_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_proto(element_exprs_ptr);
          Set_handle_stack_index(handle, index, Pop_stack_index_operand);
          Set_handle_code(handle, index + 1, Pop_code_operand);
          index := index + 2;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_code_elements(element_exprs_ptr^.subarray_element_exprs_ptr, handle,
          index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_code_elements}


procedure Set_reference_elements(element_exprs_ptr: expr_ptr_type;
  handle: handle_type;
  var index: heap_index_type);
begin
  while (element_exprs_ptr <> nil) do
    begin
      {**********************************************}
      { single dimensional integer array expressions }
      {**********************************************}
      if element_exprs_ptr^.kind <> subarray_expr then
        begin
          Eval_reference(element_exprs_ptr);
          Set_handle_addr(handle, index, Pop_addr_operand);
          index := index + 1;
        end

          {********************************************}
          { multidimensional integer array expressions }
          {********************************************}
      else
        Set_reference_elements(element_exprs_ptr^.subarray_element_exprs_ptr,
          handle, index);

      {************}
      { go to next }
      {************}
      element_exprs_ptr := element_exprs_ptr^.next;
    end;
end; {procedure Set_reference_elements}


end.
