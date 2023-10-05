unit exprs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               exprs                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The exprs module defines all of the expressions         }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  new_memory, complex_numbers, vectors, data_types, addr_types, decl_attributes,
  expr_attributes, lit_attributes, comments, arrays;


type
  {***************************************************************}
  {           Simulation / Modelling Programming Language         }
  {                  SMPL (pronounced 'simple')                   }
  {***************************************************************}
  {                           expressions                         }
  {***************************************************************}
  {                                                               }
  {       The syntax tree implementation may seem overly          }
  {       verbose because there are seperate kinds of exprs       }
  {       for integer addition, scalar addition, and the like,    }
  {       but this was done to get a little more speed out        }
  {       of the interpreter execution.                           }
  {                                                               }
  {       Alternativly, you could have one type for each          }
  {       operation and at run time, figure out what type         }
  {       of operation to perform based on the types of the       }
  {       operands.  This would be simpler, but slower.           }
  {                                                               }
  {***************************************************************}


  expr_kind_type = (

    {********************}
    { uninitialized expr }
    {********************}
    error_expr,

    {***************************************************************}
    {                        unary operators                        }
    {***************************************************************}

    {********************}
    { negation operators }
    {********************}
    not_op, byte_negate, short_negate, integer_negate, long_negate,
    scalar_negate, double_negate, complex_negate, vector_negate,

    {**********************}
    { addressing operators }
    {**********************}
    address_op, deref_op,

    {*************************************}
    { implicit integeral type conversions }
    {*************************************}
    byte_to_short, short_to_integer, integer_to_long, integer_to_scalar,
    long_to_scalar, long_to_double,

    {**********************************}
    { implicit scalar type conversions }
    {**********************************}
    scalar_to_double, scalar_to_complex,

    {****************************}
    { vector component operators }
    {****************************}
    vector_x, vector_y, vector_z,

    {*****************************}
    { memory allocation functions }
    {*****************************}
    new_struct_fn, dim_array_fn,

    {*******************}
    { special functions }
    {*******************}
    min_fn, max_fn, num_fn,

    {***************************************************************}
    {                       binary operators                        }
    {***************************************************************}

    {*******************}
    { boolean operators }
    {*******************}
    and_op, or_op, and_if_op, or_if_op,

    {******************************}
    { boolean relational operators }
    {******************************}
    boolean_equal, boolean_not_equal,

    {********************************}
    { character relational operators }
    {********************************}
    char_equal, char_not_equal,

    {***************************}
    { byte relational operators }
    {***************************}
    byte_equal, byte_not_equal, byte_less_than, byte_greater_than,
    byte_less_equal, byte_greater_equal,

    {***************************}
    { byte arithmetic operators }
    {***************************}
    byte_add, byte_subtract, byte_multiply, byte_divide, byte_mod,

    {************************************}
    { short integer relational operators }
    {************************************}
    short_equal, short_not_equal, short_less_than, short_greater_than,
    short_less_equal, short_greater_equal,

    {************************************}
    { short integer arithmetic operators }
    {************************************}
    short_add, short_subtract, short_multiply, short_divide, short_mod,

    {******************************}
    { integer relational operators }
    {******************************}
    integer_equal, integer_not_equal, integer_less_than, integer_greater_than,
    integer_less_equal, integer_greater_equal,

    {******************************}
    { integer arithmetic operators }
    {******************************}
    integer_add, integer_subtract, integer_multiply, integer_divide,
    integer_mod,

    {***********************************}
    { long integer relational operators }
    {***********************************}
    long_equal, long_not_equal, long_less_than, long_greater_than,
    long_less_equal, long_greater_equal,

    {***********************************}
    { long integer arithmetic operators }
    {***********************************}
    long_add, long_subtract, long_multiply, long_divide, long_mod,

    {*****************************}
    { scalar relational operators }
    {*****************************}
    scalar_equal, scalar_not_equal, scalar_less_than, scalar_greater_than,
    scalar_less_equal, scalar_greater_equal,

    {*****************************}
    { scalar arithmetic operators }
    {*****************************}
    scalar_add, scalar_subtract, scalar_multiply, scalar_divide,
    scalar_exponent,

    {************************************}
    { double scalar relational operators }
    {************************************}
    double_equal, double_not_equal, double_less_than, double_greater_than,
    double_less_equal, double_greater_equal,

    {************************************}
    { double scalar arithmetic operators }
    {************************************}
    double_add, double_subtract, double_multiply, double_divide,
    double_exponent,

    {******************************}
    { complex relational operators }
    {******************************}
    complex_equal, complex_not_equal,

    {******************************}
    { complex arithmetic operators }
    {******************************}
    complex_add, complex_subtract, complex_multiply, complex_divide,

    {*****************************}
    { vector relational operators }
    {*****************************}
    vector_equal, vector_not_equal,

    {*****************************}
    { vector arithmetic operators }
    {*****************************}
    vector_add, vector_subtract, vector_vector_multiply, vector_vector_divide,
    vector_mod, vector_dot_product, vector_cross_product, vector_parallel,
    vector_perpendicular,

    {************************************}
    { vector scalar arithmetic operators }
    {************************************}
    vector_scalar_multiply, vector_scalar_divide,

    {**************************************************}
    { array and structure pointer relational operators }
    {**************************************************}
    array_ptr_equal, array_ptr_not_equal, struct_ptr_equal,
    struct_ptr_not_equal,

    {**********************************************}
    { prototype and reference relational operators }
    {**********************************************}
    proto_equal, proto_not_equal, reference_equal, reference_not_equal,

    {****************************}
    { array relational operators }
    {****************************}
    array_equal, array_not_equal, array_expr_equal, array_expr_not_equal,

    {********************************}
    { structure relational operators }
    {********************************}
    struct_equal, struct_not_equal, struct_expr_equal, struct_expr_not_equal,

    {***************************************************************}
    {                         expression terms                      }
    {***************************************************************}

    {***************************}
    { explicit type conversions }
    {***************************}
    ptr_cast, type_query,

    {********************}
    { tuplet expressions }
    {********************}
    complex_pair, vector_triplet,

    {************************}
    { functional expressions }
    {************************}
    user_fn,

    {***************************************************************}
    {                      array expression terms                   }
    {***************************************************************}

    {******************************}
    { enumerated array expressions }
    {******************************}
    boolean_array_expr, char_array_expr,

    {***************************}
    { integer array expressions }
    {***************************}
    byte_array_expr, short_array_expr, integer_array_expr, long_array_expr,

    {**************************}
    { scalar array expressions }
    {**************************}
    scalar_array_expr, double_array_expr, complex_array_expr, vector_array_expr,

    {**********************************}
    { array / struct array expressions }
    {**********************************}
    array_array_expr, struct_array_expr, static_struct_array_expr,

    {******************************************}
    { subprogram / reference array expressions }
    {******************************************}
    proto_array_expr, reference_array_expr,

    {************************}
    { array expression terms }
    {************************}
    subarray_expr, element_expr,

    {***************************************************************}
    {                        array dimensioning                     }
    {***************************************************************}

    {*******************************}
    { enumerated array dimensioning }
    {*******************************}
    boolean_array_dim, char_array_dim,

    {****************************}
    { integer array dimensioning }
    {****************************}
    byte_array_dim, short_array_dim, integer_array_dim, long_array_dim,

    {***************************}
    { scalar array dimensioning }
    {***************************}
    scalar_array_dim, double_array_dim, complex_array_dim, vector_array_dim,

    {***********************************}
    { array / struct array dimensioning }
    {***********************************}
    array_array_dim, struct_array_dim, static_struct_array_dim,

    {*******************************************}
    { subprogram / reference array dimensioning }
    {*******************************************}
    proto_array_dim, reference_array_dim,

    {***************************************************************}
    {                       array dereferencing                     }
    {***************************************************************}

    {********************************}
    { enumerated array dereferencing }
    {********************************}
    boolean_array_deref, char_array_deref,

    {*****************************}
    { integer array dereferencing }
    {*****************************}
    byte_array_deref, short_array_deref, integer_array_deref, long_array_deref,

    {****************************}
    { scalar array dereferencing }
    {****************************}
    scalar_array_deref, double_array_deref, complex_array_deref,
    vector_array_deref,

    {************************************}
    { array / struct array dereferencing }
    {************************************}
    array_array_deref, struct_array_deref, static_struct_array_deref,

    {********************************************}
    { subprogram / reference array dereferencing }
    {********************************************}
    proto_array_deref, reference_array_deref,

    {***************************************************************}
    {                   array subrange expressions                  }
    {***************************************************************}

    {****************************}
    { enumerated array subranges }
    {****************************}
    boolean_array_subrange, char_array_subrange,

    {*************************}
    { integer array subranges }
    {*************************}
    byte_array_subrange, short_array_subrange, integer_array_subrange,
    long_array_subrange,

    {************************}
    { scalar array subranges }
    {************************}
    scalar_array_subrange, double_array_subrange, complex_array_subrange,
    vector_array_subrange,

    {********************************}
    { array / struct array subranges }
    {********************************}
    array_array_subrange, struct_array_subrange, static_struct_array_subrange,

    {****************************************}
    { subprogram / reference array subranges }
    {****************************************}
    proto_array_subrange, reference_array_subrange,

    {*******************************************}
    { implicit references used in array assigns }
    {*******************************************}
    array_base,

    {***************************************************************}
    {                   structure expression terms                  }
    {***************************************************************}

    {***********************}
    { structure expressions }
    {***********************}
    struct_expr,

    {**********************}
    { structure allocation }
    {**********************}
    struct_new,

    {*************************}
    { structure dereferencing }
    {*************************}
    struct_deref, struct_offset, field_deref, field_offset,

    {***********************************************}
    { implicit references used in structure assigns }
    {***********************************************}
    struct_base, static_struct_base,

    {***************************************************************}
    {                      expression terminals        	            }
    {***************************************************************}

    {***********************************}
    { user defined variable identifiers }
    {***********************************}
    global_identifier, local_identifier, nested_identifier,

    {*******************************}
    { user defined type identifiers }
    {*******************************}
    field_identifier,

    {**********************************************}
    { references to previously mentioned variables }
    {**********************************************}
    itself, new_itself, implicit_expr,

    {***************************************************************}
    {                      expression literals        	            }
    {***************************************************************}

    {*********************}
    { enumerated literals }
    {*********************}
    true_val, false_val, char_lit, enum_lit,

    {******************}
    { integer literals }
    {******************}
    byte_lit, short_lit, integer_lit, long_lit,

    {*****************}
    { scalar literals }
    {*****************}
    scalar_lit, double_lit, complex_lit, vector_lit,

    {**************}
    { ptr literals }
    {**************}
    nil_array, nil_struct, nil_proto, nil_reference); {expr_kind_type}


