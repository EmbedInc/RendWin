@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the WIN library.
rem
setlocal
call build_pasinit

call src_pas %srcdir% %libname%_admin
call src_pas %srcdir% %libname%_events
call src_pas %srcdir% %libname%_get
call src_pas %srcdir% %libname%_init
call src_pas %srcdir% %libname%_thread
call src_pas %srcdir% %libname%_util
call src_pas %srcdir% %libname%_windproc

call src_rendprim %srcdir% %libname%_flush_all
call src_rendprim %srcdir% %libname%_poly_2dim
call src_rendprim %srcdir% %libname%_rect_2dimi
call src_rendprim %srcdir% %libname%_update_span
call src_rendprim %srcdir% %libname%_vect_2dimi

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
