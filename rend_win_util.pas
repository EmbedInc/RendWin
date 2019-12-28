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

%include 'win_show_message.ins.pas';
  end;
