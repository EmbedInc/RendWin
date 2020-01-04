{   Function REND_WIN_WINDPROC (WIN_H, MSGID, WPARAM, LPARAM)
*
*   This is the window procedure for our window class.  It is called by the
*   system when messages are explicitly dispatched to our window, and when
*   certain asynchronous events happen.
}
module rend_win_windproc;
define rend_win_windproc;
%include 'rend_win.ins.pas';
%include 'win_keys.ins.pas';

function rend_win_windproc (           {our official Windows window procedure}
  in      win_h: win_handle_t;         {handle to window this message is for}
  in      msgid: winmsg_k_t;           {ID of this message}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_lresult_t;                      {unsigned 32 bit integer return value}
  val_param;

var
  x, y: sys_int_machine_t;             {scratch integer coordinates}
  coor32: win_coor32s_t;               {signed X,Y packed into 32 bits}
  dev_id: sys_int_machine_t;           {RENDlib device ID}
  wdc: win_handle_t;                   {handle to drawing device context}
  h: win_handle_t;                     {scratch Win32 handle}
  ui: win_uint_t;                      {scratch Windows UINT integer}
  paint: winpaint_t;                   {paint info from BeginPaint}
  minmax_p: win_minmaxinfo_p_t;        {pointer to window min/max allowed limits}
  ev: event_t;                         {WIN device internal event descriptor}
  key_p: rend_key_p_t;                 {pointer to RENDlib key descriptor}
  vk: sys_int_machine_t;               {Window virtual key code}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  result_set: boolean;                 {TRUE if function result already set}
  down: boolean;                       {TRUE on key down, FALSE on key up}
  stat: sys_err_t;

label
  close_user, noclose, key_flags_down, key_flags_up, mouse_button, done_message,
  default_action;
{
********************************************************************************
*
*   Local subroutine SET_DEV
*
*   Set the local variable DEV_ID to indicate the RENDlib device ID for the
*   window this message is for.
}
procedure set_dev;

begin
  for dev_id := 1 to rend_max_devices do begin {once for each RENDlib device}
    if dev[dev_id].wind_h = win_h then return; {found our device ?}
    end;                               {back to try next RENDlib device}

  sys_message_bomb ('rend_win', 'device_not_found', nil, 0);
  end;
{
********************************************************************************
*
*   Function HIGH16U (I32)
*
*   Extract the high 16 bits of a 32 bit inteteger.  The result is returned as
*   a unsigned 16 bit value (0 to 65535).
}
function high16u (                     {get high 16 bit word, unsigned}
  in      i32: sys_int_conv32_t)       {32 bit integer to extract word from}
  :sys_int_machine_t;                  {unsigned 16 bit result}
  val_param;

begin
  high16u := rshft(i32, 16) & 16#FFFF;
  end;
{
********************************************************************************
*
*   Function HIGH16S (I32)
*
*   Extract the high 16 bits of a 32 bit inteteger.  The result is returned as
*   a signed 16 bit value (-32768 to +32767).
}
function high16s (                     {get high 16 bit word, signed}
  in      i32: sys_int_conv32_t)       {32 bit integer to extract word from}
  :sys_int_machine_t;                  {signed 16 bit result}
  val_param;

var
  ii: sys_int_machine_t;

begin
  ii := high16u (i32);
  if ii > 32767 then begin
    ii := ii - 65536;
    end;
  high16s := ii;
  end;
{
********************************************************************************
*
*   Function LOW16U (I32)
*
*   Extract the low 16 bits of a 32 bit inteteger.  The result is returned as
*   a unsigned 16 bit value (0 to 65535).
}
function low16u (                      {get low 16 bit word, unsigned}
  in      i32: sys_int_conv32_t)       {32 bit integer to extract word from}
  :sys_int_machine_t;                  {unsigned 16 bit result}
  val_param;

begin
  low16u := i32 & 16#FFFF;
  end;
{
********************************************************************************
*
*   Function LOW16S (I32)
*
*   Extract the low 16 bits of a 32 bit inteteger.  The result is returned as
*   a signed 16 bit value (-32768 to +32767).
}
function low16s (                      {get low 16 bit word, signed}
  in      i32: sys_int_conv32_t)       {32 bit integer to extract word from}
  :sys_int_machine_t;                  {signed 16 bit result}
  val_param;

var
  ii: sys_int_machine_t;

begin
  ii := low16u (i32);
  if ii > 32767 then begin
    ii := ii - 65536;
    end;
  low16s := ii;
  end;
{
********************************************************************************
*
*   Subroutine LPARAM_XY (I32, X, Y)
*
*   Extract the signed coordinates from a LPARAM 32 bit integer.  I32 is the
*   LPARAM word.  X and Y are set to the resulting signed coordinate.
}
procedure lparam_xy (                  {get X,Y coordinate from LPARAM word}
  in      i32: sys_int_conv32_t;       {32 bits in LPARAM coordinate format}
  out     x, y: sys_int_machine_t);    {resulting X,Y coordinate}
  val_param;

begin
  x := low16s(i32);
  y := high16s(i32);
  end;
{
********************************************************************************
*
*   Local subroutine SEND_PNT_MOVE (X, Y)
*
*   Send a PNT_MOVE event to RENDlib, if appropriate.  The latest known pointer
*   coordinates are X,Y.  DEV_ID must be set to the RENDlib device ID for this
*   window.
*
*   This routine eliminates redundant pointer motion events.  Even event
*   actually sent will be for a different pointer coordinate than the previous.
}
procedure send_pnt_move (              {send PNT_MOVE event to RENDlib, if needed}
  in      x, y: sys_int_machine_t);    {pointer coordinate}
  val_param;

var
  ev: event_t;                         {WIN device internal event descriptor}

begin
  if                                   {already sent this pointer coordinate ?}
      (dev[dev_id].pntx = x) and
      (dev[dev_id].pnty = y)
      then begin
    return;                            {nothing to do}
    end;

  dev[dev_id].pntx := x;               {update last known pointer coordinate}
  dev[dev_id].pnty := y;

  if not (rend_evdev_pnt_k in rend_device[dev_id].ev_req) {pnt messages disabled ?}
    then return;

  ev.dev := dev_id;                    {fill in Win driver event descriptor}
  ev.id := event_pmove_k;              {pointer motion event}
  ev.pmove_x := x;                     {set event coordinate}
  ev.pmove_y := y;
  rend_win_event_put (ev);             {put the event in our queue}
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  dev_id := 0;                         {init to RENDlib device ID not determined yet}

  if rend_debug_level >= 10 then begin
    rend_win_show_message (msgid, wparam, lparam); {show message and parms}
    end;

  result_set := false;                 {init to REND_WIN_WINDPROC func value not set}
  case msgid of                        {which message is it ?}
{
**********
*
*   CREATE  -  Window is about to be created.  This message is sent while the
*     thread is still in the CreateWindow routine.
}
winmsg_create_k: begin
  dev_id := rend_dev_id;               {get our RENDlib device ID}
  dev[dev_id].wind_h := win_h;         {save handle to the window for this device}
  dev[dev_id].pntx := -100000;         {init previous pnt coor to force difference}
  dev[dev_id].pnty := -100000;
  dev[dev_id].scrollv := 0;            {init to no unsent vertical scroll increments}
  end;
{
**********
*
*   ENTERSIZEMOVE  -  The user has just switched into a mode where he may be
*     actively adjusting the size or position of the window.  We always get an
*     EXITSIZEMOVE message when the user leaves this mode.
*
*   We suppress any messages caused by window resizing until the user is
*   finished with the whole resizing operation.
}
winmsg_entersizemove_k: begin
  set_dev;                             {determine RENDlib device ID}

  dev[dev_id].sizemove := true;        {indicate we are now within a SIZEMOVE}
  dev[dev_id].size_changed := false;   {init to user didn't actually change the size}
  end;
{
**********
*
*   EXITSIZEMOVE  -  A user operation to resize or move the window has just been
*     terminated.  We now generate an internal SIZE message if the window size
*     actually got changed.
}
winmsg_exitsizemove_k: begin
  set_dev;                             {determine RENDlib device ID}

  if                                   {put SIZE message into our internal queue ?}
      dev[dev_id].size_changed and     {size got changed ?}
      ((rend_evdev_resize_k in rend_device[dev_id].ev_req) or {app cares ?}
        (rend_evdev_wiped_resize_k in rend_device[dev_id].ev_req))
      then begin
    dev[dev_id].size_changed := false; {reset pending size changed flag}
    ev.dev := dev_id;                  {fill in event descriptor}
    ev.id := event_size_k;
    rend_win_event_put (ev);           {put the event in our queue}
    end;

  dev[dev_id].sizemove := false;       {no longer within SIZEMOVE operation}
  end;
{
**********
*
*   SIZE  -  Specifies new window size in pixels.
}
winmsg_size_k: begin
  set_dev;                             {determine RENDlib device ID}

  lparam_xy (lparam, x, y);            {get new window size}
  if rend_debug_level >= 10 then begin
    writeln ('  Size = ', x, ',', y);
    end;

  if                                   {size actually changed ?}
      (dev[dev_id].size_x <> x) or (dev[dev_id].size_y <> y)
      then begin

    EnterCriticalSection (crsect_dev); {this access to DEV must be atomic}
    dev[dev_id].size_x := x;           {save new window size in common block}
    dev[dev_id].size_y := y;
    LeaveCriticalSection (crsect_dev);

    if dev[dev_id].ready then begin    {resize not just part of window startup ?}
      if dev[dev_id].sizemove
        then begin                     {user is not yet done adjusting window size}
          dev[dev_id].size_changed := true; {just flag that size got changed}
          end
        else begin                     {user is not actively changing window size}
          if                           {app wants to hear about size changed ?}
              (rend_evdev_resize_k in rend_device[dev_id].ev_req) or
              (rend_evdev_wiped_resize_k in rend_device[dev_id].ev_req)
              then begin
            ev.dev := dev_id;          {fill in event descriptor}
            ev.id := event_size_k;
            rend_win_event_put (ev);   {put the event in our queue}
            end;
          end                          {end of user done changing size case}
        ;                              {end of user active resizing cases}
      end;                             {end of not still in window startup phase}
    end;                               {end of size actually changed}
  end;                                 {end of SIZE window message case}
{
**********
*
*   MOVE  -  Tells us new window position.
}
winmsg_move_k: begin
  set_dev;                             {determine RENDlib device ID}

  lparam_xy (lparam, x, y);            {get the new window position}
  if rend_debug_level >= 10 then begin
    writeln ('  Pos = ', x, ',', y);
    end;

  EnterCriticalSection (crsect_dev);   {this access to DEV must be atomic}
  dev[dev_id].pos_x := x;
  dev[dev_id].pos_y := y;
  LeaveCriticalSection (crsect_dev);
  end;
{
**********
*
*   GETMINMAXINFO  -  Allows us to adjust window min/max limits.
*
*   We make sure the maximum window size is a big enough so that we can make a
*   window with the client area being the whole screen.  That's how we implement
*   the SCREEN device in the REND_WIN driver.
}
winmsg_getminmaxinfo_k: begin
  minmax_p := univ_ptr(lparam);        {get pointer to window allowed limits info}

  x := GetSystemMetrics (metric_cxscreen_k); {get size of the full screen}
  y := GetSystemMetrics (metric_cyscreen_k);
  x := x + 100;                        {make max adjustable window size limit}
  y := y + 100;

  if                                   {we need to make some changes ?}
      (minmax_p^.size_track_max.x <> x) or
      (minmax_p^.size_track_max.y <> y)
      then begin
    if rend_debug_level >= 10 then begin
      writeln ('  Changing max tracking size from ', minmax_p^.size_track_max.x,
        ',', minmax_p^.size_track_max.y, ' to ', x, ',', y);
      end;
    minmax_p^.size_track_max.x := x;   {make the change}
    minmax_p^.size_track_max.y := y;
    end;
  end;
{
**********
*
*   QUERYNEWPALETTE  -  One of our windows is about to receive the focus, and
*     this is our chance to make sure the system palette is set to the colors we
*     expect.  We must return WIN_BOOL_TRUE_K if we end up changing the system
*     palette, otherwise we return WIN_BOOL_FALSE_k.
}
winmsg_querynewpalette_k: begin
  rend_win_windproc := ord(win_bool_false_k); {init to not changed system palette}
  result_set := true;                  {indicate we explicitly set function value}
  set_dev;                             {set DEV_ID to RENDlib device ID}
  if not dev[dev_id].palette_set then begin {palette not in DC yet ?}
    if rend_debug_level >= 5 then begin
      writeln ('  Custom palette not available yet or not used.');
      end;
    goto done_message;
    end;
  wdc := GetDC (win_h);                {get handle to device context for this window}
  if wdc = handle_none_k then begin
    if rend_debug_level >= 5 then begin
      writeln ('  Unable to get window device context handle.');
      end;
    goto done_message;
    end;
  ok := UnrealizeObject(palette_h);    {unmap our palette from system LUT}
  if ok = win_bool_false_k then begin
    sys_error_none (stat);
    stat.sys := GetLastError;
    writeln ('  Error on attempt to unrealize palette:');
    sys_error_print (stat, '', '', nil, 0);
    end;
  h := SelectPalette (wdc, palette_h, win_bool_false_k); {select our palette into DC}
  if h = handle_none_k then begin
    if rend_debug_level >= 10 then begin
      sys_error_none (stat);
      stat.sys := GetLastError;
      writeln ('  Error on attempt to select palette into window DC.');
      sys_error_print (stat, '', '', nil, 0);
      end;
    end;
  ui := RealizePalette (wdc);          {try to realize our palette}
  if ui = win_gdi_error_k
    then begin
      if rend_debug_level >= 1 then begin
        sys_error_none (stat);
        stat.sys := GetLastError;
        writeln ('  Error on attempt to realize palette:');
        sys_error_print (stat, '', '', nil, 0);
        end;
      goto done_message;
      end
    else begin
      if rend_debug_level >= 5 then begin
        writeln ('  ', ui, ' palette entries realized.');
        end;
      rend_win_windproc := ord(win_bool_true_k); {indicate we did realize a palette}
      end
    ;
  end;
{
**********
*
*   KEYDOWN
}
winmsg_keydown_k,
winmsg_syskeydown_k: begin
  set_dev;                             {determine RENDlib device ID}
{
*   Check for whether this keystroke is an implicit CLOSE_USER event.  This is
*   only done if CLOSE_USER events are enabled.  The following keystrokes are
*   implicit CLOSE_USER events:
*
*     ALT-F4  -  This is the standard Windows key for closing an application.
*
*     ENTER  -  We only do this if this key hasn't been requested by the app.
}
  if not (rend_evdev_close_k in rend_device[dev_id].ev_req) {CLOSE_USER disabled ?}
    then goto noclose;

  if                                   {standard Windows exit request key ?}
      (wparam = ord(winkey_f4_k)) and  {F4 key ?}
      (msgid = winmsg_syskeydown_k)    {ALT modifier is active ?}
      then begin
    goto default_action;               {let system handle in standard way}
    end;

  if                                   {ENTER key close window request ?}
      (wparam = ord(winkey_return_k)) and {ENTER key ?}
      (msgid = winmsg_keydown_k)       {ALT modifier not active ?}
      then begin
    if (rend_evdev_key_k in rend_device[dev_id].ev_req) then begin {kbd events on ?}
      key_p := dev[dev_id].keyp[wparam]; {get pointer to RENDlib key descriptor}
      if                               {this key enabled for events ?}
          (key_p <> nil) and then      {RENDlib key descriptor exists ?}
          (key_p^.id <> 0) and         {RENDlib key descriptor not empty ?}
          key_p^.req                   {events for this key are enabled ?}
        then goto noclose;
      end;
    goto close_user;                   {interpret this key as CLOSE_USER event}
    end;                               {done checking for ENTER key special case}

  goto noclose;                        {no special CLOSE_USER case found}

close_user:                            {jump here to generate CLOSE_USER event}
  ev.dev := dev_id;                    {fill in Win driver event descriptor}
  ev.id := event_close_user_k;
  rend_win_event_put (ev);             {put event into Win driver event queue}
  goto done_message;                   {done handling this incoming message}

noclose:                               {skip to here if not CLOSE_USER event}
{
*   Done checking for CLOSE_USER event.
}
  if not (rend_evdev_key_k in rend_device[dev_id].ev_req) {key events disabled ?}
    then goto default_action;

  key_p := dev[dev_id].keyp[wparam];   {get pointer to RENDlib key descriptor}
  if key_p = nil then goto default_action; {no associated RENDlib key ?}
  if key_p^.id = rend_key_none_k then goto default_action; {RENDlib key desc empty ?}
  if not key_p^.req then goto default_action; {events disabled for this key ?}

  ev.dev := dev_id;                    {fill in Win driver event descriptor}
  ev.id := event_keydown_k;            {set event ID}
  ev.keydown_p := key_p;               {pointer to RENDlib key descriptor}
  coor32 := GetMessagePos;             {get cursor position during keyboard event}
  ev.keydown_x := coor32.x - dev[dev_id].pos_x; {make cursor pos within window}
  ev.keydown_y := coor32.y - dev[dev_id].pos_y;
  ev.keydown_cnt := lparam & 16#FFFF;  {repeat count}
  send_pnt_move (ev.keydown_x, ev.keydown_y); {send PNT_MOVE event if appropriate}
{
*   Common code to set the KEYDOWN_FLAGS field in the KEYDOWN event.
}
key_flags_down:
  ev.keydown_flags := [];              {init flags to all off}
  if (GetKeyState(ord(winkey_shift_k)) & 16#8000) <> 0
    then ev.keydown_flags := ev.keydown_flags + [keydown_shift_k];
  if (GetKeyState(ord(winkey_capital_k)) & 1) <> 0
    then ev.keydown_flags := ev.keydown_flags + [keydown_capslock_k];
  if (GetKeyState(ord(winkey_control_k)) & 16#8000) <> 0
    then ev.keydown_flags := ev.keydown_flags + [keydown_ctrl_k];
  if msgid = winmsg_syskeydown_k
    then ev.keydown_flags := ev.keydown_flags + [keydown_alt_k];

  rend_win_event_put (ev);             {put the event in our queue}
  end;
{
**********
*
*   KEYUP
}
winmsg_keyup_k,
winmsg_syskeyup_k: begin
  set_dev;                             {determine RENDlib device ID}

  if not (rend_evdev_key_k in rend_device[dev_id].ev_req) {key messages disabled ?}
    then goto default_action;
  key_p := dev[dev_id].keyp[wparam];   {get pointer to RENDlib key descriptor}
  if key_p = nil then goto default_action; {no associated RENDlib key ?}
  if key_p^.id = rend_key_none_k then goto default_action; {RENDlib key desc empty ?}
  if not key_p^.req then goto default_action; {events disabled for this key ?}

  ev.dev := dev_id;                    {fill in Win driver event descriptor}
  ev.id := event_keyup_k;              {set event ID}
  ev.keyup_p := key_p;                 {pointer to RENDlib key descriptor}
  coor32 := GetMessagePos;             {get cursor position during keyboard event}
  ev.keyup_x := coor32.x - dev[dev_id].pos_x; {make cursor pos within window}
  ev.keyup_y := coor32.y - dev[dev_id].pos_y;
  send_pnt_move (ev.keyup_x, ev.keyup_y); {send PNT_MOVE event if appropriate}
{
*   Common code to set the KEYUP_FLAGS field in the KEYUP event.
}
key_flags_up:
  ev.keyup_flags := [];                {init flags to all off}
  if (GetKeyState(ord(winkey_shift_k)) & 16#8000) <> 0
    then ev.keyup_flags := ev.keyup_flags + [keydown_shift_k];
  if (GetKeyState(ord(winkey_capital_k)) & 1) <> 0
    then ev.keyup_flags := ev.keyup_flags + [keydown_capslock_k];
  if (GetKeyState(ord(winkey_control_k)) & 16#8000) <> 0
    then ev.keyup_flags := ev.keyup_flags + [keydown_ctrl_k];
  if msgid = winmsg_syskeyup_k
    then ev.keydown_flags := ev.keydown_flags + [keydown_alt_k];

  rend_win_event_put (ev);             {put the event in our queue}
  end;
{
**********
*
*   A mouse button has been pressed or released.  For all these messages, the X
*   coordinate is in the low 16 bits of LPARAM, while the Y coordinate is in the
*   next higher 16 bits.
*
*   We handle all these messages by identifying the mouse button in VK, and
*   whether it's an up or down in DOWN.  We then jump to the common code at
*   MOUSE_BUTTON.
}
winmsg_lbuttondown_k: begin
  down := true;
  vk := ord(winkey_lbutton_k);
  goto mouse_button;
  end;
winmsg_mbuttondown_k: begin
  down := true;
  vk := ord(winkey_mbutton_k);
  goto mouse_button;
  end;
winmsg_rbuttondown_k: begin
  down := true;
  vk := ord(winkey_rbutton_k);
  goto mouse_button;
  end;
winmsg_lbuttonup_k: begin
  down := false;
  vk := ord(winkey_lbutton_k);
  goto mouse_button;
  end;
winmsg_mbuttonup_k: begin
  down := false;
  vk := ord(winkey_mbutton_k);
  goto mouse_button;
  end;
winmsg_rbuttonup_k: begin
  down := false;
  vk := ord(winkey_rbutton_k);
{
*   Common code for handling a mouse button message.  VK is set to the Windows
*   virtual key code for the mouse button.  DOWN is TRUE if this is a button
*   press, FALSE for a release.
}
mouse_button:
  set_dev;                             {determine RENDlib device ID}

  if down
    then begin
      discard( SetCapture(win_h) );    {keep mouse while button is down}
      end
    else begin
      discard( ReleaseCapture );       {release mouse for possibly other windows}
      end
    ;

  lparam_xy (lparam, x, y);            {get coordinates of this event}
  send_pnt_move (x, y);                {send PNT_MOVE event if appropriate}

  if not (rend_evdev_key_k in rend_device[dev_id].ev_req) {key events disabled ?}
    then goto default_action;

  key_p := dev[dev_id].keyp[vk];       {get pointer to RENDlib key descriptor}
  if key_p = nil then goto default_action; {no associated RENDlib key ?}
  if key_p^.id = rend_key_none_k then goto default_action; {RENDlib key desc empty ?}
  if not key_p^.req then goto default_action; {events disabled for this key ?}

  ev.dev := dev_id;                    {fill in Win driver event descriptor}

  if down
    then begin                         {this event is for a key press}
      ev.id := event_keydown_k;        {set event ID}
      ev.keydown_p := key_p;           {pointer to RENDlib key descriptor}
      ev.keydown_x := x;
      ev.keydown_y := y;
      ev.keydown_cnt := 1;
      goto key_flags_down;             {set FLAGS and finish handling event}
      end
    else begin                         {this event if for a key release}
      ev.id := event_keyup_k;          {set event ID}
      ev.keyup_p := key_p;             {pointer to RENDlib key descriptor}
      ev.keyup_x := x;
      ev.keyup_y := y;
      goto key_flags_up;               {set FLAGS and finish handling event}
      end
    ;
  end;
{
**********
*
*   MOUSEMOVE - The cursor has been moved.
}
winmsg_mousemove_k: begin
  set_dev;                             {determine RENDlib device ID}

  lparam_xy (lparam, x, y);            {get the new cursor coordinate}
  if rend_debug_level >= 10 then begin
    writeln ('  ', x, ',', y);
    end;

  send_pnt_move (x, y);
  end;
{
**********
*
*   MOUSEWHEEL - The scroll wheel on the mouse was rotated.
}
winmsg_mousewheel_k: begin
  set_dev;                             {determine RENDlib device ID}

  y := high16s (wparam);               {get scroll increment}
  dev[dev_id].scrollv :=               {accumulate unsent scroll delta}
    dev[dev_id].scrollv + y;
  y :=                                 {make whole scroll increments}
    dev[dev_id].scrollv div win_mousewheel_inc_k;
  if y = 0 then goto done_message;     {no new scroll increment ?}
  {
  *   Y is the signed number of whole scroll increments, and is not 0.
  }
  dev[dev_id].scrollv :=               {remove scroll delta that will be reported}
    dev[dev_id].scrollv - (y * win_mousewheel_inc_k);

  ev.dev := dev_id;                    {fill in our event descriptor}
  ev.id := event_scrollv_k;
  ev.scrollv_nup := y;
  rend_win_event_put (ev);             {put the event in our queue}
  end;
{
**********
*
*   PAINT - Windows wants us to update a dirty region.
}
winmsg_paint_k: begin
  set_dev;                             {determine RENDlib device ID}

  discard( BeginPaint (                {get info about region, reset to not dirty}
    win_h,                             {handle to our window}
    paint) );                          {returned info about how to repaint}
  discard( EndPaint (win_h, paint) );  {tell windows we are done repainting}
{
*   If the repaint request is during a user window resizing operation, then
*   we ignore it if it would get caught as a RENDlib WIPED_RESIZE event later.
}
  if
      dev[dev_id].sizemove and         {within a user resizing operation ?}
      dev[dev_id].size_changed and     {window size already known to have changed ?}
      (rend_evdev_wiped_resize_k in rend_device[dev_id].ev_req) {repaint on resize ?}
      then begin
    goto done_message;                 {do nothing further with this message}
    end;

  if                                   {app cares about dirty regions ?}
      (rend_evdev_wiped_rect_k in rend_device[dev_id].ev_req) and
      dev[dev_id].ready
      then begin
    ev.dev := dev_id;                  {fill in event descriptor}
    ev.id := event_rect_k;
    ev.rect_x := paint.dirty.lft;
    ev.rect_y := paint.dirty.top;
    ev.rect_dx := paint.dirty.rit - paint.dirty.lft + 1;
    ev.rect_dy := paint.dirty.bot - paint.dirty.top + 1;
    rend_win_event_put (ev);           {put the event in our queue}
    end;

  dev[dev_id].ready := true;           {indicate window is now ready for drawing}
  end;
{
**********
*
*   CLOSE - The user has used a system window control feature (not the app's) to
*     request that the window be closed.  We intercept this if CLOSE_USER events
*     are enabled.  In that case, the app must deliberately close the window
*     when done.  This gives the app a chance to ask about open files, clean up,
*     or whatever.  When CLOSE_USER events are disabled, then this message is
*     passed to the system for the default action, which eventually causes the
*     window to be destroyed.
}
winmsg_close_k: begin
  set_dev;                             {determine RENDlib device ID}

  if                                   {CLOSE_USER events are enabled ?}
      (rend_evdev_close_k in rend_device[dev_id].ev_req)
      then begin
    ev.dev := dev_id;                  {fill in event descriptor}
    ev.id := event_close_user_k;       {WIN driver event ID}
    rend_win_event_put (ev);           {put the event in our queue}
    end;
  end;
{
**********
*
*   DESTROY - Window is being destroyed, child windows still exist.
}
winmsg_destroy_k: begin
  set_dev;                             {determine RENDlib device ID}

  if                                   {app wants to know when window goes away ?}
      (rend_evdev_close_k in rend_device[dev_id].ev_req)
      then begin
    ev.dev := dev_id;                  {fill in event descriptor}
    ev.id := event_closed_k;
    rend_win_event_put (ev);           {put the event in our queue}
    end;

  PostQuitMessage (0);                 {indicate to terminate window thread}
  end;
{
**********
*
*   All remaining messages that weren't explicitly trapped above.  These
*   messages are passed to the system for processing in the default way.
}
otherwise
    goto default_action;               {let the system take the default action}
    end;

done_message:                          {we are done handling this event}
  if not result_set then begin         {REND_WIN_WINDPROC function val not yet set ?}
    rend_win_windproc := 0;
    end;
  return;                              {we handled the message explicitly}

default_action:                        {jump here to handle message in default way}
  rend_win_windproc := DefWindowProcA ( {let system handle message in default way}
    win_h, msgid, wparam, lparam);     {pass our call arguments exactly}
  end;
