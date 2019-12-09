{   Function REND_WIN_THREAD (THINFO)
*
*   This function is the main routine for the threads that each handle
*   a separate window.
*
*   The window thread runs in two phases, initialization and operation.
*
*   During initialization, the window is created and info about the window
*   is saved in the appropriate RENDlib state.  The THINFO call argument is
*   valid, and our device is swapped in.  The main thread waits for this
*   thread to finish initialization.  When initializtion is complete, we
*   signal the Win32 event THINFO.DONE.  This tells the main thread that
*   the window thread has completed initializing.  If an unrecoverable error
*   is detected during initialization, THINFO.STAT_P^ is set to the
*   error status and the thread is terminated.
*
*   The operation phase starts as soon as THINFO.DONE is signalled.  Our
*   RENDlib device may no longer be swapped in, and the THINFO call argument
*   is invalid and must not be referenced.  The only per-device state
*   we can access is the global rendlib REND_DEVICE[dev_id] entry, and the
*   WIN driver DEV[dev_id] entry, where "dev_id" is the RENDlib device ID
*   assigned to our device (note - this must be determined and saved locally
*   during the init phase).
*
*   This thread must try to clean up and terminate as soon as reasonably
*   possible when the QUIT message is received.
}
module rend_win_thread;
define rend_win_thread;
%include 'rend_win.ins.pas';

const
  adjust_max_k = 4;                    {max allowed attempts to adjust window}

var                                    {static variables}
  envvar_display: string_var16_t :=    {DISPLAY environment variable name}
    [str := 'DISPLAY', len := 7, max := sizeof(envvar_display.str)];
  envvar_remotehost: string_var16_t := {REMOTEHOST environment variable name}
    [str := 'REMOTEHOST', len := 10, max := sizeof(envvar_remotehost.str)];

function rend_win_thread (             {main routine for each window thread}
  in      thinfo: thinfo_t)            {special info for window thread}
  :sys_int_adr_t;                      {thread completion value, unused}

var
  dev_id: sys_int_machine_t;           {ID for our RENDlib device}
  ia: sys_int_adr_t;                   {scratch integer for manipulating addresses}
  i: sys_int_machine_t;                {scratch integer}
  getflag: win_bool_t;                 {flag from GetMessage}
  msg: win_msg_t;                      {message descriptor}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on sys call success}
  window_h: win_handle_t;              {local copy of handle to our window}
  ewstyle: ewstyle_t;                  {extended window style flags}
  wstyle: wstyle_t;                    {regular window style flags}
  pos_x, pos_y: sys_int_machine_t;     {requested window top left corner position}
  size_x, size_y: sys_int_machine_t;   {requested window size}
  parent_h: win_handle_t;              {handle to parent window}
  n_adjust: sys_int_machine_t;         {number of window adjust attempts so far}
  token: string_treename_t;            {scratch name string}
  wait_ready: boolean;                 {TRUE when waiting for window to become ready}
  adj_pos, adj_size: boolean;          {TRUE on window adjustment desired}
  stat: sys_err_t;                     {Cognivision error status code}

label
  got_scrname, screen_ok, loop_adjust, done_adjust, loop_msg, terminate, no_device;

