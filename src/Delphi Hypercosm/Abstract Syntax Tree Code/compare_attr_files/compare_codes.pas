unit compare_codes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           compare_codes               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of primitive code types which are used by the           }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  code_attributes;


{***********************************}
{ routines for comparing code types }
{***********************************}
function Same_code_attributes(code_attributes_ptr1: code_attributes_ptr_type;
  code_attributes_ptr2: code_attributes_ptr_type): boolean;
function Equal_code_attributes(code_attributes_ptr1: code_attributes_ptr_type;
  code_attributes_ptr2: code_attributes_ptr_type): boolean;


implementation
uses
  symbol_tables, code_types, decl_attributes, expr_attributes, errors,
  compare_decls, compare_exprs;


{*********************************}
{ routines for comparing keywords }
{*********************************}


function Same_keywords(keyword_ptr1, keyword_ptr2: keyword_ptr_type): boolean;
var
  same: boolean;
begin
  {*********************}
  { both keywords exist }
  {*********************}
  if (keyword_ptr1 <> nil) and (keyword_ptr2 <> nil) then
    same := keyword_ptr1^.keyword = keyword_ptr2^.keyword

    {********************}
    { one keyword exists }
    {********************}
  else if (keyword_ptr1 <> nil) or (keyword_ptr2 <> nil) then
    same := false

    {*******************}
    { no keywords exist }
    {*******************}
  else
    same := true;

  Same_keywords := same;
end; {function Same_keywords}


function Same_keyword_lists(keyword_list1, keyword_list2: keyword_ptr_type):
  boolean;
var
  same: boolean;
begin
  same := true;
  while (keyword_list1 <> nil) and (keyword_list2 <> nil) and same do
    begin
      if keyword_list1^.keyword = keyword_list2^.keyword then
        begin
          keyword_list1 := keyword_list1^.next;
          keyword_list2 := keyword_list2^.next;
        end
      else
        same := false;
    end;

  {************************************}
  { if number of keywords do not match }
  {************************************}
  if (keyword_list1 <> nil) or (keyword_list2 <> nil) then
    same := false;

  Same_keyword_lists := same;
end; {function Same_keyword_lists}


{**********************************************}
{ routines for comparing parameter identifiers }
{**********************************************}


function Same_ids(id_ptr1, id_ptr2: id_ptr_type): boolean;
var
  decl_attributes_ptr1, decl_attributes_ptr2: decl_attributes_ptr_type;
  same: boolean;
begin
  {************************}
  { both identifiers exist }
  {************************}
  if (id_ptr1 <> nil) and (id_ptr2 <> nil) then
    begin
      decl_attributes_ptr1 := decl_attributes_ptr_type(Get_id_value(id_ptr1));
      decl_attributes_ptr2 := decl_attributes_ptr_type(Get_id_value(id_ptr2));
      same := Same_decl_attributes(decl_attributes_ptr1, decl_attributes_ptr2);
    end

      {***********************}
      { one identifier exists }
      {***********************}
  else if (id_ptr1 <> nil) or (id_ptr2 <> nil) then
    same := false

    {**********************}
    { no identifiers exist }
    {**********************}
  else
    same := true;

  Same_ids := same;
end; {function Same_ids}


function Same_id_lists(id_list1, id_list2: id_ptr_type): boolean;
var
  decl_attributes_ptr1, decl_attributes_ptr2: decl_attributes_ptr_type;
  same: boolean;
begin
  same := true;
  while (id_list1 <> nil) and (id_list2 <> nil) and same do
    begin
      decl_attributes_ptr1 := decl_attributes_ptr_type(Get_id_value(id_list1));
      decl_attributes_ptr2 := decl_attributes_ptr_type(Get_id_value(id_list2));
      if Same_decl_attributes(decl_attributes_ptr1, decl_attributes_ptr2) then
        begin
          id_list1 := id_list1^.next;
          id_list2 := id_list2^.next;
        end
      else
        same := false;
    end;

  {***************************************}
  { if number of identifiers do not match }
  {***************************************}
  if (id_list1 <> nil) or (id_list2 <> nil) then
    same := false;

  Same_id_lists := same;
