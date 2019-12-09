{   Subroutine REND_WIN_POLY_2DIM (N, VERTS)
*
*   Draw a polygon.  This routine may only be installed when all of the
*   following conditions are met:
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
*     7 - Subpixel addressing for polygons is OFF.
*
*   PRIM_DATA sw_read no
*   PRIM_DATA sw_write no
}
module rend_win_poly_2dim;
define rend_win_poly_2dim;
%include 'rend_win.ins.pas';
%include 'rend_win_poly_2dim_d.ins.pas';

procedure rend_win_poly_2dim (         {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}
  wverts:                              {polygon verticies in Windows format}
    array[1..rend_max_verts] of win_point_t;

begin
  if setup <> setup_fill_k then begin  {ensure proper driver and GDI setup}
    rend_win_setup (setup_fill_k);
    end;

  for i := 1 to n do begin             {once for each vertex in polygon}
    wverts[i].x := trunc(verts[i].x);  {convert verticies to Windows format}
    wverts[i].y := trunc(verts[i].y);
    end;

  discard( Polygon (                   {draw the polygon}
    dc,                                {handle to device context}
    wverts,                            {array of vertices}
    n) );                              {number of vertices}
  end;
