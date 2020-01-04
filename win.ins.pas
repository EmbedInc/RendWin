{   This include file defines the application interface to the graphics
*   portion of the Microsoft Win32 API.  The non-graphics portion of the
*   Win32 API is declared in SYS_SYS.INS.PAS and SYS_SYS2.INS.PAS.
}
%include 'win_sys.ins.pas';
%include 'win_msg.ins.pas';

const
  win_default_coor_k = 16#80000000;    {indicate to use default window coordinates}
  win_gdi_error_k = 16#FFFFFFFF;       {used to indicate error in some cases}
  win_color_invalid_k = 16#FFFFFFFF;   {used to indicate invalid COLORREF value}
  win_mousewheel_inc_k = 120;          {mouse wheel delta for one scroll increment}

type
  win_lresult_t = win_dword_t;         {Windows LRESULT data type}
  win_lparam_t = win_long_t;           {Windows LPARAM data type for message value}
  win_wparam_t = win_uint_t;           {Windows WPARAM data type for message value}

  wstyle_k_t = sys_int_machine_t (     {separate window style flags}
    wstyle_tabstop_k = 16,             {user can select window with TAB key}
    wstyle_max_box_k = 16,             {make maximize button, no help ? button}
    wstyle_group_k = 17,               {this window starts new group}
    wstyle_min_box_k = 17,             {make minimize button, no help ? button}
    wstyle_edge_size_k = 18,           {make user sizing border}
    wstyle_sysmenu_k = 19,             {titlebar sys menu, needs EDGE_THIN, DLGFRAME}
    wstyle_hscroll_k = 20,             {horizontal scroll bar}
    wstyle_vscroll_k = 21,             {vertical scroll bar}
    wstyle_dlgframe_k = 22,            {dialog box border, can't have title bar}
    wstyle_edge_thin_k = 23,           {thin-line border}
    wstyle_maximize_k = 24,            {initially maximized}
    wstyle_clip_child_k = 25,          {child windows will clip drawing in this wind}
    wstyle_clip_sib_k = 26,            {sib windows will clip drawing in this wind}
    wstyle_disable_k = 27,             {initially disabled, can't receive user input}
    wstyle_visible_k = 28,             {initially visible}
    wstyle_minimize_k = 29,            {initially minimized}
    wstyle_child_k = 30,               {child window, exclusive with POPUP style}
    wstyle_popup_k = 31);              {popup window, exclusive with CHILD style}
  wstyle_t =                           {all window style flags in one word}
    set of bitsize bits_win_dword_k eletype wstyle_k_t;

  ewstyle_k_t = sys_int_machine_t (    {separate extended window style flags}
    ewstyle_border_dbl_k = 0,          {double border, allows title bar}
    ewstyle_nparnotify_k = 2,          {child not send parent msg on create/destroy}
    ewstyle_top_k = 3,                 {always stay above all non-top windows}
    ewstyle_drag_drop_k = 4,           {accept drag and drop files}
    ewstyle_transparent_k = 5,         {don't obscure other windows beneath}
    {
    *   Only available in Windows versions 4 and later.
    }
    ewstyle_mdi_child_k = 6,           {multiple document interface child window}
    ewstyle_tool_k = 7,                {floating toolbar window, short title, etc}
    ewstyle_edge_raised_k = 8,         {border will have raised edge}
    ewstyle_edge_sunk_k = 9,           {window has border with sunken edge}
    ewstyle_help_ques_k = 10,          {display help ? button in title bar}
    ewstyle_right_k = 12,              {right align for right-to-left languages}
    ewstyle_rtl_read_k = 13,           {right-to-left ext for right->left languages}
    ewstyle_left_scroll_k = 14,        {left scroll bar for right-to-left languages}
    ewstyle_tab_children_k = 16,       {tab key allows navigating among child winds}
    ewstyle_edge_3d_k = 17,            {3D border, for non-user input windows}
    ewstyle_taskbar_k = 18);           {onto application taskbar when minimized}
  ewstyle_t =                          {all extended window style flags in one word}
    set of bitsize bits_win_dword_k eletype ewstyle_k_t;

  clstyle_k_t = sys_int_machine_t (    {individual window class style flags}
    clstyle_redraw_height_k = 0,       {send REDRAW message on height change}
    clstyle_redraw_width_k = 1,        {send REDRAW message on width change}
    clstyle_keycvtwindow_k = 2,
    clstyle_dblclks_k = 3,             {interpret and send double-click messages}
    clstyle_own_dc_k = 5,              {each window gets a private DC}
    clstyle_class_dc_k = 6,            {all windows of this class share one DC}
    clstyle_parent_dc_k = 7,           {inherit parent's DC}
    clstyle_nokeycvt_k = 8,
    clstyle_noclose_k = 9,             {no close command on system menu}
    clstyle_savepix_k = 11,            {save pixels in backing store, slows drawing}
    clstyle_align_client_k = 12,       {align window client area in X for speed}
    clstyle_align_window_k = 13,       {align whole window in X for speed}
    clstyle_global_k = 14,             {class may be used outside this prog instance}
    {
    *   Only available in Windows versions 4 and later.
    }
    clstyle_ime_k = 16);
  clstyle_t =                          {all the window class style flags in one word}
    set of bitsize bits_win_uint_k eletype clstyle_k_t;

  windproc_p_t = ^function (           {pnt to func that receives window messages}
    in      win_h: win_handle_t;       {handle to window this message is for}
    in      msgid: winmsg_k_t;         {ID of this message}
    in      wparam: win_wparam_t;      {unsigned 32 bit integer message parameter}
    in      lparam: win_lparam_t)      {signed 32 bit integer message parameter}
    :win_lresult_t;                    {unsigned 32 bit integer return value}
    val_param;

  window_class_t = record              {window class info, unused fields must = 0}
    size: win_uint_t;                  {memory size of this structure}
    style: clstyle_t;                  {set of window class style flags}
    msg_proc: windproc_p_t;            {pnt to routine to receive window messages}
    extra_class: sys_int_machine_t;    {extra bytes to add after window class block}
    extra_wind: sys_int_machine_t;     {extra bytes to add to window instance}
    instance_h: win_handle_t;          {instance for scope of window class}
    icon_h: win_handle_t;              {handle to icon resource}
    cursor_h: win_handle_t;            {handle to cursor resource}
    backg_h: win_handle_t;             {handle to background brush}
    menu_name_p: win_string_p_t;       {pointer to name of default menu}
    name_p: win_string_p_t;            {pnt to class name, or atom ID in low 16 bits}
    small_icon_h: win_handle_t;        {handle to small icon, 0 for Win ver <= 3}
    end;

  win_point_t = record                 {Windows POINT data type}
    x, y: win_long_t;                  {X,Y integer coordinate}
    end;
  win_point_p_t = ^win_point_t;
  win_point_ar_t = array[1..1] of win_point_t;

  win_msg_t = record                   {descriptor for a Windows message}
    wind_h: win_handle_t;              {handle to window message is for}
    msg: winmsg_k_t;                   {message ID}
    wparam: win_wparam_t;              {unsigned 32 bit integer message parameter}
    lparam: win_lparam_t;              {signed 32 bit integer message parameter}
    time: win_dword_t;                 {time at which message was originally posted}
    coor: win_point_t;                 {cursor screen coordinate when msg posted}
    private: win_dword_t;              {private field, not for app use}
    end;

  win_rect_t = record                  {Windows RECT data type}
    lft, top: win_long_t;              {top left corner inside rectangle}
    rit, bot: win_long_t;              {bottom right coordinate just outside rect}
    end;

  win_coor32_t = record                {XY coordinate packed in one 32 bit word}
    x: win_word_t;                     {unsigned X in low 16 bits}
    y: win_word_t;                     {unsigned Y in high 16 bits}
    end;

  win_coor32s_t = record               {signed XY coordinate in one 32 bit word}
    x: integer16;
    y: integer16;
    end;

  cursor_k_t = sys_int_adr_t (         {IDs of the pre-defined system cursors}
    cursor_arrow_k = 32512,            {standard arrow}
    cursor_ibeam_k = 32513,            {text I-beam}
    cursor_wait_k = 32514,             {hourglass}
    cursor_cross_k = 32515,            {crosshair}
    cursor_uparrow_k = 32516,          {vertical arrow pointing up}
    cursor_sizenwse_k = 32642,         {double arrow, upper left / lower right}
    cursor_sizenesw_k = 32643,         {double arrow, upper right / lower left}
    cursor_sizewe_k = 32644,           {double arrow, left / right}
    cursor_sizens_k = 32645,           {double arrow, up / down}
    cursor_sizeall_k = 32646,          {four-pointed arrow, left / right / up / down}
    cursor_no_k = 32648,               {slashed circle, not in version 3.1}
    cursor_appstarting_k = 32650);     {standard arrow with hourglass, not ver 3.1}

  accelflag_k_t = sys_int_machine_t (  {individual keyboard accelerator flags}
    accelflag_virtkey_k = 0,           {uses virtual key IDs instead of char codes}
    accelflag_noinvert_k = 1,          {don't highlight any top level menu item}
    accelflag_shift_k = 2,             {SHIFT key must be down while key pressed}
    accelflag_control_k = 3,           {CONTROL key must be down while key pressed}
    accelflag_alt_k = 4);              {ALT key must be down while key presses}
  accelflags_t = set of bitsize 8 eletype accelflag_k_t;

  win_accel_t = record                 {Win ACCEL keyboard accelerator data struct}
    flags: accelflags_t;               {set of individual modifier flags}
    key: win_word_t;                   {virtual key code or char dep on VIRTKEY flag}
    cmd: win_word_t;                   {low 16 bits of WPARAM in COMMAND message}
    end;
  win_accel_ar_t = array[0..0] of win_accel_t; {arbitrary length ACCEL array}

  keyget_desc_t = packed record        {WIN_LONG_T key ID for GetKeyNameText}
      unused1: 0..65535;
    scan: 0..255;                      {key's particular scan code}
    ext: boolean;                      {extended key on TRUE}
    nlr: boolean;                      {don't distinguish between left/right keys}
      unused2: 0..63;
    end;

  xlatekey_k_t = win_uint_t (          {IDs for different key code translations}
    xlatekey_virt_scan_k = 0,          {virtual key code to HW scan code}
    xlatekey_scan_virt_k = 1,          {scan to generic key code, no R/L distinction}
    xlatekey_virt_char_k = 2,          {virt to unshifted char, dead keys set MSB}
    xlatekey_scan_virtlr_k = 3);       {scan to key code, R/L pairs distinguised}

  metric_k_t = sys_int_machine_t (     {IDs for individual system config values}
    metric_cxscreen_k = 0,             {pixel width of full screen}
    metric_cyscreen_k = 1,             {pixel height of full screen}
    metric_cxfullscreen_k = 16,        {client area X pix of full screen window}
    metric_cyfullscreen_k = 17,        {client area Y pix of full screen window}
    metric_mousepresent_k = 19,        {not zero if a mouse is present}
    metric_mousewheel_k = 75,          {not zero if the mouse has a wheel}
    metric_swapbutton_k = 23,          {swap mouse buttons left/right when no zero}
    metric_penwindows_k = 41,          {not zero if Pen Extensions installed}
    metric_cmousebuttons_k = 43);      {number of mouse buttons, 0 = no mouse}

  winpaint_t = record                  {repaint info from BeginPaint}
    dc: win_handle_t;                  {handle to display DC for drawing}
    erase: win_bool_t;                 {erase background if not WIN_BOOL_FALSE_K}
    dirty: win_rect_t;                 {rectangle that needs to be repainted}
    reserved1: win_bool_t;
    reserved2: win_bool_t;
    reserved3: array[0..31] of int8u_t;
    reserved4: integer32;              {extra padding, required for some alignments}
    end;

  win_pixfun2_t = sys_int_machine_t (  {IDs for pixel functions of two values}
    win_pixfun2_black_k = 1,           {0}
    win_pixfun2_notmergepen_k = 2,     {not (NEW or OLD)}
    win_pixfun2_masknotpen_k = 3,      {(not NEW) and OLD}
    win_pixfun2_notcopypen_k = 4,      {not NEW}
    win_pixfun2_maskpennot_k = 5,      {NEW and (not OLD)}
    win_pixfun2_not_k = 6,             {not OLD}
    win_pixfun2_xorpen_k = 7,          {NEW xor OLD}
    win_pixfun2_notmaskpen_k = 8,      {not (NEW and OLD)}
    win_pixfun2_maskpen_k = 9,         {NEW and OLD}
    win_pixfun2_notxorpen_k = 10,      {not (NEW xor OLD)}
    win_pixfun2_nop_k = 11,            {OLD}
    win_pixfun2_mergenotpen_k = 12,    {(not NEW) or OLD}
    win_pixfun2_copypen_k = 13,        {NEW}
    win_pixfun2_mergepennot_k = 14,    {NEW or (not OLD)}
    win_pixfun2_mergepen_k = 15,       {NEW or OLD}
    win_pixfun2_white_k = 16);         {all 1s}

  win_pixfun3_t = win_dword_t (        {IDs for pixel functions of three values}
    win_pixfun3_srccopy_k = 16#00CC0020, {dest = source}
    win_pixfun3_srcpaint_k = 16#00EE0086, {dest = source OR dest}
    win_pixfun3_srcand_k = 16#008800C6, {dest = source AND dest}
    win_pixfun3_srcinvert_k = 16#00660046, {dest = source XOR dest}
    win_pixfun3_srcerase_k = 16#00440328, {dest = source AND (NOT dest )}
    win_pixfun3_notsrccopy_k = 16#00330008, {dest = (NOT source)}
    win_pixfun3_notsrcerase_k = 16#001100A6, {dest = (NOT src) AND (NOT dest)}
    win_pixfun3_mergecopy_k = 16#00C000CA, {dest = (source AND pattern)}
    win_pixfun3_mergepaint_k = 16#00BB0226, {dest = (NOT source) OR dest}
    win_pixfun3_patcopy_k = 16#00F00021, {dest = pattern}
    win_pixfun3_patpaint_k = 16#00FB0A09, {dest = DPSnoo}
    win_pixfun3_patinvert_k = 16#005A0049, {dest = pattern XOR dest}
    win_pixfun3_dstinvert_k = 16#00550009, {dest = (NOT dest)}
    win_pixfun3_blackness_k = 16#00000042, {dest = BLACK}
    win_pixfun3_whiteness_k = 16#00FF0062); {dest = WHITE}

  win_minmaxinfo_t = record            {min/max allowed window size limits}
    reserved: win_point_t;
    size_maximized: win_point_t;       {size of a maximized window}
    pos_maximized: win_point_t;        {position of a maximized window}
    size_track_min: win_point_t;       {minimum window tracking size}
    size_track_max: win_point_t;       {maximum window tracking size}
    end;
  win_minmaxinfo_p_t = ^win_minmaxinfo_t;

  colorref_k_t = int8u_t (             {COLORREF interpretation mode flags}
    colorref_rgb_k = 0,                {24 bit RGB value in RED,GRN,BLU}
    colorref_pc_k = 1,                 {logical palette index in RED, GRN,BLU=0}
    colorref_pcrgb_k = 2);             {pick palette entry closest to RED,GRN,BLU}

  win_colorref_t = record              {24 bit RGB value in 32 bit word}
    red: 0..255;
    grn: 0..255;
    blu: 0..255;
    mode: colorref_k_t;                {RED,GRN,BLU fields interpretation mode}
    end;

  win_rgbquad_t = record               {24 bit RGB value in 32 bit word}
    blu: 0..255;
    grn: 0..255;
    red: 0..255;
    reserved: 0..255;                  {must be 0}
    end;

  dibcompress_k_t = win_dword_t (      {DIB compression strategy IDs}
    dibcompress_rgb_k = 0,             {uncompressed}
    dibcompress_rle8_k = 1,            {8 bit RLE, bottom-up only}
    dibcompress_rle4_k = 2,            {4 bit RLE, bottom-up only}
    dibcompress_bitfields_k = 3);      {masks for each comp, 16 and 32 bpp only}

  win_bitmapinfoheader_t = record      {device independent bitmap config info}
    size: win_dword_t;                 {number of bytes required for whole structure}
    width: win_long_t;                 {width of bitmap in pixels}
    height: win_long_t;                {positive for bottom-up, neg for top-down}
    planes: win_word_t;                {number of planes in device, must be 1}
    bits_pix: win_word_t;              {bits per pixel, 1, 4, 8, 16, 24, or 32}
    compress: dibcompress_k_t;         {compression strategy, only bott-up compress}
    size_img: win_dword_t;             {image byte size, may =0 for DIBCOMPRESS_RGB_K}
    ppm_x, ppm_y: win_long_t;          {pixels per meter}
    clr_used: win_dword_t;             {size of color table actually used, 0 = max}
    clr_important: win_dword_t;        {num of important color, 0 = all important}
    end;

  win_bitmapinfo_t = record            {DIB config info and color table}
    config: win_bitmapinfoheader_t;    {DIB config info}
    lut: array[0..0] of win_rgbquad_t; {color lookup table}
    end;
  win_bitmapinfo_p_t = ^win_bitmapinfo_t;

  win_diblut_k_t = win_uint_t (        {describes how values used in bitmap LUT}
    win_diblut_rgb_k = 0,              {LUT is array of literal RGB values}
    win_diblut_ref_k = 1);             {LUT is array of 16 bit indicies into another LUT}

  win_devcap_k_t = sys_int_machine_t ( {graphics device capability IDs}
    win_devcap_driverversion_k = 0,    {Device driver version}
    win_devcap_technology_k = 2,       {Device classification}
    win_devcap_horzsize_k = 4,         {Horizontal size in millimeters}
    win_devcap_vertsize_k = 6,         {Vertical size in millimeters}
    win_devcap_horzres_k = 8,          {Horizontal width in pixels}
    win_devcap_vertres_k = 10,         {Vertical height in pixels}
    win_devcap_bitspixel_k = 12,       {Number of bits per pixel}
    win_devcap_planes_k = 14,          {Number of planes}
    win_devcap_numbrushes_k = 16,      {Number of brushes the device has}
    win_devcap_numpens_k = 18,         {Number of pens the device has}
    win_devcap_nummarkers_k = 20,      {Number of markers the device has}
    win_devcap_numfonts_k = 22,        {Number of fonts the device has}
    win_devcap_numcolors_k = 24,       {Number of colors the device supports}
    win_devcap_pdevicesize_k = 26,     {Size required for device descriptor}
    win_devcap_curvecaps_k = 28,       {Curve capabilities}
    win_devcap_linecaps_k = 30,        {Line capabilities}
    win_devcap_polygonalcaps_k = 32,   {Polygonal capabilities}
    win_devcap_textcaps_k = 34,        {Text capabilities}
    win_devcap_clipcaps_k = 36,        {Clipping capabilities}
    win_devcap_rastercaps_k = 38,      {Bitblt capabilities}
    win_devcap_aspectx_k = 40,         {Length of the X leg}
    win_devcap_aspecty_k = 42,         {Length of the Y leg}
    win_devcap_aspectxy_k = 44,        {Length of the hypotenuse}
    win_devcap_logpixelsx_k = 88,      {Logical pixels/inch in X}
    win_devcap_logpixelsy_k = 90,      {Logical pixels/inch in Y}
    win_devcap_sizepalette_k = 104,    {Number of entries in physical palette}
    win_devcap_numreserved_k = 106,    {Number of reserved entries in palette}
    win_devcap_colorres_k = 108,       {Actual color resolution}
    win_devcap_physicalwidth_k = 110,  {Physical Width in device units}
    win_devcap_physicalheight_k = 111, {Physical Height in device units}
    win_devcap_physicaloffsetx_k = 112, {Physical Printable Area x margin}
    win_devcap_physicaloffsety_k = 113, {Physical Printable Area y margin}
    win_devcap_scalingfactorx_k = 114, {Scaling factor x}
    win_devcap_scalingfactory_k = 115, {Scaling factor y}
    win_devcap_vrefresh_k = 116,       {Current vertical refresh rate of the
                                        display device (for displays only) in Hz}
    win_devcap_desktopvertres_k = 117, {Horizontal width of entire desktop in
                                        pixels}
    win_devcap_desktophorzres_k = 118, {Vertical height of entire desktop in
                                        pixels}
    win_devcap_bltalignment_k = 119);  {Preferred blt alignment}

  rascap_k_t = (                       {flags from WIN_DEVCAP_RASTERCAPS_K query}
    rascap_bitblt_k = 0,               {Can do standard BLT.}
    rascap_banding_k = 1,              {Device requires banding support}
    rascap_scaling_k = 2,              {Device requires scaling support}
    rascap_bitmap64_k = 3,             {Device can support >64K bitmap}
    rascap_gdi20_output_k = 4,         {has 2.0 output calls}
    rascap_gdi20_state_k = 5,
    rascap_savebitmap_k = 6,
    rascap_di_bitmap_k = 7,            {supports DIB to memory}
    rascap_palette_k = 8,              {supports a palette}
    rascap_dibtodev_k = 9,             {supports DIBitsToDevice}
    rascap_bigfont_k = 10,             {supports >64K fonts}
    rascap_stretchblt_k = 11,          {supports StretchBlt}
    rascap_floodfill_k = 12,           {supports FloodFill}
    rascap_stretchdib_k = 13,          {supports StretchDIBits}
    rascap_op_dx_output_k = 14,
    rascap_devbits_k = 15);
  rascap_t = set of bitsize (size_min(sys_int_machine_t) * sys_bits_adr_k)
    eletype rascap_k_t;

  stockobj_k_t = sys_int_machine_t (   {ID of stock system graphics object}
    stockobj_white_brush_k = 0,
    stockobj_ltgray_brush_k = 1,
    stockobj_gray_brush_k = 2,
    stockobj_dkgray_brush_k = 3,
    stockobj_black_brush_k = 4,
    stockobj_null_brush_k = 5,
    stockobj_hollow_brush_k = 5,
    stockobj_white_pen_k = 6,
    stockobj_black_pen_k = 7,
    stockobj_null_pen_k = 8,
    stockobj_oem_fixed_font_k = 10,
    stockobj_ansi_fixed_font_k = 11,
    stockobj_ansi_var_font_k = 12,
    stockobj_system_font_k = 13,
    stockobj_device_default_font_k = 14,
    stockobj_default_palette_k = 15,
    stockobj_system_fixed_font_k = 16,
    stockobj_default_gui_font_k = 17);

  lutflag_k_t = (                      {LUT entry useage flags}
    lutflag_reserved_k = 0,            {intended for animation, no color matching}
    lutflag_explicit_k = 1,            {low 16 bits is hardware LUT index}
    lutflag_nocollapse = 2);           {don't try to re-use LUT entry with same col}
  lutflags_t = set of bitsize 8 eletype lutflag_k_t;

  lutentry_t = record                  {descriptor for one logical palette entry}
    red: 0..255;                       {the color values}
    grn: 0..255;
    blu: 0..255;
    flags: lutflags_t;                 {special flags for how this entry is used}
    end;
  lutentry_ar_t = array[0..0] of lutentry_t;

  logpalette_t = record                {descriptor for a Windows logical palette}
    version: win_word_t;               {Windows version, currently 16#300}
    n_ents: win_word_t;                {number of entries in LUT}
    lut: lutentry_ar_t;                {descriptor for N_ENTS palette entries}
    end;
  logpalette_p_t = ^logpalette_t;

  penstyle_k_t = sys_int_machine_t (   {style IDs for cosmetic pens}
    penstyle_solid_k = 0,
    penstyle_dash_k = 1,
    penstyle_dot_k = 2,
    penstyle_dashdot_k = 3,
    penstyle_dashdotdot_k = 4,
    penstyle_null_k = 5,
    penstyle_insideframe_k = 6);

  keyboard_state_t =                   {snapshot of whole keyboard state}
    array [0..255]                     {one entry for each virtual key code}
    of 0..255;                         {MSB set on key down, LSB on key toggeled on}
  keyboard_state_p_t = ^keyboard_state_t;

  enum_callback_p = ^function (        {callback routine for EnumObjects}
    in      obj_p: univ_ptr;           {pointer to the specific object for this call}
    in      data_p: univ_ptr)          {points to user data from EnumObjects call}
    :sys_int_machine_t;                {0 terminates callbacks}
    val_param;

  obj_k_t = sys_int_machine_t (        {IDs for each object type}
    obj_pen_k = 1,
    obj_brush_k = 2,
    obj_dc_k = 3,
    obj_metadc_k = 4,
    obj_pal_k = 5,
    obj_font_k = 6,
    obj_bitmap_k = 7,
    obj_region_k = 8,
    obj_metafile_k = 9,
    obj_memdc_k = 10,
    obj_extpen_k = 11,
    obj_enhmetadc_k = 12,
    obj_enhmetafile_k = 13);

  obj_pen_t = record                   {pen object descriptor}
    style: penstyle_k_t;               {solid, dashed, dot-dash, ...}
    width: win_point_t;                {X contains width, Y unused}
    color: win_colorref_t;             {pen color}
    end;
  obj_pen_p_t = ^obj_pen_t;
{
********************
*
*   Entry point declarations.
}
function BeginPaint (                  {ack PAINT msg, reset update region to empty}
  in      wind_h: win_handle_t;        {handle to window in which to start painting}
  out     paint_info: winpaint_t)      {info about how window should be repainted}
  :win_handle_t;                       {drawing DC handle, or NONE if no DC avail}
  val_param; extern;

function BitBlt (                      {copy a rectangle of pixels}
  in      dst_dc: win_handle_t;        {destination DC}
  in      dst_x, dst_y: sys_int_machine_t; {destination rectangle upper left coor}
  in      dx, dy: sys_int_machine_t;   {rectangle size in pixels}
  in      src_dc: win_handle_t;        {source DC}
  in      src_x, src_y: sys_int_machine_t; {source rectangle upper left coordinate}
  in      pixfun: win_pixfun3_t)       {pixel function ID (Windows ROP3 code)}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function BringWindowToTop (            {bring window to top and activate}
  in      wind_h: win_handle_t)        {handle to window to bring to top of Z order}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function CloseWindow (                 {minimize window and display as an icon}
  in      wind_h: win_handle_t)        {handle to the window}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function CreateAcceleratorTableA (     {create table to shortcut keys}
  in      accel: univ win_accel_ar_t;  {array of of accelerator descriptors}
  in      n: sys_int_machine_t)        {number of entries in ACCEL}
  :win_handle_t;                       {handle to new table, HANDLE_NONE_K on error}
  val_param; extern;

function CreateCompatibleBitmap (      {make bitmap compatible with existing DC}
  in      dc: win_handle_t;            {handle to DC to be compatible with}
  in      dx, dy: sys_int_machine_t)   {size of new bitmap in pixels}
  :win_handle_t;                       {handle to new bitmap, HANDLE_NONE_K on err}
  val_param; extern;

function CreateDIBSection (            {create DIB that is writeable by app}
  val     dc: win_handle_t;            {DC can be used to copy palette from}
  in      bitmapinfo: win_bitmapinfo_t; {bitmap configuration info}
  val     lutuse: win_diblut_k_t;      {identifies meaning of LUT entries}
  out     p: univ_ptr;                 {returned pointer to bitmap pixel values}
  val     map_h: win_handle_t;         {handle to file mapping object, or NONE}
  val     map_ofs: win_dword_t)        {offset into mapped file for pixel values}
  :win_handle_t;                       {handle to new bitmap, HANDLE_NONE_K on err}
  extern;

function CreatePalette (               {create a logical palette}
  in      palette: logpalette_t)       {descriptor for new palette}
  :win_handle_t;                       {handle to new palette, or NONE on error}
  extern;

function CreatePen (                   {create a cosmetic pen}
  in      style: penstyle_k_t;         {the pen's style (solid, dashed, etc.)}
  in      width: sys_int_machine_t;    {width in pixels, 0 = hardware "1" pixel}
  in      color: win_colorref_t)       {desired pen color}
  :win_handle_t;                       {handle to new pen}
  val_param; extern;

function CreateSolidBrush (            {make brush of one solid color}
  in      color: win_colorref_t)       {desired solid fill color}
  :win_handle_t;                       {handle to new brush}
  val_param; extern;

function CreateWindowExA (             {create a new window}
  in      ewstyle: ewstyle_t;          {extended window style flags}
  in      class_p: win_string_p_t;     {atom ID or pnt to class name string}
  in      name: univ win_string_t;     {window name}
  in      wstyle: wstyle_t;            {window style flags}
  in      x: sys_int_machine_t;        {left X or WIN_DEFAULT_COOR_K}
  in      y: sys_int_machine_t;        {top Y, unused with X = WIN_DEFAULT_COOR_K}
  in      width: sys_int_machine_t;    {width in pixels or WIN_DEFAULT_COOR_K}
  in      height: sys_int_machine_t;   {height, unused if WIDTH = WIN_DEFAULT_COOR_K}
  in      parent: win_handle_t;        {parent window handle, optional in some cases}
  in      menu_h: win_handle_t;        {handle to menu, or HANDLE_NONE_K}
  in      instance_h: win_handle_t;    {handle to this instance of this module}
  in      create_param: win_dword_t)   {passed in CREATE window message}
  :win_handle_t;                       {handle to new window, HANDLE_NONE_K on error}
  val_param; extern;

function DeleteObject (                {delete graphics object and its handle}
  in      h: win_handle_t)             {handle to pen, brush, font, bitmap, palette}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function DefWindowProcA (              {default window procedure}
  in      win_h: win_handle_t;         {handle to window this message is for}
  in      msg: winmsg_k_t;             {ID of this message}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_lresult_t;                      {unsigned 32 bit integer return value}
  val_param; extern;

function DestroyAcceleratorTable (     {delete accel table and dealocate resources}
  in      accel_h: win_handle_t)       {handle to accel table from CreateAccel...}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function DestroyWindow (               {completely remove a window from the system}
  in      wind_h: win_handle_t)        {handle to the window}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function DispatchMessageA (            {cause window proc to be called with message}
  in      msg: win_msg_t)              {message descriptor}
  :win_long_t;                         {value returned by window procedure}
  extern;

function EnableWindow (                {enable or disable a window}
  in      wind_h: win_handle_t;        {handle to the window}
  in      enable: win_bool_t)          {enable on TRUE, disable on FALSE}
  :win_bool_t;                         {WIN_BOOL_FALSE_K if previously enabled}
  val_param; extern;

function EndPaint (                    {close painting started with BeginPaint}
  val     wind_h: win_handle_t;        {handle to window BeginPaint called on}
  in      paint_info: winpaint_t)      {paint info received from BeginPaint}
  :win_bool_t;                         {always returns TRUE}
  extern;

function EnumObjects (                 {get complete list of related groups of obj}
  in      dc: win_handle_t;            {handle to device context}
  in      objtype: obj_k_t;            {object type ID}
  in      callback_p: enum_callback_p; {pointer to callback routine}
  in      data_p: univ_ptr)            {passed directly to callback routine}
  :sys_int_machine_t;                  {from last callback, -1 = too many to enum}
  val_param; extern;

function FillRect (                    {draw filled rectangle}
  val     dc: win_handle_t;            {handle to drawing device context}
  in      coor: win_rect_t;            {rectangle coordinates}
  val     brush_h: win_handle_t)       {handle to brush to use for painting interior}
  :sys_int_machine_t;                  {not 0 on error with GetLastError set}
  extern;

function GdiFlush                      {flush buffered GDI funcs with BOOL values}
  :win_bool_t;                         {WIN_BOOL_FALSE_K if any bufferd func failed}
  extern;

function GetClientRect (               {used to get size of window client area}
  in      wind_h: win_handle_t;        {handle to the window}
  out     rect: win_rect_t)            {window client rect in client area coord}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function GetCursorPos (                {get current cursor position}
  out     coor: win_point_t)           {cursor position in screen coordinates}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  extern;

function GetDC (                       {get drawing device context for a window}
  in      wind_h: win_handle_t)        {handle to window DC will be for}
  :win_handle_t;                       {DC handle, HANDLE_NONE_K on error}
  val_param; extern;

function GetDeviceCaps (               {get capabilities info about a graphics dev}
  in      dc: win_handle_t;            {handle to device context}
  in      devcap: win_devcap_k_t)      {ID of capability inquiring about}
  :sys_int_machine_t;                  {info about specific device capability}
  val_param; extern;

function GetDIBits (                   {get data or info from a bitmap}
  in      dc: win_handle_t;            {device context, for pseudo color reference}
  in      bitmap_h: win_handle_t;      {handle to bitmap requesting info about}
  in      scan_start: win_uint_t;      {first scan line to set in dest bitmap}
  in      n_scans: win_uint_t;         {number of scan lines to copy}
  in      pix_p: univ_ptr;             {pnt to dest pixels, may be NIL}
  out     info: win_bitmapinfo_t;      {filled in, SIZE must be set, see docs}
  in      diblut: win_diblut_k_t)      {destination LUT interpretation ID}
  :sys_int_machine_t;                  {number of scan lines, 0 = failure}
  val_param; extern;

function GetKeyNameTextA (             {get the name of a particular keyboard key}
  in      desc: keyget_desc_t;         {describes particular key inquiring about}
  out     name: univ win_string_t;     {key cap name of the key}
  in      name_len: sys_int_machine_t) {max chars allowed to write into NAME}
  :sys_int_machine_t;                  {length of string in NAME, not counting NULL}
  val_param; extern;

function GetKeyState (                 {get state of key for last message fetched}
  in      virtk: sys_int_machine_t)    {virtual key code}
  :win_short_t;                        {MSB 1 on down, LSB 1 on toggled on}
  val_param; extern;

function GetMessageA (                 {get next message for this thread}
  out     msg: win_msg_t;              {returned message descriptor}
  val     wind_h: win_handle_t;        {NONE = any message for this thread}
  val     msg_low: winmsg_k_t;         {lowest allowed message ID to retrieve}
  val     msg_high: winmsg_k_t)        {highest allowed message ID to retrieve}
  :win_bool_t;                         {normal >0, QUIT msg =0, error <0}
  extern;

function GetMessageExtraInfo           {get extra info for last message from queue}
  :win_long_t;                         {input device driver-specific info}
  extern;

function GetMessagePos                 {get position for last msg from GetMessage}
  :win_coor32s_t;                      {cursor position in screen coordinates}
  extern;

function GetMessageTime                {get time for last message from GetMessage}
  :win_long_t;                         {mS since sys start at time message created}
  extern;

function GetNearestColor (             {get nearest displayable color approximation}
  in      dc: win_handle_t;            {handle to device context}
  in      color: win_colorref_t)       {color to find closest approximation to}
  :win_colorref_t;                     {closest color, or WIN_COLOR_INVALID_K}
  val_param; extern;

function GetObject (                   {get info about a graphics object}
  in      h: win_handle_t;             {handle to bitmap, DIB sect, pen, brush, font}
  in      bufsize: sys_int_adr_t;      {size of BUF allowed to write into}
  in      buf_p: univ_ptr)             {pnt to BUF, return required size on NIL}
  :sys_int_adr_t;                      {BUF size written, buf size needed, or 0=err}
  val_param; extern;

function GetStockObject (              {get handle to a pre-defined graphics object}
  in      id: stockobj_k_t)            {ID of object to get handle of}
  :win_handle_t;                       {handle of object, HANDLE_NONE_K on error}
  val_param; extern;

function GetSystemMetrics (            {get a selected system configuration value}
  in      id: metric_k_t)              {selects which metric to return value of}
  :sys_int_machine_t;                  {value of selected metric}
  val_param; extern;

function GetWindowRect (               {get size and screen pos of whole window}
  in      wind_h: win_handle_t;        {handle to the window}
  out     rect: win_rect_t)            {whole window rectangle in screen coordinates}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function GlobalAddAtomA (              {add string to global atom table}
  in      name: univ win_string_t)     {name to add to atom table}
  :win_atom_t;                         {atom ID, or 0 on error}
  val_param; extern;

function LineTo (                      {line from curr pnt up to, but not incl, pnt}
  in      dc: win_handle_t;            {handle to drawing device context}
  in      x, y: sys_int_machine_t)     {line end point, this point will not be drawn}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function LoadCursorA (                 {get handle to a cursor}
  in      inst_h: win_handle_t;        {instance handle of mod with cursor resorce}
  in      id: cursor_k_t)              {cursor ID with INST_H = HANDLE_NONE_K, or
                                        pointer to cursor name string}
  :win_handle_t;                       {cursor handle, GetLastError on HANDLE_NONE_K}
  val_param; extern;

function MapVirtualKeyA (              {xlate virt key code, scan codes, and chars}
  in      inval: win_uint_t;           {input scan code or virtual key code}
  in      xlate: xlatekey_k_t)         {ID for particular translation to perform}
  :win_uint_t;                         {translated value, 0 = no translation exists}
  val_param; extern;

function MoveToEx (                    {set new current point}
  in      dc: win_handle_t;            {handle to drawing device context}
  in      x, y: sys_int_machine_t;     {new current point coordinates}
  in      old_p: win_point_p_t)        {will write old value at this adr, may be NIL}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function MoveWindow (                  {set new window size and position}
  in      wind_h: win_handle_t;        {handle to the window}
  in      x, y: sys_int_machine_t;     {new window position relative to parent}
  in      dx, dy: sys_int_machine_t;   {new window size}
  in      repaint: win_bool_t)         {invalidate all effected regions on TRUE}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function Polygon (                     {draw 2D arbitrary polygon}
  in      dc: win_handle_t;            {handle to drawing device context}
  in      verts: univ win_point_ar_t;  {array of vertices}
  in      n: sys_int_machine_t)        {number of vertices in VERTS}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function PolylineTo (                  {draw line segments starting at current point}
  in      dc: win_handle_t;            {handle to drawing device context}
  in      verts: univ win_point_ar_t;  {array of vertices}
  in      n: win_dword_t)              {number of vertices in VERTS}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function PostMessageA (                {put msg into queue of a window's thread}
  in      wind_h: win_handle_t;        {window handle, HANDLE_NONE_K for this thread}
  in      msg_id: winmsg_k_t;          {ID of message to post}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

procedure PostQuitMessage (            {put QUIT message in thread's message queue}
  in      exit_code: sys_int_machine_t); {will be put into WPARAM value of QUIT msg}
  val_param; extern;

function RealizePalette (              {set device to reflect palette's contents}
  in      dc: win_handle_t)            {device context whos palette to realize}
  :win_uint_t;                         {number of entries mapped or WIN_GDI_ERROR_K}
  val_param; extern;

function RegisterClassExA (            {create a new window class}
  in      class: window_class_t)       {info for the new window class}
  :win_atom_t;                         {atom ID, or 0 on error}
  extern;

function ReleaseCapture                {release mouse after SetCapture}
  :win_bool_t;                         {WIN_BOOL_FALSE_K on failure}
  extern;

function SelectObject (                {select a new object into a device context}
  in      dc: win_handle_t;            {handle to device context to modify}
  in      obj: win_handle_t)           {handle to new object to set in DC}
  :win_handle_t;                       {handle to old replaced object or region ID}
  val_param; extern;

function SelectPalette (               {bind a palette into a device context}
  in      dc: win_handle_t;            {handle to device context to receive palette}
  in      pal_h: win_handle_t;         {handle to new palette for this DC}
  in      backg: win_bool_t)           {background paletted on WIN_BOOL_TRUE_K}
  :win_handle_t;                       {handle to previous palette or NONE on error}
  val_param; extern;

function SetCapture (                  {route all mouse events to particular window}
  in      wind_h: win_handle_t)        {handle of window to get all mouse events}
  :win_handle_t;                       {previous mouse events wind or HANDLE_NONE_K}
  val_param; extern;

function SetCursorPos (                {set cursor position}
  in      x, y: sys_int_machine_t)     {cursor position in screen coordinates}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function SetDIBitsToDevice (           {copy DIB rectangle to device context}
  in      dc: win_handle_t;            {handle to destination DC}
  in      dst_x, dst_y: sys_int_machine_t; {destination rectangle upper left coord}
  in      dx, dy: sys_int_machine_t;   {source rectangle size}
  in      src_x, src_y: sys_int_machine_t; {source rectangle lower left coord}
  in      dib_start: win_uint_t;       {starting scan line number in DIB array}
  in      dib_height: win_uint_t;      {number of scan lines in DIB array}
  in      pix_adr: sys_int_adr_t;      {starting address of DIB pixels array}
  in      dib_info: win_bitmapinfo_t;  {DIB descriptor}
  in      lutuse: win_diblut_k_t)      {ID of how DIB LUT is interpreted}
  :sys_int_machine_t;                  {num scan lines set, 0 = err with GetLastError}
  val_param; extern;

function SetPixelV (                   {set one pixel to closest available color}
  in      dc: win_handle_t;            {device context handle}
  in      x, y: sys_int_machine_t;     {pixel coordinate within device}
  in      color: win_colorref_t)       {24 bit RGB value in 32 bit word}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;

function SetROP2 (                     {set foreground pixel function}
  in      dc: win_handle_t;            {handle to drawing device context}
  in      pixfun: win_pixfun2_t)       {new pixel function ID}
  :win_pixfun2_t;                      {previous pixfun ID}
  val_param; extern;

function SetWindowTextA (              {set window title text string}
  in      wind: win_handle_t;          {handle to window}
  in      str: univ win_string_t)      {new window title text string}
  :win_bool_t;                         {>0 on success, 0 on failure}
  val_param; extern;

function ShowCursor (                  {increment/decrement cursor show count}
  in      show: win_bool_t)            {inc on WIN_BOOL_TRUE_K, decrement on FALSE}
  :sys_int_machine_t;                  {new show count, cursor displayed if >= 0}
  val_param; extern;

function ShowWindow (                  {set show state of window}
  in      wind_h: win_handle_t;        {handle of window to set show state of}
  in      show: winshow_k_t)           {window's new show state}
  :win_bool_t;                         {>0 on window previously visible, 0 on invis}
  val_param; extern;

function ToAscii (                     {get ASCII value of a keyboard key}
  in      vkey: win_uint_t;            {Windows virtual key code value}
  in      scode: win_uint_t;           {scan code, high bit set if key is up}
  in      kstate: keyboard_state_t;    {state of all the keyboard keys}
  out     chars: univ string;          {returned 1 or 2 char ASCII string}
  in      menu: win_uint_t)            {1 if a menu is active, 0 otherwise}
  :sys_int_machine_t;                  {0 no translation, 1-2 num of chars returned}
  val_param; extern;

function TranslateAcceleratorA (       {translate keystrokes into COMMAND messages}
  val     wind_h: win_handle_t;        {handle of window to receive translated msg}
  val     accel_h: win_handle_t;       {handle to accelerator table}
  in      msg: win_msg_t)              {input message descriptor}
  :sys_int_machine_t;                  {0 on error with GetLastError set}
  extern;

function TranslateMessage (            {translate key code to character message}
  in      msg: win_msg_t)              {input message descriptor}
  :win_bool_t;                         {>0 on msg translated and queued, 0 = not}
  extern;

function UnrealizeObject (             {unmap logical palette from system palette}
  in      pal_h: win_handle_t)         {handle to palette to unrealize}
  :win_bool_t;                         {WIN_BOOL_FALSE_K with GetLastError on error}
  val_param; extern;