end; {function Same_id_lists}


{***********************************}
{ routines for comparing parameters }
{***********************************}


function Same_parameters(parameter_ptr1, parameter_ptr2: parameter_ptr_type):
  boolean;
var
  decl_attributes_ptr1, decl_attributes_ptr2: decl_attributes_ptr_type;
  same: boolean;
begin
  {***********************}
  { both parameters exist }
  {***********************}
  if (parameter_ptr1 <> nil) and (parameter_ptr2 <> nil) then
    begin
      decl_attributes_ptr1 :=
        decl_attributes_ptr_type(Get_id_value(parameter_ptr1^.id_ptr));
      decl_attributes_ptr2 :=
        decl_attributes_ptr_type(Get_id_value(parameter_ptr2^.id_ptr));
      same := Same_decl_attributes(decl_attributes_ptr1, decl_attributes_ptr2);
    end

      {**********************}
      { one parameter exists }
      {**********************}
  else if (parameter_ptr1 <> nil) or (parameter_ptr2 <> nil) then
    same := false

    {*********************}
    { no parameters exist }
    {*********************}
  else
    same := true;

  Same_parameters := same;
end; {function Same_parameters}


function Same_parameter_lists(parameter_list1, parameter_list2:
  parameter_ptr_type): boolean;
var
  decl_attributes_ptr1, decl_attributes_ptr2: decl_attributes_ptr_type;
  same: boolean;
begin
  same := true;
  while (parameter_list1 <> nil) and (parameter_list2 <> nil) and same do
    begin
      decl_attributes_ptr1 :=
        decl_attributes_ptr_type(Get_id_value(parameter_list1^.id_ptr));
      decl_attributes_ptr2 :=
        decl_attributes_ptr_type(Get_id_value(parameter_list2^.id_ptr));
      if Same_decl_attributes(decl_attributes_ptr1, decl_attributes_ptr2) then
        begin
          parameter_list1 := parameter_list1^.next;
          parameter_list2 := parameter_list2^.next;
        end
      else
        same := false;
    end;

  {**************************************}
  { if number of parameters do not match }
  {**************************************}
  if (parameter_list1 <> nil) or (parameter_list2 <> nil) then
    same := false;

  Same_parameter_lists := same;
end; {function Same_parameter_lists}


{***********************************}
{ routines for comparing signatures }
{***********************************}


function Same_signatures(signature_ptr1, signature_ptr2: signature_ptr_type):
  boolean;
var
  same: boolean;
begin
  {***********************}
  { both signatures exist }
  {***********************}
  if (signature_ptr1 <> nil) and (signature_ptr2 <> nil) then
    begin
      if signature_ptr1^.optional <> signature_ptr2^.optional then
        same := false
      else if Same_keyword_lists(signature_ptr1^.keyword_ptr,
        signature_ptr2^.keyword_ptr) then
        same := Same_parameters(signature_ptr1^.parameter_ptr,
          signature_ptr2^.parameter_ptr)
      else
        same := false;
    end

      {**********************}
      { one signature exists }
      {**********************}
  else if (signature_ptr1 <> nil) or (signature_ptr2 <> nil) then
    same := false

    {*********************}
    { no signatures exist }
    {*********************}
  else
    same := true;

  Same_signatures := same;
end; {function Same_signatures}


function Same_signature_lists(signature_list1, signature_list2:
  signature_ptr_type): boolean;
var
  same: boolean;
begin
  same := true;
  while (signature_list1 <> nil) and (signature_list2 <> nil) do
    begin
      if Same_signatures(signature_list1, signature_list2) then
        begin
          signature_list1 := signature_list1^.next;
          signature_list2 := signature_list2^.next;
        end
      else
        same := false;
    end; {while}

  {****************************************}
  { if number of signatures does not match }
  {****************************************}
  if (signature_list1 <> nil) or (signature_list2 <> nil) then
    same := false;

  Same_signature_lists := same;
end; {function Same_signature_lists}


{***********************************}
{ routines for comparing code types }
{***********************************}


