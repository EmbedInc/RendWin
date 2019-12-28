{   This include file is really part of WIN.INS.PAS.  It enumerates the
*   Windows messages.  These are broken into a separate include file to
*   make WIN.INS.PAS easier to manage.
}
type
  winmsg_k_t = win_uint_t (            {all the windows message IDs}
    winmsg_null_k = 16#0000,
    winmsg_create_k = 16#0001,
    winmsg_destroy_k = 16#0002,
    winmsg_move_k = 16#0003,
    winmsg_size_k = 16#0005,
    winmsg_activate_k = 16#0006,
    winmsg_setfocus_k = 16#0007,
    winmsg_killfocus_k = 16#0008,
    winmsg_enable_k = 16#000A,
    winmsg_setredraw_k = 16#000B,
    winmsg_settext_k = 16#000C,
    winmsg_gettext_k = 16#000D,
    winmsg_gettextlength_k = 16#000E,
    winmsg_paint_k = 16#000F,
    winmsg_close_k = 16#0010,
    winmsg_queryendsession_k = 16#0011,
    winmsg_queryopen_k = 16#0013,
    winmsg_endsession_k = 16#0016,
    winmsg_quit_k = 16#0012,
    winmsg_erasebkgnd_k = 16#0014,
    winmsg_syscolorchange_k = 16#0015,
    winmsg_showwindow_k = 16#0018,
    winmsg_wininichange_k = 16#001A,
    winmsg_devmodechange_k = 16#001B,
    winmsg_activateapp_k = 16#001C,
    winmsg_fontchange_k = 16#001D,
    winmsg_timechange_k = 16#001E,
    winmsg_cancelmode_k = 16#001F,
    winmsg_setcursor_k = 16#0020,
    winmsg_mouseactivate_k = 16#0021,
    winmsg_childactivate_k = 16#0022,
    winmsg_queuesync_k = 16#0023,
    winmsg_getminmaxinfo_k = 16#0024,
    winmsg_painticon_k = 16#0026,
    winmsg_iconerasebkgnd_k = 16#0027,
    winmsg_nextdlgctl_k = 16#0028,
    winmsg_spoolerstatus_k = 16#002A,
    winmsg_drawitem_k = 16#002B,
    winmsg_measureitem_k = 16#002C,
    winmsg_deleteitem_k = 16#002D,
    winmsg_vkeytoitem_k = 16#002E,
    winmsg_chartoitem_k = 16#002F,
    winmsg_setfont_k = 16#0030,
    winmsg_getfont_k = 16#0031,
    winmsg_sethotkey_k = 16#0032,
    winmsg_gethotkey_k = 16#0033,
    winmsg_querydragicon_k = 16#0037,
    winmsg_compareitem_k = 16#0039,
    winmsg_getobject_k = 16#003D,
    winmsg_compacting_k = 16#0041,
    winmsg_commnotify_k = 16#0044,
    winmsg_windowposchanging_k = 16#0046,
    winmsg_windowposchanged_k = 16#0047,
    winmsg_power_k = 16#0048,
    winmsg_copydata_k = 16#004A,
    winmsg_canceljournal_k = 16#004B,
    winmsg_notify_k = 16#004E,
    winmsg_inputlangchangerequest_k = 16#0050,
    winmsg_inputlangchange_k = 16#0051,
    winmsg_tcard_k = 16#0052,
    winmsg_help_k = 16#0053,
    winmsg_userchanged_k = 16#0054,
    winmsg_notifyformat_k = 16#0055,
    winmsg_contextmenu_k = 16#007B,
    winmsg_stylechanging_k = 16#007C,
    winmsg_stylechanged_k = 16#007D,
    winmsg_displaychange_k = 16#007E,
    winmsg_geticon_k = 16#007F,
    winmsg_seticon_k = 16#0080,
    winmsg_nccreate_k = 16#0081,
    winmsg_ncdestroy_k = 16#0082,
    winmsg_nccalcsize_k = 16#0083,
    winmsg_nchittest_k = 16#0084,
    winmsg_ncpaint_k = 16#0085,
    winmsg_ncactivate_k = 16#0086,
    winmsg_getdlgcode_k = 16#0087,
    winmsg_syncpaint_k = 16#0088,
    winmsg_ncmousemove_k = 16#00A0,
    winmsg_nclbuttondown_k = 16#00A1,
    winmsg_nclbuttonup_k = 16#00A2,
    winmsg_nclbuttondblclk_k = 16#00A3,
    winmsg_ncrbuttondown_k = 16#00A4,
    winmsg_ncrbuttonup_k = 16#00A5,
    winmsg_ncrbuttondblclk_k = 16#00A6,
    winmsg_ncmbuttondown_k = 16#00A7,
    winmsg_ncmbuttonup_k = 16#00A8,
    winmsg_ncmbuttondblclk_k = 16#00A9,
    winmsg_ncxbuttondown_k = 16#00AB,
    winmsg_ncxbuttonup_k = 16#00AC,
    winmsg_ncxbuttondblclk_k = 16#00AD,
    winmsg_input_device_change_k = 16#00FE,
    winmsg_input_k = 16#00FF,
    winmsg_keyfirst_k = 16#0100,
    winmsg_keydown_k = 16#0100,
    winmsg_keyup_k = 16#0101,
    winmsg_char_k = 16#0102,
    winmsg_deadchar_k = 16#0103,
    winmsg_syskeydown_k = 16#0104,
    winmsg_syskeyup_k = 16#0105,
    winmsg_syschar_k = 16#0106,
    winmsg_sysdeadchar_k = 16#0107,
    winmsg_keylast_k = 16#0108,
    winmsg_unichar_k = 16#0109,
    winmsg_ime_startcomposition_k = 16#010D,
    winmsg_ime_endcomposition_k = 16#010E,
    winmsg_ime_composition_k = 16#010F,
    winmsg_ime_keylast_k = 16#010F,
    winmsg_initdialog_k = 16#0110,
    winmsg_command_k = 16#0111,
    winmsg_syscommand_k = 16#0112,
    winmsg_timer_k = 16#0113,
    winmsg_hscroll_k = 16#0114,
    winmsg_vscroll_k = 16#0115,
    winmsg_initmenu_k = 16#0116,
    winmsg_initmenupopup_k = 16#0117,
    winmsg_gesture_k = 16#0119,
    winmsg_gesturenotify_k = 16#011A,
    winmsg_menuselect_k = 16#011F,
    winmsg_menuchar_k = 16#0120,
    winmsg_enteridle_k = 16#0121,
    winmsg_menurbuttonup_k = 16#0122,
    winmsg_menudrag_k = 16#0123,
    winmsg_menugetobject_k = 16#0124,
    winmsg_uninitmenupopup_k = 16#0125,
    winmsg_menucommand_k = 16#0126,
    winmsg_changeuistate_k = 16#0127,
    winmsg_updateuistate_k = 16#0128,
    winmsg_queryuistate_k = 16#0129,
    winmsg_ctlcolormsgbox_k = 16#0132,
    winmsg_ctlcoloredit_k = 16#0133,
    winmsg_ctlcolorlistbox_k = 16#0134,
    winmsg_ctlcolorbtn_k = 16#0135,
    winmsg_ctlcolordlg_k = 16#0136,
    winmsg_ctlcolorscrollbar_k = 16#0137,
    winmsg_ctlcolorstatic_k = 16#0138,
    winmsg_mousefirst_k = 16#0200,
    winmsg_mousemove_k = 16#0200,
    winmsg_lbuttondown_k = 16#0201,
    winmsg_lbuttonup_k = 16#0202,
    winmsg_lbuttondblclk_k = 16#0203,
    winmsg_rbuttondown_k = 16#0204,
    winmsg_rbuttonup_k = 16#0205,
    winmsg_rbuttondblclk_k = 16#0206,
    winmsg_mbuttondown_k = 16#0207,
    winmsg_mbuttonup_k = 16#0208,
    winmsg_mbuttondblclk_k = 16#0209,
    winmsg_mousewheel_k = 16#020A,
    winmsg_xbuttondown_k = 16#020B,
    winmsg_xbuttonup_k = 16#020C,
    winmsg_xbuttondblclk_k = 16#020D,
    winmsg_mousehwheel_k = 16#020E,
    winmsg_mouselast_k = 16#020E,
    winmsg_parentnotify_k = 16#0210,
    winmsg_entermenuloop_k = 16#0211,
    winmsg_exitmenuloop_k = 16#0212,
    winmsg_nextmenu_k = 16#0213,
    winmsg_sizing_k = 16#0214,
    winmsg_capturechanged_k = 16#0215,
    winmsg_moving_k = 16#0216,
    winmsg_powerbroadcast_k = 16#0218,
    winmsg_devicechange_k = 16#0219,
    winmsg_mdicreate_k = 16#0220,
    winmsg_mdidestroy_k = 16#0221,
    winmsg_mdiactivate_k = 16#0222,
    winmsg_mdirestore_k = 16#0223,
    winmsg_mdinext_k = 16#0224,
    winmsg_mdimaximize_k = 16#0225,
    winmsg_mditile_k = 16#0226,
    winmsg_mdicascade_k = 16#0227,
    winmsg_mdiiconarrange_k = 16#0228,
    winmsg_mdigetactive_k = 16#0229,
    winmsg_mdisetmenu_k = 16#0230,
    winmsg_entersizemove_k = 16#0231,
    winmsg_exitsizemove_k = 16#0232,
    winmsg_dropfiles_k = 16#0233,
    winmsg_mdirefreshmenu_k = 16#0234,
    winmsg_pointerdevicechange_k = 16#0238,
    winmsg_pointerdeviceinrange_k = 16#0239,
    winmsg_pointerdeviceoutofrange_k = 16#023A,
    winmsg_touch_k = 16#0240,
    winmsg_ncpointerupdate_k = 16#0241,
    winmsg_ncpointerdown_k = 16#0242,
    winmsg_ncpointerup_k = 16#0243,
    winmsg_pointerupdate_k = 16#0245,
    winmsg_pointerdown_k = 16#0246,
    winmsg_pointerup_k = 16#0247,
    winmsg_pointerenter_k = 16#0249,
    winmsg_pointerleave_k = 16#024A,
    winmsg_pointeractivate_k = 16#024B,
    winmsg_pointercapturechanged_k = 16#024C,
    winmsg_touchhittesting_k = 16#024D,
    winmsg_pointerwheel_k = 16#024E,
    winmsg_pointerhwheel_k = 16#024F,
    winmsg_pointerroutedto_k = 16#0251,
    winmsg_pointerroutedaway_k = 16#0252,
    winmsg_pointerroutedreleased_k = 16#0253,
    winmsg_ime_setcontext_k = 16#0281,
    winmsg_ime_notify_k = 16#0282,
    winmsg_ime_control_k = 16#0283,
    winmsg_ime_compositionfull_k = 16#0284,
    winmsg_ime_select_k = 16#0285,
    winmsg_ime_char_k = 16#0286,
    winmsg_ime_request_k = 16#0288,
    winmsg_ime_keydown_k = 16#0290,
    winmsg_ime_keyup_k = 16#0291,
    winmsg_mousehover_k = 16#02A1,
    winmsg_mouseleave_k = 16#02A3,
    winmsg_ncmousehover_k = 16#02A0,
    winmsg_ncmouseleave_k = 16#02A2,
    winmsg_wtssession_change_k = 16#02B1,
    winmsg_tablet_first_k = 16#02C0,
    winmsg_tablet_last_k = 16#02DF,
    winmsg_dpichanged_k = 16#02E0,
    winmsg_dpichanged_beforeparent_k = 16#02E2,
    winmsg_dpichanged_afterparent_k = 16#02E3,
    winmsg_getdpiscaledsize_k = 16#02E4,
    winmsg_cut_k = 16#0300,
    winmsg_copy_k = 16#0301,
    winmsg_paste_k = 16#0302,
    winmsg_clear_k = 16#0303,
    winmsg_undo_k = 16#0304,
    winmsg_renderformat_k = 16#0305,
    winmsg_renderallformats_k = 16#0306,
    winmsg_destroyclipboard_k = 16#0307,
    winmsg_drawclipboard_k = 16#0308,
    winmsg_paintclipboard_k = 16#0309,
    winmsg_vscrollclipboard_k = 16#030A,
    winmsg_sizeclipboard_k = 16#030B,
    winmsg_askcbformatname_k = 16#030C,
    winmsg_changecbchain_k = 16#030D,
    winmsg_hscrollclipboard_k = 16#030E,
    winmsg_querynewpalette_k = 16#030F,
    winmsg_paletteischanging_k = 16#0310,
    winmsg_palettechanged_k = 16#0311,
    winmsg_hotkey_k = 16#0312,
    winmsg_print_k = 16#0317,
    winmsg_printclient_k = 16#0318,
    winmsg_appcommand_k = 16#0319,
    winmsg_themechanged_k = 16#031A,
    winmsg_clipboardupdate_k = 16#031D,
    winmsg_dwmcompositionchanged_k = 16#031E,
    winmsg_dwmncrenderingchanged_k = 16#031F,
    winmsg_dwmcolorizationcolorchanged_k = 16#0320,
    winmsg_dwmwindowmaximizedchange_k = 16#0321,
    winmsg_dwmsendiconicthumbnail_k = 16#0323,
    winmsg_dwmsendiconiclivepreviewbitmap_k = 16#0326,
    winmsg_gettitlebarinfoex_k = 16#033F,
    winmsg_handheldfirst_k = 16#0358,
    winmsg_handheldlast_k = 16#035F,
    winmsg_afxfirst_k = 16#0360,
    winmsg_afxlast_k = 16#037F,
    winmsg_penwinfirst_k = 16#0380,
    winmsg_penwinlast_k = 16#038F,
    winmsg_user_k = 16#0400,
    winmsg_app_k = 16#8000);
