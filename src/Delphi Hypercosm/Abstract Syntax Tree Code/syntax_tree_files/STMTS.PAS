unit stmts;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               stmts                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The stmts module defines all of the expressions         }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  new_memory, stmt_attributes, decl_attributes, comments, arrays, exprs,
  instructs;


const
  switch_array_size = 256;


  {***************************************************************}
  {           Simulation / Modelling Programming Language         }
  {                   SMPL (pronounced 'simple')                  }
  {***************************************************************}
  {                           statements                          }
  {***************************************************************}
type
  stmt_kind_type = (

    {***********************}
    { null or nop statement }
    {***********************}
    null_stmt,

    {***************************************************************}
    {                     assignment statements                     }
    {***************************************************************}

    {**********************************}
    { enumerated assignment statements }
    {**********************************}
    boolean_assign, char_assign,

    {*******************************}
    { integer assignment statements }
    {*******************************}
    byte_assign, short_assign, integer_assign, long_assign,

    {******************************}
    { scalar assignment statements }
    {******************************}
    scalar_assign, double_assign, complex_assign, vector_assign,

    {*********************************}
    { reference assignment statements }
    {*********************************}
    array_ptr_assign, struct_ptr_assign, proto_assign, reference_assign,

    {***************************************************************}
    {                  array assignment statements                  }
    {***************************************************************}

    {****************************************}
    { enumerated array assignment statements }
    {****************************************}
    boolean_array_assign, char_array_assign,

    {*************************************}
    { integer array assignment statements }
    {*************************************}
    byte_array_assign, short_array_assign, integer_array_assign,
    long_array_assign,

    {************************************}
    { scalar array assignment statements }
    {************************************}
    scalar_array_assign, double_array_assign, complex_array_assign,
    vector_array_assign,

    {***************************************}
    { reference array assignment statements }
    {***************************************}
    array_array_assign, struct_array_assign, static_struct_array_assign,
    proto_array_assign, reference_array_assign,

    {********************************}
    { subarray assignment statements }
    {********************************}
    subarray_assign,

    {***************************************************************}
    {             array expression assignment statements            }
    {***************************************************************}

    {****************************************}
    { enumerated array assignment statements }
    {****************************************}
    boolean_array_expr_assign, char_array_expr_assign,

    {*************************************}
    { integer array assignment statements }
    {*************************************}
    byte_array_expr_assign, short_array_expr_assign, integer_array_expr_assign,
    long_array_expr_assign,

    {************************************}
    { scalar array assignment statements }
    {************************************}
    scalar_array_expr_assign, double_array_expr_assign,
    complex_array_expr_assign, vector_array_expr_assign,

    {***************************************}
    { reference array assignment statements }
    {***************************************}
    array_array_expr_assign, struct_array_expr_assign,
    static_struct_array_expr_assign, proto_array_expr_assign,
    reference_array_expr_assign,

    {********************************}
    { subarray assignment statements }
    {********************************}
    subarray_expr_assign,

    {***************************************************************}
    {                structure assignment statements                }
    {***************************************************************}

    {******************************}
    { struct assignment statements }
    {******************************}
    struct_assign, struct_base_assign, struct_expr_assign,
    struct_expr_ptr_assign,

    {***************************************************************}
    {                        logical statements                     }
    {***************************************************************}

    {************************}
    { conditional statements }
    {************************}
    if_then_else, case_char_stmt, case_enum_stmt,

    {********************}
    { looping statements }
    {********************}
    while_loop, for_loop, for_each, for_each_loop, for_each_list,

    {***************************************************************}
    {                        control statements                     }
    {***************************************************************}

    {*************************}
    { flow control statements }
    {*************************}
    break_stmt, continue_stmt, loop_label_stmt, return_stmt, exit_stmt,

    {***************************************************************}
    {                     function return statements                }
    {***************************************************************}

    {***************************************}
    { enumerated function return statements }
    {***************************************}
    boolean_answer, char_answer,

    {************************************}
    { integer function return statements }
    {************************************}
    byte_answer, short_answer, integer_answer, long_answer,

    {***********************************}
    { scalar function return statements }
    {***********************************}
    scalar_answer, double_answer, complex_answer, vector_answer,

    {**************************************}
    { reference function return statements }
    {**************************************}
    array_ptr_answer, struct_ptr_answer, proto_answer, reference_answer,

    {********************}
    { scoping statements }
    {********************}
    with_stmt,

    {***************************************************************}
    {                    memory allocation statements               }
    {***************************************************************}

    {***************************************}
    { memory explicit allocation statements }
    {***************************************}
    dim_stmt, new_struct_stmt,

    {********************************}
    { memory reallocation statements }
    {********************************}
    redim_stmt, renew_struct_stmt,

    {********************************}
    { memory deallocation statements }
    {********************************}
    implicit_free_array_stmt, implicit_free_struct_stmt,
    implicit_free_reference_stmt, implicit_free_params_stmt,

    {***************************************************************}
    {                      subprogram call statements               }
    {***************************************************************}

    {*********************}
    { built in statements }
    {*********************}
    built_in_stmt,

    {*****************************************}
    { user defined subprogram call statements }
    {*****************************************}
    static_method_stmt, dynamic_method_stmt, interface_method_stmt,
    proto_method_stmt);


