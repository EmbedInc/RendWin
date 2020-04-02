{   Private include file for the RENDlib Windows GDI driver.
}
%include 'rend2.ins.pas';
%include 'sys_sys2.ins.pas';
%include 'win.ins.pas';

const
  eventq_size_k = 100;                 {total number of slots in event queue}
  eventq_last_k = eventq_size_k - 1;   {last valid EVENTQ entry}
  x_dith_k = 4;                        {horizontal size of dither pattern}
  y_dith_k = 4;                        {vertical size of dither pattern}
  frac_high_k = 1024;                  {FRAC value to indicate DITH_HIGH value}
  n_colors_max_k = 256;                {max pseudo colors we can support}

  x_dith_max_k = x_dith_k - 1;         {max X dither table index}
  y_dith_max_k = y_dith_k - 1;         {max Y dither table index}
  dith_vals_k = x_dith_k * y_dith_k;   {number of dither table entries}
  pcolor_max_k = n_colors_max_k - 1;   {index of last pcolor we can support}

type
  sys_window_p_t = ^sys_window_t;      {pointer to Cognivision window descriptor}
{
*   The color index table, CINDEX, is used to translate from a 24 bit true
*   color to the appropriate psuedo-color index value (0-PCOLOR_MAX).  It
*   contains an entry for each possible value (0-255) for each primary color.
*   The appropriate values from each of the red, green and blue entries
*   are added together to obtain the final pseudo color ID.
*
*   Each CINDEX entry is actually 4 numbers.  The field called CLOSE is
*   the closest possible approximation to the original color.  The fields
*   DITH_HIGH and DITH_LOW are used when dithering is enabled.  The result
*   of the dither test selects whether the DITH_HIGH or DITH_LOW value is
*   used.  FRAC is a value from 0 to FRAC_HIGH_K indicating the fraction
*   this color is within the range between the DITH_LOW and DITH_HIGH
*   values.  A value of 0 indicates that the requested color value is
*   identical to the DITH_LOW value.  A value of FRAC_HIGH_K indicates
*   it is identical to the DITH_HIGH value.
}
  cindex_entry_t = record              {one color index table entry template}
    frac: 0..frac_high_k;              {fraction into range between high/low values}
    close: sys_int_conv32_t;           {used for closest single approximation}
    dith_high: sys_int_conv32_t;       {higher of two values dithering between}
    dith_low: sys_int_conv32_t;        {lower of two values dithering between}
    end;

  cindex_t = record                    {24 bit color to color index translate table}
    red: array[0..255] of cindex_entry_t;
    grn: array[0..255] of cindex_entry_t;
    blu: array[0..255] of cindex_entry_t;
    end;

  thinfo_t = record                    {info passed to window thread routine}
    winfo_p: sys_window_p_t;           {pointer to descriptor for desired window}
    done: win_handle_t;                {handle to system event for synchronization}
    stat_p: sys_err_p_t;               {pointer to where to return abnormal err}
    end;

  dvinfo_t = record                    {per-device state that is not swapped out}
    wind_h: win_handle_t;              {handle to window for this device}
    size_x, size_y: sys_int_machine_t; {current window size in pixels}
    pos_x, pos_y: sys_int_machine_t;   {top left window position within parent}
    pntx, pnty: sys_int_machine_t;     {last pointer coordinate passed to RENDlib}
    sig_nfull: win_handle_t;           {signalled when queue becomes not full}
    ready: boolean;                    {TRUE if window is ready for drawing}
    shut: boolean;                     {device being shut down}
    sizemove: boolean;                 {user is currently moving or resizing window}
    size_changed: boolean;             {TRUE on user changed size during SIZEMOVE}
    palette_set: boolean;              {TRUE if our palette set in window DC}
    keyp:                              {pnts to RENDlib key descriptors each key}
      array[0..255]                    {one entry for each Windows virtual key code}
      of rend_key_p_t;                 {may be NIL if no such key}
    scrollv: sys_int_machine_t;        {accumulated but unsent vertical scroll increment}
    end;

  event_k_t = (                        {list of our internal event IDs}
    event_none_k,                      {used to indicate no event present}
    event_close_user_k,                {user has requested the window be closed}
    event_closed_k,                    {the window has been closed}
    event_keydown_k,                   {a key was pressed}
    event_keyup_k,                     {a key was released}
    event_size_k,                      {window size changed}
    event_rect_k,                      {a rectangle needs repainting}
    event_penter_k,                    {pointer entered window}
    event_pexit_k,                     {pointer left window}
    event_pmove_k,                     {pointer location changed}
    event_scrollv_k);                  {vertical scroll}

  keydown_k_t = (                      {additional flags for KEY_DOWN event}
    keydown_shift_k,                   {SHIFT was down}
    keydown_capslock_k,                {CAPS LOCK was active}
    keydown_ctrl_k,                    {control key was also pressed}
    keydown_alt_k);                    {ALT key was also pressed}
  keydown_t = set of keydown_k_t;

  event_t = record                     {info about each possible event}
    dev: rend_dev_id_t;                {ID of device that received the event}
    id: event_k_t;                     {ID of this event}
    case event_k_t of                  {additional event-specific information}
