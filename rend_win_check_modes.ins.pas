{   Subroutine REND_WIN_CHECK_MODES
*
*   This routine is called by RENDlib whenever some internal state got changed.
*   We must inspect the current state and configure the driver accordingly.
}
procedure rend_win_check_modes;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  rgb_simple: boolean;                 {indicates simple state for RGB interpolants}
  pixfun_ok: boolean;                  {TRUE if Xlib can do our pixel functions}
  old_inhibit: boolean;                {old value of CHECK_MODES inhibit flag}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  old_inhibit := rend_inhibit_check_modes2; {save old inhibit flag}
  rend_inhibit_check_modes2 := true;   {inhibit CHECK_MODES2 for now}
  rend_sw_internal.check_modes^;       {call software CHECK_MODES routine}
  if rend_vect_state.replaced_prim_entry_p <> nil then begin {replaced something ?}
    rend_install_prim (                {restore REND_PRIM entry}
      rend_vect_state.replaced_prim_data_p^, {data block for primitive to install}
      rend_vect_state.replaced_prim_entry_p^); {where to install the primitive}
    end;

  if                                   {turn on dithering ?}
      may_dith and                     {dithering allowed ?}
      (not rend_dith.on) and           {dithering not already on ?}
      (rend_min_bits_vis > (bits_vis_ndith + 0.01)) {need the extra colors ?}
      then begin
    rend_prim.flush_all^;              {finish any drawing before modes change}
    rend_dith.on := true;              {turn on dithering}
    rend_cmode[rend_cmode_dithon_k] := true; {indicate this mode got changed}
    end;

  if rend_dith.on
    then begin                         {dithering is ON}
      rend_bits_vis := bits_vis_dith;  {set effective color resolution in bits}
      end
    else begin                         {dithering is OFF}
      rend_bits_vis := bits_vis_ndith; {set effective color resolution in bits}
      end
    ;

  case pixform of                      {what is the pixel format of this window ?}
{
*   Pixel format is 4 bit pseudo color.
}
pixform_pc4_k,
pixform_pc4dith_k: begin
      if rend_dith.on
        then begin                     {dithering is ON}
          pixform := pixform_pc4dith_k; {pixel format is dithered psuedo color}
          end
        else begin                     {dithering is OFF}
          pixform := pixform_pc4_k;    {pixel format is psuedo color}
          end
        ;
      end;
{
*   Pixel format is 8 bit pseudo color.
}
pixform_pc8_k,
pixform_pc8dith_k: begin
      if rend_dith.on
        then begin                     {dithering is ON}
          pixform := pixform_pc8dith_k; {pixel format is dithered psuedo color}
          end
        else begin                     {dithering is OFF}
          pixform := pixform_pc8_k;    {pixel format is psuedo color}
          end
        ;
      end;
{
*   Pixel format is 16 bit true color.
}
pixform_tc16_k,
pixform_tc16dith_k: begin
      if rend_dith.on
        then begin                     {dithering is ON}
          pixform := pixform_tc16dith_k; {pixel format is dithered}
          end
        else begin                     {dithering is OFF}
          pixform := pixform_tc16_k;   {pixel format is not dithered}
          end
        ;
      end;
{
*   Pixel format is 16 bit true color.
}
pixform_tc24_k,
pixform_tc24dith_k: begin
      if rend_dith.on
        then begin                     {dithering is ON}
          pixform := pixform_tc24dith_k; {pixel format is dithered}
          end
        else begin                     {dithering is OFF}
          pixform := pixform_tc24_k;   {pixel format is not dithered}
          end
        ;
      end;
{
*   Pixel format is 16 bit true color.
}
pixform_tc32_k,
pixform_tc32dith_k: begin
      if rend_dith.on
        then begin                     {dithering is ON}
          pixform := pixform_tc32dith_k; {pixel format is dithered}
          end
        else begin                     {dithering is OFF}
          pixform := pixform_tc32_k;   {pixel format is not dithered}
          end
        ;
      end;
{
*   Unexpected pixel format.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(pixform));
    sys_message_bomb ('rend_win', 'pixform_checkmodes', msg_parm, 1);
    end;                               {end of hardware pixel format cases}
{
*   Done with unique code for the different hardware pixel formats.
}
  if rend_min_bits_hw > (rend_bits_hw+0.01) then begin {downgrade req num planes ?}
    rend_min_bits_hw := rend_bits_hw;
    rend_cmode[rend_cmode_minbits_hw_k] := true;
    end;

  if rend_min_bits_vis > (rend_bits_vis+0.01) then begin {downgrade min bits vis ?}
    rend_min_bits_vis := rend_bits_vis;
    rend_cmode[rend_cmode_minbits_vis_k] := true;
    end;
{
*   Check for common conditions required for several of the optimized
*   primitives.
}
  pixfun_ok :=                         {TRUE on basic RGB only drawing}
    (rend_iterp_data.n_rgb = 3) and    {R, G, and B all on ?}
    (rend_iterp_data.n_on = 3) and     {only R, G, and B on ?}
    (rend_iterps.red.pixfun = rend_iterps.grn.pixfun) and {RGB PIXFUNs all same ?}
    (rend_iterps.red.pixfun = rend_iterps.blu.pixfun);
  case rend_iterps.red.pixfun of       {what is RGB PIXFUN setting ?}
