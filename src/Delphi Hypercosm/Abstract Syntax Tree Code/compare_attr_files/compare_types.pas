unit compare_types;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            compare_types              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of data types which are used by the interpreter.        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes;


{******************************}
{ routines for comparing types }
{******************************}
function Same_type_attributes(type_attributes_ptr1: type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;
function Equal_type_attributes(type_attributes_ptr1: type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;
function Same_base_type_attributes(type_attributes_ptr1:
  type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;


implementation
uses
  symbol_tables, compare_codes;


{******************************}
{ routines for comparing types }
{******************************}


function Same_base_type_attributes(type_attributes_ptr1:
  type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;
var
  base_type_attributes_ptr1, base_type_attributes_ptr2:
  type_attributes_ptr_type;
begin
  if type_attributes_ptr1^.kind <> type_array then
    base_type_attributes_ptr1 := type_attributes_ptr1
  else
    base_type_attributes_ptr1 := type_attributes_ptr1^.base_type_attributes_ptr;

  if type_attributes_ptr2^.kind <> type_array then
    base_type_attributes_ptr2 := type_attributes_ptr2
  else
    base_type_attributes_ptr2 := type_attributes_ptr2^.base_type_attributes_ptr;

  Same_base_type_attributes := (base_type_attributes_ptr1^.kind =
    base_type_attributes_ptr2^.kind);
end; {function Same_base_type_attributes}


function Equal_type_attributes(type_attributes_ptr1: type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;
var
  equal: boolean;
  symbol_table_ptr1, symbol_table_ptr2: symbol_table_ptr_type;
begin
  {***************************************************************}
  {                         logical equivalence                   }
  {***************************************************************}
  {       This function checks to see if two data types are       }
  {       logically equivalent, meaning that they can be          }
  {       assigned to each other.                                 }
  {                                                               }
  {       (but, in the case of arrays, they may be not be         }
  {       structurally equivalent (they may have a different      }
  {       memory layout).                                         }
  {                                                               }
  {       for example:                                            }
  {       a[1..2][1..2] is logically equivalent to b[1..2, 1..2]  }
  {       but they are not structurally equivalent.               }
  {                                                               }
  {       in this case:                                           }
  {       a = b is valid, but                                     }
  {       a is b is not valid.                                    }
  {***************************************************************}
  equal := false;

  {**************************}
  { dereference type aliases }
  {**************************}
  type_attributes_ptr1 := Unalias_type_attributes(type_attributes_ptr1);
  type_attributes_ptr2 := Unalias_type_attributes(type_attributes_ptr2);

  if (type_attributes_ptr1 = type_attributes_ptr2) then
    equal := true
  else if (type_attributes_ptr1 = nil) or (type_attributes_ptr2 = nil) then
    equal := true
  else if (type_attributes_ptr1^.kind <> type_attributes_ptr2^.kind) then
    equal := false
  else
    case type_attributes_ptr1^.kind of

      type_error:
        equal := false;

      type_boolean..type_vector:
        equal := true;

      type_enum:
        begin
          symbol_table_ptr1 := type_attributes_ptr1^.enum_table_ptr;
          symbol_table_ptr2 := type_attributes_ptr2^.enum_table_ptr;
          equal := Equal_symbol_tables(symbol_table_ptr1, symbol_table_ptr2);
        end;

      type_array:
        if not
          Equal_type_attributes(type_attributes_ptr1^.base_type_attributes_ptr,
          type_attributes_ptr2^.base_type_attributes_ptr) then
          equal := false
        else
          equal := (type_attributes_ptr1^.absolute_dimensions =
            type_attributes_ptr2^.absolute_dimensions);

      type_struct:
        equal := false;

      type_class:
        begin
          {*****************************************************}
          { search for first type in second type's superclasses }
          {*****************************************************}
          equal := false;
          while (type_attributes_ptr2 <> nil) and not equal do
            begin
              if (type_attributes_ptr1 <> type_attributes_ptr2) then
                type_attributes_ptr2 :=
                  type_attributes_ptr2^.parent_type_attributes_ptr
              else
                equal := true;
            end;
        end;

      type_code:
        equal :=
          Equal_code_attributes(type_attributes_ptr1^.code_attributes_ptr,
          type_attributes_ptr2^.code_attributes_ptr);

      type_reference:
        equal :=
          Equal_type_attributes(type_attributes_ptr1^.reference_type_attributes_ptr, type_attributes_ptr2^.reference_type_attributes_ptr);

    end; {case}

  Equal_type_attributes := equal;
end; {function Equal_type_attributes}


function Same_type_attributes(type_attributes_ptr1: type_attributes_ptr_type;
  type_attributes_ptr2: type_attributes_ptr_type): boolean;
var
  same: boolean;
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
  symbol_table_ptr1, symbol_table_ptr2: symbol_table_ptr_type;
begin
  {***************************************************************}
  {                       structural equivalence                  }
  {***************************************************************}
  {       This function checks to see if two data types are       }
  {       structurally equivalent, meaning that they can be       }
  {       assigned to each other and they also have the same      }
  {       memory layout.  This is a more stringent requirement    }
  {       than logical equivalence because the types must be      }
  {       pointer compatible.                                     }
  {                                                               }
  {       for example:                                            }
  {       a[1..2][1..2] is logically equivalent to b[1..2, 1..2]  }
  {       but they are not structurally equivalent.               }
  {                                                               }
  {       in this case:                                           }
  {       a = b is valid, but                                     }
  {       a is b is not valid.                                    }
  {***************************************************************}
  same := false;

  {**************************}
  { dereference type aliases }
  {**************************}
  type_attributes_ptr1 := Unalias_type_attributes(type_attributes_ptr1);
  type_attributes_ptr2 := Unalias_type_attributes(type_attributes_ptr2);

  if (type_attributes_ptr1 = type_attributes_ptr2) then
    same := true
  else if (type_attributes_ptr1 = nil) or (type_attributes_ptr2 = nil) then
    same := true
  else if (type_attributes_ptr1^.kind <> type_attributes_ptr2^.kind) then
    same := false
  else
    case type_attributes_ptr1^.kind of

      type_error:
        same := false;

      type_boolean..type_vector:
        same := true;

      type_enum:
        begin
          symbol_table_ptr1 := type_attributes_ptr1^.enum_table_ptr;
          symbol_table_ptr2 := type_attributes_ptr2^.enum_table_ptr;
          same := Equal_symbol_tables(symbol_table_ptr1, symbol_table_ptr2);
        end;

      type_array:
        if not
          Same_type_attributes(type_attributes_ptr1^.base_type_attributes_ptr,
          type_attributes_ptr2^.base_type_attributes_ptr) then
          same := false
        else if (type_attributes_ptr1^.absolute_dimensions <>
          type_attributes_ptr2^.absolute_dimensions) then
          same := false
        else if (type_attributes_ptr1^.relative_dimensions <>
          type_attributes_ptr2^.relative_dimensions) then
          same := false
        else
          same :=
            Same_type_attributes(type_attributes_ptr1^.element_type_attributes_ptr, type_attributes_ptr2^.element_type_attributes_ptr);

      type_struct:
        same := false;

      type_class:
        begin
          {*****************************************************}
          { search for first type in second type's superclasses }
          {*****************************************************}
          same := false;
          while (type_attributes_ptr2 <> nil) and not same do
            begin
              {*****************************************************************}
              { search for first type in second type's superclasses' interfaces }
              {*****************************************************************}
              type_attributes_ref_ptr :=
                type_attributes_ptr2^.interface_type_attributes_ptr;
              while (type_attributes_ref_ptr <> nil) and not same do
                begin
                  same := Same_type_attributes(type_attributes_ptr1,
                    type_attributes_ref_ptr^.type_attributes_ptr);
                  if not same then
                    type_attributes_ref_ptr := type_attributes_ref_ptr^.next
                end;

              if (type_attributes_ptr1 <> type_attributes_ptr2) then
                type_attributes_ptr2 :=
                  type_attributes_ptr2^.parent_type_attributes_ptr
              else
                same := true;
            end;
        end;

      type_code:
        same := Same_code_attributes(type_attributes_ptr1^.code_attributes_ptr,
          type_attributes_ptr2^.code_attributes_ptr);

      type_reference:
        same :=
          Same_type_attributes(type_attributes_ptr1^.reference_type_attributes_ptr, type_attributes_ptr2^.reference_type_attributes_ptr);

    end; {case}

  Same_type_attributes := same;
end; {function Same_type_attributes}


end.
