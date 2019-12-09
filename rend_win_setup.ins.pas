{   Subroutine REND_WIN_SETUP (NEWSET)
*
*   Set up our driver and GDI state in preperation for the kind of drawing
*   indicated by NEWSET.  The possible NEWSET values and their associated
*   drawing catagories are:
*
*     SETUP_PIX_K  -  Direct pixel writes using DIBitsToDevice.
*
*     SETUP_LINE_K  -  2D fixed color line drawing.
*
*     SETUP_FILL_K  -  2D fixed color area filling.
*
*   The SETUP value for this device is updated.  A primitive routine would
*   typically call REND_WIN_SETUP if the SETUP value is not what it requires.
*   SETUP must be reset to SETUP_NONE_K whenever any state is changed that
*   might invalidate the current setup.
}
procedure rend_win_setup (             {set up GDI for a particular kind of drawing}
  in      newset: setup_k_t);          {ID of new GDI setup configuration}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  h: win_handle_t;                     {scratch Win32 handles}
  cref: win_colorref_t;                {Windows color value}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
{
*********************************************************************
*
*   Local subroutine SET_PIXFUN
*
*   Set the Windows equivalent of the RENDlib PIXFUN state.  The RENDlib
*   PIXFUN state is assumed to be one that Windows can emulate.  This must
*   have been previously checked.  The pixel functions for red, green, and
*   blue are assumed to be set identically.
*
*   Valid PIXFUN settings are: INSERT, AND, OR, XOR, NOT
}
procedure set_pixfun;

var
  win_pixfun: win_pixfun2_t;           {Windows pixel function ID}

begin
  case rend_iterps.red.pixfun of       {what PIXFUN is RED set to ?}
rend_pixfun_and_k: begin               {pixel <-- old and new (bitwise logical and)}
      win_pixfun := win_pixfun2_maskpen_k;
      end;
rend_pixfun_or_k: begin                {pixel <-- old or new (bitwise logical or)}
      win_pixfun := win_pixfun2_mergepen_k;
      end;
rend_pixfun_xor_k: begin               {pixel <-- old xor new (bitwise logical xor)}
      win_pixfun := win_pixfun2_xorpen_k;
      end;
rend_pixfun_not_k: begin               {pixel <-- not new (bitwise invert of new val)}
      win_pixfun := win_pixfun2_notcopypen_k;
      end;
otherwise                              {assume PIXFUN INSERT}
    win_pixfun := win_pixfun2_copypen_k;
    end;

  discard( SetROP2 (dc, win_pixfun) ); {set new pixel function in our DC}
  end;
{
*********************************************************************
*
*   Local subroutine SET_COLORS
*
*   Make sure the interpolator VALUE fields are set correctly.
*   This assumes all interpolants are set to FLAT interpolation.
}
procedure set_colors;

var
  x, y: sys_int_machine_t;             {saved copy of current point}