event_none_k: (                        {used to indicate no event present}
      );
event_close_user_k: (                  {the user wants the window closed}
      );
event_closed_k: (                      {then window has been closed}
      );
event_keydown_k: (                     {a key was pressed}
      keydown_p: rend_key_p_t;         {pointer to RENDlib key descriptor}
      keydown_x, keydown_y: sys_int_machine_t; {pointer coordinates during event}
      keydown_cnt: 0..65535;           {total key presses due to auto repeat}
      keydown_flags: keydown_t;        {additional modifier flags}
      );
event_keyup_k: (                       {a key was released}
      keyup_p: rend_key_p_t;           {pointer to RENDlib key descriptor}
      keyup_x, keyup_y: sys_int_machine_t; {pointer coordinates during event}
      keyup_flags: keydown_t;          {additional modifier flags}
      );
event_size_k: (                        {window size changed}
      );
event_rect_k: (                        {a rectangle needs repainting}
      rect_x, rect_y: sys_int_machine_t; {top left pixel inside effected rectangle}
      rect_dx, rect_dy: sys_int_machine_t; {size of rectangle}
      );
event_penter_k: (                      {pointer entered window}
      penter_x, penter_y: sys_int_machine_t; {pointer coordinate}
      );
event_pexit_k: (                       {pointer left window}
      pexit_x, pexit_y: sys_int_machine_t; {pointer coordinate}
      );
event_pmove_k: (                       {pointer location changed}
      pmove_x, pmove_y: sys_int_machine_t; {pointer coordinate}
      );
event_scrollv_k: (                     {vertical scroll}
      scrollv_nup: sys_int_machine_t;  {number of increments up}
      );
    end;

  pixform_k_t = (                      {our ID for the Windows pixel format type}
    pixform_pc1_k,                     {1 bit pseudo color}
    pixform_pc1dith_k,                 {1 bit pseudo color, dithered}
    pixform_pc4_k,                     {4 bit pseudo color}
    pixform_pc4dith_k,                 {4 bit pseudo color, dithered}
    pixform_pc8_k,                     {8 bit pseudo color}
    pixform_pc8dith_k,                 {8 bit pseudo color, dithered}
    pixform_tc16_k,                    {16 bit true color, xRGB 1,5,5,5}
    pixform_tc16dith_k,                {16 bit true color, xRGB 1,5,5,5, dithered}
    pixform_tc24_k,                    {24 bit true color, B, R, G byte order}
    pixform_tc24dith_k,                {24 bit true color, dithered}
    pixform_tc32_k,                    {32 bit true color, xRGB, 8,8,8,8}
    pixform_tc32dith_k);               {32 bit true color, xRGB, 8,8,8,8, dithered}

  setup_k_t = (                        {all the different driver setup modes}
    setup_none_k,                      {GDI is not set up for any of our drawing}
    setup_pix_k,                       {direct pixel writes thru DIBitsToDevice}
    setup_line_k,                      {2D fixed color line drawing}
    setup_fill_k);                     {2D fixed color area filling}

  pc_win_t =                           {xlate our pcolors to Windows pcolors}
    array[0..pcolor_max_k]             {our pcolor from CINDEX result}
    of -1 .. pcolor_max_k;             {Windows pcolor number, -1 = invalid entry}
  pc_win_p_t = ^pc_win_t;

