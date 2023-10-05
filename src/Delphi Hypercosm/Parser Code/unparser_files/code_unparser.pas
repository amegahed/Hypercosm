unit code_unparser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           code_unparser               3d       }
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
  strings, code_types, decl_attributes, decls;


{**********************************}
{ routines to unparse declarations }
{**********************************}
procedure Unparse_code_decl(var outfile: text;
  decl_ptr: decl_ptr_type);

{********************************************}
{ routines to unparse declaration components }
{********************************************}
function Code_kind_to_str(kind: code_kind_type): string_type;


implementation
uses
  type_attributes, code_attributes, expr_attributes, comments, exprs, stmts,
  code_decls, type_decls, unparser, term_unparser, expr_unparser, stmt_unparser,
  data_unparser, type_unparser, decl_unparser;


function Code_kind_to_str(kind: code_kind_type): string_type;
var
  str: string_type;
begin
  case kind of

    procedure_code, constructor_code, destructor_code:
      str := 'verb';

    function_code:
      str := 'question';

    shader_code:
      str := 'shader';

    object_code:
      str := 'shape';

    picture_code:
      str := 'picture';

    anim_code:
      str := 'anim';

  end; {case}

  Code_kind_to_str := str;
end; {function Code_kind_to_str}


{***************************************************}
{ routines to unparse method declaration signatures }
{***************************************************}


procedure Unparse_keywords(var outfile: text;
  keyword_ptr: keyword_ptr_type);
begin
  while (keyword_ptr <> nil) do
    begin
      Unparse_str(outfile, keyword_ptr^.keyword);
      Unparse_space(outfile);
      keyword_ptr := keyword_ptr^.next;
    end;
end; {procedure Unparse_keywords}


procedure Unparse_param_data_decls(var outfile: text;
  var decl_ptr: decl_ptr_type;
  parameter_ptr: parameter_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  comment_ptr: comment_ptr_type;
  last_decl_ptr: decl_ptr_type;
begin
  {********************************}
  { unparse simple data parameters }
  {********************************}
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);
  Unparse_storage_class(outfile, decl_attributes_ptr);
  Unparse_type_attributes(outfile,
    decl_attributes_ptr^.base_type_attributes_ref);
  Unparse_space(outfile);

  while (parameter_ptr <> nil) do
    begin
      Unparse_data_name(outfile, decl_ptr^.data_decl, decl_attributes_ptr);

      {**********************}
      { go to next parameter }
      {**********************}
      last_decl_ptr := decl_ptr;
      decl_ptr := decl_ptr^.next;
      parameter_ptr := parameter_ptr^.next;

      if (parameter_ptr <> nil) then
        begin
          Unparse_str(outfile, ',');
          Unparse_space(outfile);
        end
      else
        begin
          Unparse_char(outfile, ';');

          {***************************************}
          { unparse comment at end of declaration }
          {***************************************}
          if last_decl_ptr^.decl_info_ptr <> nil then
            with last_decl_ptr^.decl_info_ptr^ do
              begin
                comment_ptr := Get_post_comments(comments_ptr);
                if (comment_ptr <> nil) then
                  begin
                    Unparse_tab(outfile);
                    Unparse_comments(outfile, comment_ptr);
                  end
                else
                  Unparseln(outfile, '');
              end
          else
            Unparseln(outfile, '');
        end;

    end; {while}
end; {procedure Unparse_param_data_decls}


procedure Unparse_formatted_params(var outfile: text;
  var decl_ptr: decl_ptr_type;
  signature_ptr: signature_ptr_type);