begin
  x := rend_lead_edge.x;               {save current point coordinates}
  y := rend_lead_edge.y;

  rend_sw_set.cpnt_2dimi^ (0, 0);      {force re-compute of color values here}

  rend_lead_edge.x := x;               {restore current point coordinates}
  rend_curr_x := x;
  rend_lead_edge.y := y;
  end;
{
*********************************************************************
*
*   Start of main routine.
}
begin
  discard( GdiFlush );                 {make sure all previous drawing is complete}
  case newset of                       {what kind of setup is desired ?}
{
*******************
*
*   Set up for direct pixel writes using DIBitsToDevice from our local DIB.
}
setup_pix_k: begin
  discard( SetROP2 (dc, win_pixfun2_copypen_k) ); {set PIXFUN INSERT}
  end;
{
*******************
*
*   Set up for 2D fixed color line drawing.
}
setup_line_k: begin
  set_colors;                          {make sure interpolator VALUE fields set}
  case pixform of                      {what is the destination pixel format ?}
{
*   Pixel format is non-dithered pseudo color.
}
pixform_pc1_k,
pixform_pc4_k,
pixform_pc8_k: begin
      cref.red := pc_win[              {logical palette index for current color}
        cindex.red[rend_iterps.red.value.val8].close +
        cindex.grn[rend_iterps.grn.value.val8].close +
        cindex.blu[rend_iterps.blu.value.val8].close];
      cref.grn := 0;
      cref.blu := 0;
      cref.mode := colorref_pc_k;      {indicate pseudo color value in RED}
      end;
{
*   Pixel format is non-dithered true color.
}
pixform_tc16_k,
pixform_tc24_k,
pixform_tc32_k: begin
      cref.red := rend_iterps.red.value.val8;
      cref.grn := rend_iterps.grn.value.val8;
      cref.blu := rend_iterps.blu.value.val8;
      cref.mode := colorref_rgb_k;
      end;
{
*   Unexpected pixel format ID.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(pixform));
    rend_message_bomb ('rend_win', 'pixform_setup', msg_parm, 1);
    end;                               {end of window pixel format cases}
{
*   Set the new pen.
}
  h := CreatePen (                     {make new pen with color in CREF}
    penstyle_solid_k,                  {pen will be one solid color}
    0,                                 {use hardware "1" pixel width}
    cref);                             {pen color}
  discard( SelectObject (dc, h) );     {set new pen into DC}

  if made_pen then begin               {we created the old pen ?}
    discard( DeleteObject(pen_h) );    {delete the old pen}
    end;

  pen_h := h;                          {save handle to new pen}
  made_pen := true;                    {flag to delete new pen when done with it}

  set_pixfun;                          {emulate the RENDlib PIXFUN setting}
  end;
{
*******************
*
*   Set up for 2D fixed color area filling.
}
setup_fill_k: begin
  set_colors;                          {make sure interpolator VALUE fields set}
  case pixform of                      {what is the destination pixel format ?}
{
*   Pixel format is non-dithered pseudo color.
}
pixform_pc1_k,
pixform_pc4_k,
pixform_pc8_k: begin
      cref.red := pc_win[              {logical palette index for current color}
        cindex.red[rend_iterps.red.value.val8].close +
        cindex.grn[rend_iterps.grn.value.val8].close +
        cindex.blu[rend_iterps.blu.value.val8].close];
      cref.grn := 0;
      cref.blu := 0;
      cref.mode := colorref_pc_k;      {indicate pseudo color value in RED}
      end;
{
*   Pixel format is non-dithered true color.
}
pixform_tc16_k,
pixform_tc24_k,
pixform_tc32_k: begin
      cref.red := rend_iterps.red.value.val8;
      cref.grn := rend_iterps.grn.value.val8;
      cref.blu := rend_iterps.blu.value.val8;
      cref.mode := colorref_rgb_k;
      end;
{
*   Unexpected pixel format ID.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(pixform));
    rend_message_bomb ('rend_win', 'pixform_setup', msg_parm, 1);
    end;                               {end of window pixel format cases}
{
*   Set the new brush.
}
  h := CreateSolidBrush (cref);        {make brush with this color}
  discard( SelectObject (dc, h) );     {set new brush into DC}

  if made_brush then begin             {we created the old brush ?}
    discard( DeleteObject(brush_h) );  {delete the old brush}
    end;

  brush_h := h;                        {save handle to new brush}
  made_brush := true;                  {flag to delete new brush when done with it}
{
*   Set the pen to NULL.  The polygon routine outlines in the current pen, so
*   this is the only way to disable outlining.
}
  h := GetStockObject (stockobj_null_pen_k); {get handle to NULL pen}
  discard( SelectObject (dc, h) );     {set new pen into DC}

  if made_pen then begin               {we created the old pen ?}
    discard( DeleteObject(pen_h) );    {delete the old pen}
    end;

  pen_h := h;                          {save handle to new pen}
  made_pen := false;                   {don't delete this pen when done with it}

  set_pixfun;                          {emulate the RENDlib PIXFUN setting}
  end;
{
*******************
*
*   Unexpected value of NEWSET.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(newset));
    rend_message_bomb ('rend_win', 'setup_setup', msg_parm, 1);
    end;

  setup := newset;                     {update ID for our current setup}
  end;