type
  expr_kind_set_type = set of expr_kind_type;


  {**********************************}
  { auxillary expression information }
  {**********************************}
  expr_info_ptr_type = ^expr_info_type;
  expr_info_type = record
    next: expr_info_ptr_type;

    {***********************************}
    { compile time semantic information }
    {***********************************}
    expr_attributes_ptr: expr_attributes_ptr_type;

    {************************************}
    { compile time stylistic information }
    {************************************}
    comments_ptr: comments_ptr_type; { line and block comments }
    explicit_expr: boolean; { explicit precedence }
  end;


  {********************************************************}
  { a ref type is like a ptr type except that a type ref   }
  { is a secondary reference to the type node and hence,   }
  { is not responsible for allocating or freeing the node. }
  {********************************************************}
  forward_type_ref_type = ptr_type;
  forward_stmt_ptr_type = ptr_type;
  forward_fn_ptr_type = ptr_type;


  {*************************************}
  { the abstract syntax tree expression }
  {*************************************}
  expr_ptr_type = ^expr_type;
  expr_ref_type = expr_ptr_type;


  {******************************************************}
  { Note:                                                }
  { the names 'expr_ptr', 'stmt_ptr' and 'decl_ptr' are  }
  { intentionally not used as fields so that they may be }
  { used as locals inside of a 'with expr_ptr^' block.   }
  {                                                      }
  { Otherwise be wary of 'with expr_ptr^' blocks because }
  { the expr node has so many fields that an identifier  }
  { clash may easily cause a misunderstanding not found  }
  { by the compiler.                                     }
  {******************************************************}
  expr_type = record
    next: expr_ptr_type;
    expr_info_ptr: expr_info_ptr_type;
    expr_index: integer;

    case kind: expr_kind_type of

      {***************************************************************}
      {                        unary operators                        }
      {***************************************************************}

      {********************}
      { negation operators }
      {********************}
      not_op, byte_negate, short_negate, integer_negate, long_negate,
        scalar_negate, double_negate, complex_negate, vector_negate,

      {**********************}
      { addressing operators }
      {**********************}
      address_op, deref_op,

      {*************************************}
      { implicit integeral type conversions }
      {*************************************}
      byte_to_short, short_to_integer, integer_to_long, integer_to_scalar,
        long_to_scalar, long_to_double,

      {**********************************}
      { implicit scalar type conversions }
      {**********************************}
      scalar_to_double, scalar_to_complex,

      {****************************}
      { vector component operators }
      {****************************}
      vector_x, vector_y, vector_z,

      {*****************************}
      { memory allocation functions }
      {*****************************}
      new_struct_fn, dim_array_fn,

      {*******************}
      { special functions }
      {*******************}
      min_fn, max_fn, num_fn: (
        operand_ptr: expr_ptr_type;
        );

      {***************************************************************}
      {                       binary operators                        }
      {***************************************************************}

      {*******************}
      { boolean operators }
      {*******************}
      and_op, or_op, and_if_op, or_if_op,

      {******************************}
      { boolean relational operators }
      {******************************}
      boolean_equal, boolean_not_equal,

      {********************************}
      { character relational operators }
      {********************************}
      char_equal, char_not_equal,

      {***************************}
      { byte relational operators }
      {***************************}
      byte_equal, byte_not_equal, byte_less_than, byte_greater_than,
        byte_less_equal, byte_greater_equal,

      {***************************}
      { byte arithmetic operators }
      {***************************}
      byte_add, byte_subtract, byte_multiply, byte_divide, byte_mod,

      {************************************}
      { short integer relational operators }
      {************************************}
      short_equal, short_not_equal, short_less_than, short_greater_than,
        short_less_equal, short_greater_equal,

      {************************************}
      { short integer arithmetic operators }
      {************************************}
      short_add, short_subtract, short_multiply, short_divide, short_mod,

      {******************************}
      { integer relational operators }
      {******************************}
      integer_equal, integer_not_equal, integer_less_than, integer_greater_than,
        integer_less_equal, integer_greater_equal,

      {******************************}
      { integer arithmetic operators }
      {******************************}
      integer_add, integer_subtract, integer_multiply, integer_divide,
        integer_mod,

      {***********************************}
      { long integer relational operators }
      {***********************************}
      long_equal, long_not_equal, long_less_than, long_greater_than,
        long_less_equal, long_greater_equal,

      {***********************************}
      { long integer arithmetic operators }
      {***********************************}
      long_add, long_subtract, long_multiply, long_divide, long_mod,

      {*****************************}
      { scalar relational operators }
      {*****************************}
      scalar_equal, scalar_not_equal, scalar_less_than, scalar_greater_than,
        scalar_less_equal, scalar_greater_equal,

      {*****************************}
      { scalar arithmetic operators }
      {*****************************}
      scalar_add, scalar_subtract, scalar_multiply, scalar_divide,
        scalar_exponent,

      {************************************}
      { double scalar relational operators }
      {************************************}
      double_equal, double_not_equal, double_less_than, double_greater_than,
        double_less_equal, double_greater_equal,

      {************************************}
      { double scalar arithmetic operators }
      {************************************}
      double_add, double_subtract, double_multiply, double_divide,
        double_exponent,

      {******************************}
      { complex relational operators }
      {******************************}
      complex_equal, complex_not_equal,

      {******************************}
      { complex arithmetic operators }
      {******************************}
      complex_add, complex_subtract, complex_multiply, complex_divide,

      {*****************************}
      { vector relational operators }
      {*****************************}
      vector_equal, vector_not_equal,

      {*****************************}
      { vector arithmetic operators }
      {*****************************}
      vector_add, vector_subtract, vector_vector_multiply, vector_vector_divide,
        vector_mod, vector_dot_product, vector_cross_product, vector_parallel,
        vector_perpendicular,

      {************************************}
      { vector scalar arithmetic operators }
      {************************************}
      vector_scalar_multiply, vector_scalar_divide,

      {**************************************************}
      { array and structure pointer relational operators }
      {**************************************************}
      array_ptr_equal, array_ptr_not_equal, struct_ptr_equal,
        struct_ptr_not_equal,

      {**********************************************}
      { prototype and reference relational operators }
      {**********************************************}
      proto_equal, proto_not_equal, reference_equal, reference_not_equal: (
        implicit_and: boolean;
        left_operand_ptr, right_operand_ptr: expr_ptr_type;
        );

      {****************************}
      { array relational operators }
      {****************************}
      array_equal, array_not_equal, array_expr_equal, array_expr_not_equal: (
        );

      {********************************}
      { structure relational operators }
      {********************************}
      struct_equal, struct_not_equal, struct_expr_equal, struct_expr_not_equal: (
        );

      {***************************************************************}
      {                        expression terms                       }
      {***************************************************************}

      {*************************}
      { explicit ptr conversion }
      {*************************}
      ptr_cast, type_query: (
        desired_subclass_ref: forward_type_ref_type;
        class_expr_ptr: expr_ptr_type;
        );

      {********************}
      { tuplet expressions }
      {********************}
      complex_pair: (
        a_expr_ptr, b_expr_ptr: expr_ptr_type;
        );
      vector_triplet: (
        x_expr_ptr, y_expr_ptr, z_expr_ptr: expr_ptr_type
        );

      {************************}
      { functional expressions }
      {************************}
      user_fn: (
        fn_stmt_ptr: forward_stmt_ptr_type;
        );

      {***************************************************************}
      {                      array expression terms                   }
      {***************************************************************}

      {******************************}
      { enumerated array expressions }
      {******************************}
      boolean_array_expr, char_array_expr,

      {***************************}
      { integer array expressions }
      {***************************}
      byte_array_expr, short_array_expr, integer_array_expr, long_array_expr,

      {**************************}
      { scalar array expressions }
      {**************************}
      scalar_array_expr, double_array_expr, complex_array_expr,
        vector_array_expr,

      {**********************************}
      { array / struct array expressions }
      {**********************************}
      array_array_expr, struct_array_expr, static_struct_array_expr,

      {******************************************}
      { subprogram / reference array expressions }
      {******************************************}
      proto_array_expr, reference_array_expr: (
        array_expr_bounds_list_ptr: array_bounds_list_ptr_type;
        array_element_exprs_ptr: expr_ptr_type;

        {************************************}
        { static structure array expressions }
        {************************************}
        array_expr_static_struct_type_ref: forward_type_ref_type;
        );
      subarray_expr: (
        array_expr_bounds_ref: array_bounds_ref_type;
        subarray_element_exprs_ptr: expr_ptr_type;
        );
      element_expr: (
        element_array_expr_ptr: expr_ptr_type;
        element_expr_ref: expr_ref_type;
        );

      {***************************************************************}
      {                        array dimensioning                     }
      {***************************************************************}

      {*******************************}
      { enumerated array dimensioning }
      {*******************************}
      boolean_array_dim, char_array_dim,

      {****************************}
      { integer array dimensioning }
      {****************************}
      byte_array_dim, short_array_dim, integer_array_dim, long_array_dim,

      {***************************}
      { scalar array dimensioning }
      {***************************}
      scalar_array_dim, double_array_dim, complex_array_dim, vector_array_dim,

      {***********************************}
      { array / struct array dimensioning }
      {***********************************}
      array_array_dim, struct_array_dim, static_struct_array_dim,

      {*******************************************}
      { subprogram / reference array dimensioning }
      {*******************************************}
      proto_array_dim, reference_array_dim: (
        dim_bounds_list_ptr: array_bounds_list_ptr_type;

        {*******************************************************}
        { array of array / dynamic structure array dimensioning }
        {*******************************************************}
        dim_element_expr_ptr: expr_ptr_type;

        {*************************************}
        { static structure array dimensioning }
        {*************************************}
        dim_static_struct_type_ref: forward_type_ref_type;
        dim_static_struct_init_stmt_ptr: forward_stmt_ptr_type;
        );

      {***************************************************************}
      {                       array dereferencing                     }
      {***************************************************************}

      {********************************}
      { enumerated array dereferencing }
      {********************************}
      boolean_array_deref, char_array_deref,

      {*****************************}
      { integer array dereferencing }
      {*****************************}
      byte_array_deref, short_array_deref, integer_array_deref,
        long_array_deref,

      {****************************}
      { scalar array dereferencing }
      {****************************}
      scalar_array_deref, double_array_deref, complex_array_deref,
        vector_array_deref,

      {************************************}
      { array / struct array dereferencing }
      {************************************}
      array_array_deref, struct_array_deref, static_struct_array_deref,

      {********************************************}
      { subprogram / reference array dereferencing }
      {********************************************}
      proto_array_deref, reference_array_deref: (
        deref_index_list_ptr: array_index_list_ptr_type;

        deref_base_ptr: expr_ptr_type;
        deref_element_ref: expr_ref_type;

        {**************************************}
        { static structure array dereferencing }
        {**************************************}
        deref_static_struct_type_ref: forward_type_ref_type;
        );

      {***************************************************************}
      {                   array subrange expressions                  }
      {***************************************************************}

      {****************************}
      { enumerated array subranges }
      {****************************}
      boolean_array_subrange, char_array_subrange,

      {*************************}
      { integer array subranges }
      {*************************}
      byte_array_subrange, short_array_subrange, integer_array_subrange,
        long_array_subrange,

      {************************}
      { scalar array subranges }
      {************************}
      scalar_array_subrange, double_array_subrange, complex_array_subrange,
        vector_array_subrange,

      {********************************}
      { array / struct array subranges }
      {********************************}
      array_array_subrange, struct_array_subrange, static_struct_array_subrange,

      {****************************************}
      { subprogram / reference array subranges }
      {****************************************}
      proto_array_subrange, reference_array_subrange: (
        subrange_index_list_ptr: array_index_list_ptr_type;
        subrange_bounds_list_ptr: array_bounds_list_ptr_type;

        subrange_base_ptr: expr_ptr_type;
        subrange_element_ref: expr_ref_type;
        next_subrange_ref: expr_ptr_type;
        implicit_subrange: boolean;

        {**************************************}
        { static structure array dereferencing }
        {**************************************}
        subrange_static_struct_type_ref: forward_type_ref_type;
        );

      {*******************************************}
      { implicit references used in array assigns }
      {*******************************************}
      array_base: (
        array_base_expr_ref: expr_ref_type;
        array_base_addr: addr_type;
        array_base_handle: handle_type;
        );

      {***************************************************************}
      {                   structure expression terms                  }
      {***************************************************************}

      {***********************}
      { structure expressions }
      {***********************}
      struct_expr: (
        struct_expr_size: integer;
        field_exprs_ptr: expr_ptr_type;
        );

      {**********************}
      { structure allocation }
      {**********************}
      struct_new: (
        new_struct_type_ref: forward_type_ref_type;
        new_struct_init_stmt_ptr: forward_stmt_ptr_type;
        );

      {*************************}
      { structure dereferencing }
      {*************************}
      struct_deref, struct_offset: (
        base_expr_ptr: expr_ptr_type;
        field_expr_ptr: expr_ptr_type;
        implicit_field, antecedent_field: boolean;
        );
      field_deref, field_offset: (
        base_expr_ref: expr_ref_type;
        field_name_ptr: expr_ptr_type;
        );

      {***********************************************}
      { implicit references used in structure assigns }
      {***********************************************}
      struct_base: (
        struct_base_type_ref: forward_type_ref_type;
        struct_base_memref: memref_type;
        );
      static_struct_base: (
        static_struct_base_type_ref: forward_type_ref_type;
        static_struct_base_addr: addr_type;
        );

      {***************************************************************}
      {                      expression terminals                     }
      {***************************************************************}

      {***********************************}
      { user defined variable identifiers }
      {***********************************}
      global_identifier, local_identifier: (
        stack_index: stack_index_type;
        );
      nested_identifier: (
        static_links, dynamic_links: integer;
        nested_id_expr_ptr: expr_ptr_type;
        );

      {*******************************}
      { user defined type identifiers }
      {*******************************}
      field_identifier: (
        field_index: heap_index_type;
        );

      {*************************}
      { most recent addr caches }
      {*************************}
      itself: (
        );
      new_itself: (
        new_type_ref: forward_type_ref_type;
        );
      implicit_expr: (
        implicit_expr_ref: expr_ref_type;
        );

      {***************************************************************}
      {                      expression literals        	            }
      {***************************************************************}

      {*********************}
      { enumerated literals }
      {*********************}
      true_val, false_val: (
        );
      char_lit: (
        char_val: char_type;
        );
      enum_lit: (
        enum_val: integer;
        );

      {******************}
      { integer literals }
      {******************}
      byte_lit: (
        byte_val: byte_type;
        );
      short_lit: (
        short_val: short_type;
        );
      integer_lit: (
        integer_val: integer_type;
        );
      long_lit: (
        long_val: long_type;
        );

      {*****************}
      { scalar literals }
      {*****************}
      scalar_lit: (
        scalar_val: scalar_type;
        scalar_attributes_ptr: literal_attributes_ptr_type;
        );
      double_lit: (
        double_val: double_type;
        double_attributes_ptr: literal_attributes_ptr_type;
        );
      complex_lit: (
        complex_val: complex_type;
        complex_attributes_ptr: literal_attributes_ptr_type;
        );
      vector_lit: (
        vector_val: vector_type;
        vector_attributes_ptr: literal_attributes_ptr_type;
        );
  end; {expr_type}


