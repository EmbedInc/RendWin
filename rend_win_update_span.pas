{   Subroutine REND_WIN_UPDATE_SPAN (X, Y, LEN)
*
*   Update a span of pixels by copying them from the software bitmap to the
*   display.  The left end of the span is at X,Y, and its total length is
*   LEN pixels.  A value of zero for LEN causes nothing to happen.
*
*   PRIM_DATA sw_read yes
*   PRIM_DATA sw_write no
}
module rend_win_update_span;
define rend_win_update_span;
%include 'rend_win.ins.pas';
%include 'rend_win_update_span_d.ins.pas';

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

type
  comp_t = 0..255;                     {one source color component value}
  comp_p_t = ^comp_t;

var
  off_pix: comp_t := 0;                {default when no source component available}

procedure rend_win_update_span (       {update device span from SW bitmap}
  in      x: sys_int_machine_t;        {starting X pixel address of span}
  in      y: sys_int_machine_t;        {scan line coordinate span is on}
  in      len: sys_int_machine_t);     {number of pixels in span}
  val_param;

var
  i, n: sys_int_machine_t;             {scratch integers}
  pix: sys_int_machine_t;              {scratch pixel value}
  dithx, dithy: sys_int_machine_t;     {dither pattern indicies for curren pixel}
  red_p, blu_p, grn_p: comp_p_t;       {pointers to current source pixel components}
  dred, dgrn, dblu: sys_int_adr_t;     {source pixel component strides}
  pix32: win_rgbquad_t;                {24 bit RGB value in one 32 bit word}
  thresh: 0..frac_high_k;              {dither threshold for this pixel}
  pix8_p: ^0..255;                     {pointer to one 8 bit DIB pixel value}
  pix16_p: ^integer16;                 {pointer to one 16 bit true color DIB pixel}
  pix32_p: ^win_rgbquad_t;             {pointer to one 32 bit true color DIB pixel}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if rend_iterp_data.n_rgb <= 0 then return; {no enabled interpolants to copy ?}

  if setup <> setup_pix_k then begin   {ensure proper driver and GDI setup}
    rend_win_setup (setup_pix_k);
    end;
{
*   Init the source pixel component pointers and their memory address strides.
}
  with                                 {process RED interpolant ON/OFF}
      rend_iterps.red: iterp,          {ITERP is this interpolant}
      iterp.bitmap_p^: bitmap          {BITMAP is bitmap descriptor for this iterp}
      do begin
    if iterp.on
      then begin                       {this interpolant is ON}
        red_p := univ_ptr(             {make pointer to first pixel in span}
          sys_int_adr_t(bitmap.line_p[y]) +
          (bitmap.x_offset * x) +
          iterp.iterp_offset);
        dred := bitmap.x_offset;       {address increment for subsequent pixels}
        end
      else begin                       {this interpolant is OFF}
        red_p := addr(off_pix);        {point to default color for OFF interpolant}
        dred := 0;                     {stay on default color value}
        end
      ;
    end;                               {done with ITERP and BITMAP abbreviations}

  with                                 {process GREEN interpolant ON/OFF}
      rend_iterps.grn: iterp,          {ITERP is this interpolant}
      iterp.bitmap_p^: bitmap          {BITMAP is bitmap descriptor for this iterp}
      do begin
    if iterp.on
      then begin                       {this interpolant is ON}
        grn_p := univ_ptr(             {make pointer to first pixel in span}
          sys_int_adr_t(bitmap.line_p[y]) +
          (bitmap.x_offset * x) +
          iterp.iterp_offset);
        dgrn := bitmap.x_offset;       {address increment for subsequent pixels}
        end
      else begin                       {this interpolant is OFF}
        grn_p := addr(off_pix);        {point to default color for OFF interpolant}
        dgrn := 0;                     {stay on default color value}
        end
      ;
    end;                               {done with ITERP and BITMAP abbreviations}

  with                                 {process BLUE interpolant ON/OFF}
      rend_iterps.blu: iterp,          {ITERP is this interpolant}
      iterp.bitmap_p^: bitmap          {BITMAP is bitmap descriptor for this iterp}
      do begin
    if iterp.on
      then begin                       {this interpolant is ON}
        blu_p := univ_ptr(             {make pointer to first pixel in span}
          sys_int_adr_t(bitmap.line_p[y]) +
          (bitmap.x_offset * x) +
          iterp.iterp_offset);
        dblu := bitmap.x_offset;       {address increment for subsequent pixels}
        end
      else begin                       {this interpolant is OFF}
        blu_p := addr(off_pix);        {point to default color for OFF interpolant}
        dblu := 0;                     {stay on default color value}
        end
      ;
    end;                               {done with ITERP and BITMAP abbreviations}
{
************************************
*
*   Copy the pixel values into the DIB.
}
  case pixform of                      {what is the window pixel format ?}
{
*   Pixel format is 4 bit pseudo color, not dithered.
}
pixform_pc4_k: begin
  pix8_p := univ_ptr(pixadr);          {get pointer to first pixel in DIB}

  n := len div 2;                      {number of whole DIB bytes to write}
  for i := 1 to n do begin             {once for each whole DIB byte in span}
    pix := lshft(                      {make value for first pixel in byte}
      cindex.red[red_p^].close +
      cindex.grn[grn_p^].close +
      cindex.blu[blu_p^].close, 4);
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix8_p^ := pix ! (                 {merge value for second pix and store in DIB}
      cindex.red[red_p^].close +
      cindex.grn[grn_p^].close +
      cindex.blu[blu_p^].close);
    pix8_p := succ(pix8_p);            {advance destination pointer}
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    end;                               {back to do next pixel accross in span}

  if odd(i) then begin                 {one pixel left for next DIB byte ?}
    pix8_p^ := (pix8_p^ & 15) ! lshft( {write pix value to high DIB byte only}
      cindex.red[red_p^].close +
      cindex.grn[grn_p^].close +
      cindex.blu[blu_p^].close, 4);
    end;
  end;
{
*   Pixel format is 4 bit pseudo color, dithered.
}
pixform_pc4dith_k: begin
  pix8_p := univ_ptr(pixadr);          {get pointer to first pixel in DIB}
  dithy := y mod y_dith_k;             {Y dither pattern index for this scan line}
  dithx := x mod x_dith_k;             {X dither pattern index for first pixel}

  n := len div 2;                      {number of whole DIB bytes to write}
  for i := 1 to n do begin             {once for each whole DIB byte in span}
    thresh := dith[dithx, dithy];      {fetch dither threshold for this pixel}
    if cindex.red[red_p^].frac > thresh
      then pix := cindex.red[red_p^].dith_high
      else pix := cindex.red[red_p^].dith_low;
    if cindex.grn[grn_p^].frac > thresh
      then pix := pix + cindex.grn[grn_p^].dith_high
      else pix := pix + cindex.grn[grn_p^].dith_low;
    if cindex.blu[blu_p^].frac > thresh
      then pix := pix + cindex.blu[blu_p^].dith_high
      else pix := pix + cindex.blu[blu_p^].dith_low;
    pix := lshft(pix, 4);              {move this pixel value to high nibble}

    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    dithx := dithx + 1;                {advance to next dither pattern threshold}
    if dithx >= x_dith_k then dithx := 0; {wrap back to dither pattern left edge ?}
    thresh := dith[dithx, dithy];      {fetch dither threshold for this pixel}

    if cindex.red[red_p^].frac > thresh
      then pix := pix + cindex.red[red_p^].dith_high
      else pix := pix + cindex.red[red_p^].dith_low;
    if cindex.grn[grn_p^].frac > thresh
      then pix := pix + cindex.grn[grn_p^].dith_high
      else pix := pix + cindex.grn[grn_p^].dith_low;
    if cindex.blu[blu_p^].frac > thresh
      then pix := pix + cindex.blu[blu_p^].dith_high
      else pix := pix + cindex.blu[blu_p^].dith_low;
    pix8_p^ := pix;                    {stuff values for both pixels into DIB}

    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix8_p := succ(pix8_p);            {advance destination pointer}
    dithx := dithx + 1;                {advance to next dither pattern threshold}
    if dithx >= x_dith_k then dithx := 0; {wrap back to dither pattern left edge ?}
    end;                               {back to do next pixel accross in span}

  if odd(i) then begin                 {one pixel left for next DIB byte ?}
    thresh := dith[dithx, dithy];      {fetch dither threshold for this pixel}
    if cindex.red[red_p^].frac > thresh
      then pix := cindex.red[red_p^].dith_high
      else pix := cindex.red[red_p^].dith_low;
    if cindex.grn[grn_p^].frac > thresh
      then pix := pix + cindex.grn[grn_p^].dith_high
      else pix := pix + cindex.grn[grn_p^].dith_low;
    if cindex.blu[blu_p^].frac > thresh
      then pix := pix + cindex.blu[blu_p^].dith_high
      else pix := pix + cindex.blu[blu_p^].dith_low;
    pix8_p^ := (pix8_p^ & 15) ! lshft(pix, 4); {write pix val to high DIB byte only}
    end;
  end;
{
*   Pixel format is 8 bit pseudo color, not dithered.
}
pixform_pc8_k: begin
  pix8_p := univ_ptr(pixadr);          {get pointer to first pixel in DIB}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    pix8_p^ :=                         {make psuedo color and stuff into DIB}
      cindex.red[red_p^].close +
      cindex.grn[grn_p^].close +
      cindex.blu[blu_p^].close;
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix8_p := succ(pix8_p);            {advance destination pointer}
    end;                               {back to do next pixel accross in span}
  end;
{
*   Pixel format is 8 bit pseudo color, dithered.
}
pixform_pc8dith_k: begin
  pix8_p := univ_ptr(pixadr);          {get pointer to first pixel in DIB}
  dithy := y mod y_dith_k;             {Y dither pattern index for this scan line}
  dithx := x mod x_dith_k;             {X dither pattern index for first pixel}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    thresh := dith[dithx, dithy];      {fetch dither threshold for this pixel}
    if cindex.red[red_p^].frac > thresh
      then pix := cindex.red[red_p^].dith_high
      else pix := cindex.red[red_p^].dith_low;
    if cindex.grn[grn_p^].frac > thresh
      then pix := pix + cindex.grn[grn_p^].dith_high
      else pix := pix + cindex.grn[grn_p^].dith_low;
    if cindex.blu[blu_p^].frac > thresh
      then pix := pix + cindex.blu[blu_p^].dith_high
      else pix := pix + cindex.blu[blu_p^].dith_low;
    pix8_p^ := pix;                    {stuff pixel value into DIB pixel}

    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix8_p := succ(pix8_p);            {advance destination pointer}

    dithx := dithx + 1;                {advance to next dither pattern threshold}
    if dithx >= x_dith_k then dithx := 0; {wrap back to dither pattern left edge ?}
    end;                               {back to do next pixel accross in span}
  end;
{
*   Pixel format is 16 bit true color, not dithered.
}
pixform_tc16_k: begin
  pix16_p := univ_ptr(pixadr);         {get pointer to first pixel in DIB}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    pix16_p^ :=
      rshft(blu_p^, 3) !
      lshft(grn_p^ & 16#F8, 2) !
      lshft(red_p^ & 16#F8, 7);
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix16_p := succ(pix16_p);          {advance destination pointer}
    end;                               {back to do next pixel accross in span}
  end;
{
*   Pixel format is 16 bit true color, dithered.
}
pixform_tc16dith_k: begin
  pix16_p := univ_ptr(pixadr);         {get pointer to first pixel in DIB}
  dithy := y mod y_dith_k;             {Y dither pattern index for this scan line}
  dithx := x mod x_dith_k;             {X dither pattern index for first pixel}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    thresh := dith[dithx, dithy];      {fetch dither threshold for this pixel}
    if cindex.red[red_p^].frac > thresh
      then pix := cindex.red[red_p^].dith_high
      else pix := cindex.red[red_p^].dith_low;
    if cindex.grn[grn_p^].frac > thresh
      then pix := pix + cindex.grn[grn_p^].dith_high
      else pix := pix + cindex.grn[grn_p^].dith_low;
    if cindex.blu[blu_p^].frac > thresh
      then pix := pix + cindex.blu[blu_p^].dith_high
      else pix := pix + cindex.blu[blu_p^].dith_low;
    pix16_p^ := pix;                   {stuff pixel value into DIB pixel}

    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix16_p := succ(pix16_p);          {advance destination pointer}

    dithx := dithx + 1;                {advance to next dither pattern threshold}
    if dithx >= x_dith_k then dithx := 0; {wrap back to dither pattern left edge ?}
    end;                               {back to do next pixel accross in span}
  end;
{
*   Pixel format is 24 bit true color, not dithered.
}
pixform_tc24_k: begin
  pix8_p := univ_ptr(pixadr);          {get pointer to first pixel in DIB}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    pix8_p^ := blu_p^;                 {stuff blue value into DIB pixel}
    pix8_p := succ(pix8_p);
    pix8_p^ := grn_p^;                 {stuff green value into DIB pixel}
    pix8_p := succ(pix8_p);
    pix8_p^ := red_p^;                 {stuff red value into DIB pixel}
    pix8_p := succ(pix8_p);
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    end;                               {back to do next pixel accross in span}
  end;
{
*   Pixel format is 32 bit true color, not dithered.
}
pixform_tc32_k: begin
  pix32_p := univ_ptr(pixadr);         {get pointer to first pixel in DIB}
  pix32.reserved := 0;                 {init static field in 32 bit pixel value}

  for i := 0 to len-1 do begin         {once for each pixel in the span}
    pix32.blu := blu_p^;               {fill in local copy of final pixel}
    pix32.grn := grn_p^;
    pix32.red := red_p^;
    pix32_p^ := pix32;                 {stuff 32 bit pixel into DIB}
    red_p := univ_ptr(sys_int_adr_t(red_p) + dred); {advance source pixel pointers}
    grn_p := univ_ptr(sys_int_adr_t(grn_p) + dgrn);
    blu_p := univ_ptr(sys_int_adr_t(blu_p) + dblu);
    pix32_p := succ(pix32_p);          {advance destination pointer}
    end;                               {back to do next pixel accross in span}
  end;
{
*   Unexpected pixel format ID.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(pixform));
    rend_message_bomb ('rend_win', 'pixform_span', msg_parm, 1);
    end;                               {end of window pixel format cases}
{
*   Done copying the RENDlib pixel values into the DIB.
*
************************************
*
*   Copy the appropriate portion of the DIB to the window.
}
  discard( SetDIBitsToDevice (         {copy DIB rectangle to window}
    dc,                                {handle to destination device context}
    x, y,                              {destination upper left corner}
    len, 1,                            {rectangle width and height}
    0, dib_y - 1,                      {source rectangle lower left corner}
    dib_y - 1,                         {first scan line number in DIB memory}
    dib_y,                             {number of scan lines in DIB array}
    pixadr,                            {starting address of DIB pixel array}
    dib_info_p^,                       {config info for this DIB}
    win_diblut_ref_k));                {DIB colors are references to DC colors}
  end;