var (rend_win)
{
******************
*
*   State that is common to all Windows devices.  These variables are not
*   saved/restored on a RENDlib context swap.
}
  wclass: window_class_t;              {descriptor for our window class}
  atom_class: win_atom_t;              {atom ID for our window class name}
  n_windows: sys_int_machine_t;        {number of WIN devices currently open}
  n_red, n_grn, n_blu: sys_int_machine_t; {num primary color levels in pcolor mode}
  n_colors: sys_int_machine_t;         {total number of colors in pcolor mode}
  bits_vis_ndith: real;                {color resolution in bits when not dithering}
  bits_vis_dith: real;                 {color resolution in bits when dithering}
  bits_per_pixel: sys_int_machine_t;   {Windows bits per pixel value}
  true_color: boolean;                 {TRUE for true color, FALSE for pcolor}
  may_dith: boolean;                   {TRUE if may dither this pixel format}
  palette: boolean;                    {TRUE when using a Windows pallette}
  pcolor_max: sys_int_machine_t;       {largest pseudo color value we use}
  palette_h: win_handle_t;             {handle to palette when using pseudo color}
  crsect_dev: sys_sys_threadlock_t;    {thread interlock for accessing DEV}
  lut:                                 {saved copy of LUT if using pseudo colors}
    array[0..pcolor_max_k] of win_colorref_t;
  dev:                                 {special per-device info that is not swapped}
    array[1..rend_max_devices] of dvinfo_t;
  cindex: cindex_t;                    {true color to pseudo color translate table}
  dith:                                {thresholds for dithering decision}
    array[0..y_dith_max_k, 0..x_dith_max_k] of 0..frac_high_k;
  pc_win: pc_win_t;                    {CINDEX result to Win pcolor values table}
{
*   End of state that is common to all Windows devices.
*
******************
*
*   The following state is part of the saved/restored context for Windows
*   devices, and is therefore private to each device.
}
  rend_win_com_start: sys_int_machine_t; {marks start of saved/restored region}

  thread_h: win_handle_t;              {handle to thread for this window}
  wind_h: win_handle_t;                {handle to our drawing window}
  dc: win_handle_t;                    {handle to our drawing device context}
  dib_info_p: win_bitmapinfo_p_t;      {pointer to config info for our DIB}
  dib_h: win_handle_t;                 {handle to in-memory bitmap}
  dib_x, dib_y: sys_int_machine_t;     {dimensions of DIB currently allocated}
  pixadr: sys_int_adr_t;               {first memory address of DIB pixels}
  pixform: pixform_k_t;                {our ID for the Windows pixel format}
  setup: setup_k_t;                    {indicates how we currently have GDI set up}
  brush_h: win_handle_t;               {handle to current brush in DC}
  pen_h: win_handle_t;                 {handle to current pen in DC}
  last_msg_time: sys_clock_t;          {time last Windows message received}
  made_brush: boolean;                 {TRUE if we created brush in DC}
  made_pen: boolean;                   {TRUE if we created pen in DC}
  whole_screen: boolean;               {TRUE if SCREEN instead of WINDOW device}

  rend_win_com_end: sys_int_machine_t; {marks the end of the saved common block}
{
******************
*
*   General driver routines that are not installed in one of the various
*   RENDlib call tables.
}
procedure rend_win_event (             {process a Windows event}
  in      wev: event_t);               {new Windows event}
  val_param; extern;

procedure rend_win_init (              {device is a window in Microsoft Windows}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_win_keys_init;          {init events key state for this device}
  extern;

procedure rend_win_nodevs;             {clean up after closing last Windows device}
  extern;

procedure rend_win_setup (             {set up GDI for a particular kind of drawing}
  in      newset: setup_k_t);          {ID of new GDI setup configuration}
  val_param; extern;

procedure rend_win_show_message (      {show a message and its parameters to STDOUT}
  in      msg: winmsg_k_t;             {message ID}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t);       {signed 32 bit integer message parameter}
  val_param; extern;

function rend_win_thread (             {main routine for each window thread}
  in      thinfo: thinfo_t)            {special info for window thread}
  :sys_int_adr_t;                      {thread completion value, unused}
  extern;

procedure rend_win_thread_stop;        {try to tell window thread to terminate}
  extern;

function rend_win_windproc (           {our official Windows window procedure}
  in      win_h: win_handle_t;         {handle to window this message is for}
  in      msgid: winmsg_k_t;           {ID of this message}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_lresult_t;                      {unsigned 32 bit integer return value}
  val_param; extern;
{
******************
*
*   Call table routines that are not primitives.
}
procedure rend_win_check_modes;        {check state and install appropriate routines}
  extern;

procedure rend_win_close;              {close device and release resources}
  extern;

procedure rend_win_cpnt_2dimi (        {set current point with absolute coordinates}
  in      x, y: sys_int_machine_t);    {new integer pixel coor of current point}
  val_param; extern;

procedure rend_win_dev_reconfig;       {look at device parameters and reconfigure}
  extern;

procedure rend_win_dith_on (           {turn dithering on/off}
  in      on: boolean);                {TRUE for dithering on}
  val_param; extern;

function rend_win_get_ev_possible (    {find whether event might ever occurr}
  event_id: rend_evdev_k_t)            {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param; extern;

procedure rend_win_iterp_flat (        {set interpolation to flat and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: real);                  {0.0 to 1.0 interpolant value}
  val_param; extern;

procedure rend_win_min_bits_vis (      {set minimum required effective bits per pixel}
  in      n: real);                    {Log2 of total effective number of colors}
  val_param; extern;
{
******************
*
*   Primitives.
}
procedure rend_win_flush_all;          {flush all data, insure image is up to date}
  extern;

procedure rend_win_poly_2dim (         {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_win_rect_2dimi (        {integer image space axis aligned rectangle}
  in      idx, idy: sys_int_machine_t); {pixel displacement to opposite corner}
  val_param; extern;

procedure rend_win_update_span (       {update device span from SW bitmap}
  in      x: sys_int_machine_t;        {starting X pixel address of span}
  in      y: sys_int_machine_t;        {scan line coordinate span is on}
  in      len: sys_int_machine_t);     {number of pixels in span}
  val_param; extern;

procedure rend_win_vect_2dimi (        {integer 2D image space vector}
  in      ix, iy: sys_int_machine_t);  {pixel coordinate end point}
  val_param; extern;

var
  rend_win_flush_all_d: extern rend_prim_data_t;
  rend_win_poly_2dim_d: extern rend_prim_data_t;
  rend_win_rect_2dimi_d: extern rend_prim_data_t;
  rend_win_update_span_d: extern rend_prim_data_t;
  rend_win_vect_2dimi_d: extern rend_prim_data_t;