var
  {***********************}
  { various subrange sets }
  {***********************}
  unary_operator_set: expr_kind_set_type;
  simple_binary_operator_set, compound_binary_operator_set, binary_operator_set:
  expr_kind_set_type;
  expr_term_set, terminal_set, literal_set, scalar_literal_set:
  expr_kind_set_type;
  array_dim_set, array_subrange_set, array_deref_set: expr_kind_set_type;
  array_element_set, array_expr_set: expr_kind_set_type;
  struct_deref_set, struct_expr_set: expr_kind_set_type;
  deref_set, ptr_conversion_set: expr_kind_set_type;
  nonterminal_id_set, identifier_set, terminal_attributes_set:
  expr_kind_set_type;
  deref_expr_kinds, dim_expr_kinds: expr_kind_set_type;

  {**************************}
  { relational operator sets }
  {**************************}
  boolean_rel_op_set, char_rel_op_set: expr_kind_set_type;
  byte_rel_op_set, short_rel_op_set: expr_kind_set_type;
  integer_rel_op_set, long_rel_op_set: expr_kind_set_type;
  scalar_rel_op_set, double_rel_op_set: expr_kind_set_type;
  complex_rel_op_set, vector_rel_op_set: expr_kind_set_type;
  ptr_rel_op_set, proto_rel_op_set, reference_rel_op_set: expr_kind_set_type;
  array_rel_op_set, struct_rel_op_set: expr_kind_set_type;
  enum_rel_op_set, numerical_rel_op_set: expr_kind_set_type;
  rel_op_set: expr_kind_set_type;

  {********************************************}
  { subrange sets base on operator return type }
  {********************************************}
  byte_operator_set, short_operator_set: expr_kind_set_type;
  integer_operator_set, long_operator_set: expr_kind_set_type;
  scalar_operator_set, double_operator_set: expr_kind_set_type;
  complex_operator_set, vector_operator_set: expr_kind_set_type;

  {*********************************************}
  { subrange sets based on function return type }
  {*********************************************}
  integer_fn_set, scalar_fn_set: expr_kind_set_type;

  {************************************}
  { subrange sets based on return type }
  {************************************}
  boolean_expr_set, char_expr_set: expr_kind_set_type;
  byte_expr_set, short_expr_set: expr_kind_set_type;
  integer_expr_set, long_expr_set: expr_kind_set_type;
  scalar_expr_set, double_expr_set: expr_kind_set_type;
  complex_expr_set, vector_expr_set: expr_kind_set_type;


{************************************************}
{ routines for allocating and initializing exprs }
{************************************************}
function New_expr(kind: expr_kind_type): expr_ptr_type;
procedure Init_expr(expr_ptr: expr_ptr_type;
  kind: expr_kind_type);
function Copy_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
function Copy_exprs(expr_ptr: expr_ptr_type): expr_ptr_type;
procedure Free_expr(var expr_ptr: expr_ptr_type);
procedure Free_exprs(var expr_ptr: expr_ptr_type);
function Expr_count: longint;

{**********************************************************}
{ routines for allocating and freeing auxiliiary expr info }
{**********************************************************}
function New_expr_info: expr_info_ptr_type;
procedure Init_expr_info(expr_info_ptr: expr_info_ptr_type);
function Copy_expr_info(expr_info_ptr: expr_info_ptr_type;
  copy_attributes: boolean): expr_info_ptr_type;
procedure Free_expr_info(var expr_info_ptr: expr_info_ptr_type;
  free_attributes: boolean);
function Expr_info_count: longint;

{************************************************}
{ routines for manipulating auxilliary expr info }
{************************************************}
procedure Set_expr_info(expr_ptr: expr_ptr_type;
  expr_info_ptr: expr_info_ptr_type);
function Get_expr_info(expr_ptr: expr_ptr_type): expr_info_ptr_type;

