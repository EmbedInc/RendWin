{   Subroutine REND_WIN_DEV_RECONFIG
*
*   Check the device configuration and reconfigure the driver as necessary.
}
procedure rend_win_dev_reconfig;

type
  reflut_t = array[0..0] of int16u_t;  {LUT with values referencing another LUT}
  reflut_p_t = ^reflut_t;

var
  dx, dy: sys_int_machine_t;           {current size of our drawing window}
  aspect: real;                        {window width/height aspect ratio}
  p: univ_ptr;                         {scratch pointer}
  reflut_p: reflut_p_t;                {pointer to LUT containing reference values}
  sz: sys_int_adr_t;                   {scratch memory size value}
  i: sys_int_machine_t;                {scratch integer}
  diblut: win_diblut_k_t;              {DIB pixel values interpretation mode}
  stat: sys_err_t;

begin
{
*   Get current size of our drawing window in DX, DY.
}
  EnterCriticalSection (crsect_dev);   {start atomic access to DEV}
  dx := dev[rend_dev_id].size_x;       {fetch current window dimensions}
  dy := dev[rend_dev_id].size_y;
  LeaveCriticalSection (crsect_dev);   {end atomic access to DEV}
{
*   Adjust to the new window size, if it changed.
}
  if (dib_x <> dx) or (dib_y <> dy) then begin {window size changed ?}
    aspect := dx / dy;                 {make image aspect ratio}
    rend_image.size_fixed := false;    {temporarily allow image size change}
    rend_set.image_size^ (dx, dy, aspect); {set new image size and aspect ratio}
    rend_image.size_fixed := true;     {don't allow app to change image size}

    if dib_h <> handle_none_k then begin {we currently have a DIB ?}
      discard( DeleteObject(dib_h) );  {delete the old (wrong size) DIB}
      dib_h := handle_none_k;          {indicate we don't currently have a DIB}
      end;
    end;                               {done handling window size changed}
{
*   Create a DIB if we don't already have one.  We might not have one because
*   this is the first call to this routine, or because we just deleted the
*   old DIB because the window size changed.
}
  if dib_h = handle_none_k then begin  {we don't currently have a DIB ?}
    if dib_info_p = nil then begin     {need to allocate DIB config info structure ?}
      sz :=                            {size needed for whole BITMAPINFO structure}
        offset(win_bitmapinfo_t.lut);  {size up to variable part}
      if not true_color then begin     {we will be using a LUT ?}
        sz := sz +                     {make room for all the LUT entries}
          sizeof(win_bitmapinfo_t.lut[0]) * n_colors;
        end;
      rend_mem_alloc (                 {allocate memory for bitmap descriptor}
        sz,                            {amount of memory to allocate}
        rend_scope_dev_k,              {memory will belong to this device}
        false,                         {we don't need to individually dealloc mem}
        dib_info_p);                   {returned pointer to new memory}
      end;

    reflut_p := univ_ptr(addr(dib_info_p^.lut)); {make pointer to lut reference values}

    dib_info_p^.config.size := sizeof(dib_info_p^.config);
    dib_info_p^.config.width := dx;
    dib_info_p^.config.height := dy;   {scan lines will be stored bottom-up}
    dib_info_p^.config.planes := 1;
    dib_info_p^.config.bits_pix := bits_per_pixel;
    dib_info_p^.config.compress := dibcompress_rgb_k; {uncompressed}
    dib_info_p^.config.size_img := 0;
    dib_info_p^.config.ppm_x := 0;
    dib_info_p^.config.ppm_y := 0;
    if true_color
      then begin                       {true color}
        dib_info_p^.config.clr_used := 0;
        diblut := win_diblut_rgb_k;
        end
      else begin                       {pseudo color}
        dib_info_p^.config.clr_used := n_colors;
        diblut := win_diblut_ref_k;
        for i := 0 to pcolor_max do begin {once for each LUT entry}
          reflut_p^[i] := pc_win[i];
          end;
        end
      ;
    dib_info_p^.config.clr_important := 0; {all colors are important}

    sys_error_none (stat);             {reset to no error occurred}
    dib_h := CreateDIBSection (        {create the new DIB}
      dc,                              {device where reference palette comes from}
      dib_info_p^,                     {bitmap configuration info}
      diblut,                          {selects how pixel values are interpreted}
      p,                               {returned pointer to first pixel in memory}
      handle_none_k,                   {bitmap is not in a mapped file}
      0);                              {offset into mapped file for pixels, unused}
    if dib_h = handle_none_k then begin
      stat.sys := GetLastError;
      rend_error_abort (stat, 'rend_win', 'create_dib', nil, 0);
      end;
    pixadr := sys_int_adr_t(p);        {save starting address of DIB pixels array}
    dib_x := dx;                       {save DIB dimensions}
    dib_y := dy;
    end;                               {done creating DIB to match our window}
  end;
