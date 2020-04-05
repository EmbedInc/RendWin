{   Module of relatively small administration routines that are part of
*   the RENDlib Windows driver.  Some of the routines are kept in separate
*   files for clarity.  They are, however, still part of this module because
*   they are referenced here with INCLUDE directives.
}
module rend_win_admin;
define rend_win_check_modes;
define rend_win_close;
define rend_win_cpnt_2dimi;
define rend_win_dev_reconfig;
define rend_win_dith_on;
define rend_win_iterp_flat;
define rend_win_min_bits_vis;
define rend_win_nodevs;
define rend_win_setup;
define rend_win_thread_stop;
%include 'rend_win.ins.pas';

define rend_win;                       {our common block is defined here}

%include 'rend_win_check_modes.ins.pas';
%include 'rend_win_dev_reconfig.ins.pas';
%include 'rend_win_setup.ins.pas';
{
*****************************************************************************
*
*   Subroutine REND_WIN_CPNT_2DIMI (X, Y)
*
*   Set the 2D integer pixel space current point.
}
procedure rend_win_cpnt_2dimi (        {set current point with absolute coordinates}
  in      x, y: sys_int_machine_t);    {new integer pixel coor of current point}
  val_param;

begin
  rend_sw_set.cpnt_2dimi^ (x, y);      {set RENDlib 2DIMI space current point}

  discard( MoveToEx (                  {set Windows current point}
    dc,                                {handle to drawing device context}
    x, y,                              {new current point coordinates}
    nil) );                            {we don't care where current point was}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_ITERP_FLAT (ITERP, VAL)
*
*   This routine is installed in the call table to catch any flat color changes.
}
procedure rend_win_iterp_flat (        {set interpolation to flat and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: real);                  {0.0 to 1.0 interpolant value}
  val_param;

begin
  rend_sw_set.iterp_flat^ (iterp, val); {do the real work}
  setup := setup_none_k;               {invalidate the current GDI setup}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_THREAD_STOP
*
*   Try to get the window thread to terminate.  This routine only makes the
*   request.  There is no guarantee when/if the window thread will actually
*   terminate.
}
procedure rend_win_thread_stop;

begin
  if wind_h = handle_none_k then return; {don't have handle to thread's window ?}

  dev[rend_dev_id].shut := true;       {tell thread we are trying to shut down}
  discard( SetEvent (                  {release thread from waiting on event queue}
    dev[rend_dev_id].sig_nfull) );

  discard( PostMessageA (              {try to send QUIT message to window thread}
    wind_h,                            {handle to window to send message to}
    winmsg_quit_k,                     {message ID}
    0,                                 {WPARAM, unsigned 32 bit integer}
    0) );                              {LPARAM, signed 32 bit integer}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_NODEVS
*
*   This routine must be called whenever the last Windows device is closed.
*   Some state shared between all Windows devices is initialized when the
*   first Windows device is opened, and the resources released when the last
*   Windows device is closed.
}
procedure rend_win_nodevs;             {clean up after closing last Windows device}

begin
  discard( DeleteObject(palette_h) );  {delete our Windows palette}
  DeleteCriticalSection (crsect_dev);  {delete thread interlocks}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_CLOSE
*
*   Close this window and release associated resources.
}
procedure rend_win_close;

begin
  rend_win_thread_stop;                {try to tell window thread to terminate}
  if rend_debug_level >= 1 then begin
    writeln ('Waiting for window thread to terminate in REND_WIN_CLOSE.');
    end;
  discard( WaitForSingleObject (       {wait for window thread to terminate}
    thread_h,                          {handle to window thread}
    timeout_infinite_k) );             {wait as long as it takes}
  discard( CloseHandle(thread_h) );    {all done with window thread}
  if rend_debug_level >= 1 then begin
    writeln ('  Terminated.');
    end;
{
*   The window thread has been terminated.
}
  discard( DeleteObject(dib_h) );      {delete bitmap matching our window}
  dev[rend_dev_id].wind_h := handle_none_k; {no window for this RENDlib device}
  n_windows := n_windows - 1;          {log one less active WIN device}
{
*   Clean up other Win driver state.
}
  if made_brush then begin             {we created a brush that still exists ?}
    discard( DeleteObject(brush_h) );  {delete the old brush}
    end;

  if made_pen then begin               {we created a pen that still exists ?}
    discard( DeleteObject(pen_h) );    {delete the old pen}
    end;
{
*   Clean up some local state if we just shut down the last Windows device.
}
  if n_windows <= 0 then begin         {no Windows devices left running ?}
    rend_win_nodevs;                   {release shared Windows devices resources}
    end;

  rend_sw_set.close^;                  {do standard part of close device}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_DITH_ON (ON)
}
procedure rend_win_dith_on (           {turn dithering on/off}
  in      on: boolean);                {TRUE for dithering on}
  val_param;

begin
  rend_cmode[rend_cmode_dithon_k] := false; {reset to this mode not changed}

  if on = rend_dith.on then return;    {dither mode already set correctly ?}

  rend_prim.flush_all^;                {finish any drawing before modes change}
  rend_dith.on := on;                  {set dithering switch to new value}

  if                                   {downgrade MIN_BITS to dither off level ?}
      (not rend_dith.on) and           {dithering just deliberately disabled ?}
      (rend_min_bits_vis > (bits_vis_ndith + 0.001))
      then begin
    rend_min_bits_vis := bits_vis_ndith; {reset min bits to reflect dithering off}
    rend_cmode[rend_cmode_minbits_vis_k] := true; {indicate this mode got changed}
    end;

  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_MIN_BITS_VIS (N)
}
procedure rend_win_min_bits_vis (      {set minimum required effective bits per pixel}
  in      n: real);                    {Log2 of total effective number of colors}
  val_param;

begin
  rend_cmode[rend_cmode_minbits_vis_k] := false; {reset to this mode not changed}
  if abs(rend_min_bits_vis - n) < 0.001 then return; {nothing to do ?}
  rend_min_bits_vis := n;              {set new value}

  if                                   {turn off dithering ?}
      rend_dith.on and                 {dithering is ON ?}
      (rend_min_bits_vis < (bits_vis_ndith + 0.001)) {don't need the color res ?}
      then begin
    rend_prim.flush_all^;              {finish any drawing before modes change}
    rend_dith.on := false;             {turn off dithering}
    rend_cmode[rend_cmode_dithon_k] := true; {indicate dithering got changed}
    end;

  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