rend_pixfun_insert_k,                  {all the PIXFUNs Windows can emulate}
rend_pixfun_and_k,
rend_pixfun_or_k,
rend_pixfun_xor_k,
rend_pixfun_not_k: ;
otherwise
    pixfun_ok := false;                {anything else requires software emulation}
    end;

  rgb_simple :=
    (not rend_force_sw) and            {software emulation not explicitly requested ?}
    pixfun_ok and                      {exactly RGB on, we can do PIXFUN ?}
    (rend_iterps.red.mode = rend_iterp_mode_flat_k) and
    (rend_iterps.grn.mode = rend_iterp_mode_flat_k) and
    (rend_iterps.blu.mode = rend_iterp_mode_flat_k) and
    (rend_iterp_data.n_wmask_all = rend_iterp_data.n_on) and {write masks all on ?}
    (not rend_dith.on) and             {dithering is off ?}
    (not rend_alpha_on) and            {alpha buffering is off ?}
    (not rend_tmap.on)                 {texture mapping is off ?}
    ;
{
*   Install the right VECT_2DIMI primitive.
}
  if                                   {install Windows vector routine ?}
      rgb_simple and                   {simple RGB setup ?}
      (not rend_vect_parms.subpixel) and {subpixel addressing for vectors off ?}
      (rend_vect_parms.poly_level <> rend_space_2dimi_k) {not converted to polygons ?}
    then begin                         {install optimized routine}
      rend_install_prim (rend_win_vect_2dimi_d, rend_prim.vect_2dimi);
      end
    else begin                         {install emulation routine}
      rend_prim_restore_sw (rend_prim.vect_2dimi);
      end
    ;
{
*   Install the right RECT_2DIMI primitive.
}
  if rgb_simple
    then begin                         {install optimized routine}
      rend_install_prim (rend_win_rect_2dimi_d, rend_prim.rect_2dimi);
      end
    else begin                         {install emulation routine}
      rend_prim_restore_sw (rend_prim.rect_2dimi);
      end
    ;
{
*   Install the right POLY_2DIM primitive.
}
  if rgb_simple and (not rend_poly_parms.subpixel)
    then begin                         {install optimized routine}
      rend_install_prim (rend_win_poly_2dim_d, rend_prim.poly_2dim);
      end
    else begin                         {install emulation routine}
      rend_prim_restore_sw (rend_prim.poly_2dim);
      end
    ;
{
*   Restore what we did at the start of this routine.
}
  rend_set.vect_parms^ (rend_vect_parms); {reset vector parms to existing values}
  if not old_inhibit then begin
    rend_sw_internal.check_modes2^;    {run second part of common CHECK_MODES}
    end;

  setup := setup_none_k;               {force reset of any drawing setup}
  end;