begin
  if decl_ptr <> nil then
    begin
      {***********************}
      { unparse prev comments }
      {***********************}
      if decl_ptr^.decl_info_ptr <> nil then
        Unparse_comments(outfile,
          Get_prev_comments(decl_ptr^.decl_info_ptr^.comments_ptr));

      {******************************************************}
      { unparse formatted (mandatory and keyword) parameters }
      {******************************************************}
      while (signature_ptr <> nil) do
        begin
          Indent(outfile);

          {***************************}
          { unparse type declarations }
          {***************************}
          while (decl_ptr^.kind = type_decl) do
            begin
              Unparse_type_decl(outfile, decl_ptr);
              Indent(outfile);
              decl_ptr := decl_ptr^.next;
            end;

          {********************************}
          { unparse parameter declarations }
          {********************************}
          Unparse_keywords(outfile, signature_ptr^.keyword_ptr);
          case decl_ptr^.kind of

            boolean_decl..reference_decl:
              Unparse_param_data_decls(outfile, decl_ptr,
                signature_ptr^.parameter_ptr);

            code_decl, code_reference_decl:
              begin
                Unparse_code_decl(outfile, decl_ptr);
                decl_ptr := decl_ptr^.next;
              end;
          end; {case}

          signature_ptr := signature_ptr^.next;
        end;
    end;
end; {procedure Unparse_formatted_params}


{********************************************}
{ routine to unparse all method declarations }
{********************************************}


procedure Unparse_method_kind(var outfile: text;
  code_ptr: code_ptr_type);
var
  implicit: boolean;
begin
  with code_ptr^ do
    case method_kind of

      void_method:
        begin
          Unparse_str(outfile, 'objective');
          Unparse_space(outfile);
        end;

      static_method:
        if decl_kind = forward_decl then
          if not (code_ptr^.kind in special_code_kinds) then
            begin
              if code_ptr^.class_type_ref <> nil then
                implicit := type_ptr_type(code_ptr^.class_type_ref)^.class_kind
                  = alias_class
              else
                implicit := false;

              if not implicit then
                begin
                  Unparse_str(outfile, 'static');
                  Unparse_space(outfile);
                end;
            end;

      virtual_method:
        ;

      abstract_method:
        if decl_kind = forward_decl then
          if (type_ptr_type(code_ptr^.class_type_ref)^.class_kind <>
            interface_class) then
            begin
              Unparse_str(outfile, 'abstract');
              Unparse_space(outfile);
            end;

      final_method:
        if decl_kind = forward_decl then
          begin
            Unparse_str(outfile, 'final');
            Unparse_space(outfile);
          end;

    end; {case}
end; {procedure Unparse_method_kind}


procedure Unparse_method_attributes(var outfile: text;
  code_ptr: code_ptr_type);
var
  decl_ptr: decl_ptr_type;
  type_ptr: type_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  decl_ptr := code_ptr^.code_decl_ref;
  type_ptr := type_ptr_type(code_ptr^.class_type_ref);
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);

  with code_ptr^ do
    begin
      if show_implicit then
        if decl_kind = proto_decl then
          begin
            Unparse_str(outfile, 'proto');
            Unparse_space(outfile);
          end;

      if decl_kind = native_decl then
        begin
          Unparse_str(outfile, 'native');
          Unparse_space(outfile);
        end;

      {**************************}
      { unparse declaration kind }
      {**************************}
      if decl_kind = forward_decl then
        if type_ptr = nil then
          begin
            Unparse_str(outfile, 'forward');
            Unparse_space(outfile);
          end;

      if type_ptr <> nil then
        begin
          {**********************}
          { unparse access level }
          {**********************}
          if Found_protected_member(decl_attributes_ptr) then
            begin
              Unparse_str(outfile, 'protected');
              Unparse_space(outfile);
            end;

          {*********************}
          { unparse method kind }
          {*********************}
          Unparse_method_kind(outfile, code_ptr);

          if reference_method then
            if not type_ptr^.static then
              begin
                Unparse_str(outfile, 'reference');
                Unparse_space(outfile);
              end;
        end
      else
        begin
          {**************************}
          { free (non-class) methods }
          {**************************}
          if decl_attributes_ptr^.static then
            begin
              Unparse_str(outfile, 'static');
              Unparse_space(outfile);
            end;
        end;

      {***********************}
      { unparse function kind }
      {***********************}
      if code_ptr^.kind = function_code then
        begin
          code_attributes_ptr :=
            decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr;
          expr_attributes_ptr :=
            expr_attributes_ptr_type(code_attributes_ptr^.return_value_attributes_ptr);
          Unparse_type_attributes(outfile,
            expr_attributes_ptr^.alias_type_attributes_ptr);
          Unparse_space(outfile);
        end;

      {*************************************}
      { unparse subprogram declaration kind }
      {*************************************}
      Unparse_str(outfile, Code_kind_to_str(code_ptr^.kind));
      Unparse_space(outfile);
    end; {with}