type
  stmt_kind_set_type = set of stmt_kind_type;


  {*********************************}
  { auxillary statement information }
  {*********************************}
  stmt_info_ptr_type = ^stmt_info_type;
  stmt_info_type = record
    {***********************************}
    { compile time semantic information }
    {***********************************}
    stmt_attributes_ptr: stmt_attributes_ptr_type;

    {*********************************}
    { compile time syntax information }
    {*********************************}
    comments_ptr: comments_ptr_type; { line and block comments }
    stmt_number: integer; { order of stmt in a multiple stmt }
    implicit_method: boolean;

    {********************************}
    { run time debugging information }
    {********************************}
    line_number: integer; { line number of stmt in source text }

    {********************************************}
    { syntax tree statement which uses this info }
    {********************************************}
    stmt_ref: forward_stmt_ref_type;

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: stmt_info_ptr_type;
  end; {stmt_info_type}


  {************************************}
  { the abstract syntax tree statement }
  {************************************}
  stmt_ptr_type = ^stmt_type;
  stmt_ref_type = stmt_ptr_type;


  {********************************************************}
  { a ref type is like a ptr type except that a type ref   }
  { is a secondary reference to the type node and hence,   }
  { is not responsible for allocating or freeing the node. }
  {********************************************************}
  forward_code_ref_type = ptr_type;
  forward_decl_ptr_type = ptr_type;


  {********************************************}
  { records of case constants and their values }
  {********************************************}
  case_constant_ptr_type = ^case_constant_type;
  case_constant_type = record
    case_expr_ptr: expr_ptr_type;
    value: integer;
    next: case_constant_ptr_type;
  end; {case_constant_type}


  {*******************************************}
  { declarations and statements for each case }
  {*******************************************}
  switch_case_ptr_type = ^switch_case_type;
  switch_case_type = record
    case_decls_ptr: forward_decl_ptr_type;
    case_stmts_ptr: stmt_ptr_type;
    next: switch_case_ptr_type;
  end; {switch_case_type}


  {*******************************************}
  { array of ptrs to statements for case stmt }
  {*******************************************}
  switch_array_ptr_type = ^switch_array_type;
  switch_array_type = record
    switch_case_array: array[0..switch_array_size] of switch_case_ptr_type;
    next: switch_array_ptr_type;
  end; {switch_array_type}


  stmt_data_ptr_type = ^stmt_data_type;
  stmt_data_type = record
    shader_stmt_ptr: stmt_ptr_type;
    edge_shader_stmt_ptr: stmt_ptr_type;
    next: stmt_data_ptr_type;
  end; {stmt_data_type}


  {******************************************************}
  { Note:                                                }
  { the names 'expr_ptr', 'stmt_ptr' and 'decl_ptr' are  }
  { intentionally not used as fields so that they may be }
  { used as locals inside of a 'with stmt_ptr^' block.   }
  {                                                      }
  { Otherwise be wary of 'with stmt_ptr^' blocks because }
  { the stmt node has so many fields that an identifier  }
  { clash may easily cause a misunderstanding not found  }
  { by the compiler.                                     }
  {******************************************************}
  stmt_type = record
    next: stmt_ptr_type;
    stmt_info_ptr: stmt_info_ptr_type;
    stmt_index: integer;

    case kind: stmt_kind_type of

      {***********************}
      { null or nop statement }
      {***********************}
      null_stmt: (
        );

      {***************************************************************}
      {                     assignment statements                     }
      {***************************************************************}

      {**********************************}
      { enumerated assignment statements }
      {**********************************}
      boolean_assign, char_assign,

      {*******************************}
      { integer assignment statements }
      {*******************************}
      byte_assign, short_assign, integer_assign, long_assign,

      {******************************}
      { scalar assignment statements }
      {******************************}
      scalar_assign, double_assign, complex_assign, vector_assign,

      {*********************************}
      { reference assignment statements }
      {*********************************}
      array_ptr_assign, struct_ptr_assign, proto_assign, reference_assign: (
        lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
        static_level: integer;
        );

      {***************************************************************}
      {                  array assignment statements                  }
      {***************************************************************}

      {****************************************}
      { enumerated array assignment statements }
      {****************************************}
      boolean_array_assign, char_array_assign,

      {*************************************}
      { integer array assignment statements }
      {*************************************}
      byte_array_assign, short_array_assign, integer_array_assign,
        long_array_assign,

      {************************************}
      { scalar array assignment statements }
      {************************************}
      scalar_array_assign, double_array_assign, complex_array_assign,
        vector_array_assign,

      {***************************************}
      { reference array assignment statements }
      {***************************************}
      array_array_assign, struct_array_assign, static_struct_array_assign,
        proto_array_assign, reference_array_assign: (
        lhs_array_subrange_ptr, rhs_array_subrange_ptr: array_subrange_ptr_type;
        array_assign_bounds_list_ref: array_bounds_list_ref_type;
        array_assign_stmt_ptr: stmt_ptr_type;

        {******************************************************}
        { structure array implicit allocation / initialization }
        {******************************************************}
        array_struct_new_ptr: expr_ptr_type;

        {************************************************}
        { static structure array implicit initialization }
        {************************************************}
        array_static_struct_type_ref: forward_type_ref_type;
        );
      subarray_assign: (
        lhs_subarray_subrange_ptr, rhs_subarray_subrange_ptr:
        array_subrange_ptr_type;
        subarray_assign_stmt_ptr: stmt_ptr_type;
        );

      {***************************************************************}
      {             array expression assignment statements            }
      {***************************************************************}

      {****************************************}
      { enumerated array assignment statements }
      {****************************************}
      boolean_array_expr_assign, char_array_expr_assign,

      {*************************************}
      { integer array assignment statements }
      {*************************************}
      byte_array_expr_assign, short_array_expr_assign,
        integer_array_expr_assign,
        long_array_expr_assign,

      {************************************}
      { scalar array assignment statements }
      {************************************}
      scalar_array_expr_assign, double_array_expr_assign,
        complex_array_expr_assign, vector_array_expr_assign,

      {***************************************}
      { reference array assignment statements }
      {***************************************}
      array_array_expr_assign, struct_array_expr_assign,
        static_struct_array_expr_assign, proto_array_expr_assign,
        reference_array_expr_assign: (
        array_expr_subrange_ptr: array_subrange_ptr_type;
        array_expr_element_ref: expr_ref_type;
        array_expr_bounds_list_ref: array_bounds_list_ref_type;
        array_expr_assign_stmt_ptr: stmt_ptr_type;

        {******************************************************}
        { structure array implicit allocation / initialization }
        {******************************************************}
        array_expr_struct_new_ptr: expr_ptr_type;

        {************************************************}
        { static structure array implicit initialization }
        {************************************************}
        array_expr_static_struct_type_ref: forward_type_ref_type;
        );
      subarray_expr_assign: (
        subarray_expr_subrange_ptr: array_subrange_ptr_type;
        subarray_expr_assign_stmt_ptr: stmt_ptr_type;
        subarray_expr_element_ref: expr_ref_type;
        );

      {******************************}
      { struct assignment statements }
      {******************************}
      struct_assign: (
        lhs_struct_expr_ptr, rhs_struct_expr_ptr: expr_ptr_type;
        assign_struct_type_ref: forward_type_ref_type;
        );
      struct_base_assign: (
        lhs_struct_base_ptr, rhs_struct_base_ptr: expr_ptr_type;
        parent_base_assign_ref: stmt_ref_type;
        field_assign_stmts_ptr: stmt_ptr_type;
        );

      {************************}
      { conditional statements }
      {************************}
      if_then_else: (
        if_expr_ptr: expr_ptr_type;
        then_decls_ptr: forward_decl_ptr_type;
        then_stmts_ptr: stmt_ptr_type;
        else_decls_ptr: forward_decl_ptr_type;
        else_stmts_ptr: stmt_ptr_type;
        elseif_contraction: boolean;
        );
      case_char_stmt, case_enum_stmt: (
        switch_expr_ptr: expr_ptr_type;
        switch_array_ptr: switch_array_ptr_type;
        switch_else_decls_ptr: forward_decl_ptr_type;
        switch_else_stmts_ptr: stmt_ptr_type;
        switch_case_constant_ptr: case_constant_ptr_type;
        );

      {********************}
      { looping statements }
      {********************}
      while_loop: (
        while_expr_ptr: expr_ptr_type;
        while_decls_ptr: forward_decl_ptr_type;
        while_stmts_ptr: stmt_ptr_type;
        );
      for_loop: (
        counter_decl_ptr: forward_decl_ptr_type;
        start_expr_ptr, end_expr_ptr: expr_ptr_type;
        for_decls_ptr: forward_decl_ptr_type;
        for_stmts_ptr: stmt_ptr_type;
        );
      for_each: (
        each_index_decl_ptr: forward_decl_ptr_type;
        each_array_ptr: expr_ptr_type;
        each_decls_ptr: forward_decl_ptr_type;
        each_stmts_ptr: stmt_ptr_type;
        );
      for_each_loop: (
        for_each_array_subrange_ptr: array_subrange_ptr_type;
        loop_stmts_ptr: stmt_ptr_type;
        );
      for_each_list: (
        each_struct_decl_ptr: forward_decl_ptr_type;
        each_next_expr_ptr: expr_ptr_type;
        each_list_expr_ptr: expr_ptr_type;
        list_decls_ptr: forward_decl_ptr_type;
        list_stmts_ptr: stmt_ptr_type;
        );

      {*************************}
      { flow control statements }
      {*************************}
      break_stmt, continue_stmt: (
        label_index: integer;
        enclosing_loop_ref: stmt_ref_type;
        );
      loop_label_stmt: (
        loop_label_index: integer;
        loop_stmt_ptr: stmt_ptr_type;
        );
      return_stmt, exit_stmt: (
        );

      {***************************************************************}
      {                     function return statements                }
      {***************************************************************}

      {***************************************}
      { enumerated function return statements }
      {***************************************}
      boolean_answer, char_answer,

      {************************************}
      { integer function return statements }
      {************************************}
      byte_answer, short_answer, integer_answer, long_answer,

      {***********************************}
      { scalar function return statements }
      {***********************************}
      scalar_answer, double_answer, complex_answer, vector_answer,

      {**************************************}
      { reference function return statements }
      {**************************************}
      array_ptr_answer, struct_ptr_answer, proto_answer, reference_answer: (
        answer_expr_ptr: expr_ptr_type;
        );

      {********************}
      { scoping statements }
      {********************}
      with_stmt: (
        with_expr_ptr: expr_ptr_type;
        with_decls_ptr: forward_decl_ptr_type;
        with_stmts_ptr: stmt_ptr_type;
        );

      {******************************}
      { memory allocation statements }
      {******************************}
      dim_stmt, redim_stmt: (
        dim_data_ptr: expr_ptr_type;
        dim_expr_ptr: expr_ptr_type;
        );
      new_struct_stmt, renew_struct_stmt: (
        new_data_ptr: expr_ptr_type;
        new_expr_ptr: expr_ptr_type;
        );

      {********************************}
      { memory deallocation statements }
      {********************************}
      implicit_free_array_stmt: (
        free_array_expr_ref: expr_ref_type;
        );
      implicit_free_struct_stmt: (
        free_struct_expr_ref: expr_ref_type;
        );
      implicit_free_reference_stmt: (
        free_reference_expr_ref: expr_ref_type;
        );
      implicit_free_params_stmt: (
        free_decl_ref: forward_decl_ref_type;
        );

      {*********************}
      { built in statements }
      {*********************}
      built_in_stmt: (
        instruct_ptr: instruct_ptr_type;
        );

      {*****************************************}
      { user defined subprogram call statements }
      {*****************************************}
      static_method_stmt, dynamic_method_stmt, interface_method_stmt,
        proto_method_stmt: (
        stmt_code_ref: forward_code_ref_type;
        stmt_name_ptr: expr_ptr_type;
        implicit_stmts_ptr: stmt_ptr_type;
        param_assign_stmts_ptr, param_stmts_ptr: stmt_ptr_type;
        return_assign_stmts_ptr, return_stmts_ptr: stmt_ptr_type;
        stmt_data_ptr: stmt_data_ptr_type;
        );
  end; {stmt_type}


