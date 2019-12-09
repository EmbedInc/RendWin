@echo off
rem
rem   Define the variables for running builds from this source library.
rem
set srcdir=rend
set buildname=win
call treename_var "(cog)source/rend/win" sourcedir
set libname=rend_win
set fwname=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
