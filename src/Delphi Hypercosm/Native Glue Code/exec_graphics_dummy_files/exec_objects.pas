unit exec_objects;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_objects               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for the execution of         }
{       methods described by the abstract syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, stmts, decls, code_decls;


{**********************************}
{ procedures for executing objects }
{**********************************}
procedure Interpret_native_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
procedure Interpret_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
procedure Save_shader_inst(stmt_data_ptr: stmt_data_ptr_type);

{***********************************}
{ procedures for executing pictures }
{***********************************}
procedure Interpret_picture(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
procedure Update_params;


implementation


{**********************************}
{ procedures for executing objects }
{**********************************}


procedure Interpret_native_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
begin
end; {procedure Interpret_native_object}


procedure Interpret_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
begin
end; {procedure Interpret_object}


procedure Save_shader_inst(stmt_data_ptr: stmt_data_ptr_type);
begin
end; {procedure Save_shader_inst}


{***********************************}
{ procedures for executing pictures }
{***********************************}


procedure Interpret_picture(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
begin
end; {procedure Interpret_picture}


procedure Update_params;
begin
end; {procedure Update_params}


end. {module exec_objects}
