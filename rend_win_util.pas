{   Collection of utility routines used for Windows graphics programming.
}
module rend_win_util;
define rend_win_show_message;
%include 'rend_win.ins.pas';
{
*********************************************************************
*
*   Subroutine REND_WIN_SHOW_MESSAGE (MSG, WPARAM, LPARAM)
*
*   Show the Windows message by writing one line to standard output.
*   The message name and its parameter values are shown.  MSG is the message
*   descriptor.  WPARAM and LPARAM are the two standard message parameters.
}
procedure rend_win_show_message (      {show a message and its parameters to STDOUT}
  in      msg: winmsg_k_t;             {message ID}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t);       {signed 32 bit integer message parameter}
  val_param;

var
  s: string_var80_t;                   {scratch string}
  mname: string_var32_t;               {message name}
  tk: string_var32_t;                  {scratch token}

begin
  s.max := size_char(s.str);           {init local var strings}
  mname.max := size_char(mname.str);
  tk.max := size_char(tk.str);

  case msg of                          {set MNAME to message name}
winmsg_null_k: string_vstring (mname, 'NULL'(0), -1);
winmsg_create_k: string_vstring (mname, 'CREATE'(0), -1);
winmsg_destroy_k: string_vstring (mname, 'DESTROY'(0), -1);
winmsg_move_k: string_vstring (mname, 'MOVE'(0), -1);
winmsg_size_k: string_vstring (mname, 'SIZE'(0), -1);
winmsg_activate_k: string_vstring (mname, 'ACTIVATE'(0), -1);
winmsg_setfocus_k: string_vstring (mname, 'SETFOCUS'(0), -1);
winmsg_killfocus_k: string_vstring (mname, 'KILLFOCUS'(0), -1);
winmsg_enable_k: string_vstring (mname, 'ENABLE'(0), -1);
winmsg_setredraw_k: string_vstring (mname, 'SETREDRAW'(0), -1);
winmsg_settext_k: string_vstring (mname, 'SETTEXT'(0), -1);
winmsg_gettext_k: string_vstring (mname, 'GETTEXT'(0), -1);
winmsg_gettextlength_k: string_vstring (mname, 'GETTEXTLENGTH'(0), -1);
winmsg_paint_k: string_vstring (mname, 'PAINT'(0), -1);
winmsg_close_k: string_vstring (mname, 'CLOSE'(0), -1);
winmsg_queryendsession_k: string_vstring (mname, 'QUERYENDSESSION'(0), -1);
winmsg_quit_k: string_vstring (mname, 'QUIT'(0), -1);
winmsg_queryopen_k: string_vstring (mname, 'QUERYOPEN'(0), -1);
winmsg_erasebkgnd_k: string_vstring (mname, 'ERASEBKGND'(0), -1);
winmsg_syscolorchange_k: string_vstring (mname, 'SYSCOLORCHANGE'(0), -1);
winmsg_endsession_k: string_vstring (mname, 'ENDSESSION'(0), -1);
winmsg_showwindow_k: string_vstring (mname, 'SHOWWINDOW'(0), -1);
winmsg_wininichange_k: string_vstring (mname, 'WININICHANGE'(0), -1);
winmsg_devmodechange_k: string_vstring (mname, 'DEVMODECHANGE'(0), -1);
winmsg_activateapp_k: string_vstring (mname, 'ACTIVATEAPP'(0), -1);
winmsg_fontchange_k: string_vstring (mname, 'FONTCHANGE'(0), -1);
winmsg_timechange_k: string_vstring (mname, 'TIMECHANGE'(0), -1);
winmsg_cancelmode_k: string_vstring (mname, 'CANCELMODE'(0), -1);
winmsg_setcursor_k: string_vstring (mname, 'SETCURSOR'(0), -1);
winmsg_mouseactivate_k: string_vstring (mname, 'MOUSEACTIVATE'(0), -1);
winmsg_childactivate_k: string_vstring (mname, 'CHILDACTIVATE'(0), -1);
winmsg_queuesync_k: string_vstring (mname, 'QUEUESYNC'(0), -1);
winmsg_getminmaxinfo_k: string_vstring (mname, 'GETMINMAXINFO'(0), -1);
winmsg_painticon_k: string_vstring (mname, 'PAINTICON'(0), -1);
winmsg_iconerasebkgnd_k: string_vstring (mname, 'ICONERASEBKGND'(0), -1);
winmsg_nextdlgctl_k: string_vstring (mname, 'NEXTDLGCTL'(0), -1);
winmsg_spoolerstatus_k: string_vstring (mname, 'SPOOLERSTATUS'(0), -1);
winmsg_drawitem_k: string_vstring (mname, 'DRAWITEM'(0), -1);
winmsg_measureitem_k: string_vstring (mname, 'MEASUREITEM'(0), -1);
winmsg_deleteitem_k: string_vstring (mname, 'DELETEITEM'(0), -1);
winmsg_vkeytoitem_k: string_vstring (mname, 'VKEYTOITEM'(0), -1);
winmsg_chartoitem_k: string_vstring (mname, 'CHARTOITEM'(0), -1);
winmsg_setfont_k: string_vstring (mname, 'SETFONT'(0), -1);
winmsg_getfont_k: string_vstring (mname, 'GETFONT'(0), -1);
winmsg_sethotkey_k: string_vstring (mname, 'SETHOTKEY'(0), -1);
winmsg_gethotkey_k: string_vstring (mname, 'GETHOTKEY'(0), -1);
winmsg_querydragicon_k: string_vstring (mname, 'QUERYDRAGICON'(0), -1);
winmsg_compareitem_k: string_vstring (mname, 'COMPAREITEM'(0), -1);
winmsg_compacting_k: string_vstring (mname, 'COMPACTING'(0), -1);
winmsg_windowposchanging_k: string_vstring (mname, 'WINDOWPOSCHANGING'(0), -1);
winmsg_windowposchanged_k: string_vstring (mname, 'WINDOWPOSCHANGED'(0), -1);
winmsg_power_k: string_vstring (mname, 'POWER'(0), -1);
winmsg_copydata_k: string_vstring (mname, 'COPYDATA'(0), -1);
winmsg_canceljournal_k: string_vstring (mname, 'CANCELJOURNAL'(0), -1);
winmsg_notify_k: string_vstring (mname, 'NOTIFY'(0), -1);
winmsg_inputlangchangerequest_k: string_vstring (mname, 'INPUTLANGCHANGEREQUEST'(0), -1);
winmsg_inputlangchange_k: string_vstring (mname, 'INPUTLANGCHANGE'(0), -1);
winmsg_tcard_k: string_vstring (mname, 'TCARD'(0), -1);
winmsg_help_k: string_vstring (mname, 'HELP'(0), -1);
winmsg_userchanged_k: string_vstring (mname, 'USERCHANGED'(0), -1);
winmsg_notifyformat_k: string_vstring (mname, 'NOTIFYFORMAT'(0), -1);
winmsg_contextmenu_k: string_vstring (mname, 'CONTEXTMENU'(0), -1);
winmsg_stylechanging_k: string_vstring (mname, 'STYLECHANGING'(0), -1);
winmsg_stylechanged_k: string_vstring (mname, 'STYLECHANGED'(0), -1);
winmsg_displaychange_k: string_vstring (mname, 'DISPLAYCHANGE'(0), -1);
winmsg_geticon_k: string_vstring (mname, 'GETICON'(0), -1);
winmsg_seticon_k: string_vstring (mname, 'SETICON'(0), -1);
winmsg_nccreate_k: string_vstring (mname, 'NCCREATE'(0), -1);
winmsg_ncdestroy_k: string_vstring (mname, 'NCDESTROY'(0), -1);
winmsg_nccalcsize_k: string_vstring (mname, 'NCCALCSIZE'(0), -1);
winmsg_nchittest_k: string_vstring (mname, 'NCHITTEST'(0), -1);
winmsg_ncpaint_k: string_vstring (mname, 'NCPAINT'(0), -1);
winmsg_ncactivate_k: string_vstring (mname, 'NCACTIVATE'(0), -1);
winmsg_getdlgcode_k: string_vstring (mname, 'GETDLGCODE'(0), -1);
winmsg_ncmousemove_k: string_vstring (mname, 'NCMOUSEMOVE'(0), -1);
winmsg_nclbuttondown_k: string_vstring (mname, 'NCLBUTTONDOWN'(0), -1);
winmsg_nclbuttonup_k: string_vstring (mname, 'NCLBUTTONUP'(0), -1);
winmsg_nclbuttondblclk_k: string_vstring (mname, 'NCLBUTTONDBLCLK'(0), -1);
winmsg_ncrbuttondown_k: string_vstring (mname, 'NCRBUTTONDOWN'(0), -1);
winmsg_ncrbuttonup_k: string_vstring (mname, 'NCRBUTTONUP'(0), -1);
winmsg_ncrbuttondblclk_k: string_vstring (mname, 'NCRBUTTONDBLCLK'(0), -1);
winmsg_ncmbuttondown_k: string_vstring (mname, 'NCMBUTTONDOWN'(0), -1);
winmsg_ncmbuttonup_k: string_vstring (mname, 'NCMBUTTONUP'(0), -1);
winmsg_ncmbuttondblclk_k: string_vstring (mname, 'NCMBUTTONDBLCLK'(0), -1);
winmsg_keydown_k: string_vstring (mname, 'KEYDOWN'(0), -1);
winmsg_keyup_k: string_vstring (mname, 'KEYUP'(0), -1);
winmsg_char_k: string_vstring (mname, 'CHAR'(0), -1);
winmsg_deadchar_k: string_vstring (mname, 'DEADCHAR'(0), -1);
winmsg_syskeydown_k: string_vstring (mname, 'SYSKEYDOWN'(0), -1);
winmsg_syskeyup_k: string_vstring (mname, 'SYSKEYUP'(0), -1);
winmsg_syschar_k: string_vstring (mname, 'SYSCHAR'(0), -1);
winmsg_sysdeadchar_k: string_vstring (mname, 'SYSDEADCHAR'(0), -1);
winmsg_keylast_k: string_vstring (mname, 'KEYLAST'(0), -1);
winmsg_initdialog_k: string_vstring (mname, 'INITDIALOG'(0), -1);
winmsg_command_k: string_vstring (mname, 'COMMAND'(0), -1);
winmsg_syscommand_k: string_vstring (mname, 'SYSCOMMAND'(0), -1);
winmsg_timer_k: string_vstring (mname, 'TIMER'(0), -1);
winmsg_hscroll_k: string_vstring (mname, 'HSCROLL'(0), -1);
winmsg_vscroll_k: string_vstring (mname, 'VSCROLL'(0), -1);
winmsg_initmenu_k: string_vstring (mname, 'INITMENU'(0), -1);
winmsg_initmenupopup_k: string_vstring (mname, 'INITMENUPOPUP'(0), -1);
winmsg_menuselect_k: string_vstring (mname, 'MENUSELECT'(0), -1);
winmsg_menuchar_k: string_vstring (mname, 'MENUCHAR'(0), -1);
winmsg_enteridle_k: string_vstring (mname, 'ENTERIDLE'(0), -1);
winmsg_ctlcolormsgbox_k: string_vstring (mname, 'CTLCOLORMSGBOX'(0), -1);
winmsg_ctlcoloredit_k: string_vstring (mname, 'CTLCOLOREDIT'(0), -1);
winmsg_ctlcolorlistbox_k: string_vstring (mname, 'CTLCOLORLISTBOX'(0), -1);
winmsg_ctlcolorbtn_k: string_vstring (mname, 'CTLCOLORBTN'(0), -1);
winmsg_ctlcolordlg_k: string_vstring (mname, 'CTLCOLORDLG'(0), -1);
winmsg_ctlcolorscrollbar_k: string_vstring (mname, 'CTLCOLORSCROLLBAR'(0), -1);
winmsg_ctlcolorstatic_k: string_vstring (mname, 'CTLCOLORSTATIC'(0), -1);
winmsg_mousemove_k: string_vstring (mname, 'MOUSEMOVE'(0), -1);
winmsg_lbuttondown_k: string_vstring (mname, 'LBUTTONDOWN'(0), -1);
winmsg_lbuttonup_k: string_vstring (mname, 'LBUTTONUP'(0), -1);
winmsg_lbuttondblclk_k: string_vstring (mname, 'LBUTTONDBLCLK'(0), -1);
winmsg_rbuttondown_k: string_vstring (mname, 'RBUTTONDOWN'(0), -1);
winmsg_rbuttonup_k: string_vstring (mname, 'RBUTTONUP'(0), -1);
winmsg_rbuttondblclk_k: string_vstring (mname, 'RBUTTONDBLCLK'(0), -1);
winmsg_mbuttondown_k: string_vstring (mname, 'MBUTTONDOWN'(0), -1);
winmsg_mbuttonup_k: string_vstring (mname, 'MBUTTONUP'(0), -1);
winmsg_mbuttondblclk_k: string_vstring (mname, 'MBUTTONDBLCLK'(0), -1);
winmsg_parentnotify_k: string_vstring (mname, 'PARENTNOTIFY'(0), -1);
winmsg_entermenuloop_k: string_vstring (mname, 'ENTERMENULOOP'(0), -1);
winmsg_exitmenuloop_k: string_vstring (mname, 'EXITMENULOOP'(0), -1);
winmsg_nextmenu_k: string_vstring (mname, 'NEXTMENU'(0), -1);
winmsg_sizing_k: string_vstring (mname, 'SIZING'(0), -1);
winmsg_capturechanged_k: string_vstring (mname, 'CAPTURECHANGED'(0), -1);
winmsg_moving_k: string_vstring (mname, 'MOVING'(0), -1);
winmsg_powerbroadcast_k: string_vstring (mname, 'POWERBROADCAST'(0), -1);
winmsg_devicechange_k: string_vstring (mname, 'DEVICECHANGE'(0), -1);
winmsg_mdicreate_k: string_vstring (mname, 'MDICREATE'(0), -1);
winmsg_mdidestroy_k: string_vstring (mname, 'MDIDESTROY'(0), -1);
winmsg_mdiactivate_k: string_vstring (mname, 'MDIACTIVATE'(0), -1);
winmsg_mdirestore_k: string_vstring (mname, 'MDIRESTORE'(0), -1);
winmsg_mdinext_k: string_vstring (mname, 'MDINEXT'(0), -1);
winmsg_mdimaximize_k: string_vstring (mname, 'MDIMAXIMIZE'(0), -1);
winmsg_mditile_k: string_vstring (mname, 'MDITILE'(0), -1);
winmsg_mdicascade_k: string_vstring (mname, 'MDICASCADE'(0), -1);
winmsg_mdiiconarrange_k: string_vstring (mname, 'MDIICONARRANGE'(0), -1);
winmsg_mdigetactive_k: string_vstring (mname, 'MDIGETACTIVE'(0), -1);
winmsg_mdisetmenu_k: string_vstring (mname, 'MDISETMENU'(0), -1);
winmsg_entersizemove_k: string_vstring (mname, 'ENTERSIZEMOVE'(0), -1);
winmsg_exitsizemove_k: string_vstring (mname, 'EXITSIZEMOVE'(0), -1);
winmsg_dropfiles_k: string_vstring (mname, 'DROPFILES'(0), -1);
winmsg_mdirefreshmenu_k: string_vstring (mname, 'MDIREFRESHMENU'(0), -1);
winmsg_cut_k: string_vstring (mname, 'CUT'(0), -1);
winmsg_copy_k: string_vstring (mname, 'COPY'(0), -1);
winmsg_paste_k: string_vstring (mname, 'PASTE'(0), -1);
winmsg_clear_k: string_vstring (mname, 'CLEAR'(0), -1);
winmsg_undo_k: string_vstring (mname, 'UNDO'(0), -1);
winmsg_renderformat_k: string_vstring (mname, 'RENDERFORMAT'(0), -1);
winmsg_renderallformats_k: string_vstring (mname, 'RENDERALLFORMATS'(0), -1);
winmsg_destroyclipboard_k: string_vstring (mname, 'DESTROYCLIPBOARD'(0), -1);
winmsg_drawclipboard_k: string_vstring (mname, 'DRAWCLIPBOARD'(0), -1);
winmsg_paintclipboard_k: string_vstring (mname, 'PAINTCLIPBOARD'(0), -1);
winmsg_vscrollclipboard_k: string_vstring (mname, 'VSCROLLCLIPBOARD'(0), -1);
winmsg_sizeclipboard_k: string_vstring (mname, 'SIZECLIPBOARD'(0), -1);
winmsg_askcbformatname_k: string_vstring (mname, 'ASKCBFORMATNAME'(0), -1);
winmsg_changecbchain_k: string_vstring (mname, 'CHANGECBCHAIN'(0), -1);
winmsg_hscrollclipboard_k: string_vstring (mname, 'HSCROLLCLIPBOARD'(0), -1);
winmsg_querynewpalette_k: string_vstring (mname, 'QUERYNEWPALETTE'(0), -1);
winmsg_paletteischanging_k: string_vstring (mname, 'PALETTEISCHANGING'(0), -1);
winmsg_palettechanged_k: string_vstring (mname, 'PALETTECHANGED'(0), -1);
winmsg_hotkey_k: string_vstring (mname, 'HOTKEY'(0), -1);
winmsg_print_k: string_vstring (mname, 'PRINT'(0), -1);
winmsg_printclient_k: string_vstring (mname, 'PRINTCLIENT'(0), -1);
winmsg_handheldfirst_k: string_vstring (mname, 'HANDHELDFIRST'(0), -1);
winmsg_handheldlast_k: string_vstring (mname, 'HANDHELDLAST'(0), -1);
winmsg_afxfirst_k: string_vstring (mname, 'AFXFIRST'(0), -1);
winmsg_afxlast_k: string_vstring (mname, 'AFXLAST'(0), -1);
winmsg_penwinfirst_k: string_vstring (mname, 'PENWINFIRST'(0), -1);
winmsg_penwinlast_k: string_vstring (mname, 'PENWINLAST'(0), -1);
winmsg_user_k: string_vstring (mname, 'USER'(0), -1);
winmsg_app_k: string_vstring (mname, 'APP'(0), -1);
otherwise                              {not a message we explicitly know about}
    string_f_int32h (mname, ord(msg)); {message name is message number in hex}
    end;                               {end of message ID cases, MNAME all set}

  string_vstring (s, 'Message '(0), -1);
  string_append (s, mname);
  string_appends (s, ', wparam '(0));
  string_f_int32h (tk, wparam);
  string_append (s, tk);
  string_appends (s, ', lparam '(0));
  string_f_int32h (tk, lparam);
  string_append (s, tk);
  string_write (s);
  end;
