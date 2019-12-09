/*   This file contains messages used by the RENDlib driver for the Microsoft
/*   Windows graphics API.
/*
msg create_dib
  lan english -def
    Error on attempt to create DIB section in REND_WIN_DEV_RECONFIG.
msg device_not_found
  lan english -def
    Error in Windows window procedure.  Unable to determine RENDlib device
    ID from window handle.
msg err_get_message
  lan english -def
    Error encountered in window handling thread on attempt to get the next
    thread message.  Window thread aborting.
msg event_unrecognized
  lan english -def
    Unrecognized RENDlib WIN driver internal event ID encountered.  Event
    ID is %p1i.
msg pixform_checkmodes
  lan english -def
    Unexpected pixel format encountered in REND_WIN_CHECK_MODES.  Pixel
    format ID was %p1i.
msg pixform_setup
  lan english -def
    Unexpected pixel format encountered in REND_WIN_SETUP.  Pixel
    format ID was %p1i.
msg pixform_span
  lan english -def
    Unexpected pixel format encountered in REND_WIN_UPDATE_SPAN.  Pixel
    format ID was %p1i.
msg queue_signal_put
  lan english -def
    Error on attempt to signal queue is no longer empty in REND_WIN_EVENT_PUT.
msg queue_signal_reset_get
  lan english -def
    Error on reset event queue signal in REND_WIN_EVENT_GET.
msg queue_signal_reset_put
  lan english -def
    Error on reset event queue signal in REND_WIN_EVENT_PUT.
msg queue_signal_set_get
  lan english -def
    Error on set event queue signal in REND_WIN_EVENT_GET.
msg queue_signal_set_put
  lan english -def
    Error on set event queue signal in REND_WIN_EVENT_PUT.
msg queue_wait_get
  lan english -def
    Unexpected condition ended wait for event queue to become not empty
    in REND_WIN_EVENT_GET.  DONEWAIT = %P1i.
msg queue_wait_put
  lan english -def
    Unexpected condition ended wait for event queue to become not full
    in REND_WIN_EVENT_PUT.  DONEWAIT = %P1i.
msg setup_setup
  lan english -def
    Unexpected driver setup ID encountered in REND_WIN_SETUP.  Setup ID
    was %p1i.
msg thread_start_stdin
  lan english -def
    Error on attempt to launch thread to read next line of standard input.
msg write_bits_span
  lan english -def
    Error on attempt to copy DIB bits to device in REND_WIN_UPDATE_SPAN.
