{   Subroutine REND_WIN_INIT (DEV_NAME, PARMS, STAT)
}
module rend_win_init;
define rend_win_init;
%include 'rend_win.ins.pas';

const
  log2 = ln(2.0);                      {used in finding log base 2}

var
  window_class_name: string := 'RENDlib_window_class'(0); {name of our window class}
  first_time: boolean := true;         {TRUE before first call to REND_WIN_INIT}
  dith_vals:                           {sequential dither threshold values}
    array[0..y_dith_max_k, 0..x_dith_max_k] of sys_int_machine_t := [
      [ 1,  5,  9, 13],
      [ 3,  7, 11, 15],
      [10, 14,  2,  6],
      [12, 16,  4,  8]
    ];

procedure rend_win_init (              {device is a window in Microsoft Windows}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}

var
  byte_p: ^int8u_t;                    {pointer to arbitrary memory byte}
  i, j, n: sys_int_machine_t;          {scratch integers and loop counters}
  ui: win_uint_t;                      {scratch Windows UINT integer}
  h: win_handle_t;                     {scratch Windows handle}
  red_n, grn_n, blu_n: sys_int_machine_t; {color component values}
  bitspixel: sys_int_machine_t;        {number of bits per pixel on device}
  sizepalette: sys_int_machine_t;      {number of device LUT entries}
  sz: sys_int_adr_t;                   {scratch memory size value}
  winfo: sys_window_t;                 {info about window desired by caller}
  thinfo: thinfo_t;                    {info passed to window thread}
  thread_id: win_dword_t;              {ID of new window thread}
  pick: sys_int_machine_t;             {number of token picked from list}
  waitlist:                            {list of handles to wait on simultaneously}
    array[0..1] of win_handle_t;
  donewait: donewait_k_t;              {reason WaitFor... routine returned}
  rascap: rascap_t;                    {device raster capabilities flags}
  logpal_p: logpalette_p_t;            {pointer to descriptor for Windows palette}

label
  done_colors, abort0, abort1, no_dev;
{
********************************************************************
*
*   Subroutine REND_WIN_SET_CINDEX_ENTRY (N, N_COL, MULT, ENTRY)
*
*   Set a CINDEX array entry for a particular color.  N is the 0 to 255
*   input color value for this CINDEX array entry.  N_COL is the
*   number of levels for this primary.  MULT is the number of sequential
*   pseudo colors that contain the same primary value.  ENTRY is the
*   part of a CINDEX array entry to fill in.
}
procedure rend_win_set_cindex_entry (  {set entry in color index table}
  in      n: sys_int_machine_t;        {0 to 255 input color value}
  in      n_col: sys_int_machine_t;    {available levels for this primary}
  in      mult: sys_int_machine_t;     {pcolors to skip for each level change}
  out     entry: cindex_entry_t);      {the entry to fill in}
  val_param;

var
  nf: real;                            {input N level in 0.0 to 1.0 scale}
  val_low, val_high: real;             {high and low dither values, 0.0 to 1.0}
  nc: sys_int_machine_t;               {number of sequential dithered color}
  ndith: sys_int_machine_t;            {number of total possible dithered levels}
  f: real;                             {fraction within dither range}

