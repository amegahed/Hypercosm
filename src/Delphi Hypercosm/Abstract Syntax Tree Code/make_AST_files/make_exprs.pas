unit make_exprs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             make_exprs                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on the expression syntax trees.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs;


{***************************************************}
{ routines for recursively copying expression trees }
{***************************************************}
function Clone_expr(expr_ptr: expr_ptr_type;
  copy_attributes: boolean): expr_ptr_type;
function Clone_exprs(expr_ptr: expr_ptr_type;
  copy_attributes: boolean): expr_ptr_type;

{***************************************************}
{ routines for recursively freeing expression trees }
{***************************************************}
procedure Destroy_expr(var expr_ptr: expr_ptr_type;
  free_attributes: boolean);
procedure Destroy_exprs(var expr_ptr: expr_ptr_type;
  free_attributes: boolean);

{***************************************************}
{ routines for recursively marking expression trees }
{***************************************************}
procedure Mark_expr(expr_ptr: expr_ptr_type;
  touched: boolean);
procedure Mark_exprs(expr_ptr: expr_ptr_type;
  touched: boolean);
procedure Mark_expr_attributes(expr_attributes_ptr: expr_attributes_ptr_type;
  touched: boolean);

{*****************************************************}
{ routines for recursively comparing expression trees }
{*****************************************************}
function Equal_exprs(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;
function Same_exprs(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;


implementation
uses
  complex_numbers, vectors, lit_attributes, stmts, decls, type_decls,
  compare_exprs, make_arrays, make_stmts, make_decls, make_type_decls;


{***************************************************}
{ routines for recursively copying expression trees }
{***************************************************}


function Clone_expr(expr_ptr: expr_ptr_type;
  copy_attributes: boolean): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
  new_expr_info_ptr: expr_info_ptr_type;
begin
  if (expr_ptr <> nil) then
    begin
      new_expr_ptr := Copy_expr(expr_ptr);

      {***************************}
      { copy auxilliary expr info }
      {***************************}
      if copy_attributes then
        if expr_ptr^.expr_info_ptr <> nil then
          begin
            new_expr_info_ptr := Copy_expr_info(expr_ptr^.expr_info_ptr,
              copy_attributes);
            Set_expr_info(new_expr_ptr, new_expr_info_ptr);
          end;

      with new_expr_ptr^ do

        {***************************************************************}
        {                      expression operators       	            }
        {***************************************************************}

        {*****************}
        { unary operators }
        {*****************}
        if kind in unary_operator_set then
          operand_ptr := Clone_expr(operand_ptr, copy_attributes)

          {******************}
          { binary operators }
          {******************}
        else if kind in binary_operator_set then
          begin
            left_operand_ptr := Clone_expr(left_operand_ptr, copy_attributes);
            right_operand_ptr := Clone_expr(right_operand_ptr, copy_attributes);
          end

            {***************************************************************}
            {                    array expression terms                     }
            {***************************************************************}
        else if kind in array_expr_set then
          case kind of

            {*******************}
            { array expressions }
            {*******************}
            boolean_array_expr..reference_array_expr:
              begin
                array_expr_bounds_list_ptr :=
                  Clone_array_bounds_list(array_expr_bounds_list_ptr,
                  copy_attributes);
                array_element_exprs_ptr := Clone_exprs(array_element_exprs_ptr,
                  copy_attributes);
              end;
            subarray_expr:
              subarray_element_exprs_ptr :=
                Clone_exprs(subarray_element_exprs_ptr, copy_attributes);
            element_expr:
              element_array_expr_ptr := Clone_exprs(element_array_expr_ptr,
                copy_attributes);

            {********************}
            { array dimensioning }
            {********************}
            boolean_array_dim..reference_array_dim:
              begin
                dim_bounds_list_ptr :=
                  Clone_array_bounds_list(dim_bounds_list_ptr, copy_attributes);

                {*******************************************************}
                { array of array / dynamic structure array dimensioning }
                {*******************************************************}
                dim_element_expr_ptr := Clone_expr(dim_element_expr_ptr,
                  copy_attributes);

                {*************************************}
                { static structure array dimensioning }
                {*************************************}
                dim_static_struct_init_stmt_ptr :=
                  forward_stmt_ptr_type(Clone_stmt(stmt_ptr_type(dim_static_struct_init_stmt_ptr), copy_attributes));
              end;

            {*********************}
            { array dereferencing }
            {*********************}
            boolean_array_deref..reference_array_deref:
              begin
                deref_index_list_ptr :=
                  Clone_array_index_list(deref_index_list_ptr, copy_attributes);
                deref_base_ptr := Clone_expr(deref_base_ptr, copy_attributes);
              end;

            {****************************}
            { array subrange expressions }
            {****************************}
            boolean_array_subrange..reference_array_subrange:
              begin
                subrange_index_list_ptr :=
                  Clone_array_index_list(subrange_index_list_ptr,
                  copy_attributes);
                subrange_bounds_list_ptr :=
                  Clone_array_bounds_list(subrange_bounds_list_ptr,
                  copy_attributes);
                subrange_base_ptr := Clone_expr(subrange_base_ptr,
                  copy_attributes);
              end;

            {*******************************************}
            { implicit references used in array assigns }
            {*******************************************}
            array_base:
              ;

          end {case}

            {***************************************************************}
            {                  structure expression terms                   }
            {***************************************************************}
        else if kind in struct_expr_set then
          case kind of

            {***********************}
            { structure expressions }
            {***********************}
            struct_expr:
              field_exprs_ptr := Clone_exprs(field_exprs_ptr, copy_attributes);

            {**********************}
            { structure allocation }
            {**********************}
            struct_new:
              new_struct_init_stmt_ptr :=
                forward_stmt_ptr_type(Clone_stmt(stmt_ptr_type(new_struct_init_stmt_ptr), copy_attributes));

            {*************************}
            { structure dereferencing }
            {*************************}
            struct_deref, struct_offset:
              begin
                base_expr_ptr := Clone_expr(base_expr_ptr, copy_attributes);
                field_expr_ptr := Clone_expr(field_expr_ptr, copy_attributes);
              end;
            field_deref, field_offset:
              field_name_ptr := Clone_expr(field_name_ptr, copy_attributes);

            {***********************************************}
            { implicit references used in structure assigns }
            {***********************************************}
            struct_base, static_struct_base:
              ;

          end {case}

            {***************************************************************}
            {                        expression terms                       }
            {***************************************************************}
        else if not (kind in literal_set) then
          case kind of

            {*************************}
            { explicit ptr conversion }
            {*************************}
            ptr_cast, type_query:
              class_expr_ptr := Clone_expr(class_expr_ptr, copy_attributes);

            {********************}
            { tuplet expressions }
            {********************}
            complex_pair:
              begin
                a_expr_ptr := Clone_expr(a_expr_ptr, copy_attributes);
                b_expr_ptr := Clone_expr(b_expr_ptr, copy_attributes);
              end;
            vector_triplet:
              begin
                x_expr_ptr := Clone_expr(x_expr_ptr, copy_attributes);
                y_expr_ptr := Clone_expr(y_expr_ptr, copy_attributes);
                z_expr_ptr := Clone_expr(z_expr_ptr, copy_attributes);
              end;

            {************************}
            { functional expressions }
            {************************}
            user_fn:
              fn_stmt_ptr :=
                forward_stmt_ptr_type(Clone_stmt(stmt_ptr_type(fn_stmt_ptr),
                copy_attributes));

            {***************************************************************}
            {                      expression terminals                     }
            {***************************************************************}

            {***********************************}
            { user defined variable identifiers }
            {***********************************}
            global_identifier, local_identifier:
              ;
            nested_identifier:
              nested_id_expr_ptr := Clone_expr(nested_id_expr_ptr,
                copy_attributes);

            {*******************************}
            { user defined type identifiers }
            {*******************************}
            field_identifier:
              ;

            {*************************}
            { most recent addr caches }
            {*************************}
            itself, new_itself, implicit_expr:
              ;

          end {case}

            {***************************************************************}
            {                      expression literals                      }
            {***************************************************************}
        else if (kind in scalar_literal_set) then
          case kind of

            scalar_lit:
              begin
                if copy_attributes then
                  if scalar_attributes_ptr <> nil then
                    begin
                      scalar_attributes_ptr :=
                        Copy_literal_attributes(scalar_attributes_ptr);
                      scalar_attributes_ptr^.expr_ref :=
                        forward_expr_ref_type(new_expr_ptr);
                    end;
              end;

            double_lit:
              begin
                if copy_attributes then
                  if double_attributes_ptr <> nil then
                    begin
                      double_attributes_ptr :=
                        Copy_literal_attributes(double_attributes_ptr);
                      double_attributes_ptr^.expr_ref :=
                        forward_expr_ref_type(new_expr_ptr);
                    end;
              end;

            complex_lit:
              begin
                if copy_attributes then
                  if complex_attributes_ptr <> nil then
                    begin
                      complex_attributes_ptr :=
                        Copy_literal_attributes(complex_attributes_ptr);
                      complex_attributes_ptr^.expr_ref :=
                        forward_expr_ref_type(new_expr_ptr);
                    end;
              end;

            vector_lit:
              begin
                if copy_attributes then
                  if vector_attributes_ptr <> nil then
                    begin
                      vector_attributes_ptr :=
                        Copy_literal_attributes(vector_attributes_ptr);
                      vector_attributes_ptr^.expr_ref :=
                        forward_expr_ref_type(new_expr_ptr);
                    end;
              end;
          end; {case}
    end
  else
    new_expr_ptr := nil;

  Clone_expr := new_expr_ptr;
end; {function Clone_expr}


function Clone_exprs(expr_ptr: expr_ptr_type;
  copy_attributes: boolean): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
  first_expr_ptr, last_expr_ptr: expr_ptr_type;
begin
  first_expr_ptr := nil;
  last_expr_ptr := nil;

  while expr_ptr <> nil do
    begin
      new_expr_ptr := Clone_expr(expr_ptr, copy_attributes);

      {**********************************}
      { add new expr node to end of list }
      {**********************************}
      if (last_expr_ptr <> nil) then
        begin
          last_expr_ptr^.next := new_expr_ptr;
          last_expr_ptr := new_expr_ptr;
        end
      else
        begin
          first_expr_ptr := new_expr_ptr;
          last_expr_ptr := new_expr_ptr;
        end;

      expr_ptr := expr_ptr^.next;
    end;

  Clone_exprs := first_expr_ptr;
end; {function Clone_exprs}


{***************************************************}
{ routines for recursively freeing expression trees }
{***************************************************}


procedure Destroy_expr(var expr_ptr: expr_ptr_type;
  free_attributes: boolean);
begin
  if (expr_ptr <> nil) then
    with expr_ptr^ do
      begin
        {****************************************}
        { free auxilliary expression information }
        {****************************************}
        Free_expr_info(expr_ptr^.expr_info_ptr, free_attributes);

        {***************************************************************}
        {                      expression operators       	            }
        {***************************************************************}

        {*****************}
        { unary operators }
        {*****************}

        if kind in unary_operator_set then
          Destroy_expr(operand_ptr, free_attributes)

          {******************}
          { binary operators }
          {******************}
        else if kind in binary_operator_set then
          begin
            {*******************************************************}
            { for expressions of the form: a < b < c, the middle    }
            { operand is shared between the left and right subtrees }
            {*******************************************************}
            if kind = and_op then
              if implicit_and then
                right_operand_ptr^.left_operand_ptr := nil;

            Destroy_expr(left_operand_ptr, free_attributes);
            Destroy_expr(right_operand_ptr, free_attributes);
          end

            {***************************************************************}
            {                    array expression terms                     }
            {***************************************************************}
        else if kind in array_expr_set then
          case kind of

            {*******************}
            { array expressions }
            {*******************}
            boolean_array_expr..reference_array_expr:
              begin
                Destroy_array_bounds_list(array_expr_bounds_list_ptr,
                  free_attributes);
                Destroy_exprs(array_element_exprs_ptr, free_attributes);
              end;
            subarray_expr:
              Destroy_exprs(subarray_element_exprs_ptr, free_attributes);
            element_expr:
              Destroy_exprs(element_array_expr_ptr, free_attributes);

            {********************}
            { array dimensioning }
            {********************}
            boolean_array_dim..reference_array_dim:
              begin
                Destroy_array_bounds_list(dim_bounds_list_ptr, free_attributes);

                {*******************************************************}
                { array of array / dynamic structure array dimensioning }
                {*******************************************************}
                Destroy_expr(dim_element_expr_ptr, free_attributes);

                {*************************************}
                { static structure array dimensioning }
                {*************************************}
                Destroy_stmt(stmt_ptr_type(dim_static_struct_init_stmt_ptr),
                  free_attributes);
              end;

            {*********************}
            { array dereferencing }
            {*********************}
            boolean_array_deref..reference_array_deref:
              begin
                Destroy_array_index_list(deref_index_list_ptr, free_attributes);
                Destroy_expr(deref_base_ptr, free_attributes);
              end;

            {****************************}
            { array subrange expressions }
            {****************************}
            boolean_array_subrange..reference_array_subrange:
              begin
                Destroy_array_index_list(subrange_index_list_ptr,
                  free_attributes);
                Destroy_array_bounds_list(subrange_bounds_list_ptr,
                  free_attributes);
                Destroy_expr(subrange_base_ptr, free_attributes);
              end;

            {*******************************************}
            { implicit references used in array assigns }
            {*******************************************}
            array_base:
              ;

          end {case}

            {***************************************************************}
            {                 structure expression terms                    }
            {***************************************************************}
        else if kind in struct_expr_set then
          case kind of

            {***********************}
            { structure expressions }
            {***********************}
            struct_expr:
              Destroy_exprs(field_exprs_ptr, free_attributes);

            {**********************}
            { structure allocation }
            {**********************}
            struct_new:
              Destroy_stmt(stmt_ptr_type(new_struct_init_stmt_ptr),
                free_attributes);

            {*************************}
            { structure dereferencing }
            {*************************}
            struct_deref, struct_offset:
              begin
                Destroy_expr(base_expr_ptr, free_attributes);
                Destroy_expr(field_expr_ptr, free_attributes);
              end;
            field_deref, field_offset:
              Destroy_expr(field_name_ptr, free_attributes);

            {***********************************************}
            { implicit references used in structure assigns }
            {***********************************************}
            struct_base, static_struct_base:
              ;

          end {case}

            {***************************************************************}
            {                        expression terms                       }
            {***************************************************************}
        else if not (kind in literal_set) then
          case kind of

            {*************************}
            { explicit ptr conversion }
            {*************************}
            ptr_cast, type_query:
              Destroy_expr(class_expr_ptr, free_attributes);

            {********************}
            { tuplet expressions }
            {********************}
            complex_pair:
              begin
                Destroy_expr(a_expr_ptr, free_attributes);
                Destroy_expr(b_expr_ptr, free_attributes);
              end;
            vector_triplet:
              begin
                Destroy_expr(x_expr_ptr, free_attributes);
                Destroy_expr(y_expr_ptr, free_attributes);
                Destroy_expr(z_expr_ptr, free_attributes);
              end;

            {************************}
            { functional expressions }
            {************************}
            user_fn:
              Destroy_stmt(stmt_ptr_type(fn_stmt_ptr), free_attributes);

            {***************************************************************}
            {                      expression terminals                     }
            {***************************************************************}

            {***********************************}
            { user defined variable identifiers }
            {***********************************}
            global_identifier, local_identifier:
              ;
            nested_identifier:
              Destroy_expr(nested_id_expr_ptr, free_attributes);

            {*******************************}
            { user defined type identifiers }
            {*******************************}
            field_identifier:
              ;

            {*************************}
            { most recent addr caches }
            {*************************}
            itself, new_itself, implicit_expr:
              ;

          end {case}

            {***************************************************************}
            {                      expression literals                      }
            {***************************************************************}
        else if (kind in scalar_literal_set) then
          case kind of

            scalar_lit:
              if free_attributes then
                Free_literal_attributes(scalar_attributes_ptr);

            double_lit:
              if free_attributes then
                Free_literal_attributes(double_attributes_ptr);

            complex_lit:
              if free_attributes then
                Free_literal_attributes(complex_attributes_ptr);

            vector_lit:
              if free_attributes then
                Free_literal_attributes(vector_attributes_ptr);

          end; {case}

        Free_expr(expr_ptr);
      end; {with}
end; {procedure Destroy_expr}


procedure Destroy_exprs(var expr_ptr: expr_ptr_type;
  free_attributes: boolean);
var
  temp: expr_ptr_type;
begin
  while (expr_ptr <> nil) do
    begin
      temp := expr_ptr;
      expr_ptr := expr_ptr^.next;
      Destroy_expr(temp, free_attributes);
    end;
end; {procedure Destroy_exprs}


{***************************************************}
{ routines for recursively marking expression trees }
{***************************************************}


procedure Mark_expr(expr_ptr: expr_ptr_type;
  touched: boolean);
begin
  if (expr_ptr <> nil) then
    with expr_ptr^ do
      begin
        {***************************************************************}
        {                      expression operators       	        }
        {***************************************************************}

        {*****************}
        { unary operators }
        {*****************}
        if kind in unary_operator_set then
          Mark_expr(operand_ptr, touched)

          {******************}
          { binary operators }
          {******************}
        else if kind in binary_operator_set then
          begin
            Mark_expr(left_operand_ptr, touched);
            Mark_expr(right_operand_ptr, touched);
          end

            {***************************************************************}
            {                    array expression terms                     }
            {***************************************************************}
        else if kind in array_expr_set then
          case kind of

            {*******************}
            { array expressions }
            {*******************}
            boolean_array_expr..reference_array_expr:
              begin
                Mark_exprs(array_element_exprs_ptr, touched);

                {************************************}
                { static structure array expressions }
                {************************************}
                Mark_type_decl(type_ptr_type(array_expr_static_struct_type_ref),
                  touched);
              end;
            subarray_expr:
              Mark_exprs(subarray_element_exprs_ptr, touched);
            element_expr:
              Mark_exprs(element_array_expr_ptr, touched);

            {********************}
            { array dimensioning }
            {********************}
            boolean_array_dim..reference_array_dim:
              begin
                Mark_array_bounds_list(dim_bounds_list_ptr, touched);

                {*******************************************************}
                { array of array / dynamic structure array dimensioning }
                {*******************************************************}
                Mark_expr(dim_element_expr_ptr, touched);

                {*************************************}
                { static structure array dimensioning }
                {*************************************}
                Mark_type_decl(type_ptr_type(dim_static_struct_type_ref),
                  touched);
                Mark_stmt(stmt_ptr_type(dim_static_struct_init_stmt_ptr),
                  touched);
              end;

            {*********************}
            { array dereferencing }
            {*********************}
            boolean_array_deref..reference_array_deref:
              begin
                Mark_array_index_list(deref_index_list_ptr, touched);
                Mark_expr(deref_base_ptr, touched);
              end;

            {****************************}
            { array subrange expressions }
            {****************************}
            boolean_array_subrange..reference_array_subrange:
              begin
                Mark_array_index_list(subrange_index_list_ptr, touched);
                Mark_array_bounds_list(subrange_bounds_list_ptr, touched);
                Mark_expr(subrange_base_ptr, touched);
              end;

            {*******************************************}
            { implicit references used in array assigns }
            {*******************************************}
            array_base:
              ;

          end {case}

            {***************************************************************}
            {                 structure expression terms                    }
            {***************************************************************}
        else if kind in struct_expr_set then
          case kind of

            {***********************}
            { structure expressions }
            {***********************}
            struct_expr:
              Mark_exprs(field_exprs_ptr, touched);

            {**********************}
            { structure allocation }
            {**********************}
            struct_new:
              begin
                Mark_type_decl(type_ptr_type(new_struct_type_ref), touched);
                Mark_stmt(stmt_ptr_type(new_struct_init_stmt_ptr), touched);
              end;

            {*************************}
            { structure dereferencing }
            {*************************}
            struct_deref, struct_offset:
              begin
                Mark_expr(base_expr_ptr, touched);
                Mark_expr(field_expr_ptr, touched);
              end;
            field_deref, field_offset:
              Mark_expr(field_name_ptr, touched);

            {***********************************************}
            { implicit references used in structure assigns }
            {***********************************************}
            struct_base, static_struct_base:
              ;

          end {case}

            {***************************************************************}
            {                        expression terms                       }
            {***************************************************************}
        else if not (kind in literal_set) then
          case kind of

            {*************************}
            { explicit ptr conversion }
            {*************************}
            ptr_cast, type_query:
              begin
                Mark_type_decl(desired_subclass_ref, touched);
                Mark_expr(class_expr_ptr, touched);
              end;

            {********************}
            { tuplet expressions }
            {********************}
            complex_pair:
              begin
                Mark_expr(a_expr_ptr, touched);
                Mark_expr(b_expr_ptr, touched);
              end;
            vector_triplet:
              begin
                Mark_expr(x_expr_ptr, touched);
                Mark_expr(y_expr_ptr, touched);
                Mark_expr(z_expr_ptr, touched);
              end;

            {************************}
            { functional expressions }
            {************************}
            user_fn:
              Mark_stmt(stmt_ptr_type(fn_stmt_ptr), touched);

            {***************************************************************}
            {                      expression terminals                     }
            {***************************************************************}

            {***********************************}
            { user defined variable identifiers }
            {***********************************}
            global_identifier, local_identifier:
              ;
            nested_identifier:
              Mark_expr(nested_id_expr_ptr, touched);

            {*******************************}
            { user defined type identifiers }
            {*******************************}
            field_identifier:
              ;

            {*************************}
            { most recent addr caches }
            {*************************}
            itself, new_itself, implicit_expr:
              ;

          end; {case}

        {*****************************}
        { mark expression declaration }
        {*****************************}
        if expr_info_ptr <> nil then
          with expr_info_ptr^ do
            if expr_attributes_ptr <> nil then
              with expr_attributes_ptr^ do
                begin
                  if decl_attributes_ptr <> nil then
                    begin
                      Mark_decl(decl_ptr_type(decl_attributes_ptr^.decl_ref),
                        touched);

                      {******************}
                      { mark parent decl }
                      {******************}
                      if expr_attributes_ptr^.explicit_member then
                        Mark_decl(decl_ptr_type(decl_attributes_ptr^.scope_decl_attributes_ptr^.decl_ref), touched);
                    end;
                end;

      end; {with}
end; {procedure Mark_expr}


procedure Mark_exprs(expr_ptr: expr_ptr_type;
  touched: boolean);
begin
  while (expr_ptr <> nil) do
    begin
      Mark_expr(expr_ptr, touched);
      expr_ptr := expr_ptr^.next;
    end;
end; {procedure Mark_exprs}


procedure Mark_expr_attributes(expr_attributes_ptr: expr_attributes_ptr_type;
  touched: boolean);
begin
  expr_attributes_ptr^.decl_attributes_ptr^.used := touched;
end; {procedure Mark_expr_attributes}


{*****************************************************}
{ routines for recursively comparing expression trees }
{*****************************************************}


function Equal_exprs(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;
var
  equal: boolean;
  kind: expr_kind_type;
begin
  equal := false;

  if (expr_ptr1^.kind <> expr_ptr2^.kind) then
    equal := false
  else
    begin
      kind := expr_ptr1^.kind;

      {***************************************************************}
      {                      expression operators       	      }
      {***************************************************************}

      {*****************}
      { unary operators }
      {*****************}
      if kind in unary_operator_set then
        equal := Equal_exprs(expr_ptr1^.operand_ptr, expr_ptr2^.operand_ptr)

        {******************}
        { binary operators }
        {******************}
      else if kind in binary_operator_set then
        begin
          equal := Equal_exprs(expr_ptr1^.left_operand_ptr,
            expr_ptr2^.left_operand_ptr);
          if equal then
            equal := Equal_exprs(expr_ptr1^.right_operand_ptr,
              expr_ptr2^.right_operand_ptr);
        end

          {***************************************************************}
          {                    array expression terms                     }
          {***************************************************************}
      else if kind in array_expr_set then
        case kind of

          {*******************}
          { array expressions }
          {*******************}
          boolean_array_expr..reference_array_expr, subarray_expr:
            equal := true;
          element_expr:
            equal := Equal_exprs(expr_ptr1^.element_expr_ref,
              expr_ptr2^.element_expr_ref);

          {********************}
          { array dimensioning }
          {********************}
          boolean_array_dim..reference_array_dim:
            equal := true;

          {*********************}
          { array dereferencing }
          {*********************}
          boolean_array_deref..reference_array_deref:
            equal := true;

          {****************************}
          { array subrange expressions }
          {****************************}
          boolean_array_subrange..reference_array_subrange:
            equal := true;

          {*******************************************}
          { implicit references used in array assigns }
          {*******************************************}
          array_base:
            equal := Equal_exprs(expr_ptr1^.array_base_expr_ref,
              expr_ptr2^.array_base_expr_ref);

        end {case}

          {***************************************************************}
          {                 structure expression terms                    }
          {***************************************************************}
      else if kind in struct_expr_set then
        case kind of

          {***********************}
          { structure expressions }
          {***********************}
          struct_expr:
            equal := true;

          {**********************}
          { structure allocation }
          {**********************}
          struct_new:
            equal := true;

          {*************************}
          { structure dereferencing }
          {*************************}
          struct_deref, struct_offset:
            begin
              equal := Equal_exprs(expr_ptr1^.base_expr_ptr,
                expr_ptr2^.base_expr_ptr);
              if equal then
                equal := Equal_exprs(expr_ptr1^.field_expr_ptr,
                  expr_ptr2^.field_expr_ptr);
            end;
          field_deref, field_offset:
            equal := Equal_exprs(expr_ptr1^.field_name_ptr,
              expr_ptr2^.field_name_ptr);

          {***********************************************}
          { implicit references used in structure assigns }
          {***********************************************}
          struct_base:
            equal := (expr_ptr1^.struct_base_type_ref =
              expr_ptr2^.struct_base_type_ref);
          static_struct_base:
            equal := (expr_ptr1^.static_struct_base_type_ref =
              expr_ptr2^.static_struct_base_type_ref);

        end {case}

          {***************************************************************}
          {                        expression terms                       }
          {***************************************************************}
      else if kind in expr_term_set then
        case kind of

          {*************************}
          { explicit ptr conversion }
          {*************************}
          ptr_cast, type_query:
            begin
              equal := (expr_ptr1^.desired_subclass_ref =
                expr_ptr2^.desired_subclass_ref);
              if equal then
                equal := (expr_ptr1^.class_expr_ptr =
                  expr_ptr2^.class_expr_ptr);
            end;

          {********************}
          { tuplet expressions }
          {********************}
          complex_pair:
            begin
              equal := Equal_exprs(expr_ptr1^.a_expr_ptr,
                expr_ptr2^.a_expr_ptr);
              if equal then
                equal := Equal_exprs(expr_ptr1^.b_expr_ptr,
                  expr_ptr2^.b_expr_ptr);
            end;
          vector_triplet:
            begin
              equal := Equal_exprs(expr_ptr1^.x_expr_ptr,
                expr_ptr2^.x_expr_ptr);
              if equal then
                equal := Equal_exprs(expr_ptr1^.y_expr_ptr,
                  expr_ptr2^.y_expr_ptr);
              if equal then
                equal := Equal_exprs(expr_ptr1^.z_expr_ptr,
                  expr_ptr2^.z_expr_ptr);
            end;

          {************************}
          { functional expressions }
          {************************}
          user_fn:
            equal := true;
        end

          {***************************************************************}
          {                      expression terminals        	          }
          {***************************************************************}
      else if kind in terminal_set then
        case kind of

          {***********************************}
          { user defined variable identifiers }
          {***********************************}
          global_identifier, local_identifier:
            equal :=
              Equal_expr_attributes(expr_ptr1^.expr_info_ptr^.expr_attributes_ptr,
              expr_ptr2^.expr_info_ptr^.expr_attributes_ptr);
          nested_identifier:
            equal := Equal_exprs(expr_ptr1^.nested_id_expr_ptr,
              expr_ptr2^.nested_id_expr_ptr);

          {*******************************}
          { user defined type identifiers }
          {*******************************}
          field_identifier:
            equal :=
              Equal_expr_attributes(expr_ptr1^.expr_info_ptr^.expr_attributes_ptr,
              expr_ptr2^.expr_info_ptr^.expr_attributes_ptr);

          {*************************}
          { most recent addr caches }
          {*************************}
          itself:
            equal := true;
          new_itself:
            equal := (expr_ptr1^.new_type_ref = expr_ptr2^.new_type_ref);
          implicit_expr:
            equal := Equal_exprs(expr_ptr1^.implicit_expr_ref,
              expr_ptr2^.implicit_expr_ref);

          {***************************************************************}
          {                      expression literals        	          }
          {***************************************************************}

          {*********************}
          { enumerated literals }
          {*********************}
          true_val, false_val:
            equal := true;
          char_lit:
            equal := (expr_ptr1^.char_val = expr_ptr2^.char_val);
          enum_lit:
            equal := (expr_ptr1^.enum_val = expr_ptr2^.enum_val);

          {******************}
          { integer literals }
          {******************}
          byte_lit:
            equal := (expr_ptr1^.byte_val = expr_ptr2^.byte_val);
          short_lit:
            equal := (expr_ptr1^.short_val = expr_ptr2^.short_val);
          integer_lit:
            equal := (expr_ptr1^.integer_val = expr_ptr2^.integer_val);
          long_lit:
            equal := (expr_ptr1^.long_val = expr_ptr2^.long_val);

          {*****************}
          { scalar literals }
          {*****************}
          scalar_lit:
            equal := (expr_ptr1^.scalar_val = expr_ptr2^.scalar_val);
          double_lit:
            equal := (expr_ptr1^.double_val = expr_ptr2^.double_val);
          complex_lit:
            equal := Equal_complex(expr_ptr1^.complex_val,
              expr_ptr2^.complex_val);
          vector_lit:
            equal := Equal_vector(expr_ptr1^.vector_val, expr_ptr2^.vector_val);

          {**************}
          { ptr literals }
          {**************}
          nil_array, nil_struct, nil_proto, nil_reference:
            equal := true;

          {********************}
          { uninitialized expr }
          {********************}
          error_expr:
            equal := false;
        end; {case}

    end;

  Equal_exprs := equal;
end; {function Equal_exprs}


function Same_exprs(expr_ptr1, expr_ptr2: expr_ptr_type): boolean;
var
  same: boolean;
  kind: expr_kind_type;
begin
  same := false;

  if (expr_ptr1^.kind <> expr_ptr2^.kind) then
    same := false
  else
    begin
      kind := expr_ptr1^.kind;

      {***************************************************************}
      {                      expression operators       	      }
      {***************************************************************}

      {*****************}
      { unary operators }
      {*****************}
      if kind in unary_operator_set then
        begin
          same := Same_exprs(expr_ptr1^.operand_ptr, expr_ptr2^.operand_ptr);
        end

          {******************}
          { binary operators }
          {******************}
      else if kind in binary_operator_set then
        begin
          same := Same_exprs(expr_ptr1^.left_operand_ptr,
            expr_ptr2^.left_operand_ptr);
          if same then
            same := Same_exprs(expr_ptr1^.right_operand_ptr,
              expr_ptr2^.right_operand_ptr);
        end

          {***************************************************************}
          {                    array expression terms                     }
          {***************************************************************}
      else if kind in array_expr_set then
        case kind of

          {*******************}
          { array expressions }
          {*******************}
          boolean_array_expr..reference_array_expr, subarray_expr:
            same := true;
          element_expr:
            same := Same_exprs(expr_ptr1^.element_expr_ref,
              expr_ptr2^.element_expr_ref);

          {********************}
          { array dimensioning }
          {********************}
          boolean_array_dim..reference_array_dim:
            same := true;

          {*********************}
          { array dereferencing }
          {*********************}
          boolean_array_deref..reference_array_deref:
            same := true;

          {****************************}
          { array subrange expressions }
          {****************************}
          boolean_array_subrange..reference_array_subrange:
            same := true;

          {*******************************************}
          { implicit references used in array assigns }
          {*******************************************}
          array_base:
            same := Same_exprs(expr_ptr1^.array_base_expr_ref,
              expr_ptr2^.array_base_expr_ref);

        end {case}

          {***************************************************************}
          {                 structure expression terms                    }
          {***************************************************************}
      else if kind in struct_expr_set then
        case kind of

          {***********************}
          { structure expressions }
          {***********************}
          struct_expr:
            same := true;

          {**********************}
          { structure allocation }
          {**********************}
          struct_new:
            same := true;

          {*************************}
          { structure dereferencing }
          {*************************}
          struct_deref, struct_offset:
            begin
              same := Same_exprs(expr_ptr1^.base_expr_ptr,
                expr_ptr2^.base_expr_ptr);
              if same then
                same := Same_exprs(expr_ptr1^.field_expr_ptr,
                  expr_ptr2^.field_expr_ptr);
            end;
          field_deref, field_offset:
            same := Same_exprs(expr_ptr1^.field_name_ptr,
              expr_ptr2^.field_name_ptr);

          {***********************************************}
          { implicit references used in structure assigns }
          {***********************************************}
          struct_base:
            same := (expr_ptr1^.struct_base_type_ref =
              expr_ptr2^.struct_base_type_ref);
          static_struct_base:
            same := (expr_ptr1^.static_struct_base_type_ref =
              expr_ptr2^.static_struct_base_type_ref);

        end {case}

          {***************************************************************}
          {                        expression terms                       }
          {***************************************************************}
      else if kind in expr_term_set then
        case kind of

          {*************************}
          { explicit ptr conversion }
          {*************************}
          ptr_cast, type_query:
            begin
              same := (expr_ptr1^.desired_subclass_ref =
                expr_ptr2^.desired_subclass_ref);
              if same then
                same := (expr_ptr1^.class_expr_ptr = expr_ptr2^.class_expr_ptr);
            end;

          {********************}
          { tuplet expressions }
          {********************}
          complex_pair:
            begin
              same := Same_exprs(expr_ptr1^.a_expr_ptr, expr_ptr2^.a_expr_ptr);
              if same then
                same := Same_exprs(expr_ptr1^.b_expr_ptr,
                  expr_ptr2^.b_expr_ptr);
            end;
          vector_triplet:
            begin
              same := Same_exprs(expr_ptr1^.x_expr_ptr, expr_ptr2^.x_expr_ptr);
              if same then
                same := Same_exprs(expr_ptr1^.y_expr_ptr,
                  expr_ptr2^.y_expr_ptr);
              if same then
                same := Same_exprs(expr_ptr1^.z_expr_ptr,
                  expr_ptr2^.z_expr_ptr);
            end;

          {************************}
          { functional expressions }
          {************************}
          user_fn:
            same := true;
        end

          {***************************************************************}
          {                      expression terminals        	          }
          {***************************************************************}
      else if kind in terminal_set then
        case kind of

          {***********************************}
          { user defined variable identifiers }
          {***********************************}
          global_identifier, local_identifier:
            same :=
              Same_expr_attributes(expr_ptr1^.expr_info_ptr^.expr_attributes_ptr,
              expr_ptr2^.expr_info_ptr^.expr_attributes_ptr);
          nested_identifier:
            same := Same_exprs(expr_ptr1^.nested_id_expr_ptr,
              expr_ptr2^.nested_id_expr_ptr);

          {*******************************}
          { user defined type identifiers }
          {*******************************}
          field_identifier:
            same :=
              Same_expr_attributes(expr_ptr1^.expr_info_ptr^.expr_attributes_ptr,
              expr_ptr2^.expr_info_ptr^.expr_attributes_ptr);

          {*************************}
          { most recent addr caches }
          {*************************}
          itself:
            same := true;
          new_itself:
            same := (expr_ptr1^.new_type_ref = expr_ptr2^.new_type_ref);
          implicit_expr:
            same := Same_exprs(expr_ptr1^.implicit_expr_ref,
              expr_ptr2^.implicit_expr_ref);

          {***************************************************************}
          {                      expression literals        	            }
          {***************************************************************}

          {*********************}
          { enumerated literals }
          {*********************}
          true_val, false_val:
            same := true;
          char_lit:
            same := (expr_ptr1^.char_val = expr_ptr2^.char_val);
          enum_lit:
            same := (expr_ptr1^.enum_val = expr_ptr2^.enum_val);

          {******************}
          { integer literals }
          {******************}
          byte_lit:
            same := (expr_ptr1^.byte_val = expr_ptr2^.byte_val);
          short_lit:
            same := (expr_ptr1^.short_val = expr_ptr2^.short_val);
          integer_lit:
            same := (expr_ptr1^.integer_val = expr_ptr2^.integer_val);
          long_lit:
            same := (expr_ptr1^.long_val = expr_ptr2^.long_val);

          {*****************}
          { scalar literals }
          {*****************}
          scalar_lit:
            same := (expr_ptr1^.scalar_val = expr_ptr2^.scalar_val);
          double_lit:
            same := (expr_ptr1^.double_val = expr_ptr2^.double_val);
          complex_lit:
            same := Equal_complex(expr_ptr1^.complex_val,
              expr_ptr2^.complex_val);
          vector_lit:
            same := Equal_vector(expr_ptr1^.vector_val, expr_ptr2^.vector_val);

          {**************}
          { ptr literals }
          {**************}
          nil_array, nil_struct, nil_proto, nil_reference:
            same := true;

          {********************}
          { uninitialized expr }
          {********************}
          error_expr:
            same := false;
        end
    end;

  Same_exprs := same;
end; {function Same_exprs}


end.
