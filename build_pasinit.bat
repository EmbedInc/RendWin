@echo off
rem
rem   Set up for building a Pascal module.
rem
call build_vars

call src_go %srcdir%
call src_getfrom sys sys.ins.pas
call src_getfrom util util.ins.pas
call src_getfrom string string.ins.pas
call src_getfrom file file.ins.pas
call src_getfrom img img.ins.pas
call src_getfrom vect vect.ins.pas
call src_getfrom ray ray.ins.pas
call src_getfrom ray ray_type1.ins.pas
call src_getfrom sys sys_sys2.ins.pas
call src_getfrom rend core rend.ins.pas
call src_getfrom rend core rend_sw.ins.pas
call src_getfrom rend core rend_sw_sys.ins.pas
call src_getfrom rend core rend2.ins.pas

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% rend_win_check_modes.ins.pas
call src_get %srcdir% rend_win_dev_reconfig.ins.pas
call src_get %srcdir% rend_win_setup.ins.pas
call src_get %srcdir% win.ins.pas
call src_get %srcdir% win_keys.ins.pas
call src_get %srcdir% win_msg.ins.pas
call src_get %srcdir% win_sys.ins.pas

make_debug debug_switches.ins.pas
call src_builddate "%srcdir%"