begin
  nf := n / 255.0;                     {make 0.0 to 1.0 input level}
  entry.close := (n * n_col) div 256;  {find closest available output level}

  ndith := (n_col - 1) * dith_vals_k + 1; {number of total dithered levels}
  nc := trunc(nf * ndith);             {make 0-N dithered level for this input level}
  nc := min(nc, ndith - 1);
  entry.dith_low := nc div dith_vals_k; {color levels to dither between}
  entry.dith_high := min(entry.dith_low + 1, n_col - 1);

  if entry.dith_low = entry.dith_high
    then begin                         {dither levels same, nothing to dither ?}
      entry.frac := 0;
      end
    else begin
      val_low :=                       {make 0.0 to 1.0 dither level values}
        entry.dith_low * (ndith - 1) / ((n_col - 1) * ndith);
      val_high :=
        entry.dith_high * (ndith - 1) / ((n_col - 1) * ndith);
      f := (nf - val_low) / (val_high - val_low); {make fraction into dither range}
      entry.frac := min(trunc(f * frac_high_k), frac_high_k);
      end
    ;

  entry.close := entry.close * mult;   {make final pcolor offsets from level values}
  entry.dith_low := entry.dith_low * mult;
  entry.dith_high := entry.dith_high * mult;
  end;
{
********************************************************************
*
*   Start of main routine.
}
begin
  sys_error_none (stat);               {init to not error returned}
{
*   Wake up base RENDlib.  This also sets the REND_DEBUG_LEVEL variable.
}
  rend_sw_init (dev_name, string_v(''), stat); {initialize base RENDlib}
  sys_error_abort (stat, 'rend', 'rend_open_sw', nil, 0);
{
*   Make sure standard output goes somewhere if the special debug flag is set.
}
  if rend_debug_level >= 11 then begin {in special debug mode ?}
    discard( AllocConsole );           {make sure a console exists}
    sys_sys_stdout_fix;                {make sure C lib output routed to console}
    end;
{
***************************************
*
*   Init static driver state that remains valid even after all devices are
*   closed.  This section is run at most once per program on the first call
*   to REND_WIN_INIT.
}
  if first_time then begin             {driver common block totally unititialized ?}
    first_time := false;               {reset flag to prevent coming here again}
{
*   Create the window class we will use for all our windows.
}
    byte_p := univ_ptr(addr(wclass));  {init class descriptor to all zeros}
    for i := 1 to size_min(wclass) do begin
      byte_p^ := 0;
      byte_p := succ(byte_p);
      end;

    wclass.size := size_min(wclass);   {indicate size of data structure}
    wclass.style := [                  {set window class style}
      clstyle_dblclks_k,               {convert and send double click messages}
      clstyle_own_dc_k];               {each window gets a private dc}
    wclass.msg_proc := addr(rend_win_windproc); {set pointer to window procedure}
    wclass.instance_h := instance_h;   {identify who will own the window class}
    wclass.cursor_h := LoadCursorA (   {indicate which cursor to use}
      handle_none_k,                   {we will use one of the predifined cursors}
      cursor_arrow_k);                 {ID of predefined cursor}
    if wclass.cursor_h = handle_none_k then begin {error getting cursor handle ?}
      stat.sys := GetLastError;        {return with error}
      if rend_debug_level >= 1 then begin
        writeln ('Error getting handle to standard cursor.');
        end;
      return;
      end;
    wclass.name_p := univ_ptr(addr(window_class_name));

    atom_class := RegisterClassExA (wclass); {try to create our new window class}
    if atom_class = 0 then begin       {failed to create new window class ?}
      stat.sys := GetLastError;        {return with error}
      if rend_debug_level >= 1 then begin
        writeln ('Error on attempt to register RENDlib window class.');
        end;
      return;
      end;
{
*   Init other static state.
}
    for i := 1 to rend_max_devices do begin {init all our per-device state}
      dev[i].wind_h := handle_none_k;  {indicate no window for this device}
      end;

    palette_h := handle_none_k;        {init to no Windows palette created}
    n_windows := 0;                    {init number of open WIN devices}
    end;
{
*   Done with the initialization that is only performed once per program
*   invocation.
*
***************************************
*
*   Interpret the DEV_NAME and PARMS arguments to determine the window
*   configuration parameters.  The result will be put into WINFO.
*   WHOLE_SCREEN will be set if the device is supposed to be the entire screen,
*   in which case only WINFO.SCREEN is filled in.  Otherwise, WHOLE_SCREEN
*   is false, and all of WINFO is filled in.
}
  string_tkpick80 (dev_name,           {which RENDlib device was requested ?}
    'SCREEN WINDOW',
    pick);
  case pick of
{
*   The RENDlib inherent device is SCREEN.
}
1:  begin                              {RENDlib inherent device was SCREEN}
      winfo.name_wind.max := size_char(winfo.name_wind.str);
      winfo.name_wind.len := 0;
      winfo.name_icon.max := size_char(winfo.name_icon.str);
      winfo.name_icon.len := 0;
      winfo.flags := [];
      whole_screen := true;            {remember we are drawing to the whole screen}
      string_t_screen (parms, winfo.screen, stat);
      if sys_error (stat) then return;
      end;
{
*   The RENDlib inherent device is WINDOW.
}
2:  begin                              {RENDlib inherent device was WINDOW}
      whole_screen := false;
      string_t_window (parms, winfo, stat);
      if sys_error (stat) then return;
      end;
{
*   Unrecognized or unsupported RENDlib inherent device name.
}
otherwise                              {unexpected RENDlib inherent device name}
    sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat);
    return;
    end;                               {end of inherent RENDlib device name cases}
{
***************************************
*
*   Initialize some of the state shared between Windows devices.  This
*   initialization is only performed if there are no currently open
*   Windows devices.  Any resources allocated here are released when
*   the last Windows device is closed.  This is done in routine
*   REND_WIN_NODEVS.  Therefore, any changes here must be reflected in
*   REND_WIN_NODEVS.
}
  if n_windows = 0 then begin          {no currently open Windows devices ?}
    evi_write := 0;                    {init events queue to empty}
    evi_read := 0;
    n_events := 0;
    sig_nempty := CreateEventA (       {make event queue not full signal}
      nil,                             {no security info supplied}
      win_bool_false_k,                {reset by system on successful wait}
      win_bool_false_k,                {not initiallly signalled}
      nil);                            {no name supplied for sharing}
    if sig_nempty = handle_none_k then begin
      stat.sys := GetLastError;
      if rend_debug_level >= 1 then begin
        writeln ('Error on trying to create Win32 event for Windows driver event queue.');
        end;
      return;
      end;

    InitializeCriticalSection (crsect_dev); {create single-thread interlocks}
    InitializeCriticalSection (crsect_events);
    may_dith := false;                 {init to dithering not allowed this pixform}
    true_color := false;               {init to pseudo color pixel format}
    palette := true;                   {init to using Windows color palette}

    for i := 0 to pcolor_max_k do begin {once for each pcolor translate table entry}
      pc_win[i] := i;                  {init to straight thru mapping}
      end;
    end;

  n_windows := n_windows + 1;          {indicate one more active Windows device}
{
***************************************
*
*   Launch the window thread and wait for it to finish initializing.
*
*   Fill in the data structure to be passed to the thread.
}
  thinfo.winfo_p := addr(winfo);       {point to info about desired window}
  thinfo.stat_p := addr(stat);         {point to where to return any bad news}

  thinfo.done := CreateEventA (        {create semiphore for thread init done}
    nil,                               {no security attributes supplied}
    win_bool_false_k,                  {auto reset on successful wait}
    win_bool_false_k,                  {initial state is not signalled}
    nil);                              {no name sharing info supplied}
  if thinfo.done = handle_none_k then begin {failed to create semiphore ?}
    stat.sys := GetLastError;
    if rend_debug_level >= 1 then begin
      writeln ('Error on create system event for window thread init done.');
      end;
    goto abort0;
    end;
{
*   Create and start the thread.
}
  thread_h := CreateThread (           {start up the thread to service this window}
    nil,                               {no security attributes supplied}
    0,                                 {use default initial stack size}
    addr(rend_win_thread),             {address of main thread routine}
    addr(thinfo),                      {pointer to thread routine argument}
    [],                                {thread startup flags}
    thread_id);                        {returned ID of new thread}
  if thread_h = handle_none_k then begin {failed to create window thread ?}
    stat.sys := GetLastError;
    if rend_debug_level >= 1 then begin
      writeln ('Error on create window thread.');
      end;
    goto abort0;
    end;
{
*   Wait for the thread to finish initializing.
}
  waitlist[0] := thinfo.done;          {wait for thread to indicate done init}
  waitlist[1] := thread_h;             {stop waiting if thread somehow stopped}

  donewait := WaitForMultipleObjects ( {wait for thread abort or initialization done}
    2,                                 {number of events in WAITLIST to wait on}
    waitlist,                          {list of handles to wait on}
    win_bool_false_k,                  {wait for any event, not all events in list}
    timeout_infinite_k);               {no timeout, wait as long as it takes}
  if donewait = donewait_failed_k then begin {hard error like bad handle ?}
    stat.sys := GetLastError;
    if rend_debug_level >= 1 then begin
      writeln ('On wait for window thread to finish initializing.');
      end;
    end;
  discard( CloseHandle(thinfo.done) ); {done with interlock event object}

  if ord(donewait) <> 0 then begin     {something other than thread init finished ?}
    rend_win_thread_stop;              {try to tell window thread to terminate}
    discard( CloseHandle(thread_h) );  {we wash our hands of the window thread}
    if not sys_error(stat) then begin  {no error already indicated ?}
      sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat); {set the err status}
      if rend_debug_level >= 1 then begin
        writeln ('Unexpected event occurred on wait for window thread to');
        writeln ('finish initializing.  DONEWAIT = ', ord(donewait));
        end;
      end;
    goto abort0;
    end;
{
*   The window thread has been launched and it has finished its initialization.
*   This means our window is now visible on the screen.  It's initial size
*   and position have been set.
*
***************************************
*
*   Gather more info about the window.
}
  dc := GetDC (wind_h);                {get device context handle for this window}
  if dc = handle_none_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;
  if rend_debug_level >= 1 then begin
    writeln ('Window size is ', rend_image.x_size, ' x ', rend_image.y_size, '.');
    end;
{
*   Print some info about the graphics device if a suitable debug level is set.
}
  if rend_debug_level >= 5 then begin
    writeln ('Device BITSPIXEL = ', GetDeviceCaps(dc, win_devcap_bitspixel_k));
    writeln ('Device NUMCOLORS = ',
      GetDeviceCaps(dc, win_devcap_numcolors_k));
    writeln ('Device SIZEPALETTE = ',
      GetDeviceCaps(dc, win_devcap_sizepalette_k));
    writeln ('Device COLORRES = ',
      GetDeviceCaps(dc, win_devcap_colorres_k));
    writeln ('Device HORZSIZE = ', GetDeviceCaps(dc, win_devcap_horzsize_k));
    writeln ('Device VERTSIZE = ', GetDeviceCaps(dc, win_devcap_vertsize_k));
    writeln ('Device HORZRES = ', GetDeviceCaps(dc, win_devcap_horzres_k));
    writeln ('Device VERTRES = ', GetDeviceCaps(dc, win_devcap_vertres_k));
    writeln ('Device ASPECTX = ', GetDeviceCaps(dc, win_devcap_aspectx_k));
    writeln ('Device ASPECTY = ', GetDeviceCaps(dc, win_devcap_aspecty_k));
    writeln ('Device ASPECTXY = ', GetDeviceCaps(dc, win_devcap_aspectxy_k));
    end;
{
*   Get info about the device pixel format and other capabilities before
*   branching to the code unique to this pixel format.
}
  rascap :=                            {get device raster capabilities flags}
    rascap_t(GetDeviceCaps (dc, win_devcap_rastercaps_k));
  bitspixel :=                         {get number of bits/pixel on device}
    GetDeviceCaps (dc, win_devcap_bitspixel_k);
{
*   Fix up BITSPIXEL.  On some really old VGA systems, this is reported as
*   1, even though the system can display 16 colors.  We therefore make sure
*   that BITSPIXEL is never less than Log2 of NUMCOLORS.
}
  n := GetDeviceCaps(dc, win_devcap_numcolors_k); {get number of colors}
  i := 1;                              {init number of bits}
  j := 2;                              {init number of colors for I bits}
  while j < n do begin                 {still need more bits for all the colors ?}
    i := i + 1;                        {try one more bit}
    j := j + j;                        {update number of colors for I bits}
    end;
  if i > bitspixel then begin          {BITSPIXEL was reported too low ?}
    if rend_debug_level >= 5 then begin
      writeln ('BITSPIXEL was reported less than Log2(NUMCOLORS).');
      writeln ('  Increasing BITSPIXEL from ', bitspixel, ' to ', i, '.');
      end;
    bitspixel := i;
    end;

  rend_bits_hw := bitspixel;           {indicate to app how many used bits/pixel}
  sizepalette :=                       {get number of device LUT entries}
    GetDeviceCaps (dc, win_devcap_sizepalette_k);

  if not (rascap_dibtodev_k in rascap) then begin {can't copy pixels from DIB ?}
    if rend_debug_level >= 1 then begin
      writeln ('Device does not support DIBitsToDevice call.');
      end;
    goto abort1;
    end;

  case bitspixel of                    {different code for each HW pixel format}
{
*********************
*
*   4 bits per pixel.  We only use the 8 primary colors because they
*   are always available.  This means we essentially have 1 bit/color/pixel.
}
4: begin
  if n_windows = 1 then begin          {only init state for first window}
    n_red := 2;                        {number of levels per color component}
    n_grn := 2;
    n_blu := 2;
    true_color := false;               {indicate we are using pseudo color}
    may_dith := true;                  {dithering is allowed}
    palette := true;                   {init to we will use a pallette}

    if sizepalette = 0 then begin      {non-pallette VGA ?}
      palette := false;                {we won't use palette in this mode}
      {
      *   Set mapping from our internal pcolors to the Windows VGA 16 pcolors.
      *   The first 8 Windows pcolors are the full RGB primaries with red
      *   mapped to the lowest bit and blue to the highest.  Our internal
      *   pcolors are reversed with blue mapped to the lowest bit and red
      *   to the highest.  The table PC_WIN translates our pcolors to the
      *   Window pcolor.
      }
      pc_win[0] := 0;                  {       blk}
      pc_win[1] := 4;                  {    b  blu}
      pc_win[2] := 2;                  {  g    grn}
      pc_win[3] := 6;                  {  g b  cya}
      pc_win[4] := 1;                  {r      red}
      pc_win[5] := 5;                  {r   b  mag}
      pc_win[6] := 3;                  {r g    yel}
      pc_win[7] := 7;                  {r g b  whi}
      end;

    end;                               {end of code for handling first window}
  pixform := pixform_pc4_k;            {pixel format is 4 bit pseudo color}
  end;
{
*********************
*
*   8 bits per pixel pseudo color.  We always use 240 colors.
}
8: begin
  if n_windows = 1 then begin          {only init state for first window}
    n_red := 6;                        {number of levels per color component}
    n_grn := 8;
    n_blu := 5;
    true_color := false;               {indicate we are using pseudo color}
    may_dith := true;                  {dithering is allowed}
    palette := true;                   {will use Windows color palette}
    end;
  pixform := pixform_pc8_k;            {pixel format is 8 bit pseudo color}
  end;
{
*********************
*
*   16 bits per pixel true color, xRGB 1,5,5,5
}
16: begin
  if n_windows = 1 then begin          {only init state for first window}
    n_red := 32;                       {number of levels per color component}
    n_grn := 32;
    n_blu := 32;
    true_color := true;
    may_dith := true;                  {dithering is allowed}
    palette := false;                  {will not use Windows color palette}
    end;
  pixform := pixform_tc16_k;           {pixel format is 16 bit true color}
  end;
{
*********************
*
*   24 bits per pixel true color.
}
24: begin
  if n_windows = 1 then begin          {only init state for first window}
    n_red := 256;                      {number of levels per color component}
    n_grn := 256;
    n_blu := 256;
    true_color := true;
    may_dith := false;                 {disalow dithering}
    palette := false;                  {will not use Windows color palette}
    end;

  pixform := pixform_tc24_k;           {indicate exact pixel format}
  end;
{
*********************
*
*   32 bits per pixel true color.
}
32: begin
  if n_windows = 1 then begin          {only init state for first window}
    n_red := 256;                      {number of levels per color component}
    n_grn := 256;
    n_blu := 256;
    true_color := true;
    may_dith := false;                 {disalow dithering}
    palette := false;                  {will not use Windows color palette}
    end;

  pixform := pixform_tc32_k;           {indicate exact pixel format}
  rend_bits_hw := 24;                  {only 24 bits actually used to make colors}
  end;
{
*********************
*
*   Unexpected or unsupported hardware pixel size.
}
otherwise
    if rend_debug_level >= 1 then begin
      writeln ('Pixel size of ', bitspixel,
        ' is not supported in the REND_WIN driver.');
      end;
    goto abort1;
    end;                               {end of different pixel size cases}
{
***************************************
*
*   Init the common color state for all our windows.  All windows on the screen
*   always have the same pixel format.
*
*   Note that some system resources may be allocated here.  This means they
*   must be deallocated when the last WIN device is closed.  This is done
*   in subroutine REND_WIN_NODEVS.
}
  if n_windows <> 1 then goto done_colors; {color state already initialized ?}
  bits_per_pixel := bitspixel;         {save bits per pixel in common block}
  n_colors := n_red * n_grn * n_blu;   {make total number of colors we need}
  pcolor_max := n_colors - 1;          {make index of last color we need}

  if not palette
{
*   No palette is required.  This is because we are using a true color mode,
*   or a fixed pseudo color mode.
}
    then begin
      palette_h := handle_none_k;      {indicate we created no pallette}
      end
{
*   A Windows palette is required.
}
    else begin
      if not (rascap_palette_k in rascap) then begin {device doesn't have pallette ?}
        if rend_debug_level >= 1 then begin
          writeln ('Device does not support palette mode color.')
          end;
        goto abort1;
        end;

      if sizepalette < n_colors then begin {not enough possible colors ?}
        if rend_debug_level >= 1 then begin
          writeln ('Device has ', sizepalette,
            ' palette entries, minimum of ', n_colors, ' required.');
          end;
        goto abort1;
        end;
{
*   Create our Windows palette.  The handle to the palette will be left
*   in PALETTE_H in the common block.
}
      if n_colors > n_colors_max_k then begin
        if rend_debug_level >= 1 then begin
          writeln ('Required number of pseudo colors exceeds internal table size.');
          writeln (n_colors, ' required, no more than ', n_colors_max_k, ' allowed.');
          end;
        goto abort1;
        end;

      sz :=                            {total size needed for the palette descriptor}
        offset(logpalette_t.lut) +     {size up to actual palette entries}
        n_colors * sizeof(logpalette_t.lut); {size for the number of entries we need}
      sys_mem_alloc (sz, logpal_p);    {allocate memory for the palette descriptor}
      sys_mem_error (logpal_p, '', '', nil, 0);

      logpal_p^.version := 16#300;     {palette descriptor structure version ID}
      logpal_p^.n_ents := n_colors;    {number of entries in LUT array}

      red_n := 0;                      {init current sequential color values}
      grn_n := 0;
      blu_n := 0;
      for i := 0 to pcolor_max do begin {once for each LUT entry to set}
        logpal_p^.lut[i].red := min((red_n * 256) div (n_red - 1), 255);
        logpal_p^.lut[i].grn := min((grn_n * 256) div (n_grn - 1), 255);
        logpal_p^.lut[i].blu := min((blu_n * 256) div (n_blu - 1), 255);
        logpal_p^.lut[i].flags := [];
        lut[i].red := logpal_p^.lut[i].red; {save color in common block}
        lut[i].grn := logpal_p^.lut[i].grn;
        lut[i].blu := logpal_p^.lut[i].blu;
        lut[i].mode := colorref_rgb_k;
        blu_n := blu_n + 1;
        if blu_n >= n_blu then begin   {wrap blue color back to 0 ?}
          blu_n := 0;
          grn_n := grn_n + 1;
          if grn_n >= n_grn then begin {wrap green color back to 0 ?}
            grn_n := 0;
            red_n := red_n + 1;
            end;
          end;
        end;                           {back to fill in next LUT array entry}

      palette_h := CreatePalette (logpal_p^); {create our Windows palette}
      sys_mem_dealloc (logpal_p);      {dealocate temporary palette descriptor}
      if palette_h = handle_none_k then begin
        stat.sys := GetLastError;
        if rend_debug_level >= 1 then begin
          writeln ('Error on attempt to create Windows palette.');
          end;
        goto abort1;
        end;
      end                              {end of pseudo color case}
    ;                                  {end of true/pseudo color cases}

  bits_vis_ndith :=                    {effective colors when not dithering}
    n_red * n_grn * n_blu;
  bits_vis_ndith :=                    {convert to effective bits (LOG2)}
    ln(bits_vis_ndith) / log2;
{
*   Set up the dithering state.
}
  if may_dith
    then begin                         {dithering is allowed}
{
*   Set up the dither table.  This table supplies threshold values for the
*   dithering decision.  The sequential threshold values are in DITH_VALS.
*   These are converted to the runtime dither threshold values and saved
*   in DITH.
}
      for i := 0 to y_dith_max_k do begin {down the dither table rows}
        for j := 0 to x_dith_max_k do begin {across this dither table row}
          dith[i, j] := (dith_vals[i, j] * frac_high_k) div dith_vals_k;
          end
        end;
{
*   Init CINDEX array.  This array is used to translate from the RENDlib 24
*   bit true color values to lower resolution window color values with and
*   without dithering enabled.
}
      for i := 0 to 255 do begin       {once for each possible R, G, or B input val}
        rend_win_set_cindex_entry (i, n_red, n_grn * n_blu, cindex.red[i]);
        rend_win_set_cindex_entry (i, n_grn, n_blu, cindex.grn[i]);
        rend_win_set_cindex_entry (i, n_blu, 1, cindex.blu[i]);
        end;

      bits_vis_dith :=                 {total effective visible dithered colors}
        ((n_red - 1) * dith_vals_k + 1) *
        ((n_grn - 1) * dith_vals_k + 1) *
        ((n_blu - 1) * dith_vals_k + 1);
      bits_vis_dith :=                 {convert to effective bits (LOG2)}
        ln(bits_vis_dith) / log2;
      end                              {end of dithering is allowed case}

    else begin                         {dithering is will not be allowed}
      bits_vis_dith := bits_vis_ndith;
      end                              {end of dithering is not allowed case}
    ;                                  {end of dithering allowed yes/no cases}

done_colors:                           {done initializing our color handling state}
{
*   Done initializing our color handling state.
*
***************************************
}
{
*   Do more RENDlib initialization.
}
  rend_sw_add_sblock (                 {add WIN common block to save/restore list}
    univ_ptr(sys_int_adr_t(addr(rend_win_com_start)) {starting address of block}
      + sizeof(rend_win_com_start)),
    sys_int_adr_t(addr(rend_win_com_end)) - {length of block in bytes}
      (sys_int_adr_t(addr(rend_win_com_start))+sizeof(rend_win_com_start)) );

  rend_close_corrupt := true;          {closing device will destroy the drawing wind}
  rend_dev_evcheck_set (               {tell RENDlib of our events check routine}
    addr(rend_win_event_check));
{
*   Set call table entry points for this driver.
}
  rend_set.close := addr(rend_win_close);
  rend_set.cpnt_2dimi := addr(rend_win_cpnt_2dimi);
  rend_set.dev_reconfig := addr(rend_win_dev_reconfig);
  rend_set.dith_on := addr(rend_win_dith_on);
  rend_set.iterp_flat := addr(rend_win_iterp_flat);
  rend_set.min_bits_vis := addr(rend_win_min_bits_vis);

  rend_internal.check_modes := addr(rend_win_check_modes);
  rend_internal.ev_possible := addr(rend_win_get_ev_possible);

  rend_install_prim (rend_win_flush_all_d, rend_prim.flush_all);
  rend_install_prim (rend_win_update_span_d, rend_internal.update_span);
{
*   Init the remainder of our local state that is private to this window.
}
  if not palette
    then begin                         {no palette is used for this pixel format}
      dev[rend_dev_id].palette_set := false; {no pallette set in this window}
      end
    else begin                         {pixel format is pseudo color with palette}
      h := SelectPalette (             {set our palette into the DC for our window}
        dc,                            {handle to device context for our window}
        palette_h,                     {handle to our palette}
        win_bool_false_k);             {this is a foreground palette}
      if h = handle_none_k then begin
        stat.sys := GetLastError;
        if rend_debug_level >= 1 then begin
          writeln ('Error on select palette into DC in REND_WIN_INIT.');
          end;
        goto abort1;
        end;
      if h <> palette_h then begin     {old palette was not our palette ?}
        discard( DeleteObject(h) );    {delete the old palette}
        end;
      dev[rend_dev_id].palette_set := true; {palette is now set in this window's DC}
      ui := RealizePalette (dc);       {make palette visible on screen}
      if ui = win_gdi_error_k then begin
        stat.sys := GetLastError;
        if rend_debug_level >= 1 then begin
          writeln ('Error on RealizePalette in REND_WIN_INIT.');
          end;
        goto abort1;
        end;
      if rend_debug_level >= 2 then begin
        writeln (ui, ' palette entries loaded.');
        end;
      end
    ;

  dib_h := handle_none_k;              {init to no DIB created yet}
  dib_info_p := nil;                   {init to no DIB info structure allocated}
  dib_x := -1;                         {guarantee to trigger resize first time}
  dib_y := -1;
  setup := setup_none_k;               {init to no particular setup current}
  made_brush := false;                 {we didn't make brush in DC}
  made_pen := false;                   {we didn't make pen in DC}
  rend_set.dev_reconfig^;              {adjust to current device configuration}
  rend_internal.check_modes^;          {install the appropriate call table routines}
  return;                              {normal return}
{
***************************************
*
*   Error exits.
*
*   The error status will be NO_DEVICE unless STAT is already set to indicate
*   an error.
}
abort1:                                {window thread running, STAT set}
  rend_win_thread_stop;                {try to tell window thread to terminate}
  discard( CloseHandle(thread_h) );    {we wash our hands of the window thread}

abort0:                                {N_WINDOWS already incremented for this dev}
  n_windows := n_windows - 1;          {take back count for this device}
  if n_windows = 0 then begin          {no Windows devices now open ?}
    rend_win_nodevs;                   {deallocate some Win devs shared resources}
    end;
  if not sys_error(stat) then begin    {no error status indicated in STAT ?}
no_dev:                                {return with NO_DEVICE status}
    sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat); {set to NO_DEVICE err}
    end;
  end;
