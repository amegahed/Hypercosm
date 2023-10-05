unit asm_exprs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             asm_exprs                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The asm_exprs module defines all of the expressions     }
{       used in the mnemonic assembly code, the external        }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, asms;


{*************************************************}
{ routines for making and referencing expressions }
{*************************************************}
procedure Make_new_asm_exprs(count: asm_index_type);
function New_asm_expr(kind: expr_kind_type): expr_ptr_type;
function Ref_asm_expr(index: asm_index_type): expr_ref_type;

{******************************************************}
{ routines to assemble expressions from assembly codes }
{******************************************************}
function Assemble_expr: expr_ptr_type;
function Assemble_exprs: expr_ptr_type;

{*********************************************************}
{ routines to disassemble expressions into assembly codes }
{*********************************************************}
procedure Disassemble_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
procedure Disassemble_exprs(var outfile: text;
  expr_ptr: expr_ptr_type);

{****************************************}
{ functions returning assembler progress }
{****************************************}
function Exprs_assembled: asm_index_type;
function Exprs_disassembled: asm_index_type;


implementation
uses
  new_memory, complex_numbers, vectors, hashtables, expr_attributes,
  lit_attributes, arrays, stmts, decls, type_decls, asm_bounds, asm_indices,
  asm_stmts, asm_type_decls;


const
  memory_alert = false;
  debug = false;


type
  expr_mnemonic_array_type = array[expr_kind_type] of mnemonic_type;


var
  expr_mnemonic_array: expr_mnemonic_array_type;
  hashtable_ptr: hashtable_ptr_type;
  expr_asm_count, expr_disasm_count: asm_index_type;
  expr_block_ptr: expr_ptr_type;
  expr_block_count: asm_index_type;


procedure Make_expr_mnemonic(kind: expr_kind_type;
  mnemonic: mnemonic_type);
var
  value: hashtable_value_type;
begin
  value := ord(kind);
  if Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    begin
      writeln('Error - duplicate expr mnemonic found for ');
      Write_expr_kind(kind);
      writeln;
    end
  else
    begin
      Enter_hashtable(hashtable_ptr, mnemonic, value);
      expr_mnemonic_array[kind] := mnemonic;
    end;
end; {procedure Make_expr_asm}


procedure Make_expr_mnemonics;
var
  expr_kind: expr_kind_type;
