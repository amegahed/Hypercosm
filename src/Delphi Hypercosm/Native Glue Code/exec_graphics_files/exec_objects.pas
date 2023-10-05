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
uses
  trans, extents, trans_stack, state_vars, object_attr, attr_stack, objects,
  params, anim, decl_attributes, code_types, make_stmts, exec_native_model,
  exec_graphics, assign_native_model, exec_native, exec_decls, exec_stmts,
  exec_methods;


{*******************************************************}
{                    object coherence                   }
{*******************************************************}
{          Two types of coherence are exploited         }
{          to make complex scenes possible and          }
{          to make animated sequences faster.           }
{                                                       }
{       1) Interframe coherence                         }
{          If two geometrically identical objects       }
{          are instantiated within the same frame,      }
{          then the instances should point to the       }
{          same structure. The instances will           }
{          contain the location, orientation, color,    }
{          and scaling of the particular instance.      }
{          This means that when we make a new           }
{          instance of an object, we must first check   }
{          to see if there are any data structures      }
{          existing for that object with the same       }
{          parameters. (params module)                  }
{                                                       }
{       2) Intraframe coherence                         }
{          In an animation or slide show sequence,      }
{          some data structures will persist over       }
{          many frames and some data structures will    }
{          only be used for one frame.                  }
{          At the beginning of each picture, each       }
{          object should be flagged as unused, then     }
{          if we run across an instance of that object  }
{          in the picture, then we flag it as used.     }
{          At the end of each picture, we remove all    }
{          uninstantiated objects.                      }
{*******************************************************}


{**********************************}
{ procedures for executing objects }
{**********************************}


function Interpret_object_decl(code_ptr: code_ptr_type): object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
  method_inst_data_ptr: method_inst_data_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  param_ptr: param_ptr_type;
begin
  Put_trans_stack_data;
  Put_shader_trans_stack_data;

  Begin_model_context;
  Init_model_context;

  object_decl_ptr := New_object;
  decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);
  if decl_attributes_ptr <> nil then
    Name_object(Get_decl_attributes_name(decl_attributes_ptr));

  {***************************************}
  { capture record of parameter signature }
  {***************************************}
  param_ptr := Get_params(code_ptr^.params_size);

  Interpret_decls(code_ptr^.local_decls_ptr);
  Interpret_stmts(code_ptr^.local_stmts_ptr);

  if not Found_externalities(param_ptr) then
    begin
      {**************************************************}
      { add object to params module and make a note in   }
      { the object of which object decl that particular  }
      { object was created from so later on, when the    }
      { object is termimated we can remove the reference }
      { to this object from the params module.           }
      {**************************************************}
      with code_data_ptr_type(code_ptr^.code_data_ptr)^ do
        begin
          object_decl_ptr^.object_decl_id := object_decl_id;
          method_inst_data_ptr := method_inst_data_ptr_type(object_decl_ptr);
          Add_method_inst_data(param_ptr, method_inst_data_ptr, object_decl_id);
        end;
    end
  else
    Free_params(param_ptr);

  End_object;
  End_model_context;

  Interpret_object_decl := object_decl_ptr;
end; {function Interpret_object_decl}


procedure Interpret_native_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
begin
  Exec_native_method(code_ptr^.code_decl_ref^.code_data_decl.native_index);

  {*****************************}
  { interpret return statements }
  {*****************************}
  Interpret_return_stmts(stmt_ptr^.return_assign_stmts_ptr);
  Interpret_return_stmts(stmt_ptr^.return_stmts_ptr);
  Interpret_stmts(code_ptr^.param_free_stmts_ptr);
  Get_model_context;

  Inst_geom_prim(native_object_inst_ptr);
end; {procedure Interpret_native_object}


