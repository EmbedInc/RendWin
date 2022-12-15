{   Module of GET routines for the WIN driver.
}
module rend_win_get;
define rend_win_get_ev_possible;
%include 'rend_win.ins.pas';
{
*****************************************************************************
*
*   Function RENG_WIN_GET_EV_POSSIBLE (EVENT_ID)
*
*   Returns TRUE if the indicated event could happen, assuming it is enabled.
*   We only have to return TRUE for events this driver directly generates.
*   We don't need to worry about higher events created from the basic events
*   our event routine can return.  For example, we only return TRUE for
*   rotation and translation events if our device can directly generate them,
*   even though they can be created from pointer motion event at a higher level.
}
function rend_win_get_ev_possible (    {internal find whether event might ever occurr}
  event_id: rend_evdev_k_t)            {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param;

begin
  case event_id of                     {what kind of internal event is this ?}

rend_evdev_close_k,                    {CLOSE, CLOSE_USER events}
rend_evdev_resize_k,                   {RESIZE events}
rend_evdev_wiped_resize_k,             {WIPED_RESIZE compressed with WIPED_RECT}
rend_evdev_wiped_rect_k,               {WIPED_RECT events}
rend_evdev_key_k,                      {KEY events}
rend_evdev_scroll_k,                   {scroll wheel movement}
rend_evdev_pnt_k: begin                {PNT_ENTER, PNT_EXIT, PNT_MOVE events}
      rend_win_get_ev_possible := true;
      end;
otherwise
    rend_win_get_ev_possible := false;
    end;
  end;