end; {procedure Unparse_method_attributes}


procedure Unparse_param_decls(var outfile: text;
  code_ptr: code_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type);
var
  implicit_signature_ptr, param_signature_ptr, return_signature_ptr:
    signature_ptr_type;
  implicit_decls_ptr, param_decls_ptr, return_decls_ptr: decl_ptr_type;
  param_stmts_ptr, param_free_stmts_ptr: stmt_ptr_type;
begin
  {******************************************************}
  { unparse formatted (mandatory and keyword) parameters }
  {******************************************************}
  param_signature_ptr := code_attributes_ptr^.signature_ptr;
  return_signature_ptr := code_attributes_ptr^.return_signature_ptr;

  param_decls_ptr := code_ptr^.initial_param_decls_ptr;
  return_decls_ptr := code_ptr^.return_param_decls_ptr;

  if show_implicit then
    begin
      implicit_signature_ptr := code_attributes_ptr^.implicit_signature_ptr;
      implicit_decls_ptr := code_ptr^.implicit_param_decls_ptr;
      param_free_stmts_ptr := code_ptr^.param_free_stmts_ptr;
    end
  else
    begin
      implicit_signature_ptr := nil;
      implicit_decls_ptr := nil;
      param_free_stmts_ptr := nil;
    end;

  {******************************}
  { unparse formatted parameters }
  {******************************}
  if (implicit_signature_ptr <> nil) or (param_signature_ptr <> nil) then
    Unparseln(outfile, '');

  Push_margin;
  if show_shadowed_decls then
    Unparse_decls(outfile, implicit_decls_ptr)
  else
    Unparse_formatted_params(outfile, implicit_decls_ptr,
      implicit_signature_ptr);
  Unparse_formatted_params(outfile, param_decls_ptr, param_signature_ptr);
  Pop_margin;

  {*******************************************}
  { unparse unformatted (optional) parameters }
  {*******************************************}
  param_decls_ptr := code_ptr^.optional_param_decls_ptr;
  param_stmts_ptr := code_ptr^.optional_param_stmts_ptr;
  if (param_decls_ptr <> nil) or (param_stmts_ptr <> nil) then
    begin
      if (implicit_signature_ptr = nil) or (param_signature_ptr <> nil) then
        Unparse_space(outfile);

      Indent(outfile);
      Unparseln(outfile, 'with');

      Push_margin;
      Unparse_decls(outfile, param_decls_ptr);

      {******************************}
      { unparse statement parameters }
      {******************************}
      if param_stmts_ptr <> nil then
        begin
          if param_decls_ptr <> nil then
            if not (param_stmts_ptr^.kind in [null_stmt] +
              implicit_free_stmt_set) then
              Unparseln(outfile, '');
          Unparse_stmts(outfile, param_stmts_ptr);
        end;

      Pop_margin;
    end;

  {***************************}
  { unparse return parameters }
  {***************************}
  if (return_decls_ptr <> nil) or (param_free_stmts_ptr <> nil) then
    begin
      if implicit_signature_ptr = nil then
        if param_signature_ptr = nil then
          if param_stmts_ptr = nil then
            Unparse_space(outfile);

      Indent(outfile);
      Unparse_str(outfile, 'return');

      {*************************************}
      { unparse formatted return parameters }
      {*************************************}
      if return_signature_ptr <> nil then
        begin
          Unparseln(outfile, '');
          Push_margin;
          Unparse_formatted_params(outfile, return_decls_ptr,
            return_signature_ptr);
          Pop_margin;
        end
      else
        Unparse_space(outfile);

      {***************************************}
      { unparse unformatted return parameters }
      {***************************************}
      if (return_decls_ptr <> nil) or (param_free_stmts_ptr <> nil) then
        begin
          Indent(outfile);
          Unparseln(outfile, 'with');

          Push_margin;
          Unparse_decls(outfile, return_decls_ptr);

          if (return_decls_ptr <> nil) and (param_free_stmts_ptr <> nil) then
            Unparseln(outfile, '');

          Unparse_stmts(outfile, param_free_stmts_ptr);

          Pop_margin;
        end;
    end;
