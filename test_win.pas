{   This is a template for programs to test Windows graphics.
}
program "gui" test_win;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'sys_sys2.ins.pas';
%include 'win.ins.pas';
%include 'win_keys.ins.pas';

const
  cmd_close_k = 0;                     {command ID to close window}

var
  window_class_name: string := 'TEST_WIN_CLASS'(0);
  wind_h: win_handle_t;                {handle to our drawing window}
  dc: win_handle_t;                    {handle to our drawing device context}
  dirty_x, dirty_y: sys_int_machine_t; {upper left corner of dirty rectangle}
  dirty_dx, dirty_dy: sys_int_machine_t; {size of dirty rectangle}
  wind_dx, wind_dy: sys_int_machine_t; {dimensions of drawing area in pixels}
  last_msg_time: sys_clock_t;          {time of last Windows message}
  dirty: boolean;                      {TRUE if a dirty region exists}
  ready: boolean;                      {TRUE after first PAINT message received}
{
********************************************************************************
*
*   Subroutine ERROR (MSG)
*
*   Write error message and abort program with error.  MSG will be printed to
*   its full length, or to the first NULL character, whichever occurs first.
}
procedure error (                      {write error message and bomb}
  in      msg: string);                {error message to write}
  options (val_param, internal, noreturn);

var
  s: string_var80_t;                   {scratch var string}

begin
  s.max := size_char(s.str);           {init local var string}

  string_vstring (s, msg, size_char(msg));
  string_write (s);
  sys_bomb;
  end;
{
********************************************************************************
*
*   Subroutine ERROR_SYS (MSG, ERR)
*
*   Like subroutine ERROR, except first shows the system error condition ERR.
}
procedure error_sys (                  {abort due to system error}
  in      msg: string;                 {error message to show after system err info}
  in      err: sys_sys_err_t);         {system error code}
  options (val_param, internal, noreturn);

var
  stat: sys_err_t;

begin
  sys_error_none (stat);               {init to no error}
  stat.err := false;                   {indicate system error}
  stat.sys := err;                     {the system error code}
  sys_error_print (stat, '', '', nil, 0);
  error (msg);
  end;
{
********************************************************************************
}
procedure error_abort (                {abort on error with messages}
  in      ok: win_bool_t;              {common Windows success/fail value}
  in      msg: string;                 {message to show after system err info}
  in      err: sys_sys_err_t);         {system error code}
  val_param; internal;

begin
  if ok = win_bool_false_k then begin  {error ?}
    error_sys (msg, err);
    end;
  end;
{
********************************************************************************
*
*   Subroutine SHOW_MESSAGE (MSG, WPARAM, LPARAM)
*
*   Write the message name and its parameters to standard output.
}
procedure show_message (               {show a message and parameters to STDOUT}
  in      msg: winmsg_k_t;             {message ID}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t);       {signed 32 bit integer message parameter}
  val_param; internal;

%include 'win_show_message.ins.pas';
  end;
{
********************************************************************************
*
*   Function WINDOW_PROC (WIN_H, MSG, WPARAM, LPARAM)
*
*   This is the window procedure for our window class.  It is called by the
*   system when messages are explicitly dispatched to our window, and when
*   certain asynchronous events happen.
}
function window_proc (                 {our official Win32 window procedure}
  in      win_h: win_handle_t;         {handle to window this message is for}
  in      msgid: winmsg_k_t;           {ID of this message}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_lresult_t;                      {unsigned 32 bit integer return value}
  val_param;

var
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on sys call success}
  paint: winpaint_t;                   {paint info from BeginPaint}
  x, y: sys_int_machine_t;             {scratch integer coordinates}
  id: sys_int_machine_t;               {scratch for command ID, etc}
  result_set: boolean;                 {TRUE if function result already set}

label
  default_action;

begin
  show_message (msgid, wparam, lparam); {write messages name and parms to STDOUT}

  result_set := false;                 {indicate WINDOW_PROC function value not set}
  case msgid of                        {which message is it ?}
{
**********
*
*   SIZE  -  Specifies new window size in pixels.
}
winmsg_size_k: begin
  x := lparam & 16#FFFF;               {extract new window width}
  y := rshft(lparam, 16) & 16#FFFF;    {extract new window height}
  if (x <> wind_dx) or (y <> wind_dy) then begin {window size actually changed ?}
    if ready then begin                {resized after initial paint request ?}
      dirty_x := 0;                    {flag whole window as dirty}
      dirty_y := 0;
      dirty_dx := x;
      dirty_dy := y;
      dirty := true;
      end;
    wind_dx := x;                      {update our saved window size values}
    wind_dy := y;
    writeln ('Window size changed to ', wind_dx, ' x ', wind_dy);
    end;
  end;
{
**********
*
*   KEYDOWN - A key was pressed without ALT being down.
}
winmsg_keydown_k: begin
  case wparam of                       {which virtual key is it ?}

ord(winkey_end_k): begin               {END key}
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;

