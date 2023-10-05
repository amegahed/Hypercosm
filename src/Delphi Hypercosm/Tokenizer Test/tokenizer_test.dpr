program tokenizer_test;


{$APPTYPE CONSOLE}


uses
  SysUtils,
  tokenizer in '..\Parser Code\parser_files\tokenizer.pas',
  scanner in '..\Parser Code\parser_files\scanner.pas',
  strings in '..\Common Code\basic_files\strings.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  comments in '..\Abstract Syntax Tree Code\attributes_files\comments.pas',
  string_structs in '..\Common Code\basic_files\string_structs.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  tokens in '..\Parser Code\parser_files\tokens.pas',
  hashtables in '..\Common Code\basic_files\hashtables.pas',
  file_stack in '..\Common Code\basic_files\file_stack.pas',
  text_files in '..\Nonportable Code\system_files\text_files.pas';

var
  done: boolean;
  ch: char;


begin
  Open_next_file('test.txt');

  done := false;
  while not done do
    begin
      Get_next_token;
      if next_token.kind <> eof_tok then
        begin
          Write_token(next_token);
          writeln;
        end
      else
        done := true;
    end;

  readln(ch);
end.


end.
 