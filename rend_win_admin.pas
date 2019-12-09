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
define rend_win_event_get;
define rend_win_event_put;
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

  discard( CloseHandle(sig_nempty) );  {deallocate event queue not empty signal}

  DeleteCriticalSection (crsect_dev);  {delete thread interlocks}
  DeleteCriticalSection (crsect_events);
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_CLOSE
*
*   Close this window and release associated resources.
}
procedure rend_win_close;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}
  e: sys_int_machine_t;                {event queue index}

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
*   Delete all events in our private queue that originated from this window.
*   Events from dead devices get ignored, but the RENDlib device ID might get
*   re-used before all the events from this device are removed from the queue.
}
  EnterCriticalSection (crsect_events); {lock event queue for our exclusive use}
  e := evi_read;                       {make index of first event queue entry}
  for i := 1 to n_events do begin      {once for each event in the queue}
    if eventq[e].dev = rend_dev_id then begin {this event is from our device ?}
      eventq[e].id := event_none_k;    {make it a non-event}
      end;
    e := e + 1;                        {advance to next event queue entry}
    if e > eventq_last_k then e := 0;  {wrap back to start of queue array ?}
    end;                               {back to process next event queue entry}
  LeaveCriticalSection (crsect_events); {release our lock on the event queue}
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
*   Subroutine REND_WIN_EVENT_PUT (EVENT)
*
*   This routine is called by a window thread to add an event to the end
*   of our Win devices private event queue.  This routine will wait
*   indefinately for a queue slot to become available, except that it
*   will return immediately if the window thread is supposed to be
*   shutting down.
}
procedure rend_win_event_put (         {put event at end of queue, wait as needed}
  in      event: event_t);             {event to place at end of queue}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  donewait: donewait_k_t;              {reason WaitFor... returned}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

label
  retry;