{***********************************************************}
{ routines for dealing with the attributes of an expression }
{***********************************************************}
procedure Set_expr_attributes(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
function Get_expr_attributes(expr_ptr: expr_ptr_type): expr_attributes_ptr_type;

{******************************************************************}
{ routines for dealing with the attributes of a literal expression }
{******************************************************************}
procedure Set_literal_attributes(expr_ptr: expr_ptr_type;
  literal_attributes_ptr: literal_attributes_ptr_type);
function Get_literal_attributes(expr_ptr: expr_ptr_type):
  literal_attributes_ptr_type;

{*********************************}
{ routines for writing expr enums }
{*********************************}
procedure Write_expr_kind(kind: expr_kind_type);


implementation
uses
  errors, value_attributes;


{***************************************************************}
{                       array dimensioning                      }
{***************************************************************}
{                                                               }
{       An array can be dimensioned as a single dimensional     }
{       array, as a multidimensional array, or as an array      }
{       of arrays.  The first and second cases are simple,      }
{       requiring only a single dimension node with an          }
{       array bounds list for multidimensional arrays.          }
{       The arrangement can be pictured as follows:             }
{                                                               }
{                        i[1..10, 1..20]:                       }
{                                                               }
{                                |                              }
{                                v                              }
{                         /-------------\                       }
{                         | integer dim |->[1..10, 1..20]       }
{                         \-------------/                       }
{                                                               }
{       An array of arrays is a more complicated case. This     }
{       situation requires a chain of dimension nodes with      }
{       the element ptr always pointing to the expression       }
{       which represents the element kind of the array.         }
{                                                               }
{                             Example:                          }
{                      i[1..5][1..10][1..20]:                   }
{                                                               }
{       i is an array[1..5] of array[1..10] of array[1..20].    }
{       In order to interpret this declaration, first i         }
{       must be dimensioned [1..5], then each of the elements   }
{       are dimensioned [1..10] and each of these sub elements  }
{       is dimensioned [1..20].  The outermost dim is the       }
{       most significant.                                       }
{                                                               }
{                                |                              }
{                                v                              }
{                         /-------------\                       }
{                         |  array dim  |->[1..5]     (first    }
{                         \-------------/             executed) }
{                                | element ptr                  }
{                                v                              }
{                         /-------------\                       }
{                         |  array dim  |->[1..10]    (second   }
{                         \-------------/             executed) }
{                                | element ptr                  }
{                                v                              }
{                         /-------------\                       }
{                         | integer dim |->[1..20]    (last     }
{                         \-------------/             executed) }
{                                                               }
{***************************************************************}


{***************************************************************}
{                       array dereferencing                     }
{***************************************************************}
{                                                               }
{       Array dereferecing is sort of like dimensioning         }
{       in reverse.  The first array dereference is applied     }
{       to the most significant (outermost) array and so on.    }
{                                                               }
{       For example, to dereference the array:                  }
{                      i[1..5][1..10][1..20]                    }
{       we might use the expression:                            }
{                           i[1][5][10]                         }
{                                                               }
{       Note that the indices are in the same order as          }
{       the original array bounds.  When this is translated,    }
{       we will build a chain of array dereferences with the    }
{       most significant dereference on the outside, since we   }
{       recursiely traverse the syntax tree and we must         }
{       evaluate the most sigificant dereference before we      }
{       can go on to the next dereference and so forth.         }
{                                                               }
{       The base ptr always refers to the array that we are     }
{       dereferencing and the element ref always refers to      }
{       the element that we will obtain.                        }
{                                                               }
{                                |                              }
{                                v                              }
{                        /---------------\                      }
{                --------| integer deref |->[10]       (last    }
{                |       \---------------/            executed) }
{                |             ^   | base ptr                   }
{                |             |   |                            }
{                | element ref |   v                            }
{                |       /---------------\                      }
{                |       |  array deref  |->[5]       (second   }
{                |       \---------------/            executed) }
{                |             ^   | base ptr                   }
{                |             |   |                            }
{                | element ref |   v                            }
{                |       /---------------\                      }
{                |       |  array deref  |->[1]      (first     }
{                |       \---------------/            executed) }
{                |                 | base ptr                   }
{                |                 |                            }
{                | element ref     v                            }
{                |            /-----\                           }
{                \----------->|  i  |                           }
{                             \-----/                           }
{                                                               }
{***************************************************************}


{***************************************************************}
{                        array expressions                      }
{***************************************************************}
{                                                               }
{       Array expressions for arrays of arrays are encoded      }
{       differently than array expressions which are meant      }
{       to express multidimensional arrays.  This is because    }
{       multidimensional arrays must always be 'square'         }
{       whereas arrays of arrays may be non square requiring    }
{       a separate bounds list to represent each subarray       }
{       because each subarray may be of a differing size.       }
{                                                               }
{       Example:                                                }
{       The multidimensional array:  [[1 2 3] [4 5 6]]          }
{       will be represented as:                                 }
{                                                               }
{                     /--------------------\  bounds list       }
{                     | integer array expr |->[1..2]->[1..3]    }
{                     \--------------------/          ^         }
{               element expr ptr |                    | bounds  }
{              /-----------------/                    | refs    }
{              |         /----------------/-----------/         }
{              |  /-------------\  /-------------\              }
{              \->|array subexpr|->|array subexpr|-//           }
{                 \-------------/  \-------------/ next         }
{     element subexpr ptr |               |                     }
{     /-------------------/      /--------/                     }
{     |  /---\  /---\  /---\     |  /---\  /---\  /---\         }
{     \->| 1 |->| 2 |->| 3 |-//  \->| 4 |->| 5 |->| 6 |-//      }
{        \---/  \---/  \---/ next   \---/  \---/  \---/ next    }
{                                                               }
{      Whereas the array of arrays:  [[1 2 3] [4 5]]            }
{      will be represented as:                                  }
{                                                               }
{                                /->[1..2] bounds               }
{                       /------------------\ list               }
{                       | array array expr |                    }
{                       \------------------/                    }
{               element expr ptr |                              }
{      /-------------------------/                     bounds   }
{      |             /->[1..3] bounds list   /->[1..2] list     }
{      |  /--------------------\  /--------------------\        }
{      \->| integer array expr |->| integer array expr |-//     }
{         \--------------------/  \--------------------/ next   }
{   element expr ptr |      element expr ptr |                  }
{     /--------------/           /-----------/                  }
{     |  /---\  /---\  /---\     |  /---\  /---\                }
{     \->| 1 |->| 2 |->| 3 |-//  \->| 4 |->| 5 |-//             }
{        \---/  \---/  \---/ next   \---/  \---/  next          }
{                                                               }
{***************************************************************}


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  expr_block_ptr_type = ^expr_block_type;
  expr_block_type = array[0..block_size] of expr_type;

  expr_info_block_ptr_type = ^expr_info_block_type;
  expr_info_block_type = array[0..block_size] of expr_info_type;


var
  {************}
  { free lists }
  {************}
  expr_free_list: expr_ptr_type;
  expr_info_free_list: expr_info_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  expr_block_ptr: expr_block_ptr_type;
  expr_counter: longint;

  expr_info_block_ptr: expr_info_block_ptr_type;
  expr_info_counter: longint;


procedure Init_expr_sets;
begin
  {**************************}
  { expression operator sets }
  {**************************}
  unary_operator_set := [not_op..num_fn];
  simple_binary_operator_set := [and_op..reference_not_equal];
  compound_binary_operator_set := [array_equal..struct_expr_not_equal];
  binary_operator_set := simple_binary_operator_set +
    compound_binary_operator_set;

  {**********************}
  { expression term sets }
  {**********************}
  expr_term_set := [ptr_cast..user_fn];
  terminal_set := [global_identifier..nil_reference];
  literal_set := [true_val..nil_reference];
  scalar_literal_set := [scalar_lit..vector_lit];

  {***********************}
  { array expression sets }
  {***********************}
  array_dim_set := [boolean_array_dim..reference_array_dim];
  array_subrange_set := [boolean_array_subrange..reference_array_subrange];
  array_deref_set := [boolean_array_deref..reference_array_deref] +
    array_subrange_set;
  array_element_set := [boolean_array_expr..reference_array_expr, subarray_expr,
    element_expr];
  array_expr_set := array_dim_set + array_deref_set + array_element_set +
    [array_base];

  {***************************}
  { structure expression sets }
  {***************************}
  struct_deref_set := [struct_deref, struct_offset, field_deref, field_offset];
  struct_expr_set := struct_deref_set + [struct_new, struct_expr, struct_base,
    static_struct_base];

  {*****************************}
  { nonterminal expression sets }
  {*****************************}
  deref_set := [deref_op] + struct_deref_set + array_deref_set;
  ptr_conversion_set := [ptr_cast, type_query];
  nonterminal_id_set := [nested_identifier, address_op] + array_expr_set +
    struct_expr_set + deref_set + ptr_conversion_set;

  {****************************}
  { identifier expression sets }
  {****************************}
  identifier_set := [global_identifier, local_identifier, nested_identifier,
    field_identifier];
  terminal_attributes_set := [itself, user_fn, enum_lit,
    boolean_array_expr..reference_array_expr] + identifier_set;
  deref_expr_kinds := identifier_set + deref_set + [ptr_cast];
  dim_expr_kinds := identifier_set + deref_set + array_dim_set + [struct_new];

  {**************************}
  { relational operator sets }
  {**************************}
  boolean_rel_op_set := [boolean_equal..boolean_not_equal];
  char_rel_op_set := [char_equal..char_not_equal];
  byte_rel_op_set := [byte_equal..byte_greater_equal];
  short_rel_op_set := [short_equal..short_greater_equal];
  integer_rel_op_set := [integer_equal..integer_greater_equal];
  long_rel_op_set := [long_equal..long_greater_equal];
  scalar_rel_op_set := [scalar_equal..scalar_greater_equal];
  double_rel_op_set := [double_equal..double_greater_equal];
  complex_rel_op_set := [complex_equal..complex_not_equal];
  vector_rel_op_set := [vector_equal..vector_not_equal];
  ptr_rel_op_set := [array_ptr_equal..struct_ptr_not_equal];
  proto_rel_op_set := [proto_equal..proto_not_equal];
  reference_rel_op_set := [reference_equal..reference_not_equal];
  array_rel_op_set := [array_equal, array_not_equal, array_expr_equal,
    array_expr_not_equal];
  struct_rel_op_set := [struct_equal, struct_not_equal, struct_expr_equal,
    struct_expr_not_equal];
  enum_rel_op_set := boolean_rel_op_set + char_rel_op_set;
  numerical_rel_op_set := byte_rel_op_set + short_rel_op_set + integer_rel_op_set
    + long_rel_op_set + scalar_rel_op_set + double_rel_op_set +
    complex_rel_op_set
    + vector_rel_op_set;
  rel_op_set := enum_rel_op_set + numerical_rel_op_set + ptr_rel_op_set +
    proto_rel_op_set + reference_rel_op_set + array_rel_op_set +
    struct_rel_op_set;

  {********************************************}
  { subrange sets base on operator return type }
  {********************************************}
  byte_operator_set := [byte_add, byte_subtract, byte_multiply, byte_divide,
    byte_mod];
  short_operator_set := [short_add, short_subtract, short_multiply,
    short_divide, short_mod];

  integer_operator_set := [integer_add, integer_subtract, integer_multiply,
    integer_divide, integer_mod];
  long_operator_set := [long_add, long_subtract, long_multiply, long_divide,
    long_mod];

  scalar_operator_set := [scalar_add, scalar_subtract, scalar_multiply,
    scalar_divide, scalar_exponent] + [vector_dot_product, vector_x, vector_y,
    vector_z];
  double_operator_set := [double_add, double_subtract, double_multiply,
    double_divide, double_exponent];

  complex_operator_set := [complex_add, complex_subtract, complex_multiply,
    complex_divide];
  vector_operator_set := [vector_add, vector_subtract, vector_vector_multiply,
    vector_vector_divide, vector_mod, vector_cross_product, vector_parallel,
    vector_perpendicular] + [vector_scalar_multiply, vector_scalar_divide];

  {*********************************************}
  { subrange sets based on function return type }
  {*********************************************}
  integer_fn_set := [min_fn, max_fn, num_fn];
  scalar_fn_set := unary_operator_set + integer_fn_set;

  {************************************}
  { subrange sets based on return type }
  {************************************}
  boolean_expr_set := rel_op_set + [true_val, false_val];
  char_expr_set := [char_lit];

  byte_expr_set := [byte_lit] + byte_operator_set;
  short_expr_set := [short_lit] + short_operator_set;

  integer_expr_set := [integer_lit] + integer_operator_set + integer_fn_set;
  long_expr_set := [long_lit] + long_operator_set + integer_fn_set;

  scalar_expr_set := [scalar_lit] + scalar_operator_set + scalar_fn_set;
  double_expr_set := [double_lit] + double_operator_set + scalar_fn_set;

  complex_expr_set := [complex_lit] + complex_operator_set;
  vector_expr_set := [vector_lit] + vector_operator_set;
end; {procedure Init_expr_sets}


{**********************************************************}
{ routines for allocating and freeing auxiliiary expr info }
{**********************************************************}


procedure Init_expr_info(expr_info_ptr: expr_info_ptr_type);
begin
  with expr_info_ptr^ do
    begin
      next := nil;

      {**********************************************}
      { initialize compile time semantic information }
      {**********************************************}
      expr_attributes_ptr := nil;

      {***********************************************}
      { initialize compile time stylistic information }
      {***********************************************}
      comments_ptr := nil;
      explicit_expr := false;
    end;
end; {procedure Init_expr_info}


function New_expr_info: expr_info_ptr_type;
var
  expr_info_ptr: expr_info_ptr_type;
  index: integer;
begin
  {******************************}
  { get expr info from free list }
  {******************************}
  if expr_info_free_list <> nil then
    begin
      expr_info_ptr := expr_info_free_list;
      expr_info_free_list := expr_info_free_list^.next;
    end
  else
    begin
      index := expr_info_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new expr info block');
          new(expr_info_block_ptr);
        end;
      expr_info_ptr := @expr_info_block_ptr^[index];
    end;

  {************************}
  { increment expr counter }
  {************************}
  expr_info_counter := expr_info_counter + 1;

  {**********************}
  { initialize expr info }
  {**********************}
  Init_expr_info(expr_info_ptr);

  New_expr_info := expr_info_ptr;
end; {function New_expr_info}


function Copy_expr_info(expr_info_ptr: expr_info_ptr_type;
  copy_attributes: boolean): expr_info_ptr_type;
var
  new_expr_info_ptr: expr_info_ptr_type;
begin
  if expr_info_ptr <> nil then
    begin
      new_expr_info_ptr := New_expr_info;
      new_expr_info_ptr^ := expr_info_ptr^;
      new_expr_info_ptr^.next := nil;

      if copy_attributes then
        with new_expr_info_ptr^ do
          expr_attributes_ptr := Copy_expr_attributes(expr_attributes_ptr);
    end
  else
    new_expr_info_ptr := nil;

  Copy_expr_info := new_expr_info_ptr;
end; {function Copy_expr_info}


procedure Free_expr_info(var expr_info_ptr: expr_info_ptr_type;
  free_attributes: boolean);
begin
  if expr_info_ptr <> nil then
    begin
      if free_attributes then
        Free_expr_attributes(expr_info_ptr^.expr_attributes_ptr);

      {****************************}
      { add expr info to free list }
      {****************************}
      expr_info_ptr^.next := expr_info_free_list;
      expr_info_free_list := expr_info_ptr;
      expr_info_ptr := nil;

      {*****************************}
      { decrement expr info counter }
      {*****************************}
      expr_info_counter := expr_info_counter - 1;
    end;
end; {procedure Free_expr_info}


function Expr_info_count: longint;
begin
  Expr_info_count := expr_info_counter;
end; {function Expr_info_count}


{************************************************}
{ routines for manipulating auxilliary expr info }
{************************************************}


procedure Set_expr_info(expr_ptr: expr_ptr_type;
  expr_info_ptr: expr_info_ptr_type);
begin
  expr_ptr^.expr_info_ptr := expr_info_ptr;
  if expr_info_ptr^.expr_attributes_ptr <> nil then
    Set_expr_attributes(expr_ptr, expr_info_ptr^.expr_attributes_ptr);
end; {procedure Set_expr_info}


function Get_expr_info(expr_ptr: expr_ptr_type): expr_info_ptr_type;
begin
  if expr_ptr <> nil then
    Get_expr_info := expr_ptr^.expr_info_ptr
  else
    Get_expr_info := nil;
end; {function Get_expr_info}


{**********************************************************}
{ routine for dealing with the attributes of an expression }
{**********************************************************}


procedure Set_expr_attributes(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if expr_ptr^.expr_info_ptr = nil then
    expr_ptr^.expr_info_ptr := New_expr_info;

  {************************************}
  { link expression and its attributes }
  {************************************}
  expr_ptr^.expr_info_ptr^.expr_attributes_ptr := expr_attributes_ptr;
  if expr_attributes_ptr <> nil then
    expr_attributes_ptr^.expr_ref := forward_expr_ref_type(expr_ptr);
end; {procedure Set_expr_attributes}


function Get_subexpr_attributes(expr_ptr: expr_ptr_type):
  expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  expr_attributes_ptr := nil;

  if expr_ptr <> nil then
    with expr_ptr^ do
      begin
        {**************************}
        { non terminal expressions }
        {**************************}
        if kind in nonterminal_id_set then
          case kind of

            {************************}
            { identifier expressions }
            {************************}
            nested_identifier:
              expr_attributes_ptr := Get_expr_attributes(nested_id_expr_ptr);
            deref_op, address_op:
              expr_attributes_ptr := Get_expr_attributes(operand_ptr);

            {****************************}
            { ptr conversion expressions }
            {****************************}
            ptr_cast, type_query:
              expr_attributes_ptr := Get_expr_attributes(class_expr_ptr);

            {*******************}
            { array expressions }
            {*******************}
            boolean_array_expr..reference_array_expr:
              expr_attributes_ptr :=
                Get_expr_attributes(array_element_exprs_ptr);
            element_expr:
              expr_attributes_ptr := Get_expr_attributes(element_expr_ref);
            boolean_array_deref..reference_array_deref:
              expr_attributes_ptr := Get_expr_attributes(deref_element_ref);
            boolean_array_subrange..reference_array_subrange:
              expr_attributes_ptr := Get_expr_attributes(subrange_element_ref);

            {***********************}
            { structure expressions }
            {***********************}
            struct_expr:
              expr_attributes_ptr := Get_expr_attributes(field_exprs_ptr);
            struct_deref, struct_offset:
              expr_attributes_ptr := Get_expr_attributes(field_expr_ptr);
            field_deref, field_offset:
              expr_attributes_ptr := Get_expr_attributes(field_name_ptr);

          end
        else
          expr_attributes_ptr := nil;
      end
  else
    expr_attributes_ptr := nil;

  Get_subexpr_attributes := expr_attributes_ptr;
end; {function Get_subexpr_attributes}


function Get_literal_expr_attributes(expr_ptr: expr_ptr_type):
  expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  expr_attributes_ptr := nil;

  case expr_ptr^.kind of

    {*********************}
    { enumerated literals }
    {*********************}
    true_val, false_val:
      expr_attributes_ptr := boolean_value_attributes_ptr;
    char_lit:
      expr_attributes_ptr := char_value_attributes_ptr;
    enum_lit:
      expr_attributes_ptr := expr_ptr^.expr_info_ptr^.expr_attributes_ptr;

    {******************}
    { integer literals }
    {******************}
    byte_lit:
      expr_attributes_ptr := byte_value_attributes_ptr;
    short_lit:
      expr_attributes_ptr := short_value_attributes_ptr;
    integer_lit:
      expr_attributes_ptr := integer_value_attributes_ptr;
    long_lit:
      expr_attributes_ptr := long_value_attributes_ptr;

    {*****************}
    { scalar literals }
    {*****************}
    scalar_lit:
      expr_attributes_ptr := scalar_value_attributes_ptr;
    double_lit:
      expr_attributes_ptr := double_value_attributes_ptr;
    complex_lit:
      expr_attributes_ptr := complex_value_attributes_ptr;
    vector_lit:
      expr_attributes_ptr := vector_value_attributes_ptr;

    {**************}
    { ptr literals }
    {**************}
    nil_array, nil_struct, nil_proto, nil_reference:
      expr_attributes_ptr := typeless_value_attributes_ptr;
  end; {case}

  Get_literal_expr_attributes := expr_attributes_ptr;
end; {function Get_literal_expr_attributes}


function Get_expr_attributes(expr_ptr: expr_ptr_type): expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if expr_ptr <> nil then
    with expr_ptr^ do
      begin
        {**********************}
        { terminal expressions }
        {**********************}
        if expr_info_ptr <> nil then
          expr_attributes_ptr := expr_info_ptr^.expr_attributes_ptr
        else
          expr_attributes_ptr := nil;

        if expr_attributes_ptr = nil then
          begin
            {*************************}
            { nonterminal expressions }
            {*************************}
            if kind in literal_set then
              expr_attributes_ptr := Get_literal_expr_attributes(expr_ptr);
            if kind in nonterminal_id_set then
              expr_attributes_ptr := Get_subexpr_attributes(expr_ptr)

              {****************************}
              { primitive type expressions }
              {****************************}
            else if kind in boolean_expr_set then
              expr_attributes_ptr := boolean_value_attributes_ptr
            else if kind in char_expr_set then
              expr_attributes_ptr := char_value_attributes_ptr

            else if kind in byte_expr_set then
              expr_attributes_ptr := byte_value_attributes_ptr
            else if kind in short_expr_set then
              expr_attributes_ptr := short_value_attributes_ptr

            else if kind in integer_expr_set then
              expr_attributes_ptr := integer_value_attributes_ptr
            else if kind in long_expr_set then
              expr_attributes_ptr := long_value_attributes_ptr

            else if kind in scalar_expr_set then
              expr_attributes_ptr := scalar_value_attributes_ptr
            else if kind in double_expr_set then
              expr_attributes_ptr := double_value_attributes_ptr

            else if kind in complex_expr_set then
              expr_attributes_ptr := complex_value_attributes_ptr
            else if kind in vector_expr_set then
              expr_attributes_ptr := vector_value_attributes_ptr;
          end;
      end
  else
    expr_attributes_ptr := nil;

  Get_expr_attributes := expr_attributes_ptr;
end; {function Get_expr_attributes}


{******************************************************************}
{ routines for dealing with the attributes of a literal expression }
{******************************************************************}


procedure Set_literal_attributes(expr_ptr: expr_ptr_type;
  literal_attributes_ptr: literal_attributes_ptr_type);
begin
  with expr_ptr^ do
    if kind in scalar_literal_set then
      begin
        case kind of

          scalar_lit:
            scalar_attributes_ptr := literal_attributes_ptr;

          double_lit:
            double_attributes_ptr := literal_attributes_ptr;

          complex_lit:
            complex_attributes_ptr := literal_attributes_ptr;

          vector_lit:
            vector_attributes_ptr := literal_attributes_ptr;

        end; {case}

        if literal_attributes_ptr <> nil then
          literal_attributes_ptr^.expr_ref := forward_expr_ref_type(expr_ptr);
      end;
end; {procedure Set_literal_attributes}


function Get_literal_attributes(expr_ptr: expr_ptr_type):
  literal_attributes_ptr_type;
var
  literal_attributes_ptr: literal_attributes_ptr_type;
begin
  literal_attributes_ptr := nil;
  
  with expr_ptr^ do
    if kind in scalar_literal_set then
      case kind of

        scalar_lit:
          literal_attributes_ptr := scalar_attributes_ptr;

        double_lit:
          literal_attributes_ptr := double_attributes_ptr;

        complex_lit:
          literal_attributes_ptr := complex_attributes_ptr;

        vector_lit:
          literal_attributes_ptr := vector_attributes_ptr;

      end
    else
      literal_attributes_ptr := nil;

  Get_literal_attributes := literal_attributes_ptr;
end; {function Get_literal_attributes}


{************************************************}
{ routines for allocating and initializing exprs }
{************************************************}


procedure Init_expr(expr_ptr: expr_ptr_type;
  kind: expr_kind_type);
begin
  {********************}
  { init common fields }
  {********************}
  expr_ptr^.kind := kind;
  expr_ptr^.expr_info_ptr := nil;
  expr_ptr^.expr_index := 0;
  expr_ptr^.next := nil;

  {**********************}
  { init specific fields }
  {**********************}
  with expr_ptr^ do

    {***************************************************************}
    {                      expression operators       	            }
    {***************************************************************}

    {*****************}
    { unary operators }
    {*****************}
    if kind in unary_operator_set then
      operand_ptr := nil

      {******************}
      { binary operators }
      {******************}
    else if kind in binary_operator_set then
      begin
        implicit_and := false;
        left_operand_ptr := nil;
        right_operand_ptr := nil;
      end

        {***************************************************************}
        {                     array expression terms                    }
        {***************************************************************}
    else if kind in array_expr_set then
      case kind of

        {*******************}
        { array expressions }
        {*******************}
        boolean_array_expr..reference_array_expr:
          begin
            array_expr_bounds_list_ptr := nil;
            array_element_exprs_ptr := nil;

            {************************************}
            { static structure array expressions }
            {************************************}
            array_expr_static_struct_type_ref := nil;
          end;
        subarray_expr:
          begin
            array_expr_bounds_ref := nil;
            subarray_element_exprs_ptr := nil;
          end;
        element_expr:
          begin
            element_array_expr_ptr := nil;
            element_expr_ref := nil;
          end;

        {********************}
        { array dimensioning }
        {********************}
        boolean_array_dim..reference_array_dim:
          begin
            dim_bounds_list_ptr := nil;

            {*******************************************************}
            { array of array / dynamic structure array dimensioning }
            {*******************************************************}
            dim_element_expr_ptr := nil;

            {*************************************}
            { static structure array dimensioning }
            {*************************************}
            dim_static_struct_type_ref := nil;
            dim_static_struct_init_stmt_ptr := nil;
          end;

        {*********************}
        { array dereferencing }
        {*********************}
        boolean_array_deref..reference_array_deref:
          begin
            deref_index_list_ptr := nil;

            deref_base_ptr := nil;
            deref_element_ref := nil;

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            deref_static_struct_type_ref := nil;
          end;

        {****************************}
        { array subrange expressions }
        {****************************}
        boolean_array_subrange..reference_array_subrange:
          begin
            subrange_index_list_ptr := nil;
            subrange_bounds_list_ptr := nil;

            subrange_base_ptr := nil;
            subrange_element_ref := nil;
            next_subrange_ref := nil;
            implicit_subrange := false;

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            subrange_static_struct_type_ref := nil;
          end;

        {*******************************************}
        { implicit references used in array assigns }
        {*******************************************}
        array_base:
          begin
            array_base_expr_ref := nil;
            Init_addr(array_base_addr, stack_index_addr);
            array_base_handle := 0;
          end;

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
          begin
            struct_expr_size := 0;
            field_exprs_ptr := nil;
          end;

        {**********************}
        { structure allocation }
        {**********************}
        struct_new:
          begin
            new_struct_type_ref := nil;
            new_struct_init_stmt_ptr := nil;
          end;

        {*************************}
        { structure dereferencing }
        {*************************}
        struct_deref, struct_offset:
          begin
            base_expr_ptr := nil;
            field_expr_ptr := nil;
            implicit_field := false;
            antecedent_field := false;
          end;
        field_deref, field_offset:
          begin
            base_expr_ref := nil;
            field_name_ptr := nil;
          end;

        {***********************************************}
        { implicit references used in structure assigns }
        {***********************************************}
        struct_base:
          begin
            struct_base_type_ref := nil;
            struct_base_memref := 0;
          end;
        static_struct_base:
          begin
            static_struct_base_type_ref := nil;
            Init_addr(static_struct_base_addr, stack_index_addr);
          end;

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
            desired_subclass_ref := nil;
            class_expr_ptr := nil;
          end;

        {********************}
        { tuplet expressions }
        {********************}
        complex_pair:
          begin
            a_expr_ptr := nil;
            b_expr_ptr := nil;
          end;
        vector_triplet:
          begin
            x_expr_ptr := nil;
            y_expr_ptr := nil;
            z_expr_ptr := nil;
          end;

        {************************}
        { functional expressions }
        {************************}
        user_fn:
          fn_stmt_ptr := nil;

        {***************************************************************}
        {                      expression terminals                     }
        {***************************************************************}

        {***********************************}
        { user defined variable identifiers }
        {***********************************}
        global_identifier, local_identifier:
          stack_index := 0;
        nested_identifier:
          begin
            static_links := 0;
            dynamic_links := 0;
            nested_id_expr_ptr := nil;
          end;

        {*****************************}
        { user defined type variables }
        {*****************************}
        field_identifier:
          field_index := 0;

        {*************************}
        { most recent addr caches }
        {*************************}
        itself:
          ;
        new_itself:
          new_type_ref := nil;
        implicit_expr:
          implicit_expr_ref := nil;

      end {case}

        {***************************************************************}
        {                      expression literals        	            }
        {***************************************************************}
    else
      case kind of

        {*********************}
        { enumerated literals }
        {*********************}
        true_val, false_val:
          ;
        char_lit:
          char_val := chr(0);
        enum_lit:
          enum_val := 0;

        {******************}
        { integer literals }
        {******************}
        byte_lit:
          byte_val := 0;
        short_lit:
          short_val := 0;
        integer_lit:
          integer_val := 0;
        long_lit:
          long_val := 0;

        {*****************}
        { scalar literals }
        {*****************}
        scalar_lit:
          begin
            scalar_val := 0;
            scalar_attributes_ptr := nil;
          end;

        double_lit:
          begin
            double_val := 0;
            double_attributes_ptr := nil;
          end;

        complex_lit:
          begin
            complex_val := To_complex(0, 0);
            complex_attributes_ptr := nil;
          end;

        vector_lit:
          begin
            vector_val := zero_vector;
            vector_attributes_ptr := nil;
          end;

        {**************}
        { nil literals }
        {**************}
        nil_array, nil_struct, nil_proto, nil_reference:
          ;

        {********************}
        { uninitialized expr }
        {********************}
        error_expr:
          ;

      end; {case}
end; {procedure Init_expr}


function New_expr(kind: expr_kind_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  index: integer;
begin
  {******************************}
  { get expr node from free list }
  {******************************}
  if expr_free_list <> nil then
    begin
      expr_ptr := expr_free_list;
      expr_free_list := expr_free_list^.next;
    end
  else
    begin
      index := expr_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new expr block');
          new(expr_block_ptr);
        end;
      expr_ptr := @expr_block_ptr^[index];
    end;

  {************************}
  { increment expr counter }
  {************************}
  expr_counter := expr_counter + 1;

  {**********************}
  { initialize expr node }
  {**********************}
  Init_expr(expr_ptr, kind);

  New_expr := expr_ptr;
end; {function New_expr}


function Expr_count: longint;
begin
  Expr_count := expr_counter;
end; {function Expr_count}


{*****************************}
{ expression copying routines }
{*****************************}


function Copy_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr <> nil) then
    begin
      new_expr_ptr := New_expr(expr_ptr^.kind);
      new_expr_ptr^ := expr_ptr^;
      new_expr_ptr^.next := nil;
    end
  else
    new_expr_ptr := nil;

  Copy_expr := new_expr_ptr;
end; {function Copy_expr}


function Copy_exprs(expr_ptr: expr_ptr_type): expr_ptr_type;
var
  new_expr_ptr: expr_ptr_type;
  first_expr_ptr, last_expr_ptr: expr_ptr_type;
begin
  first_expr_ptr := nil;
  last_expr_ptr := nil;

  while expr_ptr <> nil do
    begin
      new_expr_ptr := Copy_expr(expr_ptr);

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

  Copy_exprs := first_expr_ptr;
end; {function Copy_exprs}


{*****************************}
{ expression freeing routines }
{*****************************}


procedure Free_expr(var expr_ptr: expr_ptr_type);
begin
  if (expr_ptr <> nil) then
    begin
      {***********************}
      { add expr to free list }
      {***********************}
      expr_ptr^.next := expr_free_list;
      expr_free_list := expr_ptr;
      expr_ptr := nil;

      {************************}
      { decrement expr counter }
      {************************}
      expr_counter := expr_counter - 1;
    end; {with}
end; {procedure Free_expr}


procedure Free_exprs(var expr_ptr: expr_ptr_type);
var
  temp: expr_ptr_type;
begin
  while (expr_ptr <> nil) do
    begin
      temp := expr_ptr;
      expr_ptr := expr_ptr^.next;
      Free_expr(temp);
    end;
end; {procedure Free_exprs}


{*********************************}
{ routines for writing expr enums }
{*********************************}


procedure Write_expr_kind(kind: expr_kind_type);
begin
  case kind of

    {********************}
    { uninitialized expr }
    {********************}
    error_expr:
      write('error_expr');

    {*******************}
    { boolean operators }
    {*******************}
    and_op:
      write('and_op');
    or_op:
      write('or_op');
    and_if_op:
      write('and_if_op');
    or_if_op:
      write('or_if_op');
    not_op:
      write('not_op');

    {******************************}
    { boolean relational operators }
    {******************************}
    boolean_equal:
      write('boolean_equal');
    boolean_not_equal:
      write('boolean_not_equal');

    {***************************}
    { char relational operators }
    {***************************}
    char_equal:
      write('char_equal');
    char_not_equal:
      write('char_not_equal');

    {***************************}
    { byte relational operators }
    {***************************}
    byte_equal:
      write('byte_equal');
    byte_not_equal:
      write('byte_not_equal');
    byte_less_than:
      write('byte_less_than');
    byte_greater_than:
      write('byte_greater_than');
    byte_less_equal:
      write('byte_less_equal');
    byte_greater_equal:
      write('byte_greater_equal');

    {************************************}
    { short integer relational operators }
    {************************************}
    short_equal:
      write('short_equal');
    short_not_equal:
      write('short_not_equal');
    short_less_than:
      write('short_less_than');
    short_greater_than:
      write('short_greater_than');
    short_less_equal:
      write('short_less_equal');
    short_greater_equal:
      write('short_greater_equal');

    {******************************}
    { integer relational operators }
    {******************************}
    integer_equal:
      write('integer_equal');
    integer_not_equal:
      write('integer_not_equal');
    integer_less_than:
      write('integer_less_than');
    integer_greater_than:
      write('integer_greater_than');
    integer_less_equal:
      write('integer_less_equal');
    integer_greater_equal:
      write('integer_greater_equal');

    {***********************************}
    { long integer relational operators }
    {***********************************}
    long_equal:
      write('long_equal');
    long_not_equal:
      write('long_not_equal');
    long_less_than:
      write('long_less_than');
    long_greater_than:
      write('long_greater_than');
    long_less_equal:
      write('long_less_equal');
    long_greater_equal:
      write('long_greater_equal');

    {*****************************}
    { scalar relational operators }
    {*****************************}
    scalar_equal:
      write('scalar_equal');
    scalar_not_equal:
      write('scalar_not_equal');
    scalar_less_than:
      write('scalar_less_than');
    scalar_greater_than:
      write('scalar_greater_than');
    scalar_less_equal:
      write('scalar_less_equal');
    scalar_greater_equal:
      write('scalar_greater_equal');

    {**********************************************}
    { double precision scalar relational operators }
    {**********************************************}
    double_equal:
      write('double_equal');
    double_not_equal:
      write('double_not_equal');
    double_less_than:
      write('double_less_than');
    double_greater_than:
      write('double_greater_than');
    double_less_equal:
      write('double_less_equal');
    double_greater_equal:
      write('double_greater_equal');

    {*************************************}
    { complex number relational operators }
    {*************************************}
    complex_equal:
      write('complex_equal');
    complex_not_equal:
      write('complex_not_equal');

    {*****************************}
    { vector relational operators }
    {*****************************}
    vector_equal:
      write('vector_equal');
    vector_not_equal:
      write('vector_not_equal');

    {****************}
    { byte operators }
    {****************}
    byte_add:
      write('byte_add');
    byte_subtract:
      write('byte_subtract');
    byte_multiply:
      write('byte_multiply');
    byte_divide:
      write('byte_divide');
    byte_mod:
      write('byte_mod');
    byte_negate:
      write('byte_negate');

    {*************************}
    { short integer operators }
    {*************************}
    short_add:
      write('short_add');
    short_subtract:
      write('short_subtract');
    short_multiply:
      write('short_multiply');
    short_divide:
      write('short_divide');
    short_mod:
      write('short_mod');
    short_negate:
      write('short_negate');

    {*******************}
    { integer operators }
    {*******************}
    integer_add:
      write('integer_add');
    integer_subtract:
      write('integer_subtract');
    integer_multiply:
      write('integer_multiply');
    integer_divide:
      write('integer_divide');
    integer_mod:
      write('integer_mod');
    integer_negate:
      write('integer_negate');

    {************************}
    { long integer operators }
    {************************}
    long_add:
      write('long_add');
    long_subtract:
      write('long_subtract');
    long_multiply:
      write('long_multiply');
    long_divide:
      write('long_divide');
    long_mod:
      write('long_mod');
    long_negate:
      write('long_negate');

    {******************}
    { scalar operators }
    {******************}
    scalar_add:
      write('scalar_add');
    scalar_subtract:
      write('scalar_subtract');
    scalar_multiply:
      write('scalar_multiply');
    scalar_divide:
      write('scalar_divide');
    scalar_negate:
      write('scalar_negate');
    scalar_exponent:
      write('scalar_exponent');

    {***********************************}
    { double precision scalar operators }
    {***********************************}
    double_add:
      write('double_add');
    double_subtract:
      write('double_subtract');
    double_multiply:
      write('double_multiply');
    double_divide:
      write('double_divide');
    double_negate:
      write('double_negate');
    double_exponent:
      write('double_exponent');

    {*******************}
    { complex operators }
    {*******************}
    complex_add:
      write('complex_add');
    complex_subtract:
      write('complex_subtract');
    complex_multiply:
      write('complex_multiply');
    complex_divide:
      write('complex_divide');

    {******************}
    { vector operators }
    {******************}
    vector_add:
      write('vector_add');
    vector_subtract:
      write('vector_subtract');
    vector_scalar_multiply:
      write('vector_scalar_multiply');
    vector_scalar_divide:
      write('vector_scalar_divide');
    vector_vector_multiply:
      write('vector_vector_multiply');
    vector_vector_divide:
      write('vector_vector_divide');
    vector_mod:
      write('vector_mod');
    vector_negate:
      write('vector_negate');
    vector_dot_product:
      write('dot_product');
    vector_cross_product:
      write('cross_product');
    vector_parallel:
      write('vector_parallel');
    vector_perpendicular:
      write('vector_perpendicular');

    {******************************}
    { pointer relational operators }
    {******************************}
    array_ptr_equal:
      write('array_ptr_equal');
    array_ptr_not_equal:
      write('array_ptr_not_equal');
    struct_ptr_equal:
      write('struct_ptr_equal');
    struct_ptr_not_equal:
      write('struct_ptr_not_equal');
    proto_equal:
      write('proto_equal');
    proto_not_equal:
      write('proto_not_equal');
    reference_equal:
      write('reference_equal');
    reference_not_equal:
      write('reference_not_equal');

    {****************************}
    { array relational operators }
    {****************************}
    array_equal:
      write('array_equal');
    array_not_equal:
      write('array_not_equal');
    array_expr_equal:
      write('array_expr_equal');
    array_expr_not_equal:
      write('array_expr_not_equal');

    {********************************}
    { structure relational operators }
    {********************************}
    struct_equal:
      write('struct_equal');
    struct_not_equal:
      write('struct_not_equal');
    struct_expr_equal:
      write('struct_expr_equal');
    struct_expr_not_equal:
      write('struct_expr_not_equal');

    {***************************************************************}
    {                         expression terms                      }
    {***************************************************************}

    {**************************}
    { explicit type conversion }
    {**************************}
    ptr_cast:
      write('ptr_cast');
    type_query:
      write('type_query');

    {********************}
    { tuplet expressions }
    {********************}
    complex_pair:
      write('complex_pair');
    vector_triplet:
      write('vector_triplet');

    {************************}
    { functional expressions }
    {************************}
    user_fn:
      write('user_fn');

    {***************************************************************}
    {                      array expression terms                   }
    {***************************************************************}

    {******************************}
    { enumerated array expressions }
    {******************************}
    boolean_array_expr:
      write('boolean_array_expr');
    char_array_expr:
      write('char_array_expr');

    {***************************}
    { integer array expressions }
    {***************************}
    byte_array_expr:
      write('byte_array_expr');
    short_array_expr:
      write('short_array_expr');
    integer_array_expr:
      write('integer_array_expr');
    long_array_expr:
      write('long_array_expr');

    {**************************}
    { scalar array expressions }
    {**************************}
    scalar_array_expr:
      write('scalar_array_expr');
    double_array_expr:
      write('double_array_expr');
    complex_array_expr:
      write('complex_array_expr');
    vector_array_expr:
      write('vector_array_expr');

    {**********************************}
    { array / struct array expressions }
    {**********************************}
    array_array_expr:
      write('array_array_expr');
    struct_array_expr:
      write('struct_array_expr');
    static_struct_array_expr:
      write('static_struct_array_expr');

    {******************************************}
    { subprogram / reference array expressions }
    {******************************************}
    proto_array_expr:
      write('proto_array_expr');
    reference_array_expr:
      write('reference_array_expr');

    {************************}
    { array expression terms }
    {************************}
    subarray_expr:
      write('subarray_expr');
    element_expr:
      write('element_expr');

    {***************************************************************}
    {                        array dimensioning                     }
    {***************************************************************}

    {*******************************}
    { enumerated array dimensioning }
    {*******************************}
    boolean_array_dim:
      write('boolean_array_dim');
    char_array_dim:
      write('char_array_dim');

    {****************************}
    { integer array dimensioning }
    {****************************}
    byte_array_dim:
      write('byte_array_dim');
    short_array_dim:
      write('short_array_dim');
    integer_array_dim:
      write('integer_array_dim');
    long_array_dim:
      write('long_array_dim');

    {***************************}
    { scalar array dimensioning }
    {***************************}
    scalar_array_dim:
      write('scalar_array_dim');
    double_array_dim:
      write('double_array_dim');
    complex_array_dim:
      write('complex_array_dim');
    vector_array_dim:
      write('vector_array_dim');

    {***********************************}
    { array / struct array dimensioning }
    {***********************************}
    array_array_dim:
      write('array_array_dim');
    struct_array_dim:
      write('struct_array_dim');
    static_struct_array_dim:
      write('static_struct_array_dim');

    {*******************************************}
    { subprogram / reference array dimensioning }
    {*******************************************}
    proto_array_dim:
      write('proto_array_dim');
    reference_array_dim:
      write('reference_array_dim');

    {***************************************************************}
    {                       array dereferencing                     }
    {***************************************************************}

    {********************************}
    { enumerated array dereferencing }
    {********************************}
    boolean_array_deref:
      write('boolean_array_deref');
    char_array_deref:
      write('char_array_deref');

    {*****************************}
    { integer array dereferencing }
    {*****************************}
    byte_array_deref:
      write('byte_array_deref');
    short_array_deref:
      write('short_array_deref');
    integer_array_deref:
      write('integer_array_deref');
    long_array_deref:
      write('long_array_deref');

    {****************************}
    { scalar array dereferencing }
    {****************************}
    scalar_array_deref:
      write('scalar_array_deref');
    double_array_deref:
      write('double_array_deref');
    complex_array_deref:
      write('complex_array_deref');
    vector_array_deref:
      write('vector_array_deref');

    {************************************}
    { array / struct array dereferencing }
    {************************************}
    array_array_deref:
      write('array_array_deref');
    struct_array_deref:
      write('struct_array_deref');
    static_struct_array_deref:
      write('static_struct_array_deref');

    {********************************************}
    { subprogram / reference array dereferencing }
    {********************************************}
    proto_array_deref:
      write('proto_array_deref');
    reference_array_deref:
      write('reference_array_deref');

    {***************************************************************}
    {                   array subrange expressions                  }
    {***************************************************************}

    {****************************}
    { enumerated array subranges }
    {****************************}
    boolean_array_subrange:
      write('boolean_array_subrange');
    char_array_subrange:
      write('char_array_subrange');

    {*************************}
    { integer array subranges }
    {*************************}
    byte_array_subrange:
      write('byte_array_subrange');
    short_array_subrange:
      write('short_array_subrange');
    integer_array_subrange:
      write('integer_array_subrange');
    long_array_subrange:
      write('long_array_subrange');

    {************************}
    { scalar array subranges }
    {************************}
    scalar_array_subrange:
      write('scalar_array_subrange');
    double_array_subrange:
      write('double_array_subrange');
    complex_array_subrange:
      write('complex_array_subrange');
    vector_array_subrange:
      write('vector_array_subrange');

    {********************************}
    { array / struct array subranges }
    {********************************}
    array_array_subrange:
      write('array_array_subrange');
    struct_array_subrange:
      write('struct_array_subrange');
    static_struct_array_subrange:
      write('static_struct_array_subrange');

    {****************************************}
    { subprogram / reference array subranges }
    {****************************************}
    proto_array_subrange:
      write('proto_array_subrange');
    reference_array_subrange:
      write('reference_array_subrange');

    {*******************************************}
    { implicit references used in array assigns }
    {*******************************************}
    array_base:
      write('array_base');

    {***************************************************************}
    {                   structure expression terms                  }
    {***************************************************************}

    {***********************}
    { structure expressions }
    {***********************}
    struct_expr:
      write('struct_expr');

    {**********************}
    { structure allocation }
    {**********************}
    struct_new:
      write('struct_new');

    {*************************}
    { structure dereferencing }
    {*************************}
    struct_deref:
      write('struct_deref');
    struct_offset:
      write('struct_offset');
    field_deref:
      write('field_deref');
    field_offset:
      write('field_offset');

    {***********************************************}
    { implicit references used in structure assigns }
    {***********************************************}
    struct_base:
      write('struct_base');
    static_struct_base:
      write('static_struct_base');

    {***************************************************************}
    {                      expression terminals        	            }
    {***************************************************************}

    {***********************************}
    { user defined variable identifiers }
    {***********************************}
    global_identifier:
      write('global_identifier');
    local_identifier:
      write('local_identifier');
    nested_identifier:
      write('nested_identifier');

    {*******************************}
    { user defined type identifiers }
    {*******************************}
    field_identifier:
      write('field_identifier');

    {*************************}
    { most recent addr caches }
    {*************************}
    itself:
      write('itself');
    new_itself:
      write('new_itself');
    implicit_expr:
      write('implicit_expr');

    {**********************}
    { addressing operators }
    {**********************}
    address_op:
      write('address_op');
    deref_op:
      write('deref_op');

    {***************************************************************}
    {                      expression literals        	            }
    {***************************************************************}

    {*********************}
    { enumerated literals }
    {*********************}
    true_val:
      write('true_val');
    false_val:
      write('false_val');
    char_lit:
      write('char_lit');
    enum_lit:
      write('enum_lit');

    {******************}
    { integer literals }
    {******************}
    byte_lit:
      write('byte_lit');
    short_lit:
      write('short_lit');
    integer_lit:
      write('integer_lit');
    long_lit:
      write('long_lit');

    {*****************}
    { scalar literals }
    {*****************}
    scalar_lit:
      write('scalar_lit');
    double_lit:
      write('double_lit');
    complex_lit:
      write('complex_lit');
    vector_lit:
      write('vector_lit');

    {******************************}
    { array and structure literals }
    {******************************}
    nil_array:
      write('nil_array');
    nil_struct:
      write('nil_struct');
    nil_proto:
      write('nil_proto');
    nil_reference:
      write('nil_reference');

    {*****************************}
    { memory allocation functions }
    {*****************************}
    new_struct_fn:
      write('new_struct_fn');
    dim_array_fn:
      write('dim_array_fn');

    {*******************}
    { special functions }
    {*******************}
    min_fn:
      write('min_fn');
    max_fn:
      write('max_fn');
    num_fn:
      write('num_fn');

    {************************************}
    { implicit integeral type conversion }
    {************************************}
    byte_to_short:
      write('byte_to_short');
    short_to_integer:
      write('short_to_integer');
    integer_to_long:
      write('integer_to_long');
    integer_to_scalar:
      write('integer_to_scalar');
    long_to_scalar:
      write('long_to_scalar');
    long_to_double:
      write('long_to_double');

    {*********************************}
    { implicit scalar type conversion }
    {*********************************}
    scalar_to_double:
      write('scalar_to_double');
    scalar_to_complex:
      write('scalar_to_complex');

    {****************************}
    { vector component operators }
    {****************************}
    vector_x:
      write('vector_x');
    vector_y:
      write('vector_y');
    vector_z:
      write('vector_z');

  end; {case}
end; {procedure Write_expr_kind}


initialization
  Init_expr_sets;

  {***********************}
  { initialize free lists }
  {***********************}
  expr_free_list := nil;
  expr_info_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  expr_block_ptr := nil;
  expr_counter := 0;

  expr_info_block_ptr := nil;
  expr_info_counter := 0;
end.
