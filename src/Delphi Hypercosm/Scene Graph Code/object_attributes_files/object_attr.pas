unit object_attr;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             object_attr               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The object_attr module provides data structures and     }
{       routines for creating the basic non geometric           }
{       attributes which describe an object.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, state_vars, materials;


type
  {*************************************************}
  { a shader points to a routine in the syntax tree }
  { which must be interpreted to compute the color. }
  {*************************************************}
  shader_ptr_type = Pointer;


  object_attributes_kind_type = (

    {******************}
    { color attributes }
    {******************}
    color_attributes, default_color_attributes,

    {*********************}
    { material attributes }
    {*********************}
    material_attributes, edge_material_attributes,

    {*******************}
    { shader attributes }
    {*******************}
    shader_attributes, edge_shader_attributes,

    {**********************}
    { rendering attributes }
    {**********************}
    render_mode_attributes, shading_attributes,

    {**********************}
    { wireframe attributes }
    {**********************}
    edge_mode_attributes, edge_orientation_attributes, outline_kind_attributes,

    {************************}
    { ray tracing attributes }
    {************************}
    shadow_attributes, reflection_attributes, refraction_attributes);


  object_attributes_type = record
    valid: array[object_attributes_kind_type] of boolean;

    {******************}
    { color attributes }
    {******************}
    color: color_type;
    default_color: color_type;

    {*********************}
    { material attributes }
    {*********************}
    material_ptr: material_ptr_type;
    edge_material_ptr: material_ptr_type;

    {*******************}
    { shader attributes }
    {*******************}
    shader_ptr: shader_ptr_type;
    edge_shader_ptr: shader_ptr_type;

    {**********************}
    { rendering attributes }
    {**********************}
    render_mode: render_mode_type;
    shading: shading_type;

    {**********************}
    { wireframe attributes }
    {**********************}
    edge_mode: edge_mode_type;
    edge_orientation: edge_orientation_type;
    outline_kind: outline_kind_type;

    {************************}
    { ray tracing attributes }
    {************************}
    shadows: boolean;
    reflections: boolean;
    refractions: boolean;
  end; {object_attributes_type}


var
  null_attributes: object_attributes_type;


procedure Set_null_attributes(var attributes: object_attributes_type);

{***************************************}
{ routines for setting color attributes }
{***************************************}
procedure Set_color_attributes(var attributes: object_attributes_type;
  color: color_type);
procedure Set_default_color_attributes(var attributes: object_attributes_type;
  default_color: color_type);

{******************************************}
{ routines for setting material attributes }
{******************************************}
procedure Set_material_attributes(var attributes: object_attributes_type;
  material_ptr: material_ptr_type);
procedure Set_edge_material_attributes(var attributes: object_attributes_type;
  edge_material_ptr: material_ptr_type);

{****************************************}
{ routines for setting shader attributes }
{****************************************}
procedure Set_shader_attributes(var attributes: object_attributes_type;
  shader_ptr: shader_ptr_type);
procedure Set_edge_shader_attributes(var attributes: object_attributes_type;
  edge_shader_ptr: shader_ptr_type);

{*******************************************}
{ routines for setting rendering attributes }
{*******************************************}
procedure Set_render_mode_attributes(var attributes: object_attributes_type;
  render_mode: render_mode_type);
procedure Set_shading_attributes(var attributes: object_attributes_type;
  shading: shading_type);

{*******************************************}
{ routines for setting wireframe attributes }
{*******************************************}
procedure Set_edge_mode_attributes(var attributes: object_attributes_type;
  edge_mode: edge_mode_type);
procedure Set_edge_orientation_attributes(var attributes:
  object_attributes_type;
  edge_orientation: edge_orientation_type);
procedure Set_outline_kind_attributes(var attributes: object_attributes_type;
  outline_kind: outline_kind_type);

{*********************************************}
{ routines for setting ray tracing attributes }
{*********************************************}
procedure Set_shadow_attributes(var attributes: object_attributes_type;
  shadows: boolean);
procedure Set_reflection_attributes(var attributes: object_attributes_type;
  reflections: boolean);
procedure Set_refraction_attributes(var attributes: object_attributes_type;
  refractions: boolean);

{**************************************************}
{ routines for applying and aggregating attributes }
{**************************************************}
procedure Reset_object_attributes(var attributes: object_attributes_type;
  kind: object_attributes_kind_type);
procedure Apply_object_attributes(var attributes: object_attributes_type;
  new_attributes: object_attributes_type);
procedure Free_object_attributes(var attributes: object_attributes_type);

{*********************************}
{ routines for writing attributes }
{*********************************}
procedure Write_object_attributes_kind(kind: object_attributes_kind_type);
procedure Write_object_attributes(attributes: object_attributes_type);


implementation
uses
  make_stmts;


type
  forward_stmt_ptr_type = shader_ptr_type;


procedure Write_object_attributes_kind(kind: object_attributes_kind_type);
begin
  case kind of

    {******************}
    { color attributes }
    {******************}
    color_attributes:
      write('color_attributes');
    default_color_attributes:
      write('default_color_attributes');

    {*********************}
    { material attributes }
    {*********************}
    material_attributes:
      write('material_attributes');
    edge_material_attributes:
      write('edge_material_attributes');

    {*******************}
    { shader attributes }
    {*******************}
    shader_attributes:
      write('shader_attributes');
    edge_shader_attributes:
      write('edge_shader_attributes');

    {**********************}
    { rendering attributes }
    {**********************}
    render_mode_attributes:
      write('render_mode_attributes');
    shading_attributes:
      write('shading_attributes');

    {**********************}
    { wireframe attributes }
    {**********************}
    edge_mode_attributes:
      write('edge_mode_attributes');
    edge_orientation_attributes:
      write('edge_orientation_attributes');
    outline_kind_attributes:
      write('outline_kind_attributes');

    {************************}
    { ray tracing attributes }
    {************************}
    shadow_attributes:
      write('shadow_attributes');
    reflection_attributes:
      write('reflection_attributes');
    refraction_attributes:
      write('refraction_attributes');

  end; {case}
end; {procedure Write_object_attributes_kind}


procedure Write_boolean_state(state: boolean);
begin
  if state then
    write('on')
  else
    write('off');
end; {procedure Write_boolean_state}


procedure Write_object_attributes(attributes: object_attributes_type);
var
  counter: object_attributes_kind_type;
begin
  with attributes do
    for counter := color_attributes to refraction_attributes do
      begin
        Write_object_attributes_kind(counter);
        write(':     ');

        if not valid[counter] then
          write('undefined')
        else
          case counter of

            {******************}
            { color attributes }
            {******************}
            color_attributes:
              Write_color(color);
            default_color_attributes:
              Write_color(default_color);

            {*********************}
            { material attributes }
            {*********************}
            material_attributes:
              ;
            edge_material_attributes:
              ;

            {*******************}
            { shader attributes }
            {*******************}
            shader_attributes:
              ;
            edge_shader_attributes:
              ;

            {**********************}
            { rendering attributes }
            {**********************}
            render_mode_attributes:
              Write_render_mode(render_mode);
            shading_attributes:
              Write_shading(shading);

            {**********************}
            { wireframe attributes }
            {**********************}
            edge_mode_attributes:
              Write_edge_mode(edge_mode);
            edge_orientation_attributes:
              Write_edge_orientation(edge_orientation);
            outline_kind_attributes:
              Write_outline_kind(outline_kind);

            {************************}
            { ray tracing attributes }
            {************************}
            shadow_attributes:
              Write_boolean_state(shadows);
            reflection_attributes:
              Write_boolean_state(reflections);
            refraction_attributes:
              Write_boolean_state(refractions);

          end; {case}

        writeln;
      end;
end; {procedure Write_object_attributes}


procedure Set_null_attributes(var attributes: object_attributes_type);
var
  counter: object_attributes_kind_type;
begin
  for counter := color_attributes to refraction_attributes do
    attributes.valid[counter] := false;

  attributes.color := black_color;
  attributes.default_color := black_color;
  attributes.shader_ptr := shader_ptr_type(nil);
  attributes.edge_shader_ptr := shader_ptr_type(nil);
end; {procedure Set_null_attributes}


{***************************************}
{ routines for setting color attributes }
{***************************************}


procedure Set_color_attributes(var attributes: object_attributes_type;
  color: color_type);
begin
  attributes.color := color;
  attributes.valid[color_attributes] := true;
end; {procedure Set_color_attributes}


procedure Set_default_color_attributes(var attributes: object_attributes_type;
  default_color: color_type);
begin
  attributes.default_color := default_color;
  attributes.valid[default_color_attributes] := true;

  if not attributes.valid[color_attributes] then
    attributes.color := default_color;
end; {procedure Set_default_color_attributes}


{******************************************}
{ routines for setting material attributes }
{******************************************}


procedure Set_material_attributes(var attributes: object_attributes_type;
  material_ptr: material_ptr_type);
begin
  if material_ptr <> nil then
    begin
      attributes.material_ptr := material_ptr;
      attributes.valid[material_attributes] := true;
    end;
end; {procedure Set_material_attributes}


procedure Set_edge_material_attributes(var attributes: object_attributes_type;
  edge_material_ptr: material_ptr_type);
begin
  if edge_material_ptr <> nil then
    begin
      attributes.edge_material_ptr := edge_material_ptr;
      attributes.valid[edge_material_attributes] := true;
    end;
end; {procedure Set_edge_material_attributes}


{****************************************}
{ routines for setting shader attributes }
{****************************************}


procedure Set_shader_attributes(var attributes: object_attributes_type;
  shader_ptr: shader_ptr_type);
begin
  if shader_ptr <> shader_ptr_type(nil) then
    begin
      attributes.shader_ptr := shader_ptr;
      attributes.valid[shader_attributes] := true;
    end;
end; {procedure Set_shader_attributes}


procedure Set_edge_shader_attributes(var attributes: object_attributes_type;
  edge_shader_ptr: shader_ptr_type);
begin
  if edge_shader_ptr <> shader_ptr_type(nil) then
    begin
      attributes.edge_shader_ptr := edge_shader_ptr;
      attributes.valid[edge_shader_attributes] := true;
    end;
end; {procedure Set_edge_shader_attributes}


{*******************************************}
{ routines for setting rendering attributes }
{*******************************************}


procedure Set_render_mode_attributes(var attributes: object_attributes_type;
  render_mode: render_mode_type);
begin
  attributes.render_mode := render_mode;
  attributes.valid[render_mode_attributes] := true;
end; {procedure Set_render_mode_attributes}


procedure Set_shading_attributes(var attributes: object_attributes_type;
  shading: shading_type);
begin
  attributes.shading := shading;
  attributes.valid[shading_attributes] := true;
end; {procedure Set_shading_attributes}


{*******************************************}
{ routines for setting wireframe attributes }
{*******************************************}


procedure Set_edge_mode_attributes(var attributes: object_attributes_type;
  edge_mode: edge_mode_type);
begin
  attributes.edge_mode := edge_mode;
  attributes.valid[edge_mode_attributes] := true;
end; {procedure Set_edge_mode_attributes}


procedure Set_edge_orientation_attributes(var attributes:
  object_attributes_type;
  edge_orientation: edge_orientation_type);
begin
  attributes.edge_orientation := edge_orientation;
  attributes.valid[edge_orientation_attributes] := true;
end; {procedure Set_outline_mode_attributes}


procedure Set_outline_kind_attributes(var attributes: object_attributes_type;
  outline_kind: outline_kind_type);
begin
  attributes.outline_kind := outline_kind;
  attributes.valid[outline_kind_attributes] := true;
end; {procedure Set_outline_kind_attributes}


{*********************************************}
{ routines for setting ray tracing attributes }
{*********************************************}


procedure Set_shadow_attributes(var attributes: object_attributes_type;
  shadows: boolean);
begin
  attributes.shadows := shadows;
  attributes.valid[shadow_attributes] := true;
end; {procedure Set_shadow_attributes}


procedure Set_reflection_attributes(var attributes: object_attributes_type;
  reflections: boolean);
begin
  attributes.reflections := reflections;
  attributes.valid[reflection_attributes] := true;
end; {procedure Set_reflection_attributes}


procedure Set_refraction_attributes(var attributes: object_attributes_type;
  refractions: boolean);
begin
  attributes.refractions := refractions;
  attributes.valid[refraction_attributes] := true;
end; {procedure Set_refraction_attributes}


{**************************************************}
{ routines for applying and aggregating attributes }
{**************************************************}


procedure Reset_object_attributes(var attributes: object_attributes_type;
  kind: object_attributes_kind_type);
begin
  attributes.valid[kind] := false;
end; {procedure Reset_object_attributes}


procedure Apply_object_attributes(var attributes: object_attributes_type;
  new_attributes: object_attributes_type);
var
  counter: object_attributes_kind_type;
begin
  for counter := color_attributes to refraction_attributes do
    if new_attributes.valid[counter] then
      if not attributes.valid[counter] then
        case counter of

          {******************}
          { color attributes }
          {******************}
          color_attributes:
            Set_color_attributes(attributes, new_attributes.color);
          default_color_attributes:
            Set_default_color_attributes(attributes,
              new_attributes.default_color);

          {*********************}
          { material attributes }
          {*********************}
          material_attributes:
            Set_material_attributes(attributes, new_attributes.material_ptr);
          edge_material_attributes:
            Set_edge_material_attributes(attributes,
              new_attributes.edge_material_ptr);

          {*******************}
          { shader attributes }
          {*******************}
          shader_attributes:
            Set_shader_attributes(attributes, new_attributes.shader_ptr);
          edge_shader_attributes:
            Set_edge_shader_attributes(attributes,
              new_attributes.edge_shader_ptr);

          {**********************}
          { rendering attributes }
          {**********************}
          render_mode_attributes:
            Set_render_mode_attributes(attributes, new_attributes.render_mode);
          shading_attributes:
            Set_shading_attributes(attributes, new_attributes.shading);

          {**********************}
          { wireframe attributes }
          {**********************}
          edge_mode_attributes:
            Set_edge_mode_attributes(attributes, new_attributes.edge_mode);
          edge_orientation_attributes:
            Set_edge_orientation_attributes(attributes,
              new_attributes.edge_orientation);
          outline_kind_attributes:
            Set_outline_kind_attributes(attributes,
              new_attributes.outline_kind);

          {************************}
          { ray tracing attributes }
          {************************}
          shadow_attributes:
            Set_shadow_attributes(attributes, new_attributes.shadows);
          reflection_attributes:
            Set_reflection_attributes(attributes, new_attributes.reflections);
          refraction_attributes:
            Set_refraction_attributes(attributes, new_attributes.refractions);

        end; {case}
end; {procedure Apply_object_attributes}


procedure Free_object_attributes(var attributes: object_attributes_type);
begin
  {**************************}
  { free material attributes }
  {**************************}
  if attributes.material_ptr <> nil then
    Free_material(attributes.material_ptr);
  if attributes.edge_material_ptr <> nil then
    Free_material(attributes.edge_material_ptr);

  {************************}
  { free shader attributes }
  {************************}
  if attributes.shader_ptr <> nil then
    Destroy_abstract_stmt(attributes.shader_ptr, false);
  if attributes.edge_shader_ptr <> nil then
    Destroy_abstract_stmt(attributes.edge_shader_ptr, false);
end; {procedure Free_object_attributes}


initialization
  Set_null_attributes(null_attributes);
end.