function Same_param_id_lists(private_id_list1, protected_id_list1: id_ptr_type;
  private_id_list2, protected_id_list2: id_ptr_type): boolean;
var
  id_list_ptr1, id_list_ptr2: id_ptr_type;
  same, done: boolean;
begin
  id_list_ptr1 := private_id_list1;
  id_list_ptr2 := private_id_list2;

  same := true;
  done := false;
  while same and (not done) do
    begin
      {************************************************}
      { if the end of the private list is reached then }
      { continue checking using the protected list.    }
      {************************************************}
      if id_list_ptr1 = nil then
        begin
          id_list_ptr1 := protected_id_list1;
          protected_id_list1 := nil;
        end;
      if id_list_ptr2 = nil then
        begin
          id_list_ptr2 := protected_id_list2;
          protected_id_list2 := nil;
        end;

      {************************}
      { both identifiers exist }
      {************************}
      if (id_list_ptr1 <> nil) and (id_list_ptr2 <> nil) then
        begin
          if Same_ids(id_list_ptr1, id_list_ptr2) then
            begin
              id_list_ptr1 := id_list_ptr1^.next;
              id_list_ptr2 := id_list_ptr2^.next;
            end
          else
            same := false;
        end

          {***********************}
          { one identifier exists }
          {***********************}
      else if (id_list_ptr1 <> nil) or (id_list_ptr2 <> nil) then
        same := false

        {**********************}
        { no identifiers exist }
        {**********************}
      else
        begin
          done := true;
          same := true;
        end;
    end; {while}

  Same_param_id_lists := same;
end; {function Same_param_id_lists}


function Equal_code_attributes(code_attributes_ptr1: code_attributes_ptr_type;
  code_attributes_ptr2: code_attributes_ptr_type): boolean;
var
  equal: boolean;
  private_id_list1, protected_id_list1: id_ptr_type;
  private_id_list2, protected_id_list2: id_ptr_type;
  expr_attributes_ptr1, expr_attributes_ptr2: expr_attributes_ptr_type;
begin
  {***************************************************************}
  {                         logical equivalence                   }
  {***************************************************************}
  {       This function checks to see if two code types are       }
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
  if (code_attributes_ptr1 = code_attributes_ptr2) then
    equal := true
  else if (code_attributes_ptr1 = nil) or (code_attributes_ptr2 = nil) then
    equal := true
  else if (code_attributes_ptr1^.kind <> code_attributes_ptr2^.kind) then
    equal := false
  else
    begin
      {*****************************}
      { check function return types }
      {*****************************}
      if code_attributes_ptr1^.kind = function_code then
        begin
          expr_attributes_ptr1 :=
            expr_attributes_ptr_type(code_attributes_ptr1^.return_value_attributes_ptr);
          expr_attributes_ptr2 :=
            expr_attributes_ptr_type(code_attributes_ptr2^.return_value_attributes_ptr);
          equal := Equal_expr_attributes(expr_attributes_ptr1,
            expr_attributes_ptr2);
        end
      else
        equal := true;

      if equal then
        begin
          {********************************************}
          { check formatted and unformatted parameters }
          {********************************************}
          private_id_list1 :=
            code_attributes_ptr1^.private_param_table_ptr^.id_list;
          protected_id_list1 :=
            code_attributes_ptr1^.protected_param_table_ptr^.id_list;
          private_id_list2 :=
            code_attributes_ptr2^.private_param_table_ptr^.id_list;
          protected_id_list2 :=
            code_attributes_ptr2^.protected_param_table_ptr^.id_list;
          equal := Same_param_id_lists(private_id_list1, protected_id_list1,
            private_id_list2, protected_id_list2);

          if equal then
            begin
              {***************************************************}
              { check formatted and unformatted return parameters }
              {***************************************************}
              private_id_list1 :=
                code_attributes_ptr1^.private_return_table_ptr^.id_list;
              protected_id_list1 :=
                code_attributes_ptr1^.protected_return_table_ptr^.id_list;
              private_id_list2 :=
                code_attributes_ptr2^.private_return_table_ptr^.id_list;
              protected_id_list2 :=
                code_attributes_ptr2^.protected_return_table_ptr^.id_list;
              equal := Same_param_id_lists(private_id_list1, protected_id_list1,
                private_id_list2, protected_id_list2);

              if equal then
                begin
                  {***************************}
                  { check implicit parameters }
                  {***************************}
                  private_id_list1 :=
                    code_attributes_ptr1^.implicit_table_ptr^.id_list;
                  private_id_list2 :=
                    code_attributes_ptr2^.implicit_table_ptr^.id_list;
                  equal := Same_id_lists(private_id_list1, private_id_list2);
                end;
            end;
        end;
    end;

  Equal_code_attributes := equal;
