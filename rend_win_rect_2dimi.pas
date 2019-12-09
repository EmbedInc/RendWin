{   Subroutine REND_WIN_RECT_2DIMI (IDX, IDY)
*
*   Draw 2D image space axis aligned rectangle.  This routine may only be
*   installed when all of the following conditions are met:
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
*   PRIM_DATA sw_write no
*   PRIM_DATA sw_read no
}
module rend_win_rect_2dimi;
define rend_win_rect_2dimi;
%include 'rend_win.ins.pas';
%include 'rend_win_rect_2dimi_d.ins.pas';

procedure rend_win_rect_2dimi (        {integer image space axis aligned rectangle}
  in      idx, idy: sys_int_machine_t); {pixel displacement to opposite corner}
  val_param;

var
  rect: win_rect_t;                    {Windows rectangle descriptor}

begin
  if idx >= 0
    then begin                         {rectangle extends right from current point}
      if idx = 0 then return;          {rectangle collapsed, nothing to do ?}
      rect.lft := rend_lead_edge.x;
      rect.rit := rect.lft + idx;
      end
    else begin                         {rectangle extends left from current point}
      rect.rit := rend_lead_edge.x + 1;
      rect.lft := rect.rit + idx;
      end
    ;

  if idy >= 0
    then begin                         {rectangle extends down from current point}
      if idy = 0 then return;          {rectangle collapsed, nothing to do ?}
      rect.top := rend_lead_edge.y;
      rect.bot := rect.top + idy;
      end
    else begin                         {rectangle extends up from current point}
      rect.bot := rend_lead_edge.y + 1;
      rect.top := rect.bot + idy;
      end
    ;

  if setup <> setup_fill_k then begin  {ensure proper driver and GDI setup}
    rend_win_setup (setup_fill_k);
    end;

  discard( FillRect (                  {draw the rectangle}
    dc,                                {handle to our device context}
    rect,                              {rectangle coordinates}
    brush_h) );                        {handle to brush to use for filling rect}
  end;
