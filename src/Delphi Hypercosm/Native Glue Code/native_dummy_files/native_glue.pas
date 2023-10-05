unit native_glue;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            native_glue                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{	This module is used to glue native code to              }
{	interpreter code.					}
{								}
{       The primitive data needed by the interpreter is found   }
{       by its index on the stack (its order of declaration)    }
{       so that the identifiers which stand for this data       }
{       may be changed without recompiling the code.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings;


procedure Init_native_glue;

{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_data_by_name(name: string_type;
  var index: integer): boolean;
function Found_native_method_by_name(name: string_type;
  var index: integer): boolean;


implementation


procedure Init_native_glue;
begin
end; {procedure Init_native_glue}


function Found_native_data_by_name(name: string_type;
  var index: integer): boolean;
begin
  Found_native_data_by_name := false;
end; {function Found_native_data_by_name}


{***************************************}
{ routines to match method kind by name }
{***************************************}


function Found_native_method_by_name(name: string_type;
  var index: integer): boolean;
begin
  Found_native_method_by_name := false;
end; {function Found_native_method_by_name}


end. {module native_glue}

