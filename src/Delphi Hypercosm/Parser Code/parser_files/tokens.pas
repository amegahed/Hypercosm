unit tokens;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              tokens                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines all of the tokens which are         }
{       recognized by the scanner.                              }
{                                                               }
{       A token is like an atomic unit in the language. Each    }
{       reserved word is a token, and numbers and strings are   }
{       each considered to be individual tokens because they    }
{       are distict entities in the high level description      }
{       of the language.                                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, string_structs, comments;


type
  token_kind_type = (

    {*********************}
    { uninitialized token }
    {*********************}
    error_tok,

    {****************}
    { keyword tokens }
    {****************}
    is_tok, isnt_tok, does_tok, doesnt_tok, has_tok, with_tok, each_tok, in_tok,
      s_tok, of_tok, to_tok,

    {******************}
    { statement tokens }
    {******************}
    if_tok, then_tok, else_tok, elseif_tok, when_tok, while_tok, for_tok,
      do_tok, return_tok, answer_tok, end_tok, break_tok, continue_tok, exit_tok,
      loop_tok, refers_tok,

    {******************************}
    { input output statment tokens }
    {******************************}
    read_tok, write_tok,

    {**********************}
    { storage class tokens }
    {**********************}
    const_tok, reference_tok, static_tok, void_tok, native_tok, global_tok,

    {*******************}
    { protection tokens }
    {*******************}
    final_tok, mutable_tok, immutable_tok,

    {**********************}
    { encapsulation tokens }
    {**********************}
    abstract_tok, public_tok, private_tok, protected_tok,

    {********************}
    { inheritance tokens }
    {********************}
    extends_tok,

    {****************************}
    { primitive data type tokens }
    {****************************}
    boolean_tok, char_tok, byte_tok, short_tok, integer_tok, long_tok,
      scalar_tok, double_tok,

    {***************************}
    { compound data type tokens }
    {***************************}
    complex_tok, vector_tok, string_tok,

    {********************}
    { declaration tokens }
    {********************}
    enum_tok, struct_tok, class_tok, interface_tok,

    {****************************}
    { complex declaration tokens }
    {****************************}
    procedure_tok, function_tok, shader_tok, object_tok, picture_tok, anim_tok,
      forward_tok,

    {****************}
    { file inclusion }
    {****************}
    include_tok,

    {****************}
    { boolean tokens }
    {****************}
    true_tok, false_tok, and_tok, or_tok, not_tok,

    {*************}
    { data tokens }
    {*************}
    integer_lit_tok, scalar_lit_tok, string_lit_tok, type_tok,

    {*******************}
    { identifier tokens }
    {*******************}
    id_tok, static_id_tok, type_id_tok,

    {*****************}
    { symbolic tokens }
    {*****************}
    left_paren_tok, right_paren_tok, left_bracket_tok, right_bracket_tok,
      semi_colon_tok, colon_tok, assignment_tok, period_tok, comma_tok,
      dot_dot_tok, quote_tok,

    {****************************}
    { relational operator tokens }
    {****************************}
    greater_than_tok, less_than_tok, equal_tok, not_equal_tok,
      greater_equal_tok, less_equal_tok,

    {***************************************}
    { pointer equality and assignment token }
    {***************************************}
    points_to_tok, not_points_to_tok,

    {******************************}
    { mathematical operator tokens }
    {******************************}
    plus_tok, minus_tok, times_tok, divide_tok, div_tok, mod_tok, up_arrow_tok,

    {****************************}
    { assignment operator tokens }
    {****************************}
    plus_equal_tok, minus_equal_tok, times_equal_tok, divide_equal_tok,

    {************************}
    { vector operator tokens }
    {************************}
    dot_tok, cross_tok, parallel_tok, perpendicular_tok,

    {*************************}
    { array allocation tokens }
    {*************************}
    dim_tok, redim_tok,

    {**************************}
    { struct allocation tokens }
    {**************************}
    new_tok, free_tok, renew_tok,

    {**************************}
    { smart array query tokens }
    {**************************}
    min_tok, max_tok, num_tok,

    {***************************}
    { antecedent pronoun tokens }
    {***************************}
    itself_tok, its_tok,

    {************}
    { nil tokens }
    {************}
    none_tok, some_tok,

    {****************}
    { special tokens }
    {****************}
    eof_tok); {token_kind_type}


const
  data_token_set = [id_tok, static_id_tok, type_id_tok, integer_lit_tok,
    scalar_lit_tok, string_lit_tok, error_tok];


type
  token_type = record
    comments: comments_type;

    case kind: token_kind_type of
      id_tok, static_id_tok, type_id_tok: (
        id: string_type
        );
      integer_lit_tok: (
        integer_val: longint
        );
      scalar_lit_tok: (
        scalar_val: double;
        decimal_places: integer;
        exponential_notation: boolean;
        );
      string_lit_tok: (
        string_ptr: string_ptr_type
        );
      error_tok: (
        ch: char
        );
  end; {token_type}


procedure Init_token(var token: token_type);
function Token_kind(value: integer): token_kind_type;

procedure Write_token_kind(kind: token_kind_type);
procedure Write_token(token: token_type);


{***********************************************}
{ The procedure, Token, is necessary to map     }
{ integer values to token_kinds. This operation }
{ is not supported by Pascal but its inverse is:}
{ To get the integer value from a token_kind,   }
{ use 'ord(token)'.                             }
{***********************************************}


implementation
var
  token_kind_array: array[0..255] of token_kind_type;


procedure Init_token_kind_array;
var
  counter: token_kind_type;
begin
  for counter := error_tok to eof_tok do
    token_kind_array[ord(counter)] := counter;
end; {procedure Init_token_kind_array}


procedure Init_token(var token: token_type);
begin
  with token do
    begin
      kind := error_tok;
      Init_comments(token.comments);
    end;
end; {procedure Init_token}


function Token_kind(value: integer): token_kind_type;
var
  kind: token_kind_type;
begin
  if (value < ord(error_tok)) or (value > ord(eof_tok)) then
    begin
      writeln('Error - no token_kind of value ', value: 1);
      kind := error_tok;
    end
  else
    kind := token_kind_array[value];
  Token_kind := kind;
end; {function Token_kind}


procedure Write_token_kind(kind: token_kind_type);
begin
  case kind of

    {*********************}
    { uninitialized token }
    {*********************}
    error_tok,

    {****************}
    { keyword tokens }
    {****************}
    is_tok:
      write('is_tok');
    isnt_tok:
      write('isnt_tok');
    does_tok:
      write('does_tok');
    doesnt_tok:
      write('doesnt_tok');
    has_tok:
      write('has_tok');
    with_tok:
      write('with_tok');
    each_tok:
      write('each_tok');
    in_tok:
      write('in_tok');
    s_tok:
      write('s_tok');
    of_tok:
      write('of_tok');
    to_tok:
      write('to_tok');

    {******************}
    { statement tokens }
    {******************}
    if_tok:
      write('if_tok');
    then_tok:
      write('then_tok');
    else_tok:
      write('else_tok');
    elseif_tok:
      write('elseif_tok');
    when_tok:
      write('when_tok');
    while_tok:
      write('while_tok');
    for_tok:
      write('for_tok');
    do_tok:
      write('do_tok');
    return_tok:
      write('return_tok');
    answer_tok:
      write('answer_tok');
    end_tok:
      write('end_tok');
    break_tok:
      write('break_tok');
    continue_tok:
      write('continue_tok');
    exit_tok:
      write('exit');
    loop_tok:
      write('loop_tok');
    refers_tok:
      write('refers_tok');

    {******************************}
    { input output statment tokens }
    {******************************}
    read_tok:
      write('read_tok');
    write_tok:
      write('write_tok');

    {****************}
    { boolean_tokens }
    {****************}
    true_tok:
      write('true_tok');
    false_tok:
      write('false_tok');
    and_tok:
      write('and_tok');
    or_tok:
      write('or_tok');
    not_tok:
      write('not_tok');

    {**********************}
    { storage class tokens }
    {**********************}
    const_tok:
      write('const_tok');
    reference_tok:
      write('reference_tok');
    static_tok:
      write('static_tok');
    void_tok:
      write('void_tok');
    native_tok:
      write('native_tok');
    global_tok:
      write('global_tok');

    {*******************}
    { protection tokens }
    {*******************}
    final_tok:
      write('final_tok');
    mutable_tok:
      write('mutable_tok');
    immutable_tok:
      write('immutable_tok');

    {**********************}
    { encapsulation tokens }
    {**********************}
    abstract_tok:
      write('abstract_tok');
    public_tok:
      write('public_tok');
    private_tok:
      write('private_tok');
    protected_tok:
      write('protected_tok');

    {********************}
    { inheritance tokens }
    {********************}
    extends_tok:
      write('extends_tok');

    {****************************}
    { primitive data type tokens }
    {****************************}
    boolean_tok:
      write('boolean_tok');
    char_tok:
      write('char_tok');

    byte_tok:
      write('byte_tok');
    short_tok:
      write('short_tok');

    integer_tok:
      write('integer_tok');
    long_tok:
      write('long_tok');

    scalar_tok:
      write('scalar_tok');
    double_tok:
      write('double_tok');

    {***************************}
    { compound data type tokens }
    {***************************}
    complex_tok:
      write('complex_tok');
    vector_tok:
      write('vector_tok');
    string_tok:
      write('string_tok');

    {********************}
    { declaration tokens }
    {********************}
    type_tok:
      write('type_tok');
    enum_tok:
      write('enum_tok');
    struct_tok:
      write('struct_tok');
    class_tok:
      write('class_tok');
    interface_tok:
      write('interface_tok');

    {****************************}
    { complex declaration tokens }
    {****************************}
    procedure_tok:
      write('procedure_tok');
    function_tok:
      write('function_tok');
    shader_tok:
      write('shader_tok');
    object_tok:
      write('object_tok');
    picture_tok:
      write('picture_tok');
    anim_tok:
      write('anim_tok');
    forward_tok:
      write('forward_tok');

    {****************}
    { file inclusion }
    {****************}
    include_tok:
      write('include_tok');

    {*************}
    { data tokens }
    {*************}
    integer_lit_tok:
      write('integer_lit_tok');
    scalar_lit_tok:
      write('scalar_lit_tok');
    string_lit_tok:
      write('string_lit_tok');

    {*******************}
    { identifier tokens }
    {*******************}
    id_tok:
      write('id_tok');
    static_id_tok:
      write('static_id_tok');
    type_id_tok:
      write('type_id_tok');

    {*****************}
    { symbolic tokens }
    {*****************}
    left_paren_tok:
      write('left_paren_tok');
    right_paren_tok:
      write('right_paren_tok');
    left_bracket_tok:
      write('left_bracket_tok');
    right_bracket_tok:
      write('right_bracket_tok');
    semi_colon_tok:
      write('semi_colon_tok');
    colon_tok:
      write('colon_tok');
    assignment_tok:
      write('assignment_tok');
    period_tok:
      write('period_tok');
    comma_tok:
      write('comma_tok');
    dot_dot_tok:
      write('dot_dot_tok');
    quote_tok:
      write('quote_tok');

    {****************************}
    { relational operator tokens }
    {****************************}
    greater_than_tok:
      write('greater_than_tok');
    less_than_tok:
      write('less_than_tok');
    equal_tok:
      write('equal_tok');
    not_equal_tok:
      write('not_equal_tok');
    greater_equal_tok:
      write('greater_equal_tok');
    less_equal_tok:
      write('less_equal_tok');

    {******************************}
    { mathematical operator tokens }
    {******************************}
    plus_tok:
      write('plus_tok');
    minus_tok:
      write('minus_tok');
    times_tok:
      write('times_tok');
    divide_tok:
      write('divide_tok');
    div_tok:
      write('div_tok');
    mod_tok:
      write('mod_tok');
    dot_tok:
      write('dot_tok');
    cross_tok:
      write('cross_tok');
    parallel_tok:
      write('parallel_tok');
    perpendicular_tok:
      write('perpendicular_tok');
    up_arrow_tok:
      write('up_arrow_tok');

    {****************************}
    { assignment operator tokens }
    {****************************}
    plus_equal_tok:
      write('plus_equal_tok');
    minus_equal_tok:
      write('minus_equal_tok');
    times_equal_tok:
      write('times_equal_tok');
    divide_equal_tok:
      write('divide_equal_tok');

    {***************************************}
    { pointer equality and assignment token }
    {***************************************}
    points_to_tok:
      write('points_to_tok');
    not_points_to_tok:
      write('not_points_to_tok');

    {*************************}
    { array allocation tokens }
    {*************************}
    dim_tok:
      write('dim_tok');
    redim_tok:
      write('redim_tok');

    {**************************}
    { struct allocation tokens }
    {**************************}
    new_tok:
      write('new_tok');
    free_tok:
      write('free_tok');
    renew_tok:
      write('renew_tok');

    {**************************}
    { smart array query tokens }
    {**************************}
    min_tok:
      write('min_tok');
    max_tok:
      write('max_tok');
    num_tok:
      write('num_tok');

    {***************************}
    { antecedent pronoun tokens }
    {***************************}
    itself_tok:
      write('itself_tok');
    its_tok:
      write('its_tok');

    {************}
    { nil tokens }
    {************}
    none_tok:
      write('none_tok');
    some_tok:
      write('some_tok');

    {****************}
    { special tokens }
    {****************}
    eof_tok:
      write('eof_tok');

  end; {case statement}
end; {procedure Write_token_kind}


procedure Write_token(token: token_type);
begin
  Write_token_kind(token.kind);

  {*************}
  { data tokens }
  {*************}
  if token.kind in data_token_set then
    begin
      write(' = ');
      case token.kind of

        {*******************}
        { identifier tokens }
        {*******************}
        id_tok, static_id_tok, type_id_tok:
          write(token.id);

        {*************}
        { data tokens }
        {*************}
        integer_lit_tok:
          write(token.integer_val);
        scalar_lit_tok:
          write(token.scalar_val: 1: token.decimal_places);
        string_lit_tok:
          Write_string(token.string_ptr);

        error_tok:
          write(token.ch);

      end; {case}
    end; {if}
end; {procedure Write_token}


initialization
  Init_token_kind_array;
end.