end; {procedure Unparse_param_decls}


procedure Unparse_code_decl(var outfile: text;
  decl_ptr: decl_ptr_type);
var
  code_ptr: code_ptr_type;
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
  starting_line_number: integer;
  ending_line_number: integer;
  comment_ptr: comment_ptr_type;
begin
  if decl_ptr <> nil then
    begin
      code_ptr := code_ptr_type(decl_ptr^.code_ptr);
      expr_ptr := decl_ptr^.code_data_decl.data_expr_ptr;
      expr_attributes_ptr := Get_expr_attributes(expr_ptr);
      decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
      type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
      code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;

      with code_ptr^ do
        begin
          starting_line_number := Unparseln_number;
          Indent(outfile);

          {************************************}
          { set context for statement unparser }
          {************************************}
          unparsing_code_ptr := code_ptr;
          unparsing_code_attributes_ptr := code_attributes_ptr;

          {**************************************}
          { unparse type and modifiers of method }
          {**************************************}
          Unparse_method_attributes(outfile, code_ptr);

          {***********************************}
          { unparse method name and modifiers }
          {***********************************}
          Unparse_data_name(outfile, decl_ptr^.code_data_decl,
            decl_attributes_ptr);

          {********************************}
          { unparse parameter declarations }
          {********************************}
          Unparse_param_decls(outfile, code_ptr, code_attributes_ptr);

          {******************************}
          { unparse body of complex decl }
          {******************************}
          if decl_kind <> actual_decl then
            begin
              {*******************************}
              { forward or proto declarations }
              {*******************************}
              if (optional_param_decls_ptr <> nil) or (optional_param_stmts_ptr
                <> nil) or (return_param_decls_ptr <> nil) then
                begin
                  Indent(outfile);
                  Unparse_str(outfile, 'end;');
                end
              else if show_implicit and (implicit_param_decls_ptr <> nil) then
                begin
                  Indent(outfile);
                  Unparse_str(outfile, 'end;');
                end
              else
                begin
                  Unparse_char(outfile, ';');
                end;
            end
          else
            begin
              {*********************}
              { actual declarations }
              {*********************}
              if (optional_param_decls_ptr = nil) and (optional_param_stmts_ptr
                = nil) and (return_param_decls_ptr = nil) then
                if (implicit_param_decls_ptr = nil) or (not show_implicit) then
                  Unparse_space(outfile)
                else
                  Indent(outfile)
              else
                Indent(outfile);

              Unparseln(outfile, 'is');

              {****************************}
              { unparse local declarations }
              {****************************}
              Push_margin;
              Unparse_decls(outfile, local_decls_ptr);

              {*********************************************}
              { unparse space between local decls and stmts }
              {*********************************************}
              if (local_decls_ptr <> nil) and (local_stmts_ptr <> nil) then
                if not (local_stmts_ptr^.kind in [null_stmt] +
                  implicit_free_stmt_set) then
                  Unparseln(outfile, '');

              {*******************************************}
              { unparse local stmts (body of declaration) }
              {*******************************************}
              Unparse_stmts(outfile, local_stmts_ptr);
              Pop_margin;

              Indent(outfile);
              Unparse_str(outfile, 'end;');
            end;

          {******************************************}
          { unparse comment at end of implementation }
          {******************************************}
          ending_line_number := Unparseln_number;

          if decl_ptr^.decl_info_ptr <> nil then
            with decl_ptr^.decl_info_ptr^ do
              begin
                comment_ptr := Get_post_comments(comments_ptr);
                if comment_ptr <> nil then
                  begin
                    Unparse_tab(outfile);
                    Unparse_comments(outfile, comment_ptr);
                  end
                else if ending_line_number > starting_line_number + 1 then
                  begin
                    Unparse_tab(outfile);
                    Unparse_str(outfile, '// ');
                    Unparse_expr(outfile, expr_ptr);
                    Unparseln(outfile, '');
                  end
                else
                  Unparseln(outfile, '');
              end;

        end; {with}
    end;
end; {procedure Unparse_code_decl}


end.