begin
  token.max := size_char(token.str);   {init local var string}

  sys_error_none (thinfo.stat_p^);     {init to we didn't bomb with error}
  sys_error_none (stat);               {init our local error status code}
  rend_win_thread := 0;                {we don't use return code, will be ignored}

  dev_id := rend_dev_id;               {save ID of our RENDlib device}
  dev[dev_id].sig_nfull := handle_none_k; {queue not full signal not created yet}
  dev[dev_id].ready := false;          {init to window is not ready for drawing}
  dev[dev_id].shut := false;           {init to device is not being shut down}
  dev[dev_id].sizemove := false;       {not within user size/move operation}
  dev[dev_id].size_changed := false;   {no pending unreported window size changes}
  dev[dev_id].palette_set := false;    {palette not set yet in DC}
  for i := 0 to 255 do begin           {init to no keys exist}
    dev[dev_id].keyp[i] := nil;
    end;
{
*   Examine the THINFO.WINFO_P^ and WHOLE_SCREEN variables to determine the
*   window configuration we will request from Windows.
}
  with thinfo.winfo_p^: w do begin     {W is window descriptor from parent}

  if not (sys_winflag_name_k in w.flags) then begin {no window name set ?}
    string_progname (w.name_wind);     {default to program name}
    end;
  if not (sys_winflag_icname_k in w.flags) then begin {no icon name set ?}
    string_copy (w.name_wind, w.name_icon); {default to window name}
    end;
  string_terminate_null (w.name_wind); {make sure in format to pass to system call}
  string_terminate_null (w.name_icon);
{
*   Make sure the requested screen the window is to be on is on this machine.
*   we only know how to talk to the local screen.
}
  if sys_scrflag_proc_k in w.screen.flags {screen of machine running this process ?}
    then goto screen_ok;

  if sys_scrflag_stdout_k in w.screen.flags then begin {use screen of STDOUT ?}
    sys_envvar_get (envvar_display, w.screen.machine, stat); {read DISPLAY var}
    if sys_error(stat) then begin      {DISPLAY variable not present ?}
      sys_envvar_get (envvar_remotehost, w.screen.machine, stat); {try REMOTEHOST}
      if sys_error(stat) then begin    {no envvars to help, assume this machine}
        goto screen_ok;
        end;
      goto got_scrname;                {machine name is in W.SCREEN.MACHINE}
      end;
    for i := 1 to w.screen.machine.len do begin {scan machine name string}
      if w.screen.machine.str[i] = ':' then begin {found first ":" ?}
        w.screen.machine.len := i - 1; {truncate to just machine name part}
        exit;
        end;
      end;                             {back to look for end of machine name}
    end;                               {done handling use screen where STDOUT goes}
got_scrname:                           {machine name is in W.SCREEN.MACHINE}
  string_upcase (w.screen.machine);    {make upper case for comparison}
  sys_node_name (token);               {get name of this machine}
  string_upcase (token);               {compare is case-insensitive}
  if string_equal (w.screen.machine, token) {name of this machine ?}
    then goto screen_ok;

  goto no_device;                      {we can't access the requested screen}
screen_ok:                             {the screen is the one we can reach}

  ewstyle := [];                       {init extended window style flags}
  wstyle := [];                        {init regular window style flags}
  parent_h := handle_none_k;           {init to no parent window specified}

  if whole_screen
{
*   RENDlib inherent device is SCREEN.  Only W.SCREEN was filled in by parent.
}
    then begin
      w.size_x := GetSystemMetrics (metric_cxscreen_k); {get size of whole screen}
      w.size_y := GetSystemMetrics (metric_cyscreen_k);
      w.pos_x := 0;                    {align window with whole screen}
      w.pos_y := 0;
      w.flags :=                       {indicate window size and position important}
        w.flags + [sys_winflag_size_k, sys_winflag_pos_k];
      wstyle := [                      {select window style flags}
        wstyle_sysmenu_k,              {put standard system menu on title bar}
        wstyle_clip_child_k,           {our drawing will be clipped to child windows}
        wstyle_clip_sib_k];            {our drawing will be clipped to sib windows}
      end                              {end of inherent device is SCREEN}
{
*   RENDlib inherent device is WINDOW.  All of W was filled in by parent.
}
    else begin
      if sys_winflag_stdout_k in w.flags {don't know how to find STDOUT window}
        then goto no_device;
      if sys_winflag_dir_k in w.flags  {can't draw into a window we don't create}
        then goto no_device;
      if not (sys_winflag_pos_k in w.flags) then begin {use default position ?}
        w.pos_x := win_default_coor_k; {let Windows choose the window position}
        w.pos_y := 0
        end;
      if (w.window <> 0) and (w.window <> -1) then begin {specific parent wind ID ?}
        parent_h := w.window;
        end;
      if not (sys_winflag_size_k in w.flags) then begin {use default size ?}
        w.size_x := GetSystemMetrics (metric_cxscreen_k) div 2; {1/2 screen each dim}
        w.size_y := GetSystemMetrics (metric_cyscreen_k) div 2;
        end;
      wstyle := [                      {select window style flags}
        wstyle_max_box_k,              {make maximize box on title bar}
        wstyle_min_box_k,              {make minimize box on title bar}
        wstyle_edge_size_k,            {make user sizing border}
        wstyle_sysmenu_k,              {put standard system menu on title bar}
        wstyle_edge_thin_k,            {thin edge, needed for title bar}
        wstyle_clip_child_k,           {our drawing will be clipped to child windows}
        wstyle_clip_sib_k];            {our drawing will be clipped to sib windows}
      end                              {end of inherent device is WINDOW}
    ;                                  {end of inherent device SCREEN/WINDOW choice}

  pos_x := w.pos_x;                    {set the configuration we will request}
  pos_y := w.pos_y;
  size_x := w.size_x;
  size_y := w.size_y;
{
*   Create the window.
}
  dev[dev_id].sig_nfull := CreateEventA ( {create event queue not full signal}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {system will not automatically reset event}
    win_bool_false_k,                  {initial state will be not signalled}
    nil);                              {no name supplied for sharing}
  if dev[dev_id].sig_nfull = handle_none_k then begin
    if rend_debug_level >= 1 then begin
      writeln ('Unable to create SIG_NFULL event in REND_WIN_THREAD.');
      end;
    thinfo.stat_p^.sys := GetLastError;
    return;                            {terminate thread with error}
    end;

  if rend_debug_level >= 1 then begin
    writeln ('Creating window, RENDlib device ID = ', dev_id);
    end;
  ia := atom_class;                    {indicate atom ID for our window class}
  window_h := CreateWindowExA (        {try to create our drawing window}
    ewstyle,                           {extended window style flags}
    win_string_p_t(ia),                {global atom ID indicating our window class}
    w.name_wind.str,                   {window name for title bar}
    wstyle,                            {regular window flags}
    10, 10,                            {arbitrary position, will be adjusted later}
    64, 64,                            {arbitrary size, will be adjusted later}
    parent_h,                          {handle to parent window}
    handle_none_k,                     {no application menu specified}
    instance_h,                        {handle to our invocation instance}
    0);                                {passed in block pnt to by LPARAM of CREATE}
  if window_h = handle_none_k then begin {window wasn't created ?}
    thinfo.stat_p^.sys := GetLastError;
    discard( CloseHandle(dev[dev_id].sig_nfull) );
    return;                            {terminate thread with error}
    end;
  wind_h := window_h;                  {save window handle in common block}
  dev[dev_id].wind_h := window_h;

  ok := MoveWindow (                   {adjust window to force SIZE message}
    window_h,                          {handle to the window}
    pos_x, pos_y,                      {new upper left corner position}
    size_x, size_y,                    {new outer window size}
    win_bool_true_k);                  {invalidate window pixels}
  if ok = win_bool_false_k then begin
    thinfo.stat_p^.sys := GetLastError;
    if rend_debug_level >= 1 then begin
      writeln ('Unable to adjust window size and position.');
      end;
    goto terminate;
    end;
{
*   Try to adjust the window to the desired size and position.  The window
*   manager doesn't always do what we ask.  Our desired window configuration
*   is in W.  The value we used to request the current window configuration
*   are POS_X, POS_Y, SIZE_X, and SIZE_Y.  The actual client area window
*   configuration is in DEV[DEV_ID].
}
  n_adjust := 0;                       {init number of adjustment attempts so far}

loop_adjust:                           {back here each new adjustment attempt}
  if n_adjust >= adjust_max_k then goto done_adjust; {tried too often, give up ?}
  adj_pos := (sys_winflag_pos_k in w.flags) and {need to adjust position ?}
    ((dev[dev_id].pos_x <> w.pos_x) or (dev[dev_id].pos_y <> w.pos_y));
  adj_size := (sys_winflag_size_k in w.flags) and {need to adjust size ?}
    ((dev[dev_id].size_x <> w.size_x) or (dev[dev_id].size_y <> w.size_y));
  if not (adj_pos or adj_size)
    then goto done_adjust;             {nothing needs tweaking ?}

  if adj_size then begin               {we'd like to change window size ?}
    size_x := size_x - (dev[dev_id].size_x - w.size_x);
    size_y := size_y - (dev[dev_id].size_y - w.size_y);
    end;

  if adj_pos then begin                {we'd like to change window position ?}
    pos_x := pos_x - (dev[dev_id].pos_x - w.pos_x);
    pos_y := pos_y - (dev[dev_id].pos_y - w.pos_y);
    end;

  if rend_debug_level >= 2 then begin
    writeln ('Adjusting window to position ', pos_x, ',', pos_y,
      ' size ', size_x, ',', size_y);
    end;
  ok := MoveWindow (                   {try to adjust window size and position}
    window_h,                          {handle to the window}
    pos_x, pos_y,                      {new upper left corner position}
    size_x, size_y,                    {new outer window size}
    win_bool_true_k);                  {invalidate window pixels}
  if ok = win_bool_false_k then begin
    thinfo.stat_p^.sys := GetLastError;
    if rend_debug_level >= 1 then begin
      writeln ('Unable to adjust window size and position.');
      end;
    goto terminate;
    end;

  n_adjust := n_adjust + 1;            {log one more window diddle attempt}
  goto loop_adjust;                    {back to check new window configuration}
done_adjust:                           {all done adjusting window size/position}

  if rend_debug_level >= 1 then begin
    writeln ('Window created successfully.');
    end;

  rend_win_keys_init;                  {init keyboard and mouse keys events state}
  if rend_debug_level >= 2 then begin
    writeln ('Done initializing keyboard and mouse keys.  ',
      rend_device[dev_id].keys_n, ' keys found.');
    end;

  discard( ShowWindow (                {make our window visible}
    window_h,                          {handle to our window}
    winshow_normal_k));                {new window show state}

  end;                                 {done using W abbreviation}
{
*   Fetch messages and dispatch them to our window procedure when appropriate.
*   We enter this loop during the initialization phase.  The window is only
*   ready for normal drawing after certain messages have been received.  The
*   window procedure signals this by setting DEV[dev_id].READY.  When this
*   happens, we signal the parent thread that our initialization is complete.
}
  wait_ready := true;                  {init to waiting for window to become ready}
  if rend_debug_level >= 1 then begin
    writeln ('Window thread entering message loop.');
    end;

loop_msg:                              {back here each new thread message}
  if wait_ready and dev[dev_id].ready then begin {window just became ready ?}
    if rend_debug_level >= 1 then begin
      writeln ('Window has become ready for drawing.');
      end;
    rend_set.image_size^ (             {set size of our draw area}
      dev[dev_id].size_x, dev[dev_id].size_y, {size of draw area in pixels}
      dev[dev_id].size_x/dev[dev_id].size_y); {aspect ratio, assume square pixels}
    rend_image.size_fixed := true;     {app can't change image size}
    ok := SetEvent (thinfo.done);      {signal parent that initialization done}
    if ok = win_bool_false_k then begin {unable to signal the event ?}
      thinfo.stat_p^.sys := GetLastError;
      if rend_debug_level >= 1 then begin
        writeln ('Unable to signal window ready in window thread.');
        end;
      goto terminate;
      end;
    wait_ready := false;               {no longer waiting for window to become ready}
    end;

  getflag := GetMessageA (             {get the next message from thread msg queue}
    msg,                               {returned message descriptor}
    handle_none_k,                     {get any message for this thread}
    firstof(winmsg_k_t), lastof(winmsg_k_t)); {message range we care about}
  if ord(getflag) < 0 then begin       {error getting message ?}
    stat.sys := GetLastError;
    sys_error_print (stat, 'rend_win', 'err_get_message', nil, 0);
    goto terminate;
    end;

  if ord(getflag) = 0 then begin       {got the QUIT message ?}
    if rend_debug_level >= 1 then begin
      writeln ('QUIT message detected in window thread.');
      end;
    goto terminate;
    end;

  discard( DispatchMessageA (msg) );   {have our window procedure process the msg}
  goto loop_msg;                       {back for next thread message}
{
*   Delete the window, clean up, and terminate the thread.  This is part of
*   normal operation, and may not be due to any error.
}
terminate:
  if rend_debug_level >= 1 then begin
    writeln ('Window thread shutting down.');
    writeln ('Trying to destroy window in window thread.');
    end;
  discard( DestroyWindow(window_h) );  {try to kill the window}
  if rend_debug_level >= 1 then begin
    writeln ('Window destroyed, window thread terminating.');
    end;
  discard( CloseHandle(dev[dev_id].sig_nfull) );
  return;
{
*   Terminate thread with error status indicating NO_DEVICE.  This means the
*   SCREEN or WINDOW device can not be opened as requested.  No window currently
*   exists.
}
no_device:
  sys_stat_set (rend_subsys_k, rend_stat_no_device_k, thinfo.stat_p^);
  end;                                 {returning will terminate the thread}