var
  {***********************}
  { useful statement sets }
  {***********************}
  primitive_assign_stmt_set, reference_assign_stmt_set: stmt_kind_set_type;
  array_data_assign_stmt_set, array_expr_assign_stmt_set: stmt_kind_set_type;
  array_assign_stmt_set, struct_assign_stmt_set: stmt_kind_set_type;
  simple_assign_stmt_set, complex_assign_stmt_set: stmt_kind_set_type;
  assign_stmt_set, conditional_stmt_set, looping_stmt_set: stmt_kind_set_type;
  method_stmt_set, decl_stmt_set, answer_stmt_set, return_stmt_set:
  stmt_kind_set_type;
  implicit_free_stmt_set, implicit_stmt_set: stmt_kind_set_type;

  {*******************************}
  { active list of statement info }
  {*******************************}
  active_stmt_info_list: stmt_info_ptr_type;


{*****************************************************}
{ routines for allocating and initializing statements }
{*****************************************************}
function New_stmt(kind: stmt_kind_type): stmt_ptr_type;
procedure Init_stmt(stmt_ptr: stmt_ptr_type;
  kind: stmt_kind_type);
function Copy_stmt(stmt_ptr: stmt_ptr_type): stmt_ptr_type;
function Copy_stmts(stmt_ptr: stmt_ptr_type): stmt_ptr_type;
procedure Free_stmt(var stmt_ptr: stmt_ptr_type);
procedure Free_stmts(var stmt_ptr: stmt_ptr_type);
function Stmt_count: longint;

{***********************************************************}
{ routines for allocating and initializing auxilliary nodes }
{***********************************************************}
function New_switch_array: switch_array_ptr_type;
function New_switch_case: switch_case_ptr_type;
function New_case_constant: case_constant_ptr_type;
function New_stmt_data: stmt_data_ptr_type;

{***************************************}
{ routines for copying auxilliary nodes }
{***************************************}
function Copy_switch_array(switch_array_ptr: switch_array_ptr_type):
  switch_array_ptr_type;
function Copy_switch_case(switch_case_ptr: switch_case_ptr_type):
  switch_case_ptr_type;
function Copy_case_constant(case_constant_ptr: case_constant_ptr_type):
  case_constant_ptr_type;
function Copy_stmt_data(stmt_data_ptr: stmt_data_ptr_type): stmt_data_ptr_type;

{***************************************}
{ routines for freeing auxilliary nodes }
{***************************************}
procedure Free_switch_array(var switch_array_ptr: switch_array_ptr_type);
procedure Free_switch_case(var switch_case_ptr: switch_case_ptr_type);
procedure Free_case_constant(var case_constant_ptr: case_constant_ptr_type);
procedure Free_case_constants(var case_constant_ptr: case_constant_ptr_type);
procedure Free_stmt_data(var stmt_data_ptr: stmt_data_ptr_type);

{**********************************************************}
{ routines for allocating and freeing auxiliiary stmt info }
{**********************************************************}
function New_stmt_info: stmt_info_ptr_type;
procedure Init_stmt_info(stmt_info_ptr: stmt_info_ptr_type);
function Copy_stmt_info(stmt_info_ptr: stmt_info_ptr_type;
  copy_attributes: boolean): stmt_info_ptr_type;
procedure Free_stmt_info(var stmt_info_ptr: stmt_info_ptr_type;
  free_attributes: boolean);
function Stmt_info_count: longint;

{************************************************}
{ routines for manipulating auxilliary stmt info }
{************************************************}
procedure Set_stmt_info(stmt_ptr: stmt_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type);
function Get_stmt_info(stmt_ptr: stmt_ptr_type): stmt_info_ptr_type;

{*********************************************************}
{ routines for dealing with the attributes of a statement }
{*********************************************************}
function Get_stmt_attributes(stmt_ptr: stmt_ptr_type): stmt_attributes_ptr_type;
procedure Set_stmt_attributes(stmt_ptr: stmt_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);

{**********************************}
{ routines for querying statements }
{**********************************}
function Stmts_break(stmt_ptr: stmt_ptr_type): boolean;
function Stmts_return(stmt_ptr: stmt_ptr_type): boolean;
function Stmts_answer(stmt_ptr: stmt_ptr_type): boolean;

{**************************************}
{ routines for writing statement kinds }
{**************************************}
procedure Write_stmt_kind(kind: stmt_kind_type);


implementation
uses
  errors;