begin
retry:                                 {try again after event removed from queue}
  EnterCriticalSection (crsect_events); {acquire exclusive queue ownership}
{
*   Wait for some other thread to read an entry from the queue if it is
*   already filled.
}
  if n_events >= eventq_size_k then begin {queue is already full ?}
    ok := ResetEvent (                 {reset to queue not become unfull yet}
      dev[event.dev].sig_nfull);
    LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
    if ok = win_bool_false_k then begin
      sys_error_none (stat);
      stat.sys := GetLastError;
      sys_error_abort (stat, 'rend_win', 'queue_signal_reset_put', nil, 0);
      end;
    if dev[event.dev].shut then return; {don't hang here if closing window thread}
    if rend_debug_level >= 10 then begin
      write ('Waiting for room in WIN event queue ... ');
      end;
    donewait := WaitForSingleObject (  {wait until someone reads a queue entry}
      dev[event.dev].sig_nfull,        {handle to signal to wait on}
      timeout_infinite_k);             {wait as long as it takes}
    if ord(donewait) <> 0 then begin   {unexpected reason wait ended ?}
      sys_error_none (stat);
      stat.sys := GetLastError;
      sys_msg_parm_int (msg_parm[1], ord(donewait));
      sys_error_abort (stat, 'rend_win', 'queue_wait_put', msg_parm, 1);
      end;
    if rend_debug_level >= 10 then begin
      writeln ('Done');
      end;
    goto retry;                        {back and check for room in queue again}
    end;
{
*   There is room for at least one more queue entry.  We have queue ownership.
}
  eventq[evi_write] := event;          {copy caller's event into the queue entry}
  evi_write := evi_write + 1;          {update where to put next event into queue}
  if evi_write > eventq_last_k then begin {wrap back to first queue entry ?}
    evi_write := 0;
    end;
  n_events := n_events + 1;            {log one more event in the queue}
  if rend_debug_level >= 10 then begin
    writeln ('  ', n_events, ' events in Win queue');
    end;

  if n_events = 1
    then begin                         {queue just went from empty to not empty}
      ok := SetEvent (sig_nempty);     {signal queue is no longer empty}
      LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
      if ok = win_bool_false_k then begin
        sys_error_none (stat);
        stat.sys := GetLastError;
        sys_error_abort (stat, 'rend_win', 'queue_signal_set_put', nil, 0);
        end;
      end
    else begin                         {nothing special happened}
      LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
      end
    ;
  end;
{
*****************************************************************************
*
*   Subroutine REND_WIN_EVENT_GET (WAIT, EVENT)
*
*   Get the next event from our private device event queue.  When WAIT is
*   TRUE, this routine does not return until an event becomes available.
*   When WAIT is FALSE, this routine will return the NONE event if no
*   real event is immediately available.
}
procedure rend_win_event_get (         {get next event from driver event queue}
  in      wait: boolean;               {wait for next event evailable on TRUE}
  out     event: event_t);             {may be event NONE when WAIT if FALSE}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  donewait: donewait_k_t;              {reason WaitFor... returned}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

label
  retry;

begin
retry:                                 {try again after queue may not be empty}
  EnterCriticalSection (crsect_events); {acquire exclusive queue ownership}
  if n_events <= 0 then begin          {the queue is empty ?}
    if not wait then begin             {return immediately indicating no event ?}
      LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
      event.dev := 0;                  {event doesn't belong to any device}
      event.id := event_none_k;        {indicate no event is being returned}
      return;
      end;
    ok := ResetEvent (sig_nempty);     {init to queue is still empty}
    LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
    if ok = win_bool_false_k then begin
      sys_error_none (stat);
      stat.sys := GetLastError;
      sys_error_abort (stat, 'rend_win', 'queue_signal_reset_get', nil, 0);
      end;
    if rend_debug_level >= 10 then begin
      write ('Waiting for event to be put into WIN event queue ... ');
      end;
    donewait := WaitForSingleObject (  {wait until someone writes a queue entry}
      sig_nempty,                      {handle to signal to wait on}
      timeout_infinite_k);             {wait as long as it takes}
    if ord(donewait) <> 0 then begin   {unexpected reason wait ended ?}
      sys_error_none (stat);
      stat.sys := GetLastError;
      sys_msg_parm_int (msg_parm[1], ord(donewait));
      sys_error_abort (stat, 'rend_win', 'queue_wait_get', msg_parm, 1);
      end;
    if rend_debug_level >= 10 then begin
      writeln ('Done');
      end;
    goto retry;                        {back and check for something in the queue}
    end;
{
*   There is definately at least one event in the queue, and we have ownership
*   of the queue.
}
  event := eventq[evi_read];           {copy the event from the queue entry}
  evi_read := evi_read + 1;            {advance queue read entry index}
  if evi_read > eventq_last_k then begin {wrap back to first queue entry ?}
    evi_read := 0;
    end;
  n_events := n_events - 1;            {log one less event in the queue}
  if rend_debug_level >= 10 then begin
    write ('  ', n_events, ' events in Win queue after dev ',
      event.dev, ' ID ', ord(event.id));
    case event.id of
event_pmove_k: writeln (', ', event.pmove_x, ',', event.pmove_y);
otherwise
      writeln;
      end;
    end;

  if n_events = (eventq_size_k - 1)
    then begin                         {we just made the queue become not full}
      for i := 1 to rend_max_devices do begin {loop thru all the RENDlib devices}
        if not rend_device[i].open then next; {this device doesn't exist ?}
        if dev[i].wind_h = handle_none_k then next; {not a WIN driver device ?}
        ok := SetEvent (dev[i].sig_nfull); {signal queue is no longer full}
        if ok = win_bool_false_k then begin
          LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
          sys_error_none (stat);
          stat.sys := GetLastError;
          sys_error_abort (stat, 'rend_win', 'queue_signal_set_get', nil, 0);
          end;
        end;                           {back to check next RENDlib device}
      LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
      end
    else begin                         {nothing special happened}
      LeaveCriticalSection (crsect_events); {release our exclusive lock on the queue}
      end
    ;

  if event.id = event_none_k then begin {we just got a dummy queue entry ?}
    goto retry;                        {ignore this entry, go for next}
    end;
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
