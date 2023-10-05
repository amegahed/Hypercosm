unit exec_methods;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_methods               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These are dummy routines to satisfy requirements        }
{	for a call to destructors.  In the interpreter, this    }
{	module should be replaced by a module with actual       }
{	destructor calling code.				}
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types;


type
  abstract_type_ptr_type = Pointer;
  abstract_code_ptr_type = Pointer;


{****************************}
{ destructor calling methods }
{****************************}
function Get_abstract_type_destructor(type_ptr: abstract_type_ptr_type):
  abstract_code_ptr_type;
procedure Interpret_abstract_destructor_stmt(code_ptr: abstract_code_ptr_type;
  memref: memref_type);


implementation


{****************************}
{ destructor calling methods }
{****************************}


function Get_abstract_type_destructor(type_ptr: abstract_type_ptr_type):
  abstract_code_ptr_type;
begin
  Get_abstract_type_destructor := nil;
end; {function Get_abstract_type_destructor}


procedure Interpret_abstract_destructor_stmt(code_ptr: abstract_code_ptr_type;
  memref: memref_type);
begin
end; {procedure Interpret_abstract_destructor_stmt}


end.