{***************************************************************}
{                        array assignments                      }
{***************************************************************}
 {                                                               }
{       Complex array assignments may be created in which       }
{       an expression with multiple subranges may be            }
{       assigned to another expression with corresponding       }
 {       subranges.                                              }
{                                                               }
{       The assignment statement:                               }
{                                                               }
{            thing's a[1..2]'s b[4..5] = c[0..1, 2..3]          }
{                                                               }
{       Will be compiled as:                                    }
{                               |                               }
{                               v                               }
{                        subrange assign                        }
{       /-----------\  |-----------------|                      }
{       | thing's a |<-|  lhs_array_ptr  |                      }
{       \-----------/  |-----------------|  /---\               }
{                      |  rhs_array_ptr  |->| c |               }
{                      |-----------------|  \---/               }
{     /----------------|  lhs_base_ptr   |                      }
{     |                |-----------------|                      }
{     |                |  rhs_base_ptr   |-----------\          }
{     |                |-----------------|           |          }
{     |   /------------| lhs_subrnge_ptr |           |          }
{     |   |            |-----------------|           |          }
{     |   |            | rhs_subrnge_ptr |-------\   |          }
{     |   |            |-----------------|       |   |          }
{     |   |            |subrnge_assgn_ptr|-\     |   |          }
{     |   |            |-----------------| |     |   |          }
{     |   |                                |     |   |          }
{     v   v              subrange assign <-/     |   |          }
{  /----------------\  |-----------------|       |   |          }
{  | base[1..2]'s b |<-|  lhs_array_ptr  |       |   |          }
{  \----------------/  |-----------------|       |   |          }
{                      |  rhs_array_ptr  |->nil  |   |          }
{                      |-----------------|       |   |          }
{                /-----|  lhs_base_ptr   |       |   |          }
{                |     |-----------------|       |   |          }
{                |     |  rhs_base_ptr   |->nil  |   |          }
{                |     |-----------------|       |   |          }
{                |   /-| lhs_subrnge_ptr |       |   |          }
{                |   | |-----------------|       |   |          }
{                |   | | rhs_subrnge_ptr |---\   |   |          }
{                |   | |-----------------|   |   |   |          }
{                |   | |subrnge_assgn_ptr|-\ |   |   |          }
{                |   | |-----------------| | |   |   |          }
{                |   |                     | |   |   |          }
{                |   |   assignment stmt <-/ |   |   |          }
{                v   v  -----------------    v   |   |          }
{               base[4..5]  =  base[0..1, 2..3]; |   |          }
{                               ^   ^            |   |          }
{                               |   \------------/   |          }
{                               \--------------------/          }
{                                                               }
{       Note that in order to construct this structure,         }
{       we must rearrange the syntax tree components            }
{       of the expressions which are passed into the            }
{       assignment.                                             }
{                                                               }
{       The original left hand side expression tree:            }
{                                                               }
{                   thing 's a[1..2]'s b[4..5]                  }
{                                                               }
{                      /-----------------\                      }
{                      | subrange [4..5] |                      }
{                      \-----------------/                      }
{                               | subrange base ptr             }
{                               v                               }
{                      /-----------------\                      }
{                      |  struct deref   |                      }
{                      \-----------------/                      }
{             struct base ptr /   \ field expr ptr              }
{                            /     \                            }
{            /-----------------\ /-----------------\            }
{            | subrange [1..2] | |   field id: b   |            }
{            \-----------------/ \-----------------/            }
{                     | subrange base ptr                       }
{                     v                                         }
{            /-----------------\                                }
{            |  struct deref   |                                }
{            \-----------------/                                }
{   struct base ptr /   \ field expr ptr                        }
{                  /     \                                      }
{  /-----------------\ /-----------------\                      }
{  | local id: thing | |   field id: a   |                      }
{  \-----------------/ \-----------------/                      }
{                                                               }
{***************************************************************}


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  stmt_block_ptr_type = ^stmt_block_type;
  stmt_block_type = array[0..block_size] of stmt_type;

  stmt_info_block_ptr_type = ^stmt_info_block_type;
  stmt_info_block_type = array[0..block_size] of stmt_info_type;


var
  {************}
  { free lists }
  {************}
  stmt_free_list: stmt_ptr_type;
  stmt_info_free_list: stmt_info_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  stmt_block_ptr: stmt_block_ptr_type;
  stmt_counter: longint;

  stmt_info_block_ptr: stmt_info_block_ptr_type;
  stmt_info_counter: longint;

  {*********************************}
  { free lists for auxilliary nodes }
  {*********************************}
  switch_array_free_list: switch_array_ptr_type;
  switch_case_free_list: switch_case_ptr_type;
  case_constant_free_list: case_constant_ptr_type;
  stmt_data_free_list: stmt_data_ptr_type;

  {**************}
  { active lists }
  {**************}
  last_active_stmt_info_ptr: stmt_info_ptr_type;


procedure Init_stmt_sets;
begin
  primitive_assign_stmt_set := [boolean_assign..vector_assign];
  reference_assign_stmt_set := [array_ptr_assign..reference_assign];
  simple_assign_stmt_set := primitive_assign_stmt_set +
    reference_assign_stmt_set;
  array_data_assign_stmt_set := [boolean_array_assign..reference_array_assign,
    subarray_assign];
  array_expr_assign_stmt_set :=
    [boolean_array_expr_assign..reference_array_expr_assign,
    subarray_expr_assign];
  array_assign_stmt_set := array_data_assign_stmt_set +
    array_expr_assign_stmt_set;
  struct_assign_stmt_set := [struct_assign, struct_base_assign,
    struct_expr_assign, struct_expr_ptr_assign];
  complex_assign_stmt_set := array_assign_stmt_set + struct_assign_stmt_set;
  assign_stmt_set := simple_assign_stmt_set + complex_assign_stmt_set;
  conditional_stmt_set := [if_then_else, case_char_stmt, case_enum_stmt];
  looping_stmt_set := [while_loop, for_loop, for_each, for_each_loop,
    for_each_list, loop_label_stmt];
  method_stmt_set := [static_method_stmt, dynamic_method_stmt,
    interface_method_stmt, proto_method_stmt];
  decl_stmt_set := conditional_stmt_set + looping_stmt_set + [with_stmt];
  answer_stmt_set := [boolean_answer..reference_answer];
  return_stmt_set := answer_stmt_set + [return_stmt];
  implicit_free_stmt_set :=
    [implicit_free_array_stmt..implicit_free_params_stmt];
  implicit_stmt_set := [for_each_loop, loop_label_stmt, null_stmt] +
    array_assign_stmt_set;
end; {procedure Init_stmt_sets}


{**********************************************************}
{ routines for allocating and freeing auxiliiary stmt info }
{**********************************************************}


procedure Init_stmt_info(stmt_info_ptr: stmt_info_ptr_type);
begin
  with stmt_info_ptr^ do
    begin
      {**********************************************}
      { initialize compile time semantic information }
      {**********************************************}
      stmt_attributes_ptr := nil;

      {********************************************}
      { initialize compile time syntax information }
      {********************************************}
      comments_ptr := nil;
      stmt_number := 1;
      implicit_method := false;

      {*******************************************}
      { initialize run time debugging information }
      {*******************************************}
      line_number := 0;

      {********************************************}
     { initialize syntax tree statement reference }
     {********************************************}
      stmt_ref := nil;

      {******************************************}
      { initialize links to active or free lists }
      {******************************************}
      prev := nil;
      next := nil;
    end;
end; {procedure Init_stmt_info}


function New_stmt_info: stmt_info_ptr_type;
var
  stmt_info_ptr: stmt_info_ptr_type;
  index: integer;
begin
  {******************************}
  { get stmt info from free list }
  {******************************}
  if stmt_info_free_list <> nil then
    begin
      stmt_info_ptr := stmt_info_free_list;
      stmt_info_free_list := stmt_info_free_list^.next;
    end
  else
    begin
      index := stmt_info_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new stmt info block');
          new(stmt_info_block_ptr);
        end;
      stmt_info_ptr := @stmt_info_block_ptr^[index];
    end;

  {*****************************}
  { increment stmt info counter }
  {*****************************}
  stmt_info_counter := stmt_info_counter + 1;

  {**********************}
  { initialize stmt info }
  {**********************}
  Init_stmt_info(stmt_info_ptr);

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_stmt_info_ptr <> nil then
    begin
      last_active_stmt_info_ptr^.next := stmt_info_ptr;
      stmt_info_ptr^.prev := last_active_stmt_info_ptr;
      last_active_stmt_info_ptr := stmt_info_ptr;
      stmt_info_ptr^.next := nil;
    end
  else
    begin
      active_stmt_info_list := stmt_info_ptr;
      last_active_stmt_info_ptr := stmt_info_ptr;
      stmt_info_ptr^.prev := nil;
      stmt_info_ptr^.next := nil;
    end;

  New_stmt_info := stmt_info_ptr;
end; {function New_stmt_info}


function Copy_stmt_info(stmt_info_ptr: stmt_info_ptr_type;
  copy_attributes: boolean): stmt_info_ptr_type;
var
  new_stmt_info_ptr: stmt_info_ptr_type;
  next, prev: stmt_info_ptr_type;
begin
  if stmt_info_ptr <> nil then
    begin
      new_stmt_info_ptr := New_stmt_info;

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := new_stmt_info_ptr^.next;
      prev := new_stmt_info_ptr^.prev;
      new_stmt_info_ptr^ := stmt_info_ptr^;
      new_stmt_info_ptr^.next := next;
      new_stmt_info_ptr^.prev := prev;

      if copy_attributes then
        with new_stmt_info_ptr^ do
          stmt_attributes_ptr := Copy_stmt_attributes(stmt_attributes_ptr);
    end
  else
    new_stmt_info_ptr := nil;

  Copy_stmt_info := new_stmt_info_ptr;
end; {function Copy_stmt_info}


procedure Free_stmt_info(var stmt_info_ptr: stmt_info_ptr_type;
  free_attributes: boolean);
begin
  if stmt_info_ptr <> nil then
    begin
      if free_attributes then
        Free_stmt_attributes(stmt_info_ptr^.stmt_attributes_ptr);

      {*******************************}
      { link neighbors in active list }
      {*******************************}
      if stmt_info_ptr^.prev <> nil then
        stmt_info_ptr^.prev^.next := stmt_info_ptr^.next
      else
        active_stmt_info_list := stmt_info_ptr^.next;

      if stmt_info_ptr^.next <> nil then
        stmt_info_ptr^.next^.prev := stmt_info_ptr^.prev
      else
        last_active_stmt_info_ptr := stmt_info_ptr^.prev;

      {****************************}
      { add stmt info to free list }
      {****************************}
      stmt_info_ptr^.prev := nil;
      stmt_info_ptr^.next := stmt_info_free_list;
      stmt_info_free_list := stmt_info_ptr;
      stmt_info_ptr := nil;

      {*****************************}
      { decrement stmt info counter }
      {*****************************}
      stmt_info_counter := stmt_info_counter - 1;
    end;
end; {procedure Free_stmt_info}


function Stmt_info_count: longint;
begin
  Stmt_info_count := stmt_info_counter;
end; {function Stmt_info_count}


{************************************************}
{ routines for manipulating auxilliary stmt info }
{************************************************}


procedure Set_stmt_info(stmt_ptr: stmt_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type);
begin
  {************************************}
  { link statement and its information }
  {************************************}
  stmt_ptr^.stmt_info_ptr := stmt_info_ptr;
  if stmt_info_ptr <> nil then
    stmt_info_ptr^.stmt_ref := forward_stmt_ref_type(stmt_ptr);

  {***********************************}
  { link statement and its attributes }
  {***********************************}
  if stmt_info_ptr <> nil then
    Set_stmt_attributes(stmt_ptr, stmt_info_ptr^.stmt_attributes_ptr);
end; {procedure Set_stmt_info}


function Get_stmt_info(stmt_ptr: stmt_ptr_type): stmt_info_ptr_type;
begin
  if stmt_ptr <> nil then
    Get_stmt_info := stmt_ptr^.stmt_info_ptr
  else
    Get_stmt_info := nil;
end; {function Get_stmt_info}


{*********************************************************}
{ routines for dealing with the attributes of a statement }
{*********************************************************}


procedure Set_stmt_attributes(stmt_ptr: stmt_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if stmt_ptr^.stmt_info_ptr = nil then
    begin
      stmt_info_ptr := New_stmt_info;
      Set_stmt_info(stmt_ptr, stmt_info_ptr);
    end;

  {***********************************}
  { link statement and its attributes }
  {***********************************}
  stmt_ptr^.stmt_info_ptr^.stmt_attributes_ptr := stmt_attributes_ptr;
  if stmt_attributes_ptr <> nil then
    stmt_attributes_ptr^.stmt_ref := forward_stmt_ref_type(stmt_ptr);
end; {procedure Set_stmt_attributes}


function Get_stmt_attributes(stmt_ptr: stmt_ptr_type): stmt_attributes_ptr_type;
var
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  if stmt_ptr <> nil then
    begin
      if stmt_ptr^.stmt_info_ptr <> nil then
        stmt_attributes_ptr := stmt_ptr^.stmt_info_ptr^.stmt_attributes_ptr
      else
        stmt_attributes_ptr := nil;
    end
  else
    stmt_attributes_ptr := nil;

  Get_stmt_attributes := stmt_attributes_ptr;
end; {function Get_stmt_attributes}


{***********************************************************}
{ routines for allocating and initializing auxilliary nodes }
{***********************************************************}


function New_switch_array: switch_array_ptr_type;
var
  switch_array_ptr: switch_array_ptr_type;
  counter: integer;
begin
  {*********************************}
  { get switch array from free list }
  {*********************************}
  if (switch_array_free_list <> nil) then
    begin
      switch_array_ptr := switch_array_free_list;
      switch_array_free_list := switch_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new switch array');
      new(switch_array_ptr);
    end;

  with switch_array_ptr^ do
    begin
      for counter := 0 to switch_array_size do
        switch_case_array[counter] := nil;
      next := nil;
    end;

  New_switch_array := switch_array_ptr;
end; {function New_switch_array}


function New_switch_case: switch_case_ptr_type;
var
  switch_case_ptr: switch_case_ptr_type;
begin
  {********************************}
  { get switch case from free list }
  {********************************}
  if (switch_case_free_list <> nil) then
    begin
      switch_case_ptr := switch_case_free_list;
      switch_case_free_list := switch_case_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new switch case');
      new(switch_case_ptr);
    end;

  with switch_case_ptr^ do
    begin
      case_decls_ptr := nil;
      case_stmts_ptr := nil;
      next := nil;
    end;

  New_switch_case := switch_case_ptr;
end; {function New_switch_case}


function New_case_constant: case_constant_ptr_type;
var
  case_constant_ptr: case_constant_ptr_type;
begin
  {**********************************}
  { get case constant from free list }
  {**********************************}
  if (case_constant_free_list <> nil) then
    begin
      case_constant_ptr := case_constant_free_list;
      case_constant_free_list := case_constant_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new case constant');
      new(case_constant_ptr);
    end;

  case_constant_ptr^.case_expr_ptr := nil;
  case_constant_ptr^.value := 0;
  case_constant_ptr^.next := nil;

  New_case_constant := case_constant_ptr;
end; {function New_case_constant}


function New_stmt_data: stmt_data_ptr_type;
var
  stmt_data_ptr: stmt_data_ptr_type;
begin
  {******************************}
  { get stmt data from free list }
  {******************************}
  if (stmt_data_free_list <> nil) then
    begin
      stmt_data_ptr := stmt_data_free_list;
      stmt_data_free_list := stmt_data_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new stmt data');
      new(stmt_data_ptr);
    end;

  with stmt_data_ptr^ do
    begin
      shader_stmt_ptr := nil;
      edge_shader_stmt_ptr := nil;
      next := nil;
    end;

  New_stmt_data := stmt_data_ptr;
end; {function New_stmt_data}


{*****************************************************}
{ routines for allocating and initializing statements }
{*****************************************************}


procedure Init_stmt(stmt_ptr: stmt_ptr_type;
  kind: stmt_kind_type);
begin
  {********************}
  { init common fields }
  {********************}
  stmt_ptr^.kind := kind;
  stmt_ptr^.stmt_info_ptr := nil;
  stmt_ptr^.stmt_index := 0;
  stmt_ptr^.next := nil;

  {**********************}
  { init specific fields }
  {**********************}
  with stmt_ptr^ do
    case kind of

      {***********************}
      { null or nop statement }
      {***********************}
      null_stmt:
        ;

      {******************************}
      { simple assignment statements }
      {******************************}
      boolean_assign..reference_assign:
        begin
          lhs_data_ptr := nil;
          rhs_expr_ptr := nil;
          static_level := 0;
        end;

      {*****************************}
      { array assignment statements }
      {*****************************}
      boolean_array_assign..reference_array_assign:
        begin
          lhs_array_subrange_ptr := nil;
          rhs_array_subrange_ptr := nil;
          array_assign_bounds_list_ref := nil;
          array_assign_stmt_ptr := nil;

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          array_struct_new_ptr := nil;

          {************************************************}
          { static structure array implicit initialization }
          {************************************************}
          array_static_struct_type_ref := nil;
        end;
      subarray_assign:
        begin
          lhs_subarray_subrange_ptr := nil;
          rhs_subarray_subrange_ptr := nil;
          subarray_assign_stmt_ptr := nil;
        end;

      {****************************************}
      { array expression assignment statements }
      {****************************************}
      boolean_array_expr_assign..reference_array_expr_assign:
        begin
          array_expr_subrange_ptr := nil;
          array_expr_element_ref := nil;
          array_expr_bounds_list_ref := nil;
          array_expr_assign_stmt_ptr := nil;

          {******************************************************}
          { structure array implicit allocation / initialization }
          {******************************************************}
          array_expr_struct_new_ptr := nil;

          {************************************************}
          { static structure array implicit initialization }
          {************************************************}
          array_expr_static_struct_type_ref := nil;
        end;
      subarray_expr_assign:
        begin
          subarray_expr_subrange_ptr := nil;
          subarray_expr_assign_stmt_ptr := nil;
          subarray_expr_element_ref := nil;
        end;

      {******************************}
      { struct assignment statements }
      {******************************}
      struct_assign:
        begin
          lhs_struct_expr_ptr := nil;
          rhs_struct_expr_ptr := nil;
          assign_struct_type_ref := nil;
        end;
      struct_base_assign:
        begin
          lhs_struct_base_ptr := nil;
          rhs_struct_base_ptr := nil;
          parent_base_assign_ref := nil;
          field_assign_stmts_ptr := nil;
        end;

      {************************}
      { conditional statements }
      {************************}
      if_then_else:
        begin
          if_expr_ptr := nil;
          then_decls_ptr := nil;
          then_stmts_ptr := nil;
          else_decls_ptr := nil;
          else_stmts_ptr := nil;
          elseif_contraction := false;
        end;
      case_char_stmt, case_enum_stmt:
        begin
          switch_expr_ptr := nil;
          switch_array_ptr := nil;
          switch_else_decls_ptr := nil;
          switch_else_stmts_ptr := nil;
          switch_case_constant_ptr := nil;
        end;

      {********************}
      { looping statements }
      {********************}
      while_loop:
        begin
          while_expr_ptr := nil;
          while_decls_ptr := nil;
          while_stmts_ptr := nil;
        end;
      for_loop:
        begin
          counter_decl_ptr := nil;
          start_expr_ptr := nil;
          end_expr_ptr := nil;
          for_decls_ptr := nil;
          for_stmts_ptr := nil;
        end;
      for_each:
        begin
          each_index_decl_ptr := nil;
          each_array_ptr := nil;
          each_decls_ptr := nil;
          each_stmts_ptr := nil;
        end;
      for_each_loop:
        begin
          for_each_array_subrange_ptr := nil;
          loop_stmts_ptr := nil;
        end;
      for_each_list:
        begin
          each_struct_decl_ptr := nil;
          each_next_expr_ptr := nil;
          each_list_expr_ptr := nil;
          list_decls_ptr := nil;
          list_stmts_ptr := nil;
        end;

      {*************************}
      { flow control statements }
      {*************************}
      break_stmt, continue_stmt:
        begin
          label_index := 0;
          enclosing_loop_ref := nil;
        end;
      loop_label_stmt:
        begin
          loop_label_index := 0;
          loop_stmt_ptr := nil;
        end;
      return_stmt, exit_stmt:
        ;
      boolean_answer..reference_answer:
        answer_expr_ptr := nil;

      {********************}
      { scoping statements }
      {********************}
      with_stmt:
        begin
          with_expr_ptr := nil;
          with_decls_ptr := nil;
          with_stmts_ptr := nil;
        end;

      {*************************}
      { memory allocation stmts }
      {*************************}
      dim_stmt, redim_stmt:
        begin
          dim_data_ptr := nil;
          dim_expr_ptr := nil;
        end;
      new_struct_stmt, renew_struct_stmt:
        begin
          new_data_ptr := nil;
          new_expr_ptr := nil;
        end;

      {********************************}
      { memory deallocation statements }
      {********************************}
      implicit_free_array_stmt:
        free_array_expr_ref := nil;
      implicit_free_struct_stmt:
        free_struct_expr_ref := nil;
      implicit_free_reference_stmt:
        free_reference_expr_ref := nil;
      implicit_free_params_stmt:
        free_decl_ref := nil;

      {*********************}
      { built in statements }
      {*********************}
      built_in_stmt:
        instruct_ptr := nil;

      {*****************************************}
      { user defined subprogram call statements }
      {*****************************************}
      static_method_stmt, dynamic_method_stmt, interface_method_stmt,
        proto_method_stmt:
        begin
          stmt_code_ref := nil;
          stmt_name_ptr := nil;

          implicit_stmts_ptr := nil;
          param_assign_stmts_ptr := nil;
          param_stmts_ptr := nil;
          return_assign_stmts_ptr := nil;
          return_stmts_ptr := nil;

          stmt_data_ptr := nil;
        end;

    end; {case}
end; {procedure Init_stmt}


function New_stmt(kind: stmt_kind_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  index: integer;
begin
  {******************************}
  { get stmt node from free list }
  {******************************}
  if stmt_free_list <> nil then
    begin
      stmt_ptr := stmt_free_list;
      stmt_free_list := stmt_free_list^.next;
    end
  else
    begin
      index := stmt_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new stmt block');
          new(stmt_block_ptr);
        end;
      stmt_ptr := @stmt_block_ptr^[index];
    end;

  {************************}
  { increment stmt counter }
  {************************}
  stmt_counter := stmt_counter + 1;

  {**********************}
  { initialize stmt node }
  {**********************}
  Init_stmt(stmt_ptr, kind);

  New_stmt := stmt_ptr;
end; {function New_stmt}


function Stmt_count: longint;
begin
  Stmt_count := stmt_counter;
end; {function Stmt_count}


{***************************************}
{ routines for copying auxilliary nodes }
{***************************************}


function Copy_switch_array(switch_array_ptr: switch_array_ptr_type):
  switch_array_ptr_type;
var
  new_switch_array_ptr: switch_array_ptr_type;
begin
  if switch_array_ptr <> nil then
    begin
      new_switch_array_ptr := New_switch_array;
      new_switch_array_ptr^ := switch_array_ptr^;
      new_switch_array_ptr^.next := nil;
    end
  else
    new_switch_array_ptr := nil;

  Copy_switch_array := new_switch_array_ptr;
end; {function Copy_switch_array}


function Copy_switch_case(switch_case_ptr: switch_case_ptr_type):
  switch_case_ptr_type;
var
  new_switch_case_ptr: switch_case_ptr_type;
begin
  if switch_case_ptr <> nil then
    begin
      new_switch_case_ptr := New_switch_case;
      new_switch_case_ptr^ := switch_case_ptr^;
      new_switch_case_ptr^.next := nil;
    end
  else
    new_switch_case_ptr := nil;

  Copy_switch_case := new_switch_case_ptr;
end; {function Copy_switch_case}


function Copy_case_constant(case_constant_ptr: case_constant_ptr_type):
  case_constant_ptr_type;
var
  new_case_constant_ptr: case_constant_ptr_type;
begin
  if case_constant_ptr <> nil then
    begin
      new_case_constant_ptr := New_case_constant;
      new_case_constant_ptr^ := case_constant_ptr^;
      new_case_constant_ptr^.next := nil;
    end
  else
    new_case_constant_ptr := nil;

  Copy_case_constant := new_case_constant_ptr;
end; {function Copy_case_constant}


function Copy_stmt_data(stmt_data_ptr: stmt_data_ptr_type): stmt_data_ptr_type;
var
  new_stmt_data_ptr: stmt_data_ptr_type;
begin
  if stmt_data_ptr <> nil then
    begin
      new_stmt_data_ptr := New_stmt_data;
      new_stmt_data_ptr^ := stmt_data_ptr^;
      new_stmt_data_ptr^.next := nil;
    end
  else
    new_stmt_data_ptr := nil;

  Copy_stmt_data := new_stmt_data_ptr;
end; {function Copy_stmt_data}


{******************************************************}
{ routines for copying statements and associated nodes }
{******************************************************}


function Copy_stmt(stmt_ptr: stmt_ptr_type): stmt_ptr_type;
var
  new_stmt_ptr: stmt_ptr_type;
begin
  if stmt_ptr <> nil then
    begin
      new_stmt_ptr := New_stmt(stmt_ptr^.kind);
      new_stmt_ptr^ := stmt_ptr^;
      new_stmt_ptr^.next := nil;
    end
  else
    new_stmt_ptr := nil;

  Copy_stmt := new_stmt_ptr;
end; {function Copy_stmt}


function Copy_stmts(stmt_ptr: stmt_ptr_type): stmt_ptr_type;
var
  new_stmt_ptr: stmt_ptr_type;
  first_stmt_ptr, last_stmt_ptr: stmt_ptr_type;
begin
  first_stmt_ptr := nil;
  last_stmt_ptr := nil;

  while stmt_ptr <> nil do
    begin
      new_stmt_ptr := Copy_stmt(stmt_ptr);

      {**********************************}
      { add new stmt node to end of list }
      {**********************************}
      if (last_stmt_ptr <> nil) then
        begin
          last_stmt_ptr^.next := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end
      else
        begin
          first_stmt_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end;

      stmt_ptr := stmt_ptr^.next;
    end;

  Copy_stmts := first_stmt_ptr;
end; {function Copy_stmts}


{******************************************************}
{ routines for freeing statements and associated nodes }
{******************************************************}


procedure Free_switch_case(var switch_case_ptr: switch_case_ptr_type);
begin
  if switch_case_ptr <> nil then
    begin
      {******************************}
      { add switch case to free list }
      {******************************}
      switch_case_ptr^.next := switch_case_free_list;
      switch_case_free_list := switch_case_ptr;
      switch_case_ptr := nil;
    end;
end; {procedure Free_switch_case}


procedure Free_switch_array(var switch_array_ptr: switch_array_ptr_type);
begin
  if switch_array_ptr <> nil then
    begin
      {*******************************}
      { add switch array to free list }
      {*******************************}
      switch_array_ptr^.next := switch_array_free_list;
      switch_array_free_list := switch_array_ptr;
      switch_array_ptr := nil;
    end;
end; {procedure Free_switch_array}


procedure Free_case_constant(var case_constant_ptr: case_constant_ptr_type);
begin
  if case_constant_ptr <> nil then
    begin
      {********************************}
      { add case constant to free list }
      {********************************}
      case_constant_ptr^.next := case_constant_free_list;
      case_constant_free_list := case_constant_ptr;
      case_constant_ptr := nil;
    end;
end; {procedure Free_case_constant}


procedure Free_case_constants(var case_constant_ptr: case_constant_ptr_type);
var
  temp: case_constant_ptr_type;
begin
  while (case_constant_ptr <> nil) do
    begin
      temp := case_constant_ptr;
      case_constant_ptr := case_constant_ptr^.next;
      Free_case_constant(temp);
    end;
end; {procedure Free_case_constants}


procedure Free_stmt_data(var stmt_data_ptr: stmt_data_ptr_type);
begin
  if stmt_data_ptr <> nil then
    begin
      {****************************}
      { add stmt data to free list }
      {****************************}
      stmt_data_ptr^.next := stmt_data_free_list;
      stmt_data_free_list := stmt_data_ptr;
      stmt_data_ptr := nil;
    end;
end; {procedure Free_stmt_data}


procedure Free_stmt(var stmt_ptr: stmt_ptr_type);
begin
  if (stmt_ptr <> nil) then
    begin
      {***********************}
      { add stmt to free list }
      {***********************}
      stmt_ptr^.next := stmt_free_list;
      stmt_free_list := stmt_ptr;
      stmt_ptr := nil;

      {************************}
      { decrement stmt counter }
      {************************}
      stmt_counter := stmt_counter - 1;
    end;
end; {procedure Free_stmt}


procedure Free_stmts(var stmt_ptr: stmt_ptr_type);
var
  temp: stmt_ptr_type;
begin
  while (stmt_ptr <> nil) do
    begin
      temp := stmt_ptr;
      stmt_ptr := stmt_ptr^.next;
      Free_stmt(temp);
    end;
end; {procedure Free_stmts}


{**********************************}
{ routines for querying statements }
{**********************************}


function Stmts_break(stmt_ptr: stmt_ptr_type): boolean;
var
  breaks: boolean;
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
  done: boolean;
begin
  breaks := false;

  if stmt_ptr <> nil then
    begin
      {************************************}
      { first, find last statement in list }
      {************************************}
      done := false;
      while (not done) do
        begin
          if stmt_ptr^.next = nil then
            done := true
          else if stmt_ptr^.next^.kind = null_stmt then
            done := true
          else
            stmt_ptr := stmt_ptr^.next;
        end;

      {***********************************************}
      { check to make sure that last statement breaks }
      {***********************************************}
      with stmt_ptr^ do
        if kind in [break_stmt, continue_stmt] + return_stmt_set then
          breaks := true

        else if (kind in conditional_stmt_set) then
          case kind of

            if_then_else:
              begin
                breaks := false;
                if Stmts_break(then_stmts_ptr) then
                  if Stmts_break(else_stmts_ptr) then
                    breaks := true;
              end;

            case_char_stmt, case_enum_stmt:
              begin
                breaks := true;

                case_constant_ptr := switch_case_constant_ptr;
                while (case_constant_ptr <> nil) and breaks do
                  begin
                    switch_case_ptr :=
                      switch_array_ptr^.switch_case_array[case_constant_ptr^.value];
                    if not Stmts_break(switch_case_ptr^.case_stmts_ptr) then
                      breaks := false;
                    case_constant_ptr := case_constant_ptr^.next;
                  end;

                if breaks then
                  if (switch_else_stmts_ptr <> nil) then
                    begin
                      if not Stmts_break(switch_else_stmts_ptr) then
                        breaks := false;
                    end;
              end;

          end
        else
          breaks := false;
    end
  else
    breaks := false;

  Stmts_break := breaks;
end; {function Stmts_break}


function Stmts_return(stmt_ptr: stmt_ptr_type): boolean;
var
  returns: boolean;
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
  done: boolean;
begin
  returns := false;

  if stmt_ptr <> nil then
    begin
      {************************************}
      { first, find last statement in list }
      {************************************}
      done := false;
      while (not done) do
        begin
          if stmt_ptr^.next = nil then
            done := true
          else if stmt_ptr^.next^.kind = null_stmt then
            done := true
          else
            stmt_ptr := stmt_ptr^.next;
        end;

      {************************************************}
      { check to make sure that last statement returns }
      {************************************************}
      with stmt_ptr^ do
        if kind in return_stmt_set then
          returns := true

        else if kind in conditional_stmt_set then
          case kind of

            if_then_else:
              begin
                returns := false;
                if Stmts_return(then_stmts_ptr) then
                  if Stmts_return(else_stmts_ptr) then
                    returns := true;
              end;

            case_char_stmt, case_enum_stmt:
              begin
                returns := true;

                case_constant_ptr := switch_case_constant_ptr;
                while (case_constant_ptr <> nil) and returns do
                  begin
                    switch_case_ptr :=
                      switch_array_ptr^.switch_case_array[case_constant_ptr^.value];
                    if not Stmts_return(switch_case_ptr^.case_stmts_ptr) then
                      returns := false;
                    case_constant_ptr := case_constant_ptr^.next;
                  end;

                if returns then
                  if (switch_else_stmts_ptr <> nil) then
                    begin
                      if not Stmts_return(switch_else_stmts_ptr) then
                        returns := false;
                    end;
              end;

          end
        else
          returns := false;
    end
  else
    returns := false;

  Stmts_return := returns;
end; {function Stmts_return}


function Stmts_answer(stmt_ptr: stmt_ptr_type): boolean;
var
  answers: boolean;
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
  done: boolean;
begin
  answers := false;
  
  if stmt_ptr <> nil then
    begin
      {************************************}
      { first, find last statement in list }
      {************************************}
      done := false;
      while (not done) do
        begin
          if stmt_ptr^.next = nil then
            done := true
          else if stmt_ptr^.next^.kind = null_stmt then
            done := true
          else
            stmt_ptr := stmt_ptr^.next;
        end;

      {************************************************}
      { check to make sure that last statement answers }
      {************************************************}
      with stmt_ptr^ do
        if kind in answer_stmt_set then
          answers := true

        else if kind in conditional_stmt_set then
          case kind of

            if_then_else:
              begin
                answers := false;
                if Stmts_answer(then_stmts_ptr) then
                  if Stmts_answer(else_stmts_ptr) then
                    answers := true;
              end;

            case_char_stmt, case_enum_stmt:
              begin
                answers := true;

                case_constant_ptr := switch_case_constant_ptr;
                while (case_constant_ptr <> nil) and answers do
                  begin
                    switch_case_ptr :=
                      switch_array_ptr^.switch_case_array[case_constant_ptr^.value];
                    if not Stmts_answer(switch_case_ptr^.case_stmts_ptr) then
                      answers := false;
                    case_constant_ptr := case_constant_ptr^.next;
                  end;

                if answers then
                  if (switch_else_stmts_ptr <> nil) then
                    begin
                      if not Stmts_answer(switch_else_stmts_ptr) then
                        answers := false;
                    end;
              end;

          end
        else
          answers := false;
    end
  else
    answers := false;

  Stmts_answer := answers;
end; {function Stmts_answer}


{****************************}
{ routines for writing stmts }
{****************************}


procedure Write_stmt_kind(kind: stmt_kind_type);
begin
  case kind of

    {***********************}
    { null or nop statement }
    {***********************}
    null_stmt:
      write('null_stmt');

    {***************************************************************}
    {                     assignment statements                     }
    {***************************************************************}

    {**********************************}
    { enumerated assignment statements }
    {**********************************}
    boolean_assign:
      write('boolean_assign');
    char_assign:
      write('char_assign');

    {*******************************}
    { integer assignment statements }
    {*******************************}
    byte_assign:
      write('byte_assign');
    short_assign:
      write('short_assign');
    integer_assign:
      write('integer_assign');
    long_assign:
      write('long_assign');

    {******************************}
    { scalar assignment statements }
    {******************************}
    scalar_assign:
      write('scalar_assign');
    double_assign:
      write('double_assign');
    complex_assign:
      write('complex_assign');
    vector_assign:
      write('vector_assign');

    {*********************************}
    { reference assignment statements }
    {*********************************}
    array_ptr_assign:
      write('array_ptr_assign');
    struct_ptr_assign:
      write('struct_ptr_assign');
    proto_assign:
      write('proto_assign');
    reference_assign:
      write('reference_assign');

    {***************************************************************}
    {                  array assignment statements                  }
    {***************************************************************}

    {****************************************}
    { enumerated array assignment statements }
    {****************************************}
    boolean_array_assign:
      write('boolean_array_assign');
    char_array_assign:
      write('char_array_assign');

    {*************************************}
    { integer array assignment statements }
    {*************************************}
    byte_array_assign:
      write('byte_array_assign');
    short_array_assign:
      write('short_array_assign');
    integer_array_assign:
      write('integer_array_assign');
    long_array_assign:
      write('long_array_assign');

    {************************************}
    { scalar array assignment statements }
    {************************************}
    scalar_array_assign:
      write('scalar_array_assign');
    double_array_assign:
      write('double_array_assign');
    complex_array_assign:
      write('complex_array_assign');
    vector_array_assign:
      write('vector_array_assign');

    {***************************************}
    { reference array assignment statements }
    {***************************************}
    array_array_assign:
      write('array_array_assign');
    struct_array_assign:
      write('struct_array_assign');
    static_struct_array_assign:
      write('static_struct_array_assign');
    proto_array_assign:
      write('proto_array_assign');
    reference_array_assign:
      write('reference_array_assign');

    {********************************}
    { subarray assignment statements }
    {********************************}
    subarray_assign:
      write('subarray_assign');

    {***************************************************************}
    {             array expression assignment statements            }
    {***************************************************************}

    {****************************************}
    { enumerated array assignment statements }
    {****************************************}
    boolean_array_expr_assign:
      write('boolean_array_expr_assign');
    char_array_expr_assign:
      write('char_array_expr_assign');

    {*************************************}
    { integer array assignment statements }
    {*************************************}
    byte_array_expr_assign:
      write('byte_array_expr_assign');
    short_array_expr_assign:
      write('short_array_expr_assign');
    integer_array_expr_assign:
      write('integer_array_expr_assign');
    long_array_expr_assign:
      write('long_array_expr_assign');

    {************************************}
    { scalar array assignment statements }
    {************************************}
    scalar_array_expr_assign:
      write('scalar_array_expr_assign');
    double_array_expr_assign:
      write('double_array_expr_assign');
    complex_array_expr_assign:
      write('complex_array_expr_assign');
    vector_array_expr_assign:
      write('vector_array_expr_assign');

    {***************************************}
    { reference array assignment statements }
    {***************************************}
    array_array_expr_assign:
      write('array_array_expr_assign');
    struct_array_expr_assign:
      write('struct_array_expr_assign');
    static_struct_array_expr_assign:
      write('static_struct_array_expr_assign');
    proto_array_expr_assign:
      write('proto_array_expr_assign');
    reference_array_expr_assign:
      write('reference_array_expr_assign');

    {********************************}
    { subarray assignment statements }
    {********************************}
    subarray_expr_assign:
      write('subarray_expr_assign');

    {***************************************************************}
    {                structure assignment statements                }
    {***************************************************************}

    {******************************}
    { struct assignment statements }
    {******************************}
    struct_assign:
      write('struct_assign');
    struct_base_assign:
      write('struct_base_assign');
    struct_expr_assign:
      write('struct_expr_assign');
    struct_expr_ptr_assign:
      write('struct_expr_ptr_assign');

    {***************************************************************}
    {                        logical statements                     }
    {***************************************************************}

    {************************}
    { conditional statements }
    {************************}
    if_then_else:
      write('if_then_else');
    case_char_stmt:
      write('case_char_stmt');
    case_enum_stmt:
      write('case_enum_stmt');

    {********************}
    { looping statements }
    {********************}
    while_loop:
      write('while_loop');
    for_loop:
      write('for_loop');
    for_each:
      write('for_each');
    for_each_loop:
      write('for_each_loop');
    for_each_list:
      write('for_each_list');

    {***************************************************************}
    {                        control statements                     }
    {***************************************************************}

    {*************************}
    { flow control statements }
    {*************************}
    break_stmt:
      write('break_stmt');
    continue_stmt:
      write('continue_stmt');
    loop_label_stmt:
      write('loop_label_stmt');
    return_stmt:
      write('return_stmt');
    exit_stmt:
      write('exit_stmt');

    {***************************************}
    { enumerated function return statements }
    {***************************************}
    boolean_answer:
      write('boolean_answer');
    char_answer:
      write('char_answer');

    {************************************}
    { integer function return statements }
    {************************************}
    byte_answer:
      write('byte_answer');
    short_answer:
      write('short_answer');
    integer_answer:
      write('integer_answer');
    long_answer:
      write('long_answer');

    {***********************************}
    { scalar function return statements }
    {***********************************}
    scalar_answer:
      write('scalar_answer');
    double_answer:
      write('double_answer');
    complex_answer:
      write('complex_answer');
    vector_answer:
      write('vector_answer');

    {**************************************}
    { reference function return statements }
    {**************************************}
    array_ptr_answer:
      write('array_ptr_answer');
    struct_ptr_answer:
      write('struct_ptr_answer');
    proto_answer:
      write('proto_answer');
    reference_answer:
      write('reference_answer');

    {********************}
    { scoping statements }
    {********************}
    with_stmt:
      write('with_stmt');

    {***************************************************************}
    {                    memory allocation statements               }
    {***************************************************************}

    {***************************************}
    { memory explicit allocation statements }
    {***************************************}
    dim_stmt:
      write('dim_stmt');
    new_struct_stmt:
      write('new_struct_stmt');

    {********************************}
    { memory reallocation statements }
    {********************************}
    redim_stmt:
      write('redim_stmt');
    renew_struct_stmt:
      write('renew_struct_stmt');

    {********************************}
    { memory deallocation statements }
    {********************************}
    implicit_free_array_stmt:
      write('implicit_free_array_stmt');
    implicit_free_struct_stmt:
      write('implicit_free_struct_stmt');
    implicit_free_reference_stmt:
      write('implicit_free_reference_stmt');
    implicit_free_params_stmt:
      write('implicit_free_params_stmt');

    {***************************************************************}
    {                      subprogram call statements               }
    {***************************************************************}

    {*********************}
    { built in statements }
    {*********************}
    built_in_stmt:
      write('built_in_stmt');

    {*****************************************}
    { user defined subprogram call statements }
    {*****************************************}
    static_method_stmt:
      write('static_method_stmt');
    dynamic_method_stmt:
      write('dynamic_method_stmt');
    interface_method_stmt:
      write('interface_method_stmt');
    proto_method_stmt:
      write('proto_method_stmt');
  end; {case}
end; {procedure Write_stmt_kind}


initialization
  Init_stmt_sets;

  {************}
  { free lists }
  {************}
  stmt_free_list := nil;
  stmt_info_free_list := nil;

  {****************************}
  { block allocation variables }
  {****************************}
  stmt_block_ptr := nil;
  stmt_counter := 0;

  stmt_info_block_ptr := nil;
  stmt_info_counter := 0;

  {***********************}
  { initialize free lists }
  {***********************}
  switch_array_free_list := nil;
  switch_case_free_list := nil;
  case_constant_free_list := nil;
  stmt_data_free_list := nil;

  {*************************}
  { initialize active lists }
  {*************************}
  active_stmt_info_list := nil;
  last_active_stmt_info_ptr := nil;
end.