begin
  hashtable_ptr := New_hashtable;

  {**************************************}
  { initialize expression mnemonic array }
  {**************************************}
  for expr_kind := error_expr to nil_reference do
    expr_mnemonic_array[expr_kind] := '';

  {***************************************************************}
  {                        unary operators                        }
  {***************************************************************}

  {********************}
  { negation operators }
  {********************}
  Make_expr_mnemonic(not_op, 'not');
  Make_expr_mnemonic(byte_negate, 'yng');
  Make_expr_mnemonic(short_negate, 'sng');
  Make_expr_mnemonic(integer_negate, 'ing');
  Make_expr_mnemonic(long_negate, 'lng');
  Make_expr_mnemonic(scalar_negate, 'fng');
  Make_expr_mnemonic(double_negate, 'dng');
  Make_expr_mnemonic(complex_negate, 'cng');
  Make_expr_mnemonic(vector_negate, 'vng');

  {**********************}
  { addressing operators }
  {**********************}
  Make_expr_mnemonic(address_op, 'aop');
  Make_expr_mnemonic(deref_op, 'dop');

  {*************************************}
  { implicit integeral type conversions }
  {*************************************}
  Make_expr_mnemonic(byte_to_short, 'yts');
  Make_expr_mnemonic(short_to_integer, 'sti');
  Make_expr_mnemonic(integer_to_long, 'itl');
  Make_expr_mnemonic(integer_to_scalar, 'itf');
  Make_expr_mnemonic(long_to_scalar, 'ltf');
  Make_expr_mnemonic(long_to_double, 'ltd');

  {**********************************}
  { implicit scalar type conversions }
  {**********************************}
  Make_expr_mnemonic(scalar_to_double, 'ftd');
  Make_expr_mnemonic(scalar_to_complex, 'ftm');

  {****************************}
  { vector component operators }
  {****************************}
  Make_expr_mnemonic(vector_x, 'vcx');
  Make_expr_mnemonic(vector_y, 'vcy');
  Make_expr_mnemonic(vector_z, 'vcz');

  {*****************************}
  { memory allocation functions }
  {*****************************}
  Make_expr_mnemonic(new_struct_fn, 'new');
  Make_expr_mnemonic(dim_array_fn, 'dim');

  {*******************}
  { special functions }
  {*******************}
  Make_expr_mnemonic(min_fn, 'min');
  Make_expr_mnemonic(max_fn, 'max');
  Make_expr_mnemonic(num_fn, 'num');

  {***************************************************************}
  {                       binary operators                        }
  {***************************************************************}

  {*******************}
  { boolean operators }
  {*******************}
  Make_expr_mnemonic(and_op, 'and');
  Make_expr_mnemonic(or_op, 'orr');
  Make_expr_mnemonic(and_if_op, 'aif');
  Make_expr_mnemonic(or_if_op, 'oif');

  {******************************}
  { boolean relational operators }
  {******************************}
  Make_expr_mnemonic(boolean_equal, 'beq');
  Make_expr_mnemonic(boolean_not_equal, 'bne');

  {***************************}
  { char relational operators }
  {***************************}
  Make_expr_mnemonic(char_equal, 'ceq');
  Make_expr_mnemonic(char_not_equal, 'cne');

  {***************************}
  { byte relational operators }
  {***************************}
  Make_expr_mnemonic(byte_equal, 'yeq');
  Make_expr_mnemonic(byte_not_equal, 'yne');
  Make_expr_mnemonic(byte_less_than, 'ylt');
  Make_expr_mnemonic(byte_greater_than, 'ygt');
  Make_expr_mnemonic(byte_less_equal, 'yle');
  Make_expr_mnemonic(byte_greater_equal, 'yge');

  {***************************}
  { byte arithmetic operators }
  {***************************}
  Make_expr_mnemonic(byte_add, 'yad');
  Make_expr_mnemonic(byte_subtract, 'ysb');
  Make_expr_mnemonic(byte_multiply, 'yml');
  Make_expr_mnemonic(byte_divide, 'ydv');
  Make_expr_mnemonic(byte_mod, 'ymd');

  {************************************}
  { short integer relational operators }
  {************************************}
  Make_expr_mnemonic(short_equal, 'seq');
  Make_expr_mnemonic(short_not_equal, 'sne');
  Make_expr_mnemonic(short_less_than, 'slt');
  Make_expr_mnemonic(short_greater_than, 'sgt');
  Make_expr_mnemonic(short_less_equal, 'sle');
  Make_expr_mnemonic(short_greater_equal, 'sge');

  {************************************}
  { short integer arithmetic operators }
  {************************************}
  Make_expr_mnemonic(short_add, 'sad');
  Make_expr_mnemonic(short_subtract, 'ssb');
  Make_expr_mnemonic(short_multiply, 'sml');
  Make_expr_mnemonic(short_divide, 'sdv');
  Make_expr_mnemonic(short_mod, 'smd');

  {******************************}
  { integer relational operators }
  {******************************}
  Make_expr_mnemonic(integer_equal, 'ieq');
  Make_expr_mnemonic(integer_not_equal, 'ine');
  Make_expr_mnemonic(integer_less_than, 'ilt');
  Make_expr_mnemonic(integer_greater_than, 'igt');
  Make_expr_mnemonic(integer_less_equal, 'ile');
  Make_expr_mnemonic(integer_greater_equal, 'ige');

  {******************************}
  { integer arithmetic operators }
  {******************************}
  Make_expr_mnemonic(integer_add, 'iad');
  Make_expr_mnemonic(integer_subtract, 'isb');
  Make_expr_mnemonic(integer_multiply, 'iml');
  Make_expr_mnemonic(integer_divide, 'idv');
  Make_expr_mnemonic(integer_mod, 'imd');

  {***********************************}
  { long integer relational operators }
  {***********************************}
  Make_expr_mnemonic(long_equal, 'leq');
  Make_expr_mnemonic(long_not_equal, 'lne');
  Make_expr_mnemonic(long_less_than, 'llt');
  Make_expr_mnemonic(long_greater_than, 'lgt');
  Make_expr_mnemonic(long_less_equal, 'lle');
  Make_expr_mnemonic(long_greater_equal, 'lge');

  {***********************************}
  { long integer arithmetic operators }
  {***********************************}
  Make_expr_mnemonic(long_add, 'lad');
  Make_expr_mnemonic(long_subtract, 'lsb');
  Make_expr_mnemonic(long_multiply, 'lml');
  Make_expr_mnemonic(long_divide, 'ldv');
  Make_expr_mnemonic(long_mod, 'lmd');

  {*****************************}
  { scalar relational operators }
  {*****************************}
  Make_expr_mnemonic(scalar_equal, 'feq');
  Make_expr_mnemonic(scalar_not_equal, 'fne');
  Make_expr_mnemonic(scalar_less_than, 'flt');
  Make_expr_mnemonic(scalar_greater_than, 'fgt');
  Make_expr_mnemonic(scalar_less_equal, 'fle');
  Make_expr_mnemonic(scalar_greater_equal, 'fge');

  {*****************************}
  { scalar arithmetic operators }
  {*****************************}
  Make_expr_mnemonic(scalar_add, 'fad');
  Make_expr_mnemonic(scalar_subtract, 'fsb');
  Make_expr_mnemonic(scalar_multiply, 'fml');
  Make_expr_mnemonic(scalar_divide, 'fdv');
  Make_expr_mnemonic(scalar_exponent, 'fex');

  {**********************************************}
  { double precision scalar relational operators }
  {**********************************************}
  Make_expr_mnemonic(double_equal, 'deq');
  Make_expr_mnemonic(double_not_equal, 'dne');
  Make_expr_mnemonic(double_less_than, 'dlt');
  Make_expr_mnemonic(double_greater_than, 'dgt');
  Make_expr_mnemonic(double_less_equal, 'dle');
  Make_expr_mnemonic(double_greater_equal, 'dge');

  {**********************************************}
  { double precision scalar arithmetic operators }
  {**********************************************}
  Make_expr_mnemonic(double_add, 'dad');
  Make_expr_mnemonic(double_subtract, 'dsb');
  Make_expr_mnemonic(double_multiply, 'dml');
  Make_expr_mnemonic(double_divide, 'ddv');
  Make_expr_mnemonic(double_exponent, 'dex');

  {******************************}
  { complex relational operators }
  {******************************}
  Make_expr_mnemonic(complex_equal, 'meq');
  Make_expr_mnemonic(complex_not_equal, 'mne');

  {******************************}
  { complex arithmetic operators }
  {******************************}
  Make_expr_mnemonic(complex_add, 'mad');
  Make_expr_mnemonic(complex_subtract, 'msb');
  Make_expr_mnemonic(complex_multiply, 'mml');
  Make_expr_mnemonic(complex_divide, 'mdv');

  {*****************************}
  { vector relational operators }
  {*****************************}
  Make_expr_mnemonic(vector_equal, 'veq');
  Make_expr_mnemonic(vector_not_equal, 'vne');

  {*****************************}
  { vector arithmetic operators }
  {*****************************}
  Make_expr_mnemonic(vector_add, 'vad');
  Make_expr_mnemonic(vector_subtract, 'vsb');
  Make_expr_mnemonic(vector_scalar_multiply, 'vml');
  Make_expr_mnemonic(vector_scalar_divide, 'vdv');
  Make_expr_mnemonic(vector_vector_multiply, 'vvm');
  Make_expr_mnemonic(vector_vector_divide, 'vvd');
  Make_expr_mnemonic(vector_mod, 'vmd');
  Make_expr_mnemonic(vector_dot_product, 'vdp');
  Make_expr_mnemonic(vector_cross_product, 'vcp');
  Make_expr_mnemonic(vector_parallel, 'vpl');
  Make_expr_mnemonic(vector_perpendicular, 'vpn');

  {********************************************************}
  { array / structure / proto pointer relational operators }
  {********************************************************}
  Make_expr_mnemonic(array_ptr_equal, 'ape');
  Make_expr_mnemonic(array_ptr_not_equal, 'apn');
  Make_expr_mnemonic(struct_ptr_equal, 'spe');
  Make_expr_mnemonic(struct_ptr_not_equal, 'spn');
  Make_expr_mnemonic(proto_equal, 'peq');
  Make_expr_mnemonic(proto_not_equal, 'pne');
  Make_expr_mnemonic(reference_equal, 'rfe');
  Make_expr_mnemonic(reference_not_equal, 'rfn');

  {***************************************************************}
  {                      array expression terms                   }
  {***************************************************************}

  {******************************}
  { enumerated array expressions }
  {******************************}
  Make_expr_mnemonic(boolean_array_expr, 'bax');
  Make_expr_mnemonic(char_array_expr, 'cax');

  {***************************}
  { integer array expressions }
  {***************************}
  Make_expr_mnemonic(byte_array_expr, 'yax');
  Make_expr_mnemonic(short_array_expr, 'hax');
  Make_expr_mnemonic(integer_array_expr, 'iax');
  Make_expr_mnemonic(long_array_expr, 'lax');

  {**************************}
  { scalar array expressions }
  {**************************}
  Make_expr_mnemonic(scalar_array_expr, 'fax');
  Make_expr_mnemonic(double_array_expr, 'dax');
  Make_expr_mnemonic(complex_array_expr, 'xax');
  Make_expr_mnemonic(vector_array_expr, 'vax');

  {**********************************}
  { array / struct array expressions }
  {**********************************}
  Make_expr_mnemonic(array_array_expr, 'aax');
  Make_expr_mnemonic(struct_array_expr, 'sax');
  Make_expr_mnemonic(static_struct_array_expr, 'tax');

  {******************************************}
  { subprogram / reference array expressions }
  {******************************************}
  Make_expr_mnemonic(proto_array_expr, 'pax');
  Make_expr_mnemonic(reference_array_expr, 'rax');

  {************************}
  { array expression terms }
  {************************}
  Make_expr_mnemonic(subarray_expr, 'asx');
  Make_expr_mnemonic(element_expr, 'ele');

  {***************************************************************}
  {                        array dimensioning                     }
  {***************************************************************}

  {*******************************}
  { enumerated array dimensioning }
  {*******************************}
  Make_expr_mnemonic(boolean_array_dim, 'bdm');
  Make_expr_mnemonic(char_array_dim, 'cdm');

  {****************************}
  { integer array dimensioning }
  {****************************}
  Make_expr_mnemonic(byte_array_dim, 'ydm');
  Make_expr_mnemonic(short_array_dim, 'hdm');
  Make_expr_mnemonic(integer_array_dim, 'idm');
  Make_expr_mnemonic(long_array_dim, 'ldm');

  {***************************}
  { scalar array dimensioning }
  {***************************}
  Make_expr_mnemonic(scalar_array_dim, 'fdm');
  Make_expr_mnemonic(double_array_dim, 'ddm');
  Make_expr_mnemonic(complex_array_dim, 'xdm');
  Make_expr_mnemonic(vector_array_dim, 'vdm');

  {***********************************}
  { array / struct array dimensioning }
  {***********************************}
  Make_expr_mnemonic(array_array_dim, 'adm');
  Make_expr_mnemonic(struct_array_dim, 'sdm');
  Make_expr_mnemonic(static_struct_array_dim, 'tdm');

  {*********************************************}
  { subprogram and reference array dimensioning }
  {*********************************************}
  Make_expr_mnemonic(proto_array_dim, 'pdm');
  Make_expr_mnemonic(reference_array_dim, 'rdm');

  {***************************************************************}
  {                       array dereferencing                     }
  {***************************************************************}

  {*******************************}
  { enumerated array dimensioning }
  {*******************************}
  Make_expr_mnemonic(boolean_array_deref, 'bdf');
  Make_expr_mnemonic(char_array_deref, 'cdf');

  {****************************}
  { integer array dimensioning }
  {****************************}
  Make_expr_mnemonic(byte_array_deref, 'ydf');
  Make_expr_mnemonic(short_array_deref, 'hdf');
  Make_expr_mnemonic(integer_array_deref, 'idf');
  Make_expr_mnemonic(long_array_deref, 'ldf');

  {***************************}
  { scalar array dimensioning }
  {***************************}
  Make_expr_mnemonic(scalar_array_deref, 'fdf');
  Make_expr_mnemonic(double_array_deref, 'ddf');
  Make_expr_mnemonic(complex_array_deref, 'xdf');
  Make_expr_mnemonic(vector_array_deref, 'vdf');

  {***********************************}
  { array / struct array dimensioning }
  {***********************************}
  Make_expr_mnemonic(array_array_deref, 'adf');
  Make_expr_mnemonic(struct_array_deref, 'sdf');
  Make_expr_mnemonic(static_struct_array_deref, 'tdf');

  {*******************************************}
  { subprogram / reference array dimensioning }
  {*******************************************}
  Make_expr_mnemonic(proto_array_deref, 'pdf');
  Make_expr_mnemonic(reference_array_deref, 'rdf');

  {***************************************************************}
  {                   array subrange expressions                  }
  {***************************************************************}

  {*******************************}
  { enumerated array dimensioning }
  {*******************************}
  Make_expr_mnemonic(boolean_array_subrange, 'bas');
  Make_expr_mnemonic(char_array_subrange, 'cas');

  {****************************}
  { integer array dimensioning }
  {****************************}
  Make_expr_mnemonic(byte_array_subrange, 'yas');
  Make_expr_mnemonic(short_array_subrange, 'has');
  Make_expr_mnemonic(integer_array_subrange, 'ias');
  Make_expr_mnemonic(long_array_subrange, 'las');

  {***************************}
  { scalar array dimensioning }
  {***************************}
  Make_expr_mnemonic(scalar_array_subrange, 'fas');
  Make_expr_mnemonic(double_array_subrange, 'das');
  Make_expr_mnemonic(complex_array_subrange, 'xas');
  Make_expr_mnemonic(vector_array_subrange, 'vas');

  {***********************************}
  { array / struct array dimensioning }
  {***********************************}
  Make_expr_mnemonic(array_array_subrange, 'aas');
  Make_expr_mnemonic(struct_array_subrange, 'sas');
  Make_expr_mnemonic(static_struct_array_subrange, 'tas');

  {*******************************************}
  { subprogram / reference array dimensioning }
  {*******************************************}
  Make_expr_mnemonic(proto_array_subrange, 'pas');
  Make_expr_mnemonic(reference_array_subrange, 'ras');

  {*******************************************}
  { implicit references used in array assigns }
  {*******************************************}
  Make_expr_mnemonic(array_base, 'abs');

  {***************************************************************}
  {                    structure expression terms                 }
  {***************************************************************}

  {***********************}
  { structure expressions }
  {***********************}
  Make_expr_mnemonic(struct_expr, 'sex');

  {**********************}
  { structure allocation }
  {**********************}
  Make_expr_mnemonic(struct_new, 'snw');

  {*************************}
  { structure dereferencing }
  {*************************}
  Make_expr_mnemonic(struct_deref, 'sdr');
  Make_expr_mnemonic(struct_offset, 'sos');
  Make_expr_mnemonic(field_deref, 'fdr');
  Make_expr_mnemonic(field_offset, 'fos');

  {***********************************************}
  { implicit references used in structure assigns }
  {***********************************************}
  Make_expr_mnemonic(struct_base, 'sbs');
  Make_expr_mnemonic(static_struct_base, 'tbs');

  {***************************************************************}
  {                         expression terms                      }
  {***************************************************************}

  {***************************}
  { explicit type conversions }
  {***************************}
  Make_expr_mnemonic(ptr_cast, 'ptr');
  Make_expr_mnemonic(type_query, 'tqr');

  {********************************************}
  { complex pairs and vector triplets of exprs }
  {********************************************}
  Make_expr_mnemonic(complex_pair, 'cmp');
  Make_expr_mnemonic(vector_triplet, 'vtr');

  {************************}
  { user defined functions }
  {************************}
  Make_expr_mnemonic(user_fn, 'ufn');

  {***************************************************************}
  {                           terminals                           }
  {***************************************************************}

  {***********************************}
  { user defined variable identifiers }
  {***********************************}
  Make_expr_mnemonic(global_identifier, 'gid');
  Make_expr_mnemonic(local_identifier, 'lid');
  Make_expr_mnemonic(nested_identifier, 'nid');

  {*******************************}
  { user defined type identifiers }
  {*******************************}
  Make_expr_mnemonic(field_identifier, 'fid');

  {**********************************************}
  { references to previously mentioned variables }
  {**********************************************}
  Make_expr_mnemonic(itself, 'its');
  Make_expr_mnemonic(new_itself, 'nit');
  Make_expr_mnemonic(implicit_expr, 'imx');

  {***************************************************************}
  {                      expression literals        	            }
  {***************************************************************}

  {*********************}
  { enumerated literals }
  {*********************}
  Make_expr_mnemonic(true_val, 'tru');
  Make_expr_mnemonic(false_val, 'fls');
  Make_expr_mnemonic(char_lit, 'cli');
  Make_expr_mnemonic(enum_lit, 'eli');

  {******************}
  { integer literals }
  {******************}
  Make_expr_mnemonic(byte_lit, 'yli');
  Make_expr_mnemonic(short_lit, 'sli');
  Make_expr_mnemonic(integer_lit, 'ili');
  Make_expr_mnemonic(long_lit, 'lli');

  {*****************}
  { scalar literals }
  {*****************}
  Make_expr_mnemonic(scalar_lit, 'fli');
  Make_expr_mnemonic(double_lit, 'dli');
  Make_expr_mnemonic(complex_lit, 'mli');
  Make_expr_mnemonic(vector_lit, 'vli');

  {******************************}
  { array and structure literals }
  {******************************}
  Make_expr_mnemonic(nil_array, 'nla');
  Make_expr_mnemonic(nil_struct, 'nls');
  Make_expr_mnemonic(nil_proto, 'nlp');
  Make_expr_mnemonic(nil_reference, 'nlr');