otherwise                              {all the key codes we don't explicitly handle}
    goto default_action;               {handle message in the default way}
    end;                               {end of cases for specific key codes}
  end;
{
**********
*
*   COMMAND
}
winmsg_command_k: begin
  id := wparam & 16#FFFF;              {extract the command ID}
  case id of                           {which command is this ?}

cmd_close_k: begin                     {close the window}
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;

otherwise                              {all the key codes we don't explicitly handle}
    goto default_action;               {handle message in the default way}
    end;                               {end of cases for specific key codes}
  end;
{
**********
*
*   PAINT - Windows wants us to update a dirty region.
}
winmsg_paint_k: begin
  discard( BeginPaint (                {get info about region, reset to not dirty}
    wind_h,                            {handle to our window}
    paint) );                          {returned info about how to repaint}

  if dirty
    then begin                         {a previous dirty region exists}
      dirty_x := min(dirty_x, paint.dirty.lft);
      dirty_y := min(dirty_y, paint.dirty.rit);
      x := max(dirty_x + dirty_dx, paint.dirty.rit);
      y := max(dirty_y + dirty_dy, paint.dirty.bot);
      dirty_dx := x - dirty_x;
      dirty_dy := y - dirty_y;
      end
    else begin                         {no previous dirty region exists}
      dirty_x := paint.dirty.lft;
      dirty_y := paint.dirty.top;
      dirty_dx := paint.dirty.rit - dirty_x;
      dirty_dy := paint.dirty.bot - dirty_y;
      dirty := true;
      end
    ;

  discard( EndPaint (wind_h, paint) ); {tell windows we are done repainting}
  ready := true;                       {window is now ready for drawing}
  end;
{
**********
*
*   CLOSE - Someone wants us to close the window.
}
winmsg_close_k: begin
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;
{
**********
*
*   DESTROY - Window is being destroyed, child windows still exist.
}
winmsg_destroy_k: begin
  PostQuitMessage (0);                 {indicate we want to exit application}
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
  if not result_set then begin         {WINDOW_PROC function value not yet set ?}
    window_proc := 0;
    end;
  return;                              {message handled, WINDOW_PROC already set}

default_action:                        {jump here to handle message in default way}
  window_proc := DefWindowProcA (      {let system handle message in default way}
    win_h, msgid, wparam, lparam);     {pass our call arguments exactly}
  end;
{
********************************************************************************
*
*   Main routine.
}
const
  n_accel_k = 1;                       {number of accelerator keys defined}

var
  s: string_var80_t;                   {scratch string}
  tk: string_var80_t;                  {scratch token}
  i: sys_int_machine_t;                {scratch integer}
  byte_p: ^int8u_t;                    {pointer to arbitrary memory byte}
  wclass: window_class_t;              {descriptor for our window class}
  atom_class: win_atom_t;              {atom ID for our window class name}
  getflag: win_bool_t;                 {flag from GetMessage}
  accel: array[1..n_accel_k] of win_accel_t; {our table of shortcut keys}
  accel_h: win_handle_t;               {handle to our installed accelerator table}
  msg: win_msg_t;                      {message descriptor}

  verts: array[1..4] of win_point_t;   {array of vertices for polygon, etc}

label
  loop_msg, done_msg;

begin
  tk.max := size_char(tk.str);         {init local var strings}
  s.max := size_char(s.str);
{
*   Create a new window class for our window.
}
  byte_p := univ_ptr(addr(wclass));    {init class descriptor to all zeros}
  for i := 1 to size_min(wclass) do begin
    byte_p^ := 0;
    byte_p := succ(byte_p);
    end;

  wclass.size := size_min(wclass);     {indicate size of data structure}
  wclass.style := [                    {set window class style}
    clstyle_dblclks_k,                 {convert and send double click messages}
    clstyle_own_dc_k];                 {each window gets a private dc}
  wclass.msg_proc := addr(window_proc); {set pointer to window procedure}
  wclass.instance_h := instance_h;     {identify who we are}
  wclass.cursor_h := LoadCursorA (     {indicate which cursor to use}
    handle_none_k,                     {we will use one of the predifined cursors}
    cursor_arrow_k);                   {ID of predefined cursor}
  if wclass.cursor_h = handle_none_k then begin {error getting cursor handle ?}
    error_sys ('On get handle to predefined system cursor.', GetLastError);
    end;
  wclass.name_p := univ_ptr(addr(window_class_name));

  last_msg_time := sys_clock;          {init time of last Windows message}
  atom_class := RegisterClassExA (wclass); {try to create our new window class}
  if atom_class = 0 then begin         {failed to create new window class ?}
    error_sys ('On try to create new window class.', GetLastError);
    end;

  dirty := false;                      {init to no portion of window needs updating}
  ready := false;                      {init to window not ready for drawing}
  wind_dx := 0;                        {init draw area size to invalid}
  wind_dy := 0;
{
*   Create a window with our window class and display it.
}
  wind_h := CreateWindowExA (          {try to create our drawing window}
    [],                                {extended window style flags}
    univ_ptr(addr(window_class_name)), {pointer to window class name string}
    'TEST_WIN Private Window'(0),      {window name for title bar}
    [ wstyle_max_box_k,                {make maximize box on title bar}
      wstyle_min_box_k,                {make minimize box on title bar}
      wstyle_edge_size_k,              {make user sizing border}
      wstyle_sysmenu_k,                {put standard system menu on title bar}
      wstyle_edge_thin_k,              {thin edge, needed for title bar}
      wstyle_clip_child_k,             {our drawing will be clipped to child windows}
      wstyle_clip_sib_k,               {our drawing will be clipped to sib windows}
      wstyle_visible_k],               {make initially visible}
    win_default_coor_k, 0,             {use default placement}
    512, 410,                          {window size in pixels}
    handle_none_k,                     {no parent window specified}
    handle_none_k,                     {no application menu specified}
    instance_h,                        {handle to our invocation instance}
    16#123456789);                     {data passed to CREATE window message}
  if wind_h = handle_none_k then begin {window wasn't created ?}
    error_sys ('CreateWindowExA Failed.', GetLastError);
    end;
  writeln ('Window handle = ', wind_h);
{
*   Initialize state before entering message loop.
}
  dc := GetDC (wind_h);                {get handle to our drawing device context}
  if dc = handle_none_k then begin
    error ('Failed to get device context from GetDC.');
    end;

  accel[1].flags := [
    accelflag_virtkey_k,               {use virtual key codes, not char values}
    accelflag_control_k];              {control key must be down}
  accel[1].key := ord(winkey_return_k); {selected key}
  accel[1].cmd := cmd_close_k;         {command ID to close window}

  accel_h := CreateAcceleratorTableA ( {tell system about our accelerators}
    accel,                             {array of keyboard accelerator descriptors}
    n_accel_k);                        {number of entries in the list}
  if accel_h = handle_none_k then begin {failed to create internal accel table ?}
    error_sys ('Error on create internal keyboard accelerator table.',
      GetLastError);
    end;

  discard( ShowWindow (                {make our window visible}
    wind_h,                            {handle to our window}
    winshow_normal_k));                {new window show state}
{
*   Fetch messages and dispatch them to our window procedure.
}
loop_msg:                              {back here each new thread message}
  getflag := GetMessageA (             {get the next message from thread msg queue}
    msg,                               {returned message descriptor}
    handle_none_k,                     {get any message for this thread}
    firstof(winmsg_k_t), lastof(winmsg_k_t)); {message range we care about}
  if ord(getflag) < 0 then begin       {error getting message ?}
    error_sys ('On get next thread message.', GetLastError);
    end;
  if ord(getflag) = 0 then goto done_msg; {got the QUIT message ?}
  i := TranslateAcceleratorA (         {check for accelerator key stroke}
    wind_h,                            {handle to window to receive translated msg}
    accel_h,                           {handle to our accelerator table}
    msg);                              {message to try to translate}
  if i <> 0 then goto loop_msg;        {message was translated and dealt with ?}

(*
  writeln ('Calling DispatchMessageA');
  writeln ('  wind_h ', msg.wind_h);
  writeln ('  msg ', ord(msg.msg));
  writeln ('  wparam ', msg.wparam);
  writeln ('  lparam ', msg.lparam);
  writeln ('  time ', msg.time);
  writeln ('  coor.x ', msg.coor.x);
  writeln ('  coor.y ', msg.coor.y);
*)

  i := DispatchMessageA (msg);         {have our window procedure process the msg}
{
*   Draw our stuff if any region needs updating.
}
  if dirty then begin                  {some region of window needs updating ?}
    writeln ('Dirty rect at ', dirty_x, ',', dirty_y,
      ' size ', dirty_dx, ',', dirty_dy);
    dirty := false;                    {reset to no dirty region exists}

    verts[1].x := 0;         verts[1].y := 0;
    verts[2].x := 0;         verts[2].y := wind_dy-1;
    verts[3].x := wind_dx-1; verts[3].y := wind_dy-1;
    verts[4].x := wind_dx-1; verts[4].y := 0;
    discard( Polygon (                 {clear background}
      dc,                              {handle to our drawing device context}
      verts,                           {list of polygon vertices}
      4));                             {number of vertices in list}

    discard( MoveToEx (dc, wind_dx div 2, 0, nil) );
    discard( LineTo (dc, 0, wind_dy div 2) );
    discard( LineTo (dc, wind_dx div 2, wind_dy-1) );
    discard( LineTo (dc, wind_dx-1, wind_dy div 2) );
    discard( LineTo (dc, wind_dx div 2, 0) );
    end;
{
*   Done refreshing our picture.
}
  goto loop_msg;                       {back for next thread message}

done_msg:                              {all done handling thread messages}
  discard( DestroyAcceleratorTable(accel_h) ); {try to deallocate accel resources}
  end;
