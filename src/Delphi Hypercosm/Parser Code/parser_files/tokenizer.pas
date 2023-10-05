unit tokenizer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             tokenizer                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This scanner transforms the stream of characters        }
{       from the file into a stream of tokens which are         }
{       recognized by the parser.                               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, comments, tokens;


var
  next_token: token_type;
  reserved_word_set: set of token_kind_type;


function Get_token: token_type;
procedure Put_token(token: token_type);
procedure Get_next_token;

procedure Get_prev_token_comments(var comments_ptr: comments_ptr_type);
procedure Get_post_token_comments(var comments_ptr: comments_ptr_type);

procedure Push_tokenizer_state;
procedure Pop_tokenizer_state;

{********************************}
{ functions to map tokens to ids }
{********************************}
function Token_to_id(token: token_type): string;
function Token_kind_to_id(kind: token_kind_type): string;


implementation
uses
  new_memory, chars, hashtables, file_stack, scanner;


const
  symbols = ['(', ')', '[', ']', '+', '-', '*', '/', '^', '>', '<', ';', ':',
    '=', '.', ','];
  max_look_ahead = 8;
  memory_alert = false;


type
  look_ahead_buffer_ptr_type = ^look_ahead_buffer_type;
  look_ahead_buffer_type = array[1..max_look_ahead] of token_type;

  reserved_word_array_ptr_type = ^reserved_word_array_type;
  reserved_word_array_type = array[error_tok..eof_tok] of string_type;


  tokenizer_state_ptr_type = ^tokenizer_state_type;
  tokenizer_state_type = record
    next_token: token_type;
    look_ahead_buffer_ptr: look_ahead_buffer_ptr_type;

    look_ahead: integer;
    recursion_level: integer;

    next: tokenizer_state_ptr_type;
  end; {tokenizer_state_type}


var
  {****************************}
  { tokenizer global variables }
  {****************************}
  hashtable_ptr: hashtable_ptr_type; {for reserved words}
  reserved_word_array_ptr: reserved_word_array_ptr_type;
  tokenizer_state_stack: tokenizer_state_ptr_type;
  tokenizer_state_free_list: tokenizer_state_ptr_type;

  {***************************}
  { tokenizer state variables }
  {***************************}
  look_ahead_buffer_ptr: look_ahead_buffer_ptr_type;
  look_ahead: integer;
  recursion_level: integer;


function Find_next_token(token: token_type): token_type;
  forward;


{********************************}
{ tokenizer state stack routines }
{********************************}


function New_look_ahead_buffer: look_ahead_buffer_ptr_type;
var
  look_ahead_buffer_ptr: look_ahead_buffer_ptr_type;
  counter: integer;
begin
  new(look_ahead_buffer_ptr);
  for counter := 1 to max_look_ahead do
    Init_token(look_ahead_buffer_ptr^[counter]);
  New_look_ahead_buffer := look_ahead_buffer_ptr;
end; {function New_look_ahead_buffer}


function New_tokenizer_state: tokenizer_state_ptr_type;
var
  tokenizer_state_ptr: tokenizer_state_ptr_type;
begin
  {************************************}
  { get tokenizer state from free list }
  {************************************}
  if (tokenizer_state_free_list <> nil) then
    begin
      tokenizer_state_ptr := tokenizer_state_free_list;
      tokenizer_state_free_list := tokenizer_state_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new tokenizer state');
      new(tokenizer_state_ptr);

      {*********************************}
      { allocate tokenizer state buffer }
      {*********************************}
      with tokenizer_state_ptr^ do
        look_ahead_buffer_ptr := New_look_ahead_buffer;
    end;

  {****************************}
  { initialize tokenizer state }
  {****************************}
  with tokenizer_state_ptr^ do
    begin
      look_ahead := 0;
      recursion_level := 0;
      next := nil;
    end;

  New_tokenizer_state := tokenizer_state_ptr;
end; {function New_tokenizer_state}


procedure Free_tokenizer_state(var tokenizer_state_ptr:
  tokenizer_state_ptr_type);
begin
  {***********************************}
  { add tokenizer state to freee list }
  {***********************************}
  tokenizer_state_ptr^.next := tokenizer_state_free_list;
  tokenizer_state_free_list := tokenizer_state_ptr;
end; {procedure Free_tokenizer_state}


{*******************************************************}
{ routines to move data from tokenizer state to globals }
{*******************************************************}


procedure Swap_state_buffers(tokenizer_state_ptr: tokenizer_state_ptr_type);
var
  temp_look_ahead_buffer_ptr: look_ahead_buffer_ptr_type;
begin
  temp_look_ahead_buffer_ptr := tokenizer_state_ptr^.look_ahead_buffer_ptr;
  tokenizer_state_ptr^.look_ahead_buffer_ptr := look_ahead_buffer_ptr;
  look_ahead_buffer_ptr := temp_look_ahead_buffer_ptr;
end; {procedure Swap_state_buffers}


procedure Set_tokenizer_state(tokenizer_state_ptr: tokenizer_state_ptr_type);
begin
  {*************************************}
  { set current tokenizer state globals }
  {*************************************}
  next_token := tokenizer_state_ptr^.next_token;
  look_ahead := tokenizer_state_ptr^.look_ahead;
  recursion_level := tokenizer_state_ptr^.recursion_level;

  {**************************************************}
  { swap tokenizer state buffers with global buffers }
  {**************************************************}
  Swap_state_buffers(tokenizer_state_ptr);
end; {procedure Set_tokenizer_state}


procedure Get_tokenizer_state(tokenizer_state_ptr: tokenizer_state_ptr_type);
begin
  {*************************************}
  { get current tokenizer state globals }
  {*************************************}
  tokenizer_state_ptr^.next_token := next_token;
  tokenizer_state_ptr^.look_ahead := look_ahead;
  tokenizer_state_ptr^.recursion_level := recursion_level;

  {**************************************************}
  { swap tokenizer state buffers with global buffers }
  {**************************************************}
  Swap_state_buffers(tokenizer_state_ptr);
end; {procedure Get_tokenizer_state}


procedure Push_tokenizer_state;
var
  tokenizer_state_ptr: tokenizer_state_ptr_type;
begin
  {****************************}
  { push state to top of stack }
  {****************************}
  tokenizer_state_ptr := New_tokenizer_state;
  tokenizer_state_ptr^.next := tokenizer_state_stack;
  tokenizer_state_stack := tokenizer_state_ptr;

  {******************************}
  { save current tokenizer state }
  {******************************}
  Get_tokenizer_state(tokenizer_state_ptr);

  {*********************************}
  { initialize tokenizer state vars }
  {*********************************}
  look_ahead := 0;
  recursion_level := 0;
end; {procedure Push_tokenizer_state}


procedure Pop_tokenizer_state;
var
  tokenizer_state_ptr: tokenizer_state_ptr_type;
begin
  if tokenizer_state_stack <> nil then
    begin
      {*****************************}
      { pop state from top of stack }
      {*****************************}
      tokenizer_state_ptr := tokenizer_state_stack;
      tokenizer_state_stack := tokenizer_state_stack^.next;

      {**********************************}
      { restore previous tokenizer state }
      {**********************************}
      Set_tokenizer_state(tokenizer_state_ptr);

      Free_tokenizer_state(tokenizer_state_ptr);
    end;
end; {procedure Pop_tokenizer_state}


{********************}
{ tokenizer routines }
{********************}


function Get_identifier_tok(token: token_type): token_type;
var
  str: string_type;
  ch: char;
  counter: integer;
  done: boolean;
begin
  str := '';
  counter := 0;
  done := false;

  while not done do
    begin
      ch := Scan_char;
      str := str + ch;
      counter := counter + 1;
      if not (next_char in (alphabet + digits)) or (counter > string_size) then
        done := true;
    end;

  if (counter > string_size) then
    begin
      token.kind := error_tok;
      token.ch := Scan_char;
    end
  else
    begin
      token.kind := id_tok;
      token.id := str;
    end;

  Get_identifier_tok := token;
end; {function Get_identifier_tok}


function Get_string_lit_tok(token: token_type): token_type;
begin
  single_line_mode := true;
  Scan_next_char;
  token.string_ptr := New_string;

  while (next_char <> double_quote) and (not (next_char in [end_of_file, NL,
    CR])) do
    begin
      Append_char_to_string(next_char, token.string_ptr);
      Scan_next_char;
    end;

  if (next_char = double_quote) then
    token.kind := string_lit_tok
  else
    token.kind := error_tok;

  Scan_next_char;
  single_line_mode := false;

  Get_string_lit_tok := token;
end; {function Get_string_lit_tok}


function Char_value(ch: char): integer;
begin
  Char_value := ord(ch) - ord('0');
end; {function Char_value}


function Get_number_tok(token: token_type): token_type;
var
  integer_total: longint;
  fractional_total, total: double;
  coefficient, exponent: double;
  negative_exponent: boolean;
  digits_before, digits_after: boolean;
  found_decimal, found_dot_dot: boolean;
  decimal_places: integer;
begin
  {***********************}
  { read integer mantissa }
  {***********************}
  integer_total := 0;
  digits_before := false;
  digits_after := false;
  found_decimal := false;
  found_dot_dot := false;

  if next_char in digits then
    digits_before := true;
  while next_char in digits do
    begin
      integer_total := (integer_total * 10) + Char_value(next_char);
      Scan_next_char;
    end;

  {***********************}
  { read decimal mantissa }
  {***********************}
  if next_char = '.' then
    begin
      found_decimal := true;
      Scan_next_char;
      if next_char = '.' then
        begin
          found_decimal := false;
          if digits_before then
            begin
              Unget_char('.');
              char_counter := char_counter - 1;
            end
          else
            begin
              token.kind := dot_dot_tok;
              found_dot_dot := true;
              Scan_next_char;
            end;
        end;
    end;

  {**********************}
  { read fractional part }
  {**********************}
  fractional_total := 0;
  if found_decimal then
    begin
      coefficient := 0.1;
      decimal_places := 0;

      while next_char in digits do
        begin
          digits_after := true;
          decimal_places := decimal_places + 1;
          fractional_total := fractional_total + (coefficient *
            Char_value(next_char));
          coefficient := coefficient / 10.0;
          Scan_next_char;
        end;

      token.kind := scalar_lit_tok;
      token.scalar_val := integer_total + fractional_total;
      token.decimal_places := decimal_places;

      if (not digits_before) and (not digits_after) then
        token.kind := period_tok;
    end
  else if not found_dot_dot then
    begin
      token.kind := integer_lit_tok;
      token.integer_val := integer_total;
    end;

  {***************}
  { read exponent }
  {***************}
  total := 0;
  if (token.kind = scalar_lit_tok) then
    if (next_char = 'E') or (next_char = 'e') then
      begin
        token.exponential_notation := true;
        Scan_next_char;

        if next_char = '-' then
          negative_exponent := true
        else
          negative_exponent := false;
        if next_char in ['-', '+'] then
          Scan_next_char;
        if not (next_char in digits) then
          begin
            token.kind := error_tok;
            token.ch := next_char;
          end
        else
          begin
            exponent := Char_value(Scan_char);
            while next_char in digits do
              exponent := (exponent * 10.0) + Char_value(Scan_char);

            coefficient := 1.0;
            total := integer_total + fractional_total;
            while (exponent > 0) do
              begin
                coefficient := coefficient * 10.0;
                exponent := exponent - 1;
              end;
            if negative_exponent then
              total := total / coefficient
            else
              total := total * coefficient;
          end;
        token.scalar_val := total;
      end
    else
      token.exponential_notation := false;

  Get_number_tok := token;
end; {function Get_number_tok}


function Get_comment_tok(token: token_type): token_type;
var
  comment_ptr: comment_ptr_type;
  eoln_comment: boolean;
begin
  {***************}
  { line comments }
  {***************}
  eoln_comment := not blank_line;
  Scan_next_char;

  {***********************************}
  { scan through leading spaces, tabs }
  {***********************************}
  if false then
    while (next_char <> CR) and (next_char <> NL) and (next_char in whitespace)
      do
      Scan_next_char;

  {***************}
  { parse comment }
  {***************}
  comment_ptr := New_comment(line_comment);
  while (next_char <> CR) and (next_char <> NL) and (next_char <> end_of_file)
    do
    begin
      Append_char_to_string(next_char, comment_ptr^.string_ptr);
      Scan_next_char;
    end;

  if eoln_comment then
    Append_comment(token.comments.post_comment_list, comment_ptr)
  else
    Append_comment(token.comments.prev_comment_list, comment_ptr);

  Scan_next_char;

  recursion_level := recursion_level + 1;
  token := Find_next_token(token);
  recursion_level := recursion_level - 1;

  Get_comment_tok := token;
end; {procedure Get_comment_tok}


function Get_symbol_tok(token: token_type): token_type;
var
  ch: char;
begin
  ch := Scan_char;
  case ch of
    '(':
      token.kind := left_paren_tok;
    ')':
      token.kind := right_paren_tok;
    '[':
      token.kind := left_bracket_tok;
    ']':
      token.kind := right_bracket_tok;
    '^':
      token.kind := up_arrow_tok;
    ';':
      token.kind := semi_colon_tok;
    '=':
      token.kind := equal_tok;
    '.':
      token.kind := period_tok;
    ',':
      token.kind := comma_tok;

    '+':
      if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := plus_equal_tok;
        end
      else
        token.kind := plus_tok;

    '-':
      if (next_char in digits) or (next_char = '.') then
        begin
          token := Get_number_tok(token);
          if (token.kind = scalar_lit_tok) then
            token.scalar_val := -token.scalar_val
          else if (token.kind = integer_lit_tok) then
            token.integer_val := -token.integer_val;
        end
      else if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := minus_equal_tok;
        end
      else if (next_char = '>') then
        begin
          Scan_next_char;
          token.kind := points_to_tok;
        end
      else
        token.kind := minus_tok;

    '*':
      if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := times_equal_tok;
        end
      else
        token.kind := times_tok;

    '/':
      if (next_char = '/') then
        begin
          token := Get_comment_tok(token);
        end
      else if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := divide_equal_tok;
        end
      else
        token.kind := divide_tok;

    ':':
      if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := assignment_tok;
        end
      else
        token.kind := colon_tok;

    '>':
      if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := greater_equal_tok;
        end
      else
        token.kind := greater_than_tok;

    '<':
      if (next_char = '=') then
        begin
          Scan_next_char;
          token.kind := less_equal_tok;
        end
      else if (next_char = '>') then
        begin
          Scan_next_char;
          token.kind := not_equal_tok;
        end
      else
        token.kind := less_than_tok;

  end; {case}

  Get_symbol_tok := token;
end; {function Get_symbol_tok}


procedure Check_reserved_word(var token: token_type);
var
  index: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(hashtable_ptr, index, token.id) then
    token.kind := Token_kind(index);
end; {procedure Check_reserved_word}


procedure Put_token(token: token_type);
begin
  {***************************}
  { save next token for later }
  {***************************}
  look_ahead := look_ahead + 1;
  look_ahead_buffer_ptr^[look_ahead] := next_token;
  next_token := token;
end; {procedure Put_token}


function Scan_next_token(token: token_type): token_type;
var
  comment_list: comment_list_type;
begin
  {***********************}
  { append block comments }
  {***********************}
  comment_list := Scan_block_comments;
  Append_comment_list(token.comments.prev_comment_list, comment_list);

  if (next_char in alphabet) then
    begin
      token := Get_identifier_tok(token);
      token.id := Lower_case_str(token.id);
      Check_reserved_word(token);

      if next_char = single_quote then
        begin
          {**************************}
          { handle isn't contraction }
          {**************************}
          if token.id = 'isn' then
            begin
              Scan_next_char;
              if next_char = 't' then
                begin
                  Scan_next_char;
                  token.kind := isnt_tok;
                  token.id := '';
                end
              else
                begin
                  Unget_char(single_quote);
                  char_counter := char_counter - 1;
                end;
            end

              {****************************}
              { handle doesn't contraction }
              {****************************}
          else if token.id = 'doesn' then
            begin
              Scan_next_char;
              if next_char = 't' then
                begin
                  Scan_next_char;
                  token.kind := doesnt_tok;
                  token.id := '';
                end
              else
                begin
                  Unget_char(single_quote);
                  char_counter := char_counter - 1;
                end;
            end;
        end;

    end

      {*********************}
      { handle apostrophe s }
      {*********************}
  else if (next_char = single_quote) then
    begin
      Scan_next_char;
      if next_char = 's' then
        begin
          Scan_next_char;
          token.kind := s_tok;
        end
      else
        token.kind := quote_tok;
    end

      {************************}
      { handle symbolic tokens }
      {************************}
  else if (next_char = double_quote) then
    token := Get_string_lit_tok(token)
  else if (next_char in digits) or (next_char = '.') then
    token := Get_number_tok(token)
  else if (next_char in symbols) then
    token := Get_symbol_tok(token)
  else if (next_char = end_of_file) then
    token.kind := eof_tok
  else
    begin
      token.kind := error_tok;
      token.ch := Scan_char;
    end;

  Scan_next_token := token;
end; {function Scan_next_token}


function Find_compound_token(token: token_type): token_type;
var
  temp_char_count: integer;
  new_token: token_type;
begin
  {********************}
  { id might be a type }
  {********************}
  if (token.kind in [id_tok, class_tok]) then
    begin
      recursion_level := recursion_level + 1;
      Advance_scanner;
      temp_char_count := char_counter;
      Init_token(new_token);
      next_token := Find_next_token(new_token);
      recursion_level := recursion_level - 1;

      if next_token.kind = type_tok then
        begin
          {*****************************}
          { use up token and next_token }
          {*****************************}
          Append_comment_list(token.comments.post_comment_list,
            token.comments.post_comment_list);
          Append_comment_list(token.comments.prev_comment_list,
            new_token.comments.prev_comment_list);
          Append_comment_list(token.comments.post_comment_list,
            new_token.comments.post_comment_list);

          case token.kind of

            id_tok:
              token.kind := type_id_tok;

            class_tok:
              begin
                token.kind := type_id_tok;
                token.id := 'subject';
              end;

          end; {case}
        end
      else
        begin
          Put_token(next_token);
          last_good_char := temp_char_count;
        end;
    end

      {*************************}
      { id might be a static id }
      {*************************}
  else if token.kind = static_tok then
    begin
      recursion_level := recursion_level + 1;
      Advance_scanner;
      temp_char_count := char_counter;
      Init_token(new_token);
      next_token := Find_next_token(new_token);
      recursion_level := recursion_level - 1;

      if next_token.kind = id_tok then
        begin
          {*****************************}
          { use up token and next_token }
          {*****************************}
          Append_comment_list(token.comments.post_comment_list,
            token.comments.post_comment_list);
          Append_comment_list(token.comments.prev_comment_list,
            new_token.comments.prev_comment_list);
          Append_comment_list(token.comments.post_comment_list,
            new_token.comments.post_comment_list);

          token.kind := static_id_tok;
          token.id := next_token.id;
        end
      else
        begin
          Put_token(next_token);
          last_good_char := temp_char_count;
        end;
    end;

  Find_compound_token := token;
end; {function Find_compound_token}


function Find_next_token(token: token_type): token_type;
var
  comment_list: comment_list_type;
begin
  if (look_ahead = 0) then
    Advance_scanner;
  if (recursion_level = 0) and (look_ahead = 0) then
    Advance_file_marker;

  {**************************}
  { get or lookup next token }
  {**************************}
  if (look_ahead <> 0) then
    begin
      token := look_ahead_buffer_ptr^[look_ahead];
      look_ahead := look_ahead - 1;
    end
  else
    token := Scan_next_token(token);

  {**************************************}
  { continue parsing for compound tokens }
  {**************************************}
  if recursion_level + look_ahead < max_look_ahead then
    if token.kind in [id_tok, class_tok, static_tok] then
      token := Find_compound_token(token);

  {***********************}
  { append block comments }
  {***********************}
  comment_list := Scan_block_comments;
  Append_comment_list(token.comments.prev_comment_list, comment_list);

  Find_next_token := token;
end; {function Find_next_token}


{**************************************}
{ routines for parsing compound tokens }
{**************************************}


procedure Get_next_token;
begin
  next_token := Find_next_token(next_token);
end; {procedure Get_next_token}


function Get_token: token_type;
begin
  Get_token := next_token;
  Get_next_token;
end; {function Get_token}


procedure Get_prev_token_comments(var comments_ptr: comments_ptr_type);
begin
  if next_token.comments.prev_comment_list.comment_ptr <> nil then
    begin
      if comments_ptr = nil then
        comments_ptr := New_comments;

      comments_ptr^.prev_comment_list := next_token.comments.prev_comment_list;
      Init_comment_list(next_token.comments.prev_comment_list);
    end;
end; {function Get_prev_token_comments}


procedure Get_post_token_comments(var comments_ptr: comments_ptr_type);
begin
  if next_token.comments.post_comment_list.comment_ptr <> nil then
    begin
      if comments_ptr = nil then
        comments_ptr := New_comments;

      comments_ptr^.post_comment_list := next_token.comments.post_comment_list;
      Init_comment_list(next_token.comments.post_comment_list);
    end;
end; {procedure Get_post_token_comments}


function Token_kind_to_id(kind: token_kind_type): string;
var
  id: string;
begin
  case kind of

    {*********************}
    { uninitialized token }
    {*********************}
    error_tok:
      id := '';

    {****************}
    { keyword tokens }
    {****************}
    is_tok:
      id := 'is';
    isnt_tok:
      begin
        id := 'isn';
        id := concat(id, Char_to_str(single_quote));
        id := concat(id, 't');
      end;

    does_tok:
      id := 'does';
    doesnt_tok:
      begin
        id := 'doesn';
        id := concat(id, Char_to_str(single_quote));
        id := concat(id, 't');
      end;

    has_tok:
      id := 'has';
    with_tok:
      id := 'with';
    each_tok:
      id := 'each';
    in_tok:
      id := 'in';
    of_tok:
      id := 'of';
    to_tok:
      id := 'to';

    s_tok:
      begin
        id := concat(Char_to_str(single_quote), 's');
      end;

    {******************}
    { statement tokens }
    {******************}
    if_tok:
      id := 'if';
    then_tok:
      id := 'then';
    else_tok:
      id := 'else';
    elseif_tok:
      id := 'elseif';
    when_tok:
      id := 'when';
    while_tok:
      id := 'while';
    for_tok:
      id := 'for';
    do_tok:
      id := 'do';
    return_tok:
      id := 'return';
    answer_tok:
      id := 'answer';
    end_tok:
      id := 'end';
    break_tok:
      id := 'break';
    continue_tok:
      id := 'continue';
    exit_tok:
      id := 'exit';
    loop_tok:
      id := 'loop';
    refers_tok:
      id := 'refers';

    {******************************}
    { input output statment tokens }
    {******************************}
    read_tok:
      id := 'read';
    write_tok:
      id := 'write';

    {****************}
    { boolean_tokens }
    {****************}
    true_tok:
      id := 'true';
    false_tok:
      id := 'false';
    and_tok:
      id := 'and';
    or_tok:
      id := 'or';
    not_tok:
      id := 'not';

    {**********************}
    { storage class tokens }
    {**********************}
    const_tok:
      id := 'const';
    reference_tok:
      id := 'reference';
    static_tok:
      id := 'static';
    void_tok:
      id := 'objective';
    native_tok:
      id := 'native';
    global_tok:
      id := 'global';

    {*******************}
    { protection tokens }
    {*******************}
    final_tok:
      id := 'final';
    mutable_tok:
      id := 'mutable';
    immutable_tok:
      id := 'immutable';

    {**********************}
    { encapsulation tokens }
    {**********************}
    abstract_tok:
      id := 'abstract';
    public_tok:
      id := 'public';
    private_tok:
      id := 'private';
    protected_tok:
      id := 'protected';

    {********************}
    { inheritance tokens }
    {********************}
    extends_tok:
      id := 'extends';

    {****************************}
    { primitive data type tokens }
    {****************************}
    boolean_tok:
      id := 'boolean';
    char_tok:
      id := 'char';

    byte_tok:
      id := 'byte';
    short_tok:
      id := 'short';

    integer_tok:
      id := 'integer';
    long_tok:
      id := 'long';

    scalar_tok:
      id := 'scalar';
    double_tok:
      id := 'double';

    {***************************}
    { compound data type tokens }
    {***************************}
    complex_tok:
      id := 'complex';
    vector_tok:
      id := 'vector';
    string_tok:
      id := 'string';

    {********************}
    { declaration tokens }
    {********************}
    type_tok:
      id := 'type';
    enum_tok:
      id := 'enum';
    struct_tok:
      id := 'struct';
    class_tok:
      id := 'subject';
    interface_tok:
      id := 'adjective';

    {****************************}
    { complex declaration tokens }
    {****************************}
    procedure_tok:
      id := 'verb';
    function_tok:
      id := 'question';
    shader_tok:
      id := 'shader';
    object_tok:
      id := 'shape';
    picture_tok:
      id := 'picture';
    anim_tok:
      id := 'anim';
    forward_tok:
      id := 'forward';

    {****************}
    { file inclusion }
    {****************}
    include_tok:
      id := 'include';

    {*************}
    { data tokens }
    {*************}
    id_tok:
      id := 'identifier';
    type_id_tok:
      id := 'type identifier';
    integer_lit_tok:
      id := 'integer literal';
    scalar_lit_tok:
      id := 'scalar literal';
    string_lit_tok:
      id := 'string literal';

    {*****************}
    { symbolic tokens }
    {*****************}
    left_paren_tok:
      id := '(';
    right_paren_tok:
      id := ')';
    left_bracket_tok:
      id := '[';
    right_bracket_tok:
      id := ']';
    semi_colon_tok:
      id := ';';
    colon_tok:
      id := ':';
    assignment_tok:
      id := ':=';
    period_tok:
      id := '.';
    comma_tok:
      id := ',';
    dot_dot_tok:
      id := '..';
    quote_tok:
      id := '"';

    {****************************}
    { relational operator tokens }
    {****************************}
    greater_than_tok:
      id := '>';
    less_than_tok:
      id := '<';
    equal_tok:
      id := '=';
    not_equal_tok:
      id := '<>';
    greater_equal_tok:
      id := '>=';
    less_equal_tok:
      id := '<=';

    {******************************}
    { mathematical operator tokens }
    {******************************}
    plus_tok:
      id := '+';
    minus_tok:
      id := '-';
    times_tok:
      id := '*';
    divide_tok:
      id := '/';
    div_tok:
      id := 'div';
    mod_tok:
      id := 'mod';
    dot_tok:
      id := 'dot';
    cross_tok:
      id := 'cross';
    parallel_tok:
      id := 'parallel';
    perpendicular_tok:
      id := 'perpendicular';
    up_arrow_tok:
      id := '^';

    {****************************}
    { assignment operator tokens }
    {****************************}
    plus_equal_tok:
      id := '+=';
    minus_equal_tok:
      id := '-=';
    times_equal_tok:
      id := '*=';
    divide_equal_tok:
      id := '/=';

    {***************************************}
    { pointer equality and assignment token }
    {***************************************}
    points_to_tok:
      id := '->';
    not_points_to_tok:
      id := '><';

    {*************************}
    { array allocation tokens }
    {*************************}
    dim_tok:
      id := 'dim';
    redim_tok:
      id := 'redim';

    {**************************}
    { struct allocation tokens }
    {**************************}
    new_tok:
      id := 'new';
    free_tok:
      id := 'free';
    renew_tok:
      id := 'renew';

    {**************************}
    { smart array query tokens }
    {**************************}
    min_tok:
      id := 'min';
    max_tok:
      id := 'max';
    num_tok:
      id := 'num';

    {***************************}
    { antecedent pronoun tokens }
    {***************************}
    itself_tok:
      id := 'itself';
    its_tok:
      id := 'its';

    {************}
    { nil tokens }
    {************}
    none_tok:
      id := 'none';
    some_tok:
      id := 'some';

    {****************}
    { special tokens }
    {****************}
    eof_tok:
      id := 'eof';

  end; {case statement}

  Token_kind_to_id := id;
end; {function Token_kind_to_id}


function Token_to_id(token: token_type): string;
var
  id: string;
begin
  if token.kind = id_tok then
    id := token.id
  else if token.kind = type_id_tok then
    id := concat(token.id, ' type')
  else if token.kind in reserved_word_set then
    id := reserved_word_array_ptr^[token.kind]
  else
    id := Token_kind_to_id(token.kind);

  Token_to_id := id;
end; {function Token_to_id}


procedure Make_reserved_word(token_kind: token_kind_type);
var
  name: string;
begin
  name := Token_kind_to_id(token_kind);
  Enter_hashtable(hashtable_ptr, name, ord(token_kind));
  reserved_word_set := reserved_word_set + [token_kind];
  reserved_word_array_ptr^[token_kind] := name;
end; {procedure make_reserved_word}


procedure Make_reserved_words;
begin
  {****************}
  { keyword tokens }
  {****************}
  Make_reserved_word(is_tok);
  Make_reserved_word(does_tok);
  Make_reserved_word(has_tok);
  Make_reserved_word(with_tok);
  Make_reserved_word(each_tok);
  Make_reserved_word(in_tok);
  Make_reserved_word(of_tok);
  Make_reserved_word(to_tok);

  {******************}
  { statement tokens }
  {******************}
  Make_reserved_word(if_tok);
  Make_reserved_word(then_tok);
  Make_reserved_word(else_tok);
  Make_reserved_word(elseif_tok);
  Make_reserved_word(when_tok);
  Make_reserved_word(while_tok);
  Make_reserved_word(for_tok);
  Make_reserved_word(do_tok);
  Make_reserved_word(return_tok);
  Make_reserved_word(answer_tok);
  Make_reserved_word(end_tok);
  Make_reserved_word(break_tok);
  Make_reserved_word(continue_tok);
  Make_reserved_word(exit_tok);
  Make_reserved_word(loop_tok);
  Make_reserved_word(refers_tok);

  {*******************************}
  { input output statement tokens }
  {*******************************}
  Make_reserved_word(read_tok);
  Make_reserved_word(write_tok);

  {**********************}
  { storage class tokens }
  {**********************}
  Make_reserved_word(const_tok);
  Make_reserved_word(reference_tok);
  Make_reserved_word(static_tok);
  Make_reserved_word(void_tok);
  Make_reserved_word(native_tok);
  Make_reserved_word(global_tok);

  {**********************}
  { encapsulation tokens }
  {**********************}
  Make_reserved_word(abstract_tok);
  Make_reserved_word(final_tok);
  Make_reserved_word(public_tok);
  Make_reserved_word(private_tok);
  Make_reserved_word(protected_tok);

  {********************}
  { inheritance tokens }
  {********************}
  Make_reserved_word(extends_tok);

  {****************************}
  { primitive data type tokens }
  {****************************}
  Make_reserved_word(boolean_tok);
  Make_reserved_word(char_tok);

  Make_reserved_word(byte_tok);
  Make_reserved_word(short_tok);

  Make_reserved_word(integer_tok);
  Make_reserved_word(long_tok);

  Make_reserved_word(scalar_tok);
  Make_reserved_word(double_tok);

  {***************************}
  { compound data type tokens }
  {***************************}
  Make_reserved_word(complex_tok);
  Make_reserved_word(vector_tok);
  {Make_reserved_word(string_tok);}

  {********************}
  { declaration tokens }
  {********************}
  Make_reserved_word(type_tok);
  Make_reserved_word(enum_tok);
  Make_reserved_word(struct_tok);
  Make_reserved_word(class_tok);
  Make_reserved_word(interface_tok);

  {****************************}
  { complex declaration tokens }
  {****************************}
  Make_reserved_word(procedure_tok);
  Make_reserved_word(function_tok);
  Make_reserved_word(shader_tok);
  Make_reserved_word(object_tok);
  Make_reserved_word(picture_tok);
  Make_reserved_word(anim_tok);
  Make_reserved_word(forward_tok);

  {****************}
  { file inclusion }
  {****************}
  Make_reserved_word(include_tok);

  {****************}
  { boolean tokens }
  {****************}
  Make_reserved_word(true_tok);
  Make_reserved_word(false_tok);
  Make_reserved_word(and_tok);
  Make_reserved_word(or_tok);
  Make_reserved_word(not_tok);

  {*****************}
  { symbolic tokens }
  {*****************}
  Make_reserved_word(div_tok);
  Make_reserved_word(mod_tok);
  Make_reserved_word(dot_tok);
  Make_reserved_word(cross_tok);
  Make_reserved_word(parallel_tok);
  Make_reserved_word(perpendicular_tok);

  {***************************}
  { antecedent pronoun tokens }
  {***************************}
  Make_reserved_word(itself_tok);
  Make_reserved_word(its_tok);

  {*************************}
  { array allocation tokens }
  {*************************}
  Make_reserved_word(dim_tok);
  Make_reserved_word(redim_tok);

  {**************************}
  { struct allocation tokens }
  {**************************}
  Make_reserved_word(new_tok);
  Make_reserved_word(free_tok);
  Make_reserved_word(renew_tok);

  {**************************}
  { smart array query tokens }
  {**************************}
  Make_reserved_word(min_tok);
  Make_reserved_word(max_tok);
  Make_reserved_word(num_tok);

  {************}
  { nil tokens }
  {************}
  Make_reserved_word(none_tok);
  Make_reserved_word(some_tok);
end; {procedure Make_reserved_words}


procedure Init_reserved_words;
var
  token_kind: token_kind_type;
begin
  if memory_alert then
    writeln('allocating new reserved word array');
  new(reserved_word_array_ptr);

  reserved_word_set := [];
  for token_kind := error_tok to eof_tok do
    reserved_word_array_ptr^[token_kind] := '';

  Make_reserved_words;
end; {procedure Init_reserved_words}


initialization
  if memory_alert then
    writeln('allocating new look ahead buffer');
  new(look_ahead_buffer_ptr);

  {******************************}
  { initialize tokenizer globals }
  {******************************}
  Init_token(next_token);
  next_token.kind := eof_tok;
  look_ahead := 0;
  recursion_level := 0;

  tokenizer_state_stack := nil;
  tokenizer_state_free_list := nil;
  hashtable_ptr := New_hashtable;

  {***************************}
  { initialize reserved words }
  {***************************}
  Init_reserved_words;


finalization
  dispose(look_ahead_buffer_ptr);
  dispose(reserved_word_array_ptr);
  Free_hashtable(hashtable_ptr, true);
end.