end; {function Equal_code_attributes}


function Same_code_attributes(code_attributes_ptr1: code_attributes_ptr_type;
  code_attributes_ptr2: code_attributes_ptr_type): boolean;
var
  same: boolean;
  id_list_ptr1, id_list_ptr2: id_ptr_type;
  signature_ptr1, signature_ptr2: signature_ptr_type;
  expr_attributes_ptr1, expr_attributes_ptr2: expr_attributes_ptr_type;
begin
  {***************************************************************}
  {                       structural equivalence                  }
  {***************************************************************}
  {       This function checks to see if two code types are       }
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
  if (code_attributes_ptr1 = code_attributes_ptr2) then
    same := true
  else if (code_attributes_ptr1 = nil) or (code_attributes_ptr2 = nil) then
    same := true
  else if (code_attributes_ptr1^.kind <> code_attributes_ptr2^.kind) then
    same := false
  else
    begin
      {*****************************}
      { check function return types }
      {*****************************}
      if code_attributes_ptr1^.kind = function_code then
        begin
          expr_attributes_ptr1 :=
            expr_attributes_ptr_type(code_attributes_ptr1^.return_value_attributes_ptr);
          expr_attributes_ptr2 :=
            expr_attributes_ptr_type(code_attributes_ptr2^.return_value_attributes_ptr);
          same := Same_expr_attributes(expr_attributes_ptr1,
            expr_attributes_ptr2);
        end
      else
        same := true;

      if same then
        begin
          {***************************}
          { check formatted paramters }
          {***************************}
          signature_ptr1 := code_attributes_ptr1^.signature_ptr;
          signature_ptr2 := code_attributes_ptr2^.signature_ptr;
          same := Same_signatures(signature_ptr1, signature_ptr2);

          if same then
            begin
              {*****************************}
              { check unformatted paramters }
              {*****************************}
              id_list_ptr1 :=
                code_attributes_ptr1^.protected_param_table_ptr^.id_list;
              id_list_ptr2 :=
                code_attributes_ptr1^.protected_param_table_ptr^.id_list;
              same := Same_id_lists(id_list_ptr1, id_list_ptr2);

              if same then
                begin
                  {***********************************}
                  { check formatted return parameters }
                  {***********************************}
                  signature_ptr1 := code_attributes_ptr1^.return_signature_ptr;
                  signature_ptr2 := code_attributes_ptr2^.return_signature_ptr;
                  same := Same_signatures(signature_ptr1, signature_ptr2);

                  if same then
                    begin
                      {*************************************}
                      { check unformatted return parameters }
                      {*************************************}
                      id_list_ptr1 :=
                        code_attributes_ptr1^.protected_return_table_ptr^.id_list;
                      id_list_ptr2 :=
                        code_attributes_ptr1^.protected_return_table_ptr^.id_list;
                      same := Same_id_lists(id_list_ptr1, id_list_ptr2);

                      if same then
                        begin
                          {***************************}
                          { check implicit parameters }
                          {***************************}
                          signature_ptr1 :=
                            code_attributes_ptr1^.implicit_signature_ptr;
                          signature_ptr2 :=
                            code_attributes_ptr2^.implicit_signature_ptr;
                          same := Same_signatures(signature_ptr1,
                            signature_ptr2);
                        end;
                    end;
                end;
            end;
        end;
    end;

  Same_code_attributes := same;
end; {function Same_code_attributes}


end.
