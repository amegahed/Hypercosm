unit load_operands;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            load_operands              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These routines are used in conjunction with the         }
{       stack and heap modules to more easily access the        }
{       runtime system's data.                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


{**************************************}
{ routines to load enumerated operands }
{**************************************}
procedure Load_boolean_operand;
procedure Load_char_operand;

{***********************************}
{ routines to load integer operands }
{***********************************}
procedure Load_byte_operand;
procedure Load_short_operand;
procedure Load_integer_operand;
procedure Load_long_operand;

{**********************************}
{ routines to load scalar operands }
{**********************************}
procedure Load_scalar_operand;
procedure Load_double_operand;

{************************************}
{ routines to load compound operands }
{************************************}
procedure Load_complex_operand;
procedure Load_vector_operand;

{*************************************}
{ routines to load reference operands }
{*************************************}
procedure Load_handle_operand;
procedure Load_memref_operand;
procedure Load_code_operand;
procedure Load_proto_operand;
procedure Load_addr_operand;


implementation
uses
  addr_types, data, handles, memrefs, op_stacks, set_data, get_data;


{**************************************}
{ routines to load enumerated operands }
{**************************************}


procedure Load_boolean_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_boolean_operand(Get_addr_boolean(addr));
  Free_addr(addr);
end; {procedure Load_boolean_operand}


procedure Load_char_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_char_operand(Get_addr_char(addr));
  Free_addr(addr);
end; {procedure Load_char_operand}


{***********************************}
{ routines to load integer operands }
{***********************************}


procedure Load_byte_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_byte_operand(Get_addr_byte(addr));
  Free_addr(addr);
end; {procedure Load_byte_operand}


procedure Load_short_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_short_operand(Get_addr_short(addr));
  Free_addr(addr);
end; {procedure Load_short_operand}


procedure Load_integer_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_integer_operand(Get_addr_integer(addr));
  Free_addr(addr);
end; {procedure Load_integer_operand}


procedure Load_long_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_long_operand(Get_addr_long(addr));
  Free_addr(addr);
end; {procedure Load_long_operand}


{**********************************}
{ routines to load scalar operands }
{**********************************}


procedure Load_scalar_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_scalar_operand(Get_addr_scalar(addr));
  Free_addr(addr);
end; {procedure Load_scalar_operand}


procedure Load_double_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_double_operand(Get_addr_double(addr));
  Free_addr(addr);
end; {procedure Load_double_operand}


{************************************}
{ routines to load compound operands }
{************************************}


procedure Load_complex_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_complex_operand(Get_addr_complex(addr));
  Free_addr(addr);
end; {procedure Load_complex_operand}


procedure Load_vector_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_vector_operand(Get_addr_vector(addr));
  Free_addr(addr);
end; {procedure Load_vector_operand}


{*************************************}
{ routines to load reference operands }
{*************************************}


procedure Load_handle_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_handle_operand(Clone_handle(Get_addr_handle(addr)));
  Free_addr(addr);
end; {procedure Load_handle_operand}


procedure Load_memref_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_memref_operand(Clone_memref(Get_addr_memref(addr)));
  Free_addr(addr);
end; {procedure Load_memref_operand}


procedure Load_code_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_code_operand(Get_addr_code(addr));
  Free_addr(addr);
end; {procedure Load_code_operand}


procedure Load_proto_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_code_operand(Get_addr_code(addr));
  Push_stack_index_operand(Get_addr_stack_index(Get_offset_addr(addr, 1)));
  Free_addr(addr);
end; {procedure Load_proto_operand}


procedure Load_addr_operand;
var
  addr: addr_type;
begin
  addr := Pop_addr_operand;
  Push_addr_operand(Clone_addr(Get_addr_addr(addr)));
  Free_addr(addr);
end; {procedure Load_addr_operand}


end.
