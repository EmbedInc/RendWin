{   Subroutine REND_WIN_FLUSH_ALL
*
*   Make sure all buffered graphics is actually drawn.  Note that graphics
*   may be buffered in RENDlib and in Windows.
}
module rend_win_flush_all;
define rend_win_flush_all;
%include 'rend_win.ins.pas';
%include 'rend_win_flush_all_d.ins.pas';

procedure rend_win_flush_all;          {flush all data, insure image is up to date}

begin
  rend_sw_prim.flush_all^;             {flush RENDlib's buffer}
  discard( GdiFlush );                 {flush Windows's buffer}
  end;
