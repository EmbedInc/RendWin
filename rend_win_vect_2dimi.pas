{   Subroutine REND_WIN_RECT_2DIMI (X, Y)
*
*   This routine uses the Windows vector primitive.  It may only be installed
*   under the following conditions:
*
*     1 - No interpolants other than red, green, and blue are ON.
*
*     2 - All pixel functions are INSERT.
*
*     3 - All interpolation modes are FLAT.
*
*     4 - All write mask bits are enabled.
*
*     5 - Dithering is OFF.
*
*     6 - Alpha buffering OFF, texture mapping OFF.
*
*     7 - Subpixel addressing for vectors is OFF.
*
*   PRIM_DATA sw_read no
*   PRIM_DATA sw_write no
}
module rend_win_vect_2dimi;
define rend_win_vect_2dimi;
%include 'rend_win.ins.pas';
%include 'rend_win_vect_2dimi_d.ins.pas';

procedure rend_win_vect_2dimi (        {integer 2D image space vector}
  in      ix, iy: sys_int_machine_t);  {pixel coordinate end point}
  val_param;

begin
  if setup <> setup_line_k then begin  {ensure proper driver and GDI setup}
    rend_win_setup (setup_line_k);
    end;

  discard( LineTo (dc, ix, iy) );      {draw all but the last pixel}
  discard( LineTo (dc, ix + 1, iy) );  {draw the last pixel}
  discard( MoveToEx (dc, ix, iy, nil) ); {fix current point from drawing last pixel}

  rend_lead_edge.x := ix;              {update 2DIMI space current point}
  rend_curr_x := ix;
  rend_lead_edge.y := iy;
  end;
