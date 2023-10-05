program file_test;


{$APPTYPE CONSOLE}


uses
  SysUtils,
  chars in '..\Common Code\basic_files\chars.pas',
  strings in '..\Common Code\basic_files\strings.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  text_files in '..\Nonportable Code\system_files\text_files.pas',
  find_files in '..\Nonportable Code\system_files\find_files.pas',
  string_structs in '..\Common Code\basic_files\string_structs.pas';


var
  file_name, directory_name: string_type;
  search_path_ptr: search_path_ptr_type;
  infile_ptr: text_file_ptr_type;
  done: boolean;
  ch: char;


procedure Read_file(file_name: string_type);
begin
  infile_ptr := Open_text_file(file_name, read_only);

  done := false;
  while not done do
    begin
      ch := Get_text_file_char(infile_ptr);
      if (ch <> end_of_file) then
        begin
          write(ch);
        end
      else
        done := true;
    end;
end; {procedure Read_file}


begin
  file_name := 'test.txt';

  search_path_ptr := nil;
  Add_path_to_search_path('.', search_path_ptr);
  {
  Add_path_to_search_path('this', search_path_ptr);
  Add_path_to_search_path('that', search_path_ptr);
  Add_path_to_search_path('other thing', search_path_ptr);
  }

  // if Found_file_in_search_path(file_name, search_path_ptr, directory_name) then

  directory_name := '.';
  if Found_file_in_directory_tree(file_name, directory_name) then
    begin
      writeln('The file ', Quotate_str(file_name), ' was found in ',
        Quotate_str(directory_name));
      Read_file(directory_name + file_name);
    end
  else
    begin
      writeln('Error - file ', Quotate_str(file_name), ' could not be found.');
    end;

  readln(ch);
end.

