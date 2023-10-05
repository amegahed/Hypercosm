unit comments;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              comments                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The comments module is used to store comments           }
{       as auxilliary data structs in the syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, string_structs;


type
  {*****************************************}
  { structures for creating single comments }
  {*****************************************}
  comment_kind_type = (line_comment, block_comment);
  comment_ptr_type = ^comment_type;
  comment_type = record
    next: comment_ptr_type;
    case kind: comment_kind_type of
      line_comment: (
        string_ptr: string_ptr_type;
        );
      block_comment: (
        string_tree_ptr: string_tree_ptr_type;
        trailing_spaces: integer;
        );
  end; {comment_type}

  {*******************************************}
  { structures for creating lists of comments }
  {*******************************************}
  comment_list_ptr_type = ^comment_list_type;
  comment_list_type = record
    comment_ptr: comment_ptr_type;
    last_comment_ptr: comment_ptr_type;
    next: comment_list_ptr_type;
  end; {comment_list_type}

  {*****************************************************}
  { structures for creating groups of lists of comments }
  {*****************************************************}
  comments_ptr_type = ^comments_type;
  comments_type = record
    prev_comment_list: comment_list_type;
    post_comment_list: comment_list_type;
    next: comments_ptr_type;
  end; {comment_type}


{***************************************}
{ routines for creating single comments }
{***************************************}
function New_comment(kind: comment_kind_type): comment_ptr_type;
procedure Init_comment(var comment: comment_type;
  kind: comment_kind_type);
procedure Free_comment(var comment_ptr: comment_ptr_type);

{*****************************************}
{ routines for creating lists of comments }
{*****************************************}
function New_comment_list: comment_list_ptr_type;
procedure Init_comment_list(var comment_list: comment_list_type);
procedure Free_comment_list(var comment_list_ptr: comment_list_ptr_type);

{***************************************************}
{ routines for creating groups of lists of comments }
{***************************************************}
function New_comments: comments_ptr_type;
procedure Init_comments(var comments: comments_type);
procedure Free_comments(var comments_ptr: comments_ptr_type);

{*************************************}
{ routines for building comment lists }
{*************************************}
procedure Prepend_comment(var comment_list: comment_list_type;
  comment_ptr: comment_ptr_type);
procedure Append_comment(var comment_list: comment_list_type;
  comment_ptr: comment_ptr_type);
procedure Prepend_comment_list(var comment_list: comment_list_type;
  var prev_comment_list: comment_list_type);
procedure Append_comment_list(var comment_list: comment_list_type;
  var post_comment_list: comment_list_type);

{**********************************}
{ routines for extracting comments }
{**********************************}
function Get_prev_comments(comments_ptr: comments_ptr_type): comment_ptr_type;
function Get_post_comments(comments_ptr: comments_ptr_type): comment_ptr_type;
function Get_line_comments(comment_ptr: comment_ptr_type): comment_ptr_type;
function Get_block_comments(comment_ptr: comment_ptr_type): comment_ptr_type;


implementation
uses
  errors, new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  comment_block_ptr_type = ^comment_block_type;
  comment_block_type = array[0..block_size] of comment_type;

  comment_list_block_ptr_type = ^comment_list_block_type;
  comment_list_block_type = array[0..block_size] of comment_list_type;

  comments_block_ptr_type = ^comments_block_type;
  comments_block_type = array[0..block_size] of comments_type;


var
  comment_free_list: comment_ptr_type;
  comment_block_ptr: comment_block_ptr_type;
  comment_counter: integer;

  comment_list_free_list: comment_list_ptr_type;
  comment_list_block_ptr: comment_list_block_ptr_type;
  comment_list_counter: integer;

  comments_free_list: comments_ptr_type;
  comments_block_ptr: comments_block_ptr_type;
  comments_counter: integer;


{***************************************}
{ routines for creating single comments }
{***************************************}


procedure Init_comment(var comment: comment_type;
  kind: comment_kind_type);
begin
  comment.kind := kind;
  comment.next := nil;

  case kind of
    line_comment:
      begin
        comment.string_ptr := nil;
      end;
    block_comment:
      begin
        comment.string_tree_ptr := nil;
        comment.trailing_spaces := 0;
      end;
  end; {case}
end; {procedure Init_comment}


function New_comment(kind: comment_kind_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
  index: integer;
begin
  {****************************}
  { get comment from free list }
  {****************************}
  if comment_free_list <> nil then
    begin
      comment_ptr := comment_free_list;
      comment_free_list := comment_free_list^.next;
    end
  else
    begin
      index := comment_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new comment block');
          new(comment_block_ptr);
        end;
      comment_ptr := @comment_block_ptr^[index];
      comment_counter := comment_counter + 1;
    end;

  {********************}
  { initialize comment }
  {********************}
  Init_comment(comment_ptr^, kind);

  New_comment := comment_ptr;
end; {function New_comment}


procedure Free_comment(var comment_ptr: comment_ptr_type);
begin
  if comment_ptr <> nil then
    begin
      comment_ptr^.next := comment_free_list;
      comment_free_list := comment_ptr;
      comment_ptr := nil;
    end;
end; {procedure Free_comment}


{*****************************************}
{ routines for creating lists of comments }
{*****************************************}


procedure Init_comment_list(var comment_list: comment_list_type);
begin
  comment_list.comment_ptr := nil;
  comment_list.last_comment_ptr := nil;
  comment_list.next := nil;
end; {function Init_comment_list}


function New_comment_list: comment_list_ptr_type;
var
  comment_list_ptr: comment_list_ptr_type;
  index: integer;
begin
  {*********************************}
  { get comment list from free list }
  {*********************************}
  if comment_list_free_list <> nil then
    begin
      comment_list_ptr := comment_list_free_list;
      comment_list_free_list := comment_list_free_list^.next;
    end
  else
    begin
      index := comment_list_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new comment_list block');
          new(comment_list_block_ptr);
        end;
      comment_list_ptr := @comment_list_block_ptr^[index];
      comment_list_counter := comment_list_counter + 1;
    end;

  {*************************}
  { initialize comment list }
  {*************************}
  Init_comment_list(comment_list_ptr^);

  New_comment_list := comment_list_ptr;
end; {function New_comment_list}


procedure Free_comment_list(var comment_list_ptr: comment_list_ptr_type);
begin
  if comment_list_ptr <> nil then
    begin
      comment_list_ptr^.next := comment_list_free_list;
      comment_list_free_list := comment_list_ptr;
      comment_list_ptr := nil;
    end;
end; {procedure Free_comment_list}


{***************************************************}
{ routines for creating groups of lists of comments }
{***************************************************}


procedure Init_comments(var comments: comments_type);
begin
  with comments do
    begin
      Init_comment_list(prev_comment_list);
      Init_comment_list(post_comment_list);
      next := nil;
    end;
end; {procedure Init_comments}


function New_comments: comments_ptr_type;
var
  comments_ptr: comments_ptr_type;
  index: integer;
begin
  {*****************************}
  { get comments from free list }
  {*****************************}
  if comments_free_list <> nil then
    begin
      comments_ptr := comments_free_list;
      comments_free_list := comments_free_list^.next;
    end
  else
    begin
      index := comments_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new comments block');
          new(comments_block_ptr);
        end;
      comments_ptr := @comments_block_ptr^[index];
      comments_counter := comments_counter + 1;
    end;

  {*********************}
  { initialize comments }
  {*********************}
  Init_comments(comments_ptr^);

  New_comments := comments_ptr;
end; {function New_comments}


procedure Free_comments(var comments_ptr: comments_ptr_type);
begin
  if comments_ptr <> nil then
    begin
      comments_ptr^.next := comments_free_list;
      comments_free_list := comments_ptr;
      comments_ptr := nil;
    end;
end; {procedure Free_comments}


{*************************************}
{ routines for building comment lists }
{*************************************}


procedure Prepend_comment(var comment_list: comment_list_type;
  comment_ptr: comment_ptr_type);
begin
  if comment_ptr <> nil then
    begin
      {**********************************************}
      { add a single comment to the head of the list }
      {**********************************************}
      comment_ptr^.next := comment_list.last_comment_ptr;
      comment_list.comment_ptr := comment_ptr;
      if comment_list.last_comment_ptr = nil then
        comment_list.last_comment_ptr := comment_ptr;
    end;
end; {procedure Prepend_comment}


procedure Append_comment(var comment_list: comment_list_type;
  comment_ptr: comment_ptr_type);
begin
  if comment_ptr <> nil then
    begin
      {**********************************************}
      { add a single comment to the tail of the list }
      {**********************************************}
      if comment_list.last_comment_ptr <> nil then
        begin
          comment_list.last_comment_ptr^.next := comment_ptr;
          comment_list.last_comment_ptr := comment_ptr;
        end
      else
        begin
          comment_list.comment_ptr := comment_ptr;
          comment_list.last_comment_ptr := comment_ptr;
        end;
    end;
end; {procedure Append_comment}


procedure Prepend_comment_list(var comment_list: comment_list_type;
  var prev_comment_list: comment_list_type);
begin
  if prev_comment_list.comment_ptr <> nil then
    begin
      {***********************************************}
      { add prev comment list to head of comment list }
      {***********************************************}
      if comment_list.comment_ptr <> nil then
        begin
          prev_comment_list.last_comment_ptr^.next := comment_list.comment_ptr;
          comment_list.comment_ptr := prev_comment_list.comment_ptr;
        end
      else
        begin
          comment_list.comment_ptr := prev_comment_list.comment_ptr;
          comment_list.last_comment_ptr := prev_comment_list.last_comment_ptr;
        end;
      prev_comment_list.comment_ptr := nil;
      prev_comment_list.last_comment_ptr := nil;
    end;
end; {procedure Prepend_comment_list}


procedure Append_comment_list(var comment_list: comment_list_type;
  var post_comment_list: comment_list_type);
begin
  if post_comment_list.comment_ptr <> nil then
    begin
      {***********************************************}
      { add post comment list to tail of comment list }
      {***********************************************}
      if comment_list.comment_ptr <> nil then
        begin
          comment_list.last_comment_ptr^.next := post_comment_list.comment_ptr;
          comment_list.last_comment_ptr := post_comment_list.last_comment_ptr;
        end
      else
        begin
          comment_list.comment_ptr := post_comment_list.comment_ptr;
          comment_list.last_comment_ptr := post_comment_list.last_comment_ptr;
        end;
      post_comment_list.comment_ptr := nil;
      post_comment_list.last_comment_ptr := nil;
    end;
end; {procedure Append_comment_list}


{**********************************}
{ routines for extracting comments }
{**********************************}


function Get_prev_comments(comments_ptr: comments_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  if comments_ptr <> nil then
    comment_ptr := comments_ptr^.prev_comment_list.comment_ptr
  else
    comment_ptr := nil;

  Get_prev_comments := comment_ptr;
end; {function Get_prev_comments}


function Get_post_comments(comments_ptr: comments_ptr_type): comment_ptr_type;
var
  comment_ptr: comment_ptr_type;
begin
  if comments_ptr <> nil then
    comment_ptr := comments_ptr^.post_comment_list.comment_ptr
  else
    comment_ptr := nil;

  Get_post_comments := comment_ptr;
end; {function Get_post_comments}


function Get_line_comments(comment_ptr: comment_ptr_type): comment_ptr_type;
var
  found: boolean;
begin
  found := false;
  while (comment_ptr <> nil) and (not found) do
    if comment_ptr^.kind = line_comment then
      found := true
    else
      comment_ptr := comment_ptr^.next;

  Get_line_comments := comment_ptr;
end; {function Get_line_comments}


function Get_block_comments(comment_ptr: comment_ptr_type): comment_ptr_type;
var
  found: boolean;
begin
  found := false;
  while (comment_ptr <> nil) and (not found) do
    if comment_ptr^.kind = block_comment then
      found := true
    else
      comment_ptr := comment_ptr^.next;

  Get_block_comments := comment_ptr;
end; {function Get_block_comments}


initialization
  comment_free_list := nil;
  comment_block_ptr := nil;
  comment_counter := 0;

  comment_list_free_list := nil;
  comment_list_block_ptr := nil;
  comment_list_counter := 0;

  comments_free_list := nil;
  comments_block_ptr := nil;
  comments_counter := 0;
end.
