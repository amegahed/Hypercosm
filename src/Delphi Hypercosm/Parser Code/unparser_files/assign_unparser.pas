unit assign_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           assign_unparser             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module traverses the syntax tree and writes out    }
{       the original program declarations from it.              }
{       This is useful for debugging and to tell if the         }
{       parsers have produced the correct syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts;


{**************************************************}
{ routines to find expressions for assign operands }
{**************************************************}
function Get_assign_lhs(stmt_ptr: stmt_ptr_type): expr_ptr_type;
function Get_assign_rhs(stmt_ptr: stmt_ptr_type): expr_ptr_type;

{*******************************************}
{ routines to unparse assignment statements }
{*******************************************}
procedure Unparse_initializer(var outfile: text;
  stmt_ptr: stmt_ptr_type);


implementation
uses
  type_attributes, expr_attributes, code_attributes, unparser, term_unparser,
    expr_unparser, msg_unparser;


{**************************************************}
{ routines to find expressions for assign operands }
{**************************************************}


function Get_assign_lhs(stmt_ptr: stmt_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  with stmt_ptr^ do
    case kind of

      boolean_assign..reference_assign:
        expr_ptr := lhs_data_ptr;

      boolean_array_assign..reference_array_assign:
        expr_ptr := expr_ptr_type(lhs_array_subrange_ptr^.array_expr_ptr);

      subarray_assign:
        expr_ptr := expr_ptr_type(lhs_subarray_subrange_ptr^.array_expr_ptr);

      boolean_array_expr_assign..reference_array_expr_assign:
        expr_ptr := expr_ptr_type(array_expr_subrange_ptr^.array_expr_ptr);

      struct_assign:
        expr_ptr := lhs_struct_expr_ptr;

      struct_base_assign:
        expr_ptr := lhs_struct_base_ptr;

    else
      expr_ptr := nil;
    end; {case}

  Get_assign_lhs := expr_ptr;
end; {function Get_assign_lhs}


function Get_assign_rhs(stmt_ptr: stmt_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  with stmt_ptr^ do
    case kind of

      boolean_assign..reference_assign:
        expr_ptr := rhs_expr_ptr;

      boolean_array_assign..reference_array_assign:
        expr_ptr := expr_ptr_type(rhs_array_subrange_ptr^.array_expr_ptr);

      subarray_assign:
        expr_ptr := expr_ptr_type(rhs_subarray_subrange_ptr^.array_expr_ptr);

      boolean_array_expr_assign..reference_array_expr_assign:
        expr_ptr := array_expr_element_ref;

      struct_assign:
        expr_ptr := rhs_struct_expr_ptr;

      struct_base_assign:
        expr_ptr := rhs_struct_base_ptr;

    else
      expr_ptr := nil;
    end; {case}

  Get_assign_rhs := expr_ptr;
end; {function Get_assign_rhs}


{*******************************************}
{ routines to unparse assignment statements }
{*******************************************}


procedure Unparse_initializer(var outfile: text;
  stmt_ptr: stmt_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  if (stmt_ptr <> nil) then
    with stmt_ptr^ do
      begin

        case kind of

          {**********************************}
          { enumerated assignment statements }
          {**********************************}
          boolean_assign, char_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'is');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {*******************************}
          { integer assignment statements }
          {*******************************}
          byte_assign, short_assign, long_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, '=');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          integer_assign:
            begin
              Unparse_space(outfile);
              expr_attributes_ptr := Get_expr_attributes(lhs_data_ptr);
              if expr_attributes_ptr^.type_attributes_ptr^.kind = type_enum then
                Unparse_str(outfile, 'is')
              else
                Unparse_str(outfile, '=');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {******************************}
          { scalar assignment statements }
          {******************************}
          scalar_assign, double_assign, complex_assign, vector_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, '=');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {*******************************}
          { pointer assignment statements }
          {*******************************}
          array_ptr_assign, struct_ptr_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'is');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {*********************************}
          { prototype assignment statements }
          {*********************************}
          proto_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'does');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {*******************************}
          { address assignment statements }
          {*******************************}
          reference_assign:
            begin
              Unparse_space(outfile);
              Unparse_str(outfile, 'refers');
              Unparse_space(outfile);
              Unparse_str(outfile, 'to');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_expr_ptr);
            end;

          {*****************************}
          { array assignment statements }
          {*****************************}
          boolean_array_assign..reference_array_assign:
            Unparse_initializer(outfile, array_assign_stmt_ptr);

          {****************************************}
          { array expression assignment statements }
          {****************************************}
          boolean_array_expr_assign..reference_array_expr_assign:
            begin
              Unparse_space(outfile);
              if show_implicit then
                Unparse_str(outfile, '(array)=')
              else
                Unparse_str(outfile, '=');
              Unparse_space(outfile);
              Unparse_expr(outfile, array_expr_element_ref);
            end;

          {******************************}
          { struct assignment statements }
          {******************************}
          struct_assign:
            begin
              Unparse_space(outfile);
              if show_implicit then
                Unparse_str(outfile, '(struct)=')
              else
                Unparse_str(outfile, '=');
              Unparse_space(outfile);
              Unparse_expr(outfile, rhs_struct_expr_ptr);
            end;

          {*****************************************}
          { struct expression assignment statements }
          {*****************************************}
          struct_base_assign, struct_expr_assign, struct_expr_ptr_assign:
            ;

          {************************}
          { constructor statements }
          {************************}
          static_method_stmt:
            begin
              expr_attributes_ptr :=
                Get_expr_attributes(stmt_ptr^.stmt_name_ptr);
              code_attributes_ptr :=
                expr_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
              Unparse_params(outfile, stmt_ptr, code_attributes_ptr);
            end;

        end; {case}
      end; {with}
end; {procedure Unparse_initializer}


end.
