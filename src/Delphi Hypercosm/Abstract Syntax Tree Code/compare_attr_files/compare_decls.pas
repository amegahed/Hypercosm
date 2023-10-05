unit compare_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            compare_decls              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and which are       }
{       used to describe variables and types used by the        }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes;


{***********************************************}
{ routines for comparing declaration attributes }
{***********************************************}
function Equal_decl_attributes(decl_attributes_ptr1: decl_attributes_ptr_type;
  decl_attributes_ptr2: decl_attributes_ptr_type): boolean;
function Same_decl_attributes(decl_attributes_ptr1: decl_attributes_ptr_type;
  decl_attributes_ptr2: decl_attributes_ptr_type): boolean;


implementation
uses
  type_attributes, compare_types;


{***********************************************}
{ routines for comparing declaration attributes }
{***********************************************}


function Equal_decl_attributes(decl_attributes_ptr1: decl_attributes_ptr_type;
  decl_attributes_ptr2: decl_attributes_ptr_type): boolean;
var
  equal: boolean;
  type_attributes_ptr1, type_attributes_ptr2: type_attributes_ptr_type;
begin
  if decl_attributes_ptr1^.dimensions <> decl_attributes_ptr2^.dimensions then
    equal := false
  else
    begin
      type_attributes_ptr1 := decl_attributes_ptr1^.type_attributes_ptr;
      type_attributes_ptr2 := decl_attributes_ptr2^.type_attributes_ptr;
      equal := Equal_type_attributes(type_attributes_ptr1,
        type_attributes_ptr2);
    end;

  Equal_decl_attributes := equal;
end; {function Equal_decl_attributes}


function Same_decl_attributes(decl_attributes_ptr1: decl_attributes_ptr_type;
  decl_attributes_ptr2: decl_attributes_ptr_type): boolean;
var
  same: boolean;
  type_attributes_ptr1, type_attributes_ptr2: type_attributes_ptr_type;
begin
  if decl_attributes_ptr1^.dimensions <> decl_attributes_ptr2^.dimensions then
    same := false
  else
    begin
      type_attributes_ptr1 := decl_attributes_ptr1^.type_attributes_ptr;
      type_attributes_ptr2 := decl_attributes_ptr2^.type_attributes_ptr;
      same := Same_type_attributes(type_attributes_ptr1, type_attributes_ptr2);
    end;

  Same_decl_attributes := same;
end; {function Same_decl_attributes}


end.
