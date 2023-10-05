unit eval_arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_arrays                3d       }
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


{******************************************}
{ routines to evaluate an array expression }
{******************************************}
procedure Eval_array(expr_ptr: expr_ptr_type);


implementation
uses
  addr_types, stmts, type_decls, handles, op_stacks, load_operands,
  eval_new_arrays, eval_expr_arrays, eval_addrs, eval_references,
  eval_subranges, exec_stmts;


{******************************************}
{ routines to evaluate an array expression }
{******************************************}


procedure Eval_expr_array(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    begin
      case kind of

        {******************************}
        { enumerated array expressions }
        {******************************}
        boolean_array_expr:
          Eval_boolean_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        char_array_expr:
          Eval_char_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);

        {***************************}
        { integer array expressions }
        {***************************}
        byte_array_expr:
          Eval_byte_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        short_array_expr:
          Eval_short_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        integer_array_expr:
          Eval_integer_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        long_array_expr:
          Eval_long_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);

        {**************************}
        { scalar array expressions }
        {**************************}
        scalar_array_expr:
          Eval_scalar_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        double_array_expr:
          Eval_double_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        complex_array_expr:
          Eval_complex_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        vector_array_expr:
          Eval_vector_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);

        {**********************************}
        { array / struct array expressions }
        {**********************************}
        array_array_expr:
          Eval_array_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        struct_array_expr:
          Eval_struct_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        static_struct_array_expr:
          Eval_static_struct_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);

        {******************************************}
        { subprogram / reference array expressions }
        {******************************************}
        proto_array_expr:
          Eval_code_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);
        reference_array_expr:
          Eval_reference_expr_array(array_expr_bounds_list_ptr,
            array_element_exprs_ptr);

      end; {case}
    end; {with}
end; {procedure Eval_expr_array}


procedure Eval_dim_array(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    begin
      Eval_array_bounds_list(dim_bounds_list_ptr);

      case kind of

        {*******************************}
        { enumerated array dimensioning }
        {*******************************}
        boolean_array_dim:
          Eval_new_boolean_array(dim_bounds_list_ptr);
        char_array_dim:
          Eval_new_char_array(dim_bounds_list_ptr);

        {****************************}
        { integer array dimensioning }
        {****************************}
        byte_array_dim:
          Eval_new_byte_array(dim_bounds_list_ptr);
        short_array_dim:
          Eval_new_short_array(dim_bounds_list_ptr);
        integer_array_dim:
          Eval_new_integer_array(dim_bounds_list_ptr);
        long_array_dim:
          Eval_new_long_array(dim_bounds_list_ptr);

        {***************************}
        { scalar array dimensioning }
        {***************************}
        scalar_array_dim:
          Eval_new_scalar_array(dim_bounds_list_ptr);
        double_array_dim:
          Eval_new_double_array(dim_bounds_list_ptr);
        complex_array_dim:
          Eval_new_complex_array(dim_bounds_list_ptr);
        vector_array_dim:
          Eval_new_vector_array(dim_bounds_list_ptr);

        {***********************************}
        { array / struct array dimensioning }
        {***********************************}
        array_array_dim:
          Eval_new_array_array(dim_bounds_list_ptr, dim_element_expr_ptr);
        struct_array_dim:
          Eval_new_struct_array(dim_bounds_list_ptr, dim_element_expr_ptr);
        static_struct_array_dim:
          Eval_new_static_struct_array(dim_bounds_list_ptr,
            type_ptr_type(dim_static_struct_type_ref),
            stmt_ptr_type(dim_static_struct_init_stmt_ptr));

        {*******************************************}
        { subprogram / reference array dimensioning }
        {*******************************************}
        proto_array_dim:
          Eval_new_code_array(dim_bounds_list_ptr);
        reference_array_dim:
          Eval_new_reference_array(dim_bounds_list_ptr);

      end; {case}
    end; {with}
end; {procedure Eval_dim_array}


procedure Eval_array(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do
    case kind of

      {***************************************************************}
      {                      array expression terms                   }
      {***************************************************************}

      {*******************}
      { array expressions }
      {*******************}
      boolean_array_expr..reference_array_expr:
        Eval_expr_array(expr_ptr);

      {********************}
      { array dimensioning }
      {********************}
      boolean_array_dim..reference_array_dim:
        Eval_dim_array(expr_ptr);

      {*******************************************}
      { implicit references used in array assigns }
      {*******************************************}
      array_base:
        Push_handle_operand(Clone_handle(array_base_handle));

      {***************************************************************}
      {                         expression terms        	            }
      {***************************************************************}

      {*********************************}
      { array / structure dereferencing }
      {*********************************}
      array_array_deref, array_array_subrange, struct_deref..field_offset:
        begin
          Eval_addr(expr_ptr);
          Load_handle_operand;
        end;
      deref_op:
        begin
          Eval_reference(operand_ptr);
          Load_handle_operand;
        end;

      {*******************}
      { array expressions }
      {*******************}
      element_expr:
        Eval_array(element_expr_ref);

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
          Load_handle_operand;
        end;

      {***************************************************************}
      {                      expression literals        	      }
      {***************************************************************}

      nil_array:
        Push_handle_operand(0);

    end; {case}
end; {procedure Eval_array}


end.