end; {procedure Make_expr_mnemonics}


{*************************************************}
{ routines for making and referencing expressions }
{*************************************************}


procedure Make_new_asm_exprs(count: asm_index_type);
var
  expr_block_size: longint;
begin
  if count > 0 then
    begin
      {*************************}
      { compute expr block size }
      {*************************}
      expr_block_size := longint(count + 1) * sizeof(expr_type);

      {*********************}
      { allocate expr block }
      {*********************}
      if memory_alert then
        writeln('allocating new expr block');
      expr_block_ptr := expr_ptr_type(New_ptr(expr_block_size));
      expr_block_count := count;
    end;
end; {procedure Make_new_asm_exprs}


function New_asm_expr(kind: expr_kind_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  expr_asm_count := expr_asm_count + 1;
  expr_ptr := Ref_asm_expr(expr_asm_count);
  Init_expr(expr_ptr, kind);
  expr_ptr^.expr_index := expr_asm_count;
  New_asm_expr := expr_ptr;
end; {function New_asm_expr}


function Ref_asm_expr(index: asm_index_type): expr_ref_type;
begin
  if index > expr_block_count then
    Asm_error;
  Ref_asm_expr := expr_ref_type(longint(expr_block_ptr) + sizeof(expr_type) *
    (index - 1));
end; {function Ref_asm_expr}


{***********************************************************}
{ routines to covert between assembly codes and expressions }
{***********************************************************}


function Expr_kind_to_mnemonic(kind: expr_kind_type): mnemonic_type;
begin
  Expr_kind_to_mnemonic := expr_mnemonic_array[kind];
end; {function Expr_to_mnemonic}


function Mnemonic_to_expr_kind(mnemonic: mnemonic_type): expr_kind_type;
var
  value: hashtable_value_type;
begin
  if not Found_hashtable_value_by_key(hashtable_ptr, value, mnemonic) then
    Asm_error;
  Mnemonic_to_expr_kind := expr_kind_type(value);
end; {function Mnemonic_to_expr_kind}


{******************************************************}
{ routines to assemble expressions from assembly codes }
{******************************************************}


function Assemble_complex: complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Assemble_scalar;
  complex_val.b := Assemble_scalar;

  Assemble_complex := complex_val;
end; {function Assemble_complex}


function Assemble_vector: vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Assemble_scalar;
  vector_val.y := Assemble_scalar;
  vector_val.z := Assemble_scalar;

  Assemble_vector := vector_val;
end; {function Assemble_vector}


procedure Assemble_expr_fields(expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do

    {***************************************************************}
    {                      expression operators       	            }
    {***************************************************************}

    {*****************}
    { unary operators }
    {*****************}
    if kind in unary_operator_set then
      operand_ptr := Assemble_expr

      {******************}
      { binary operators }
      {******************}
    else if kind in binary_operator_set then
      begin
        left_operand_ptr := Assemble_expr;
        right_operand_ptr := Assemble_expr;
      end

        {***************************************************************}
        {                      array expression terms                   }
        {***************************************************************}
    else if kind in array_expr_set then
      case kind of

        {*******************}
        { array expressions }
        {*******************}
        boolean_array_expr..reference_array_expr:
          begin
            array_expr_bounds_list_ptr := Assemble_array_bounds_list;
            array_element_exprs_ptr := Assemble_exprs;
          end;
        subarray_expr:
          begin
            array_expr_bounds_ref := Assemble_array_bounds;
            subarray_element_exprs_ptr := Assemble_exprs;
          end;
        element_expr:
          element_array_expr_ptr := Assemble_expr;

        {********************}
        { array dimensioning }
        {********************}
        boolean_array_dim..reference_array_dim:
          begin
            dim_bounds_list_ptr := Assemble_array_bounds_list;

            {*******************************************************}
            { array of array / dynamic structure array dimensioning }
            {*******************************************************}
            if kind in [array_array_dim, struct_array_dim] then
              dim_element_expr_ptr := Assemble_expr

              {*************************************}
              { static structure array dimensioning }
              {*************************************}
            else if kind = static_struct_array_dim then
              begin
                dim_static_struct_type_ref :=
                  forward_type_ref_type(Assemble_type);
                dim_static_struct_init_stmt_ptr :=
                  forward_stmt_ptr_type(Assemble_stmt);
              end;
          end;

        {*********************}
        { array dereferencing }
        {*********************}
        boolean_array_deref..reference_array_deref:
          begin
            deref_index_list_ptr := Assemble_array_index_list;

            deref_base_ptr := Assemble_expr;
            deref_element_ref := Assemble_expr;

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            if kind = static_struct_array_deref then
              deref_static_struct_type_ref :=
                forward_type_ref_type(Assemble_type);
          end;

        {****************************}
        { array subrange expressions }
        {****************************}
        boolean_array_subrange..reference_array_subrange:
          begin
            subrange_index_list_ptr := Assemble_array_index_list;
            subrange_bounds_list_ptr := Assemble_array_bounds_list;
            Link_array_bounds_index_list(subrange_bounds_list_ptr,
              subrange_index_list_ptr);

            subrange_base_ptr := Assemble_expr;
            subrange_element_ref := Assemble_expr;

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            if kind = static_struct_array_subrange then
              subrange_static_struct_type_ref :=
                forward_type_ref_type(Assemble_type);
          end;

        {*******************************************}
        { implicit references used in array assigns }
        {*******************************************}
        array_base:
          array_base_expr_ref := Assemble_expr;

      end {case}

        {***************************************************************}
        {                    structure expression terms                 }
        {***************************************************************}
    else if kind in struct_expr_set then
      case kind of

        {********************}
        { struct expressions }
        {********************}
        struct_expr:
          begin
            struct_expr_size := Assemble_integer;
            field_exprs_ptr := Assemble_expr;
          end;

        {**********************}
        { structure allocation }
        {**********************}
        struct_new:
          begin
            new_struct_type_ref := forward_type_ref_type(Assemble_type);
            new_struct_init_stmt_ptr := forward_stmt_ptr_type(Assemble_stmt);
          end;

        {*************************}
        { structure dereferencing }
        {*************************}
        struct_deref, struct_offset:
          begin
            base_expr_ptr := Assemble_expr;
            field_expr_ptr := Assemble_expr;
          end;
        field_deref, field_offset:
          begin
            base_expr_ref := Assemble_expr;
            field_name_ptr := Assemble_expr;
          end;

        {***********************************************}
        { implicit references used in structure assigns }
        {***********************************************}
        struct_base:
          struct_base_type_ref := forward_type_ref_type(Assemble_type);
        static_struct_base:
          static_struct_base_type_ref := forward_type_ref_type(Assemble_type);

      end {case}

        {***************************************************************}
        {                         expression terms                      }
        {***************************************************************}
    else
      case kind of

        {*************************}
        { explicit ptr conversion }
        {*************************}
        ptr_cast, type_query:
          begin
            desired_subclass_ref := forward_type_ref_type(Assemble_type);
            class_expr_ptr := Assemble_expr;
          end;

        {***************}
        { complex pairs }
        {***************}
        complex_pair:
          begin
            a_expr_ptr := Assemble_expr;
            b_expr_ptr := Assemble_expr;
          end;

        {*****************}
        { vector triplets }
        {*****************}
        vector_triplet:
          begin
            x_expr_ptr := Assemble_expr;
            y_expr_ptr := Assemble_expr;
            z_expr_ptr := Assemble_expr;
          end;

        {************************}
        { user defined functions }
        {************************}
        user_fn:
          fn_stmt_ptr := forward_stmt_ptr_type(Assemble_stmt);

        {***************************************************************}
        {                      expression terminals                     }
        {***************************************************************}

        {***********************************}
        { user defined variable identifiers }
        {***********************************}
        global_identifier, local_identifier:
          stack_index := Assemble_integer;

        nested_identifier:
          begin
            static_links := Assemble_integer;
            dynamic_links := Assemble_integer;
            nested_id_expr_ptr := New_asm_expr(local_identifier);
            with nested_id_expr_ptr^ do
              begin
                stack_index := Assemble_integer;
              end;
          end;

        {*******************************}
        { user defined type identifiers }
        {*******************************}
        field_identifier:
          field_index := Assemble_integer;

        {*************************}
        { most recent addr caches }
        {*************************}
        itself:
          ;
        new_itself:
          new_type_ref := forward_type_ref_type(Assemble_type);
        implicit_expr:
          implicit_expr_ref := Assemble_expr;

        {***************************************************************}
        {                      expression literals        	            }
        {***************************************************************}

        {*********************}
        { enumerated literals }
        {*********************}
        true_val, false_val:
          ;
        char_lit:
          char_val := Assemble_char;
        enum_lit:
          enum_val := Assemble_integer;

        {******************}
        { integer literals }
        {******************}
        byte_lit:
          byte_val := Assemble_byte;
        short_lit:
          short_val := Assemble_short;
        integer_lit:
          integer_val := Assemble_integer;
        long_lit:
          long_val := Assemble_long;

        {*****************}
        { scalar literals }
        {*****************}
        scalar_lit:
          scalar_val := Assemble_scalar;
        double_lit:
          double_val := Assemble_double;
        complex_lit:
          complex_val := Assemble_complex;
        vector_lit:
          vector_val := Assemble_vector;

        {**************}
        { nil literals }
        {**************}
        nil_array, nil_struct, nil_proto, nil_reference:
          ;

        {********************}
        { uninitialized expr }
        {********************}
        error_expr:
          ;

      end; {case}
end; {procedure Assemble_expr_fields}


function Assemble_expr: expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  mnemonic: mnemonic_type;
begin
  {******************************}
  { assemble expression mnemonic }
  {******************************}
  mnemonic := Assemble_mnemonic;

  if mnemonic <> 'nil' then
    begin
      {*******************************}
      { assemble expression reference }
      {*******************************}
      if mnemonic = 'erf' then
        expr_ptr := Ref_asm_expr(Assemble_index)

        {*********************}
        { assemble expression }
        {*********************}
      else
        begin
          expr_ptr := New_asm_expr(Mnemonic_to_expr_kind(mnemonic));
          Assemble_expr_fields(expr_ptr);
        end
    end
  else
    expr_ptr := nil;

  Assemble_expr := expr_ptr;
end; {function Assemble_expr}


function Assemble_exprs: expr_ptr_type;
var
  expr_ptr, last_expr_ptr: expr_ptr_type;
begin
  expr_ptr := Assemble_expr;
  last_expr_ptr := expr_ptr;

  while (last_expr_ptr <> nil) do
    begin
      last_expr_ptr^.next := Assemble_expr;
      last_expr_ptr := last_expr_ptr^.next;
    end;

  Assemble_exprs := expr_ptr;
end; {function Assemble_exprs}


{*********************************************************}
{ routines to disassemble expressions into assembly codes }
{*********************************************************}


procedure Disassemble_complex(var outfile: text;
  complex_val: complex_type;
  literal_attributes_ptr: literal_attributes_ptr_type);
begin
  with literal_attributes_ptr^ do
    begin
      Disassemble_scalar(outfile, complex_val.a, a_decimal_places,
        a_exponential_notation);
      Disassemble_scalar(outfile, complex_val.b, b_decimal_places,
        b_exponential_notation);
    end;
end; {procedure Disassemble_complex}


procedure Disassemble_vector(var outfile: text;
  vector_val: vector_type;
  literal_attributes_ptr: literal_attributes_ptr_type);
begin
  with literal_attributes_ptr^ do
    begin
      Disassemble_scalar(outfile, vector_val.x, x_decimal_places,
        x_exponential_notation);
      Disassemble_scalar(outfile, vector_val.y, y_decimal_places,
        y_exponential_notation);
      Disassemble_scalar(outfile, vector_val.z, z_decimal_places,
        z_exponential_notation);
    end;
end; {procedure Disassemble_vector}


procedure Disassemble_expr_fields(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  with expr_ptr^ do

    {***************************************************************}
    {                      expression operators       	            }
    {***************************************************************}

    {*****************}
    { unary operators }
    {*****************}
    if kind in unary_operator_set then
      Disassemble_expr(outfile, operand_ptr)

      {******************}
      { binary operators }
      {******************}
    else if kind in binary_operator_set then
      begin
        Disassemble_expr(outfile, left_operand_ptr);
        Disassemble_expr(outfile, right_operand_ptr);
      end

        {***************************************************************}
        {                      array expression terms                   }
        {***************************************************************}
    else if kind in array_expr_set then
      case kind of

        {*******************}
        { array expressions }
        {*******************}
        boolean_array_expr..reference_array_expr:
          begin
            Disassemble_array_bounds_list(outfile, array_expr_bounds_list_ptr);
            Disassemble_exprs(outfile, array_element_exprs_ptr);
          end;
        subarray_expr:
          begin
            Disassemble_array_bounds(outfile, array_expr_bounds_ref);
            Disassemble_exprs(outfile, subarray_element_exprs_ptr);
          end;
        element_expr:
          Disassemble_expr(outfile, element_array_expr_ptr);

        {********************}
        { array dimensioning }
        {********************}
        boolean_array_dim..reference_array_dim:
          begin
            Disassemble_array_bounds_list(outfile, dim_bounds_list_ptr);

            {*******************************************************}
            { array of array / dynamic structure array dimensioning }
            {*******************************************************}
            if kind in [array_array_dim, struct_array_dim] then
              Disassemble_expr(outfile, dim_element_expr_ptr)

              {*************************************}
              { static structure array dimensioning }
              {*************************************}
            else if kind = static_struct_array_dim then
              begin
                Disassemble_type(outfile,
                  type_ptr_type(dim_static_struct_type_ref));
                Disassemble_stmt(outfile,
                  stmt_ptr_type(dim_static_struct_init_stmt_ptr));
              end;
          end;

        {*********************}
        { array dereferencing }
        {*********************}
        boolean_array_deref..reference_array_deref:
          begin
            Disassemble_array_index_list(outfile, deref_index_list_ptr);

            Disassemble_expr(outfile, deref_base_ptr);
            Disassemble_expr(outfile, deref_element_ref);

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            if kind = static_struct_array_deref then
              Disassemble_type(outfile,
                type_ref_type(deref_static_struct_type_ref));
          end;

        {****************************}
        { array subrange expressions }
        {****************************}
        boolean_array_subrange..reference_array_subrange:
          begin
            Disassemble_array_index_list(outfile, subrange_index_list_ptr);
            Disassemble_array_bounds_list(outfile, subrange_bounds_list_ptr);

            Disassemble_expr(outfile, subrange_base_ptr);
            Disassemble_expr(outfile, subrange_element_ref);

            {**************************************}
            { static structure array dereferencing }
            {**************************************}
            if kind = static_struct_array_subrange then
              Disassemble_type(outfile,
                type_ref_type(subrange_static_struct_type_ref));
          end;

        {*******************************************}
        { implicit references used in array assigns }
        {*******************************************}
        array_base:
          Disassemble_expr(outfile, array_base_expr_ref);

      end {case}

        {***************************************************************}
        {                    structure expression terms                 }
        {***************************************************************}
    else if kind in struct_expr_set then
      case kind of

        {********************}
        { struct expressions }
        {********************}
        struct_expr:
          begin
            Disassemble_integer(outfile, struct_expr_size);
            Disassemble_expr(outfile, field_exprs_ptr);
          end;

        {**********************}
        { structure allocation }
        {**********************}
        struct_new:
          begin
            Disassemble_type(outfile, type_ref_type(new_struct_type_ref));
            Disassemble_stmt(outfile, stmt_ptr_type(new_struct_init_stmt_ptr));
          end;

        {*************************}
        { structure dereferencing }
        {*************************}
        struct_deref, struct_offset:
          begin
            Disassemble_expr(outfile, base_expr_ptr);
            Disassemble_expr(outfile, field_expr_ptr);
          end;
        field_deref, field_offset:
          begin
            Disassemble_expr(outfile, base_expr_ref);
            Disassemble_expr(outfile, field_name_ptr);
          end;

        {***********************************************}
        { implicit references used in structure assigns }
        {***********************************************}
        struct_base:
          Disassemble_type(outfile, type_ref_type(struct_base_type_ref));
        static_struct_base:
          Disassemble_type(outfile, type_ref_type(static_struct_base_type_ref));

      end {case}

        {***************************************************************}
        {                        expression terms                       }
        {***************************************************************}
    else
      case kind of

        {*************************}
        { explicit ptr conversion }
        {*************************}
        ptr_cast, type_query:
          begin
            Disassemble_type(outfile, type_ref_type(desired_subclass_ref));
            Disassemble_expr(outfile, class_expr_ptr);
          end;

        {***************}
        { complex pairs }
        {***************}
        complex_pair:
          begin
            Disassemble_expr(outfile, a_expr_ptr);
            Disassemble_expr(outfile, b_expr_ptr);
          end;

        {*****************}
        { vector triplets }
        {*****************}
        vector_triplet:
          begin
            Disassemble_expr(outfile, x_expr_ptr);
            Disassemble_expr(outfile, y_expr_ptr);
            Disassemble_expr(outfile, z_expr_ptr);
          end;

        {************************}
        { user defined functions }
        {************************}
        user_fn:
          Disassemble_stmt(outfile, stmt_ptr_type(fn_stmt_ptr));

        {***************************************************************}
        {                      expression terminals                     }
        {***************************************************************}

        {***********************************}
        { user defined variable identifiers }
        {***********************************}
        global_identifier, local_identifier:
          Disassemble_integer(outfile, stack_index);

        nested_identifier:
          begin
            Disassemble_integer(outfile, static_links);
            Disassemble_integer(outfile, dynamic_links);
            with nested_id_expr_ptr^ do
              begin
                expr_disasm_count := expr_disasm_count + 1;
                expr_index := expr_disasm_count;
                Disassemble_integer(outfile, stack_index);
              end;
          end;

        {*******************************}
        { user defined type identifiers }
        {*******************************}
        field_identifier:
          Disassemble_integer(outfile, field_index);

        {*************************}
        { most recent addr caches }
        {*************************}
        itself:
          ;
        new_itself:
          Disassemble_type(outfile, type_ref_type(new_type_ref));
        implicit_expr:
          Disassemble_expr(outfile, implicit_expr_ref);

        {***************************************************************}
        {                      expression literals        	            }
        {***************************************************************}

        {*********************}
        { enumerated literals }
        {*********************}
        true_val, false_val:
          ;
        char_lit:
          Disassemble_char(outfile, char_val);
        enum_lit:
          Disassemble_integer(outfile, enum_val);

        {******************}
        { integer literals }
        {******************}
        byte_lit:
          Disassemble_byte(outfile, byte_val);
        short_lit:
          Disassemble_short(outfile, short_val);
        integer_lit:
          Disassemble_integer(outfile, integer_val);
        long_lit:
          Disassemble_long(outfile, long_val);

        {*****************}
        { scalar literals }
        {*****************}
        scalar_lit:
          with scalar_attributes_ptr^ do
            Disassemble_scalar(outfile, scalar_val, scalar_decimal_places,
              scalar_exponential_notation);
        double_lit:
          with double_attributes_ptr^ do
            Disassemble_double(outfile, double_val, double_decimal_places,
              double_exponential_notation);
        complex_lit:
          Disassemble_complex(outfile, complex_val, complex_attributes_ptr);
        vector_lit:
          Disassemble_vector(outfile, vector_val, vector_attributes_ptr);

        {**************}
        { nil literals }
        {**************}
        nil_array, nil_struct, nil_proto, nil_reference:
          ;

        {********************}
        { uninitialized expr }
        {********************}
        error_expr:
          ;

      end; {case}
end; {procedure Disassemble_expr_fields}


procedure Disassemble_expr(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  if (expr_ptr <> nil) then
    begin
      if debug then
        with expr_ptr^ do
          if expr_info_ptr <> nil then
            with expr_info_ptr^ do
              if expr_attributes_ptr <> nil then
                with expr_attributes_ptr^ do
                  if decl_attributes_ptr <> nil then
                    if not decl_attributes_ptr^.used then
                      Disasm_error;

      {**********************************}
      { disassemble expression reference }
      {**********************************}
      if expr_ptr^.expr_index <> 0 then
        begin
          Disassemble_mnemonic(outfile, 'erf');
          Disassemble_index(outfile, expr_ptr^.expr_index);
        end

          {************************}
          { disassemble expression }
          {************************}
      else
        begin
          expr_disasm_count := expr_disasm_count + 1;
          expr_ptr^.expr_index := expr_disasm_count;

          {*********************************}
          { disassemble expression mnemonic }
          {*********************************}
          Disassemble_mnemonic(outfile, Expr_kind_to_mnemonic(expr_ptr^.kind));
          Disassemble_expr_fields(outfile, expr_ptr);
        end;
    end
  else
    Disassemble_mnemonic(outfile, 'nil');
end; {procedure Disassemble_expr}


procedure Disassemble_exprs(var outfile: text;
  expr_ptr: expr_ptr_type);
begin
  while (expr_ptr <> nil) do
    begin
      Disassemble_expr(outfile, expr_ptr);
      expr_ptr := expr_ptr^.next;
    end;
  Disassemble_expr(outfile, nil);
end; {procedure Disassemble_exprs}


{****************************************}
{ functions returning assembler progress }
{****************************************}


function Exprs_assembled: asm_index_type;
begin
  Exprs_assembled := expr_asm_count;
end; {function Exprs_assembled}


function Exprs_disassembled: asm_index_type;
begin
  Exprs_disassembled := expr_disasm_count;
end; {function Exprs_disassembled}


initialization
  Make_expr_mnemonics;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  expr_asm_count := 0;
  expr_disasm_count := 0;
  expr_block_ptr := nil;
  expr_block_count := 0;
end.
