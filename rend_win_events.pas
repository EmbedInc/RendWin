{   Module of routines for handling events in the Windows driver.
}
module rend_win_event;
define rend_win_keys_init;
%include 'rend_win.ins.pas';
%include 'win_keys.ins.pas';
{
********************************************************************************
*
*   Local subroutine GET_KEY_VAL (VK, SC, KB, STR_P)
*
*   Determine a key's value (string when pressed, not key cap name).  VK is the
*   Windows virtual key code, SC is the Windows scan code, KB is a Windows
*   keyboard state array, and STR_P is the returned string to the key value
*   string.  If a key value can be obtained, then STR_P is returned pointing to
*   a var string for the value, otherwise STR_P is returned NIL.
}
procedure get_key_val (                {get key value string}
  in      vk: sys_int_machine_t;       {Windows virtual key ID}
  in      sc: sys_int_machine_t;       {Windows key scan code}
  in      kb: keyboard_state_t;        {indicates state of all keyboard keys}
  out     str_p: univ string_var_p_t); {returned pnt to string or NIL}
  val_param; internal;

var
  s: string_var80_t;                   {local var string}
  ii: sys_int_machine_t;               {scratch integer}

begin
  s.max := size_char(s.str);           {init local var string}

  ii := ToAscii (                      {try to get key value in ASCII}
    vk,                                {virtual key code}
    sc,                                {scan code}
    kb,                                {state of all keyboard keys for context}
    s.str,                             {returned string}
    0);                                {no menu is active}
  if ii <= 0
    then begin                         {no value string is available}
      str_p := nil;
      end
    else begin                         {we have a value string of length I}
      s.len := ii;                     {set string length}
      rend_mem_alloc (                 {allocate memory for key value string}
        string_size (s.len),           {amount of memory required}
        rend_scope_dev_k,              {this memory will belong to the device}
        false,                         {we don't need to individually deallocate mem}
        str_p);                        {returned pointer to new memory}
      str_p^.max := s.len;             {set new string to key value}
      string_copy (s, str_p^);
      end
    ;
  end;
{
********************************************************************************
*
*   Local subroutine SET_SPKEY (WK, RK, DET)
*
*   Set the special key info, if possible, in a RENDlib key descriptor.  WK is
*   the Windows virtual key code.  RK is the RENDlib special key ID.  DET is the
*   RENDlib detail value for the particular special key.  Nothing is done if the
*   indicated key does not exist.
}
procedure set_spkey (                  {set RENDlib special key info}
  in      wk: winkey_k_t;              {Windows virtual key ID}
  in      rk: rend_key_sp_k_t;         {RENDlib special key ID}
  in      det: sys_int_machine_t);     {detail info for the RENDlib special key}
  val_param; internal;

var
  k_p: rend_key_p_t;                   {pointer to RENDlib key descriptor}

begin
  k_p := dev[rend_dev_id].keyp[ord(wk)]; {get REND key pointer from Win virt key ID}
  if k_p = nil then return;            {no such key exists ?}

  k_p^.spkey.key := rk;                {set RENDlib special key info}
  k_p^.spkey.detail := det;
  end;
{
********************************************************************************
*
*   Local subroutine SHOW_KEY (VK)
*
*   Show info for the key identified by the Windows virtual key code VK.  This
*   routine is for debugging purposes.
}
procedure show_key (                   {show RENDlib key info}
  in      vk: sys_int_machine_t);      {Windows virtual key code}
  val_param; internal;

var
  k_p: rend_key_p_t;                   {pointer to RENDlib key descriptor}
  s: string_var16_t;                   {scratch string}
  stat: sys_err_t;

begin
  s.max := size_char(s.str);           {init local var string}

  k_p := dev[rend_dev_id].keyp[vk];    {get pointer to RENDlib key descriptor}
  if k_p = nil then return;            {no such key ?}

  with k_p^: k do begin                {K is RENDlib key desc}
    write ('VKey ');
    string_f_int_max_base (            {make hex virtual key number}
      s,                               {output string}
      vk,                              {input number}
      16,                              {number base}
      2,                               {field width}
      [ string_fi_leadz_k,             {create leading zeros}
        string_fi_unsig_k],            {input number is unsigned}
      stat);
    sys_error_abort (stat, '', '', nil, 0);
    write (s.str:s.len);

    if k.id = rend_key_none_k then begin {no key here ?}
      writeln (' RKey unused');
      return;
      end;
    write (' RKey ', k.id);

    if k.name_p <> nil then begin
      write (', name "', k.name_p^.str:k.name_p^.len, '"');
      end;

    if k.val_p <> nil then begin
      write (', val "', k.val_p^.str:k.val_p^.len, '"');
      end;
    if k.val_mod[rend_key_mod_shift_k] <> nil then begin
      write (', val/shift "',
        k.val_mod[rend_key_mod_shift_k]^.str:k.val_mod[rend_key_mod_shift_k]^.len,
        '"');
      end;
    if k.val_mod[rend_key_mod_shiftlock_k] <> nil then begin
      write (', val/shiftlock "',
        k.val_mod[rend_key_mod_shiftlock_k]^.str:k.val_mod[rend_key_mod_shiftlock_k]^.len,
        '"');
      end;
    if k.val_mod[rend_key_mod_ctrl_k] <> nil then begin
      write (', val/ctrl "',
        k.val_mod[rend_key_mod_ctrl_k]^.str:k.val_mod[rend_key_mod_ctrl_k]^.len,
        '"');
      end;
    if k.val_mod[rend_key_mod_alt_k] <> nil then begin
      write (', val/alt "',
        k.val_mod[rend_key_mod_alt_k]^.str:k.val_mod[rend_key_mod_alt_k]^.len,
        '"');
      end;

    if k.spkey.key <> rend_key_sp_none_k then begin
      write (', special ', ord(k.spkey.key), ' detail ', k.spkey.detail);
      end;
    end;                               {done with K abbreviation}

  writeln;
  end;
{
********************************************************************************
*
*   Local subroutine MAKE_MOUSE_KEY (VK, DET)
*
*   Make sure a mouse key is in the keys list.  VK is the Windows virtual key
*   code of the mouse key, and DET is the RENDlib detail value for the mouse
*   key.  Nothing is done if DET is <= 0, or a RENDlib key descriptor already
*   exists for this virtual key code.
}
procedure make_mouse_key (             {make sure mouse key exists}
  in      vk: winkey_k_t;              {Windows virtual key code of mouse key}
  in      det: sys_int_machine_t);     {RENDlib detail value for this special key}
  val_param; internal;

var
  kn: sys_int_machine_t;               {RENDlib key ID}
  modk: rend_key_mod_k_t;              {RENDlib modifier key ID}

begin
  if det <= 0 then return;             {this mouse key doesn't really exist ?}
  if dev[rend_dev_id].keyp[ord(vk)] <> nil {this key already exists ?}
    then return;

  kn := rend_device[rend_dev_id].keys_n + 1; {make RENDlib ID of this new key}
  rend_device[rend_dev_id].keys_n := kn; {update total number of RENDlib keys}

  with rend_device[rend_dev_id].keys_p^[kn]: k do begin {K is RENDlib key descriptor}
    dev[rend_dev_id].keyp[ord(vk)] := addr(k); {point virt key codes ar to key desc}
    k.id := kn;                        {RENDlib key ID}
    k.req := false;                    {init to no events requested for this key}
    k.devkey := 0;                     {not implemented}
    k.spkey.key := rend_key_sp_pointer_k; {this key is on the pointer device}
    k.spkey.detail := det;             {copy special key detail value from caller}
    k.id_user := 0;                    {irrelevant until user requests events}
    k.name_p := nil;                   {no name written on key}
    k.val_p := nil;                    {this key produces no character string}
    for modk := firstof(modk) to lastof(modk) do begin {once for each modifier key}
      k.name_mod[modk] := nil;         {no key names}
      k.val_mod[modk] := nil;          {no key string values}
      end;
    end;                               {done with K abbreviation}
  end;
{
********************************************************************************
*
*   Subroutine REND_WIN_KEYS_INIT
*
*   Initialize the state for the keyboard, mouse, and other keys for this
*   device.  Before this routine is called, the device will appear to have no
*   keys to the application.  This routine is really part of the general device
*   initialization process.  It is a seperate routine only for maintainability.
*
*   This routine is called by the window thread after the window is created but
*   before it is made visible.  At this point the main thread is just waiting
*   for the window thread to signal it is done initializing.  Therefore the
*   state for our device is swapped in and there are no synchronization problems
*   since the main thread is just waiting.
}
procedure rend_win_keys_init;          {init events key state for this device}

var
  vk: sys_int_machine_t;               {virtual key code ID}
  sc: sys_int_machine_t;               {key scan code}
  adr: sys_int_adr_t;                  {scratch address value}
  ii: sys_int_machine_t;               {scratch integer}
  keys_p: rend_key_ar_p_t;             {pointer to RENDlib key descriptors array}
  rkey: sys_int_machine_t;             {1-N RENDlib key ID number}
  rkey_max: sys_int_machine_t;         {largest allowable RENDlib key ID}
  kinfo: keyget_desc_t;                {info for finding key name}
  modk: rend_key_mod_k_t;              {RENDlib modifier key ID}
  s: string_var80_t;                   {scratch key name and value string}
  kb: keyboard_state_t;                {simultaneous state of all keyboard keys}
  mouse_left, mouse_middle, mouse_right: {special key detail values for mouse keys}
    sys_int_machine_t;                 {0 indicates physical key doesn't exist}
  lftrit: boolean;                     {swap mouse buttons left/right}
  wheel: boolean;                      {last mouse button is really wheel}

begin
  s.max := size_char(s.str);           {init local var string}
{
*   Find out how many valid keys there are.  We will use this information to
*   allocate one contiguous array of key descriptors later.  In this loop, we
*   don't gather the information for each key, but just figure out which virtual
*   key codes are valid.  The DEV[REND_DEV_ID].KEYP entry for each virtual key
*   code will be set to NIL if the key doesn't exist, and 1 if it does.  The 1
*   will later be overwritten with a pointer to the RENDlib key descriptor.
*
*   Apparently, valid virtual key codes for keyboard keys always have associated
*   key names.  Some invalid codes still have scan codes.  Also, the mouse keys
*   don't seem to have scan codes, so these need to be handled separately.
}
  rkey_max := 0;                       {init number of valid keys found}
  adr := 1;                            {pointer value to flag virt key code exists}

  {   Set static fields in key info request structure.  Only the scan code (SCAN
  *   field) will be altered dynamically.
  }
  kinfo.unused1 := 0;
  kinfo.ext := false;                  {not an extended key}
  kinfo.nlr := true;                   {don't distinguish left and right keys}
  kinfo.unused2 := 0;

  for vk := 0 to 255 do begin          {once for each Windows virtual key code}
    dev[rend_dev_id].keyp[vk] := nil;  {init to this key doesn't exist}
    sc := MapVirtualKeyA (             {translate virtual key code to scan code}
      vk,                              {virtual key code to try to translate}
      xlatekey_virt_scan_k);           {type of translation requested}
    if sc = 0 then next;               {no such key ?}

    kinfo.scan := sc;                  {set scan code inquiring about}
    s.len := GetKeyNameTextA (         {try to get key cap name for this key}
      kinfo,                           {info on key inquiring about}
      s.str,                           {returned null-terminated string}
      s.max);                          {max chars allowed to write to S.STR}
    if s.len <= 0 then next;           {ignore key if it doesn't have a name}

    dev[rend_dev_id].keyp[vk] := univ_ptr(adr); {this virtual key code exists}
    rkey_max := rkey_max + 1;          {count more more valid key}
    end;                               {back to check out next virtual key code}

  ii := GetSystemMetrics (metric_cmousebuttons_k); {get number of mouse buttons}
  lftrit :=                            {TRUE if swap left/right mouse buttons}
    GetSystemMetrics(metric_swapbutton_k) <> 0;
  wheel :=                             {TRUE if last mouse button is really a wheel}
    GetSystemMetrics(metric_mousewheel_k) <> 0;
  mouse_left := 0;                     {init to no physical mouse keys exist}
  mouse_middle := 0;
  mouse_right := 0;
  case ii of                           {different cases for numbers of mouse buttons}
0:  ;                                  {there are no mouse buttons}
1:  begin                              {the mouse has 1 button}
      mouse_left := 1;
      end;
2:  begin                              {the mouse has 2 buttons}
      mouse_left := 1;
      mouse_right := 2;
      end;
otherwise                              {the mouse has 3 or more buttons}
    mouse_left := 1;                   {just use the first three buttons}
    mouse_middle := 2;
    mouse_right := 3;
    end;

  if                                   {+1 key if mouse button not already counted}
      (mouse_left <> 0) and            {mouse button exists ?}
      (dev[rend_dev_id].keyp[ord(winkey_lbutton_k)] = nil) {not seen as "real" key ?}
      then begin
    rkey_max := rkey_max + 1;          {make additional key desc for mouse button}
    end;
  if                                   {+1 key if mouse button not already counted}
      (mouse_middle <> 0) and          {mouse button exists ?}
      (dev[rend_dev_id].keyp[ord(winkey_mbutton_k)] = nil) {not seen as "real" key ?}
      then begin
    rkey_max := rkey_max + 1;          {make additional key desc for mouse button}
    end;
  if                                   {+1 key if mouse button not already counted}
      (mouse_right <> 0) and           {mouse button exists ?}
      (dev[rend_dev_id].keyp[ord(winkey_rbutton_k)] = nil) {not seen as "real" key ?}
      then begin
    rkey_max := rkey_max + 1;          {make additional key desc for mouse button}
    end;

  if rkey_max = 0 then return;         {no valid keys found ?}

  rend_device[rend_dev_id].keys_max := rkey_max; {set max RENDlib key ID}
{
*   The number of valid keys we found is in RKEY_MAX and
*   REND_DEVICE[REND_DEV_ID].KEYS_MAX.  Each entry in DEV[REND_DEV_ID].KEYP is
*   set to NIL for no key, and 1 if the key seemed to exist.
*
*   Now allocate the RENDlib key descriptors array.
}
  rend_mem_alloc (                     {allocate memory for key descriptors array}
    sizeof(keys_p^[1]) * rkey_max,     {amount of memory required}
    rend_scope_dev_k,                  {this memory will belong to the device}
    false,                             {we don't need to individually deallocate mem}
    keys_p);                           {returned pointer to new memory}

  rend_device[rend_dev_id].keys_p := keys_p; {save keys array pointer in dev desc}
{
*   Init KB, the keyboard state array.  This will be used to find key values
*   with various modifier keys pressed.  It must always be reset to all keys up
*   when done with it.
}
  for vk := 0 to 255 do begin          {once for each virtual key code}
    kb[vk] := 0;                       {indicate this key is not pressed}
    end;
{
*   Loop thru each key and fill in a new RENDlib key descriptor for every entry
*   in DEV[REND_DEV_ID].KEYP that was earlier flagged to exist (not NIL).
}
  rkey := 1;                           {init ID of next key descriptor to fill in}

  for vk := 0 to 255 do begin          {once for each possible virtual key code}
    if dev[rend_dev_id].keyp[vk] = nil then next; {this virt key code is invalid ?}
    dev[rend_dev_id].keyp[vk] := nil;  {reset to no key here for easy abort}
    sc := MapVirtualKeyA (             {translate virtual key code to scan code}
      vk,                              {virtual key code to try to translate}
      xlatekey_virt_scan_k);           {type of translation requested}
    if sc = 0 then next;               {couldn't translate virt key code after all ?}

    with keys_p^[rkey]: k do begin     {K is abbrev for RENDlib key descriptor}
      k.id := rkey;                    {set RENDlib key ID}
      k.req := false;                  {init to no events requested for this key}
      k.devkey := 0;                   {device where key found, not implemented}
      rend_get.key_sp_def^ (k.spkey);  {init special key data to default}
      k.id_user := 0;                  {unused until events requested for this key}

      kinfo.scan := sc;                {set scan code inquiring about}
      s.len := GetKeyNameTextA (       {try to get key cap name for this key}
        kinfo,                         {info on key inquiring about}
        s.str,                         {returned null-terminated string}
        s.max);                        {max chars allowed to write to S.STR}
      if s.len > 0
        then begin                     {we have a key cap name string}
          rend_mem_alloc (             {allocate memory for the key name string}
            string_size (s.len),       {amount of memory required}
            rend_scope_dev_k,          {this memory will belong to the device}
            false,                     {we don't need to individually deallocate mem}
            k.name_p);                 {returned pointer to new string}
          k.name_p^.max := s.len;      {fill in string with key name}
          string_copy (s, k.name_p^);
          end
        else begin                     {we didn't get any key name string}
          k.name_p := nil;             {indicate no key name string available}
          end
        ;
      for modk := firstof(modk) to lastof(modk) do begin {once for each modifier key}
        k.name_mod[modk] := nil;       {we can't get key names with modifier keys}
        k.val_mod[modk] := nil;        {init to no key value with this modifier}
        end;

      get_key_val (vk, sc, kb, k.val_p); {get key value with no modifier keys down}

      kb[ord(winkey_shift_k)] := 16#80; {indicate SHIFT key down}
      get_key_val (vk, sc, kb, k.val_mod[rend_key_mod_shift_k]);
      kb[ord(winkey_shift_k)] := 0;    {undo this modifier key}

      kb[ord(winkey_capital_k)] := 16#01; {indicate CAPS LOCK key toggled}
      get_key_val (vk, sc, kb, k.val_mod[rend_key_mod_shiftlock_k]);
      kb[ord(winkey_capital_k)] := 0;  {undo this modifier key}

      kb[ord(winkey_control_k)] := 16#80; {indicate CONTROL key down}
      get_key_val (vk, sc, kb, k.val_mod[rend_key_mod_ctrl_k]);
      kb[ord(winkey_control_k)] := 0;  {undo this modifier key}

      kb[ord(winkey_menu_k)] := 16#80; {indicate ALT key down}
      get_key_val (vk, sc, kb, k.val_mod[rend_key_mod_alt_k]);
      kb[ord(winkey_menu_k)] := 0;     {undo this modifier key}

      dev[rend_dev_id].keyp[vk] := addr(k); {set pointer from virt key code array}
      rkey := rkey + 1;                {make RENDlib key ID for next valid key}
      end;                             {done with K abbreviation}
    end;                               {back for next virtual key code}

  rend_device[rend_dev_id].keys_n := rkey - 1; {set number of valid RENDlib keys}
{
*   Make sure the mouse keys are added.  These may not have scan codes, so may
*   not have been created.  We did earlier check for how many "extra" mouse keys
*   there are and left room, so we can just assume sufficient entries exist in
*   the RENDlib keys array.
}
  make_mouse_key (winkey_lbutton_k, mouse_left); {make sure mouse keys are in list}
  make_mouse_key (winkey_mbutton_k, mouse_middle);
  make_mouse_key (winkey_rbutton_k, mouse_right);
{
*   The RENDlib key descriptors have all been filled in, except that the RENDlib
*   special key information has been set to default.
*
*   Now fill in the RENDlib special key information for those special keys we
*   know about and that exist.
}
  set_spkey (winkey_f1_k, rend_key_sp_func_k, 1); {numbered function keys}
  set_spkey (winkey_f2_k, rend_key_sp_func_k, 2);
  set_spkey (winkey_f3_k, rend_key_sp_func_k, 3);
  set_spkey (winkey_f4_k, rend_key_sp_func_k, 4);
  set_spkey (winkey_f5_k, rend_key_sp_func_k, 5);
  set_spkey (winkey_f6_k, rend_key_sp_func_k, 6);
  set_spkey (winkey_f7_k, rend_key_sp_func_k, 7);
  set_spkey (winkey_f8_k, rend_key_sp_func_k, 8);
  set_spkey (winkey_f9_k, rend_key_sp_func_k, 9);
  set_spkey (winkey_f10_k, rend_key_sp_func_k, 10);
  set_spkey (winkey_f11_k, rend_key_sp_func_k, 11);
  set_spkey (winkey_f12_k, rend_key_sp_func_k, 12);
  set_spkey (winkey_f13_k, rend_key_sp_func_k, 13);
  set_spkey (winkey_f14_k, rend_key_sp_func_k, 14);
  set_spkey (winkey_f15_k, rend_key_sp_func_k, 15);
  set_spkey (winkey_f16_k, rend_key_sp_func_k, 16);
  set_spkey (winkey_f17_k, rend_key_sp_func_k, 17);
  set_spkey (winkey_f18_k, rend_key_sp_func_k, 18);
  set_spkey (winkey_f19_k, rend_key_sp_func_k, 19);
  set_spkey (winkey_f20_k, rend_key_sp_func_k, 20);
  set_spkey (winkey_f21_k, rend_key_sp_func_k, 21);
  set_spkey (winkey_f22_k, rend_key_sp_func_k, 22);
  set_spkey (winkey_f23_k, rend_key_sp_func_k, 23);
  set_spkey (winkey_f24_k, rend_key_sp_func_k, 24);

  set_spkey (winkey_left_k, rend_key_sp_arrow_left_k, 0); {arrow keys}
  set_spkey (winkey_right_k, rend_key_sp_arrow_right_k, 0);
  set_spkey (winkey_up_k, rend_key_sp_arrow_up_k, 0);
  set_spkey (winkey_down_k, rend_key_sp_arrow_down_k, 0);

  set_spkey (winkey_prior_k, rend_key_sp_pageup_k, 0); {Page Up}
  set_spkey (winkey_next_k, rend_key_sp_pagedn_k, 0); {Page Down}
  set_spkey (winkey_delete_k, rend_key_sp_del_k, 0); {Delete}
  set_spkey (winkey_home_k, rend_key_sp_home_k, 0); {Home}
  set_spkey (winkey_end_k, rend_key_sp_end_k, 0); {End}

  set_spkey (winkey_return_k, rend_key_sp_enter_k, 0); {ENTER or RETURN}
  set_spkey (winkey_escape_k, rend_key_sp_esc_k, 0); {Escape}
  set_spkey (winkey_back_k, rend_key_sp_back_k, 0); {Backspace}

  if rend_debug_level >= 10 then begin
    for vk := 0 to 255 do begin
      show_key (vk);
      end;
    end;
  end;
