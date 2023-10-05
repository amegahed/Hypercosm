unit exec_native;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             exec_native               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for executing native         }
{       procedures and assignments                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types;


procedure Init_exec_native;

{************************************************}
{ set indices to execute native data assignments }
{************************************************}
procedure Set_native_data_index(native_index: integer;
  stack_index: stack_index_type);

{*********************************************************}
{ routine to switch between and execute native methods }
{*********************************************************}
procedure Exec_native_method(native_index: integer);


implementation


procedure Init_exec_native;
begin
end; {procedure Init_exec_native}


{************************************************}
{ set indices to execute native data assignments }
{************************************************}


procedure Set_native_data_index(native_index: integer;
  stack_index: stack_index_type);
begin
end; {procedure Set_native_data_index}


{******************************************************}
{ routine to switch between and execute native methods }
{******************************************************}


procedure Exec_native_method(native_index: integer);
begin
end; {procedure Exec_native_method}


end.