procedure Interpret_object(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
var
  bounds_trans, relative_trans: trans_type;
  absolute_trans, desired_trans: trans_type;
  method_inst_data_ptr: method_inst_data_ptr_type;
  object_decl_ptr: object_decl_ptr_type;
begin
  Get_model_context;

  {******************************************}
  { find if object has been previously built }
  {******************************************}
  case code_ptr^.kind of

    object_code:
      begin
        with code_data_ptr_type(code_ptr^.code_data_ptr)^ do
          begin
            method_inst_data_ptr := Find_method_inst_data(object_decl_id,
              code_ptr^.params_size);
            object_decl_ptr := object_decl_ptr_type(method_inst_data_ptr);
          end;
      end;

    picture_code:
      object_decl_ptr := nil;

  else
    object_decl_ptr := nil;
  end; {case}

  {*****************************************************}
  { object has not been previously built - build it now }
  {*****************************************************}
  if object_decl_ptr = nil then
    object_decl_ptr := Interpret_object_decl(code_ptr);

  {********************************************}
  { scale transformation to size of new object }
  {********************************************}
  if (stmt_ptr^.return_stmts_ptr <> nil) then
    begin
      bounds_trans := Extent_box_trans(object_decl_ptr^.extent_box);

      absolute_trans := bounds_trans;
      Get_trans_stack(model_trans_stack_ptr, relative_trans);
      Transform_trans(absolute_trans, relative_trans);

      {*******************************************}
      { put absolute trans onto interpreter stack }
      {*******************************************}
      Set_trans_stack(model_trans_stack_ptr, absolute_trans);

      {*****************************}
      { interpret return statements }
      {*****************************}
      Put_trans_data;
      Put_shader_trans_data;
      Interpret_return_stmts(stmt_ptr^.return_assign_stmts_ptr);
      Interpret_return_stmts(stmt_ptr^.return_stmts_ptr);
      Get_trans_data;
      Get_shader_trans_data;

      Get_trans_stack(model_trans_stack_ptr, desired_trans);
      if not Equal_trans(absolute_trans, desired_trans) then
        begin
          relative_trans := Inverse_trans(bounds_trans);
          Transform_trans(relative_trans, desired_trans);
          Inst_geom_object(object_decl_ptr, relative_trans);
        end
      else
        Inst_geom_object(object_decl_ptr, relative_trans);
    end
  else
    begin
      Get_trans_stack(model_trans_stack_ptr, relative_trans);
      Inst_geom_object(object_decl_ptr, relative_trans);
      Interpret_return_stmts(stmt_ptr^.return_assign_stmts_ptr);
    end;
end; {procedure Interpret_object}


procedure Save_shader_inst(stmt_data_ptr: stmt_data_ptr_type);
var
  new_shader_ptr, new_edge_shader_ptr: stmt_ptr_type;
  attributes: object_attributes_type;
begin
  if stmt_data_ptr <> nil then
    begin
      if (stmt_data_ptr^.shader_stmt_ptr <> nil) or
        (stmt_data_ptr^.edge_shader_stmt_ptr <> nil) then
        begin
          {*******************************}
          { pre evaluate shader statement }
          {*******************************}
          if (stmt_data_ptr^.shader_stmt_ptr <> nil) then
            begin
              new_shader_ptr := Clone_stmt(stmt_data_ptr^.shader_stmt_ptr,
                false);
              Pre_eval_method(new_shader_ptr);
            end
          else
            new_shader_ptr := nil;

          {************************************}
          { pre evaluate edge shader statement }
          {************************************}
          if (stmt_data_ptr^.edge_shader_stmt_ptr <> nil) then
            begin
              new_edge_shader_ptr :=
                Clone_stmt(stmt_data_ptr^.edge_shader_stmt_ptr, false);
              Pre_eval_method(new_edge_shader_ptr);
            end
          else
            new_edge_shader_ptr := nil;

          {****************************************}
          { put shader data onto interpreter stack }
          {****************************************}
          Get_attributes_stack(model_attr_stack_ptr, attributes);

          if new_shader_ptr <> nil then
            Set_shader_attributes(attributes, shader_ptr_type(new_shader_ptr));
          if new_edge_shader_ptr <> nil then
            Set_edge_shader_attributes(attributes,
              shader_ptr_type(new_edge_shader_ptr));

          Set_attributes_stack(model_attr_stack_ptr, attributes);
        end;
    end;
end; {procedure Save_shader_inst}


{***********************************}
{ procedures for executing pictures }
{***********************************}


procedure Interpret_picture(stmt_ptr: stmt_ptr_type;
  code_ptr: code_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  with code_data_ptr_type(code_ptr^.code_data_ptr)^ do
    begin
      {****************************}
      { update picture data record }
      {****************************}
      picture_number := picture_number + 1;

      {********************}
      { Execute statements }
      {********************}
      Begin_object_group(picture_decl_id);

      decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);
      if decl_attributes_ptr <> nil then
        Name_object_group(Get_decl_attributes_name(decl_attributes_ptr));

      Interpret_object(stmt_ptr, code_ptr);
      End_object_group;

      {*************************************}
      { Mark unused objects for destruction }
      {*************************************}
      Update_params;
    end;
end; {procedure Interpret_picture}


procedure Update_params;
var
  object_ptr: object_decl_ptr_type;
  method_inst_data_ptr: method_inst_data_ptr_type;
begin
  Goto_first_terminated_object;
  object_ptr := Next_terminated_object;

  while (object_ptr <> nil) do
    begin
      method_inst_data_ptr := method_inst_data_ptr_type(object_ptr);
      Free_method_inst_data(method_inst_data_ptr, object_ptr^.object_decl_id);
      object_ptr := Next_terminated_object;
    end;
end; {procedure Update_params}


end.
