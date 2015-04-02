module basics.alleg5;

public import allegro5.allegro;
public import allegro5.allegro_acodec;
public import allegro5.allegro_audio;
public import allegro5.allegro_color;
public import allegro5.allegro_font;
public import allegro5.allegro_image;
public import allegro5.allegro_primitives;
public import allegro5.allegro_ttf;

alias ALLEGRO_BITMAP* AlBit;
alias ALLEGRO_COLOR   AlCol;
alias ALLEGRO_FONT*   AlFont;

AlBit albit_create    (in int xl, in int yl); // create normal VRAM bitmap
AlBit albit_ram_create(in int xl, in int yl); // create a RAM bitmap, uncommon

ALLEGRO_TIMER*       timer;

int default_new_bitmap_flags;



AlBit albit_create(in int xl, in int yl)
{
    return albit_create_with_flags(xl, yl, default_new_bitmap_flags
     | ALLEGRO_VIDEO_BITMAP
     &~ ALLEGRO_MEMORY_BITMAP);
}



AlBit albit_ram_create(in int xl, in int yl)
{
    return albit_create_with_flags(xl, yl, default_new_bitmap_flags
     &~ ALLEGRO_VIDEO_BITMAP
     | ALLEGRO_MEMORY_BITMAP);
}



private AlBit albit_create_with_flags(in int xl, in int yl, in int flags)
{
    al_set_new_bitmap_flags(flags);
    scope (exit) al_set_new_bitmap_flags(default_new_bitmap_flags);

    AlBit ret = al_create_bitmap(xl, yl);
    assert (ret);
    assert (al_get_bitmap_width (ret) == xl);
    assert (al_get_bitmap_height(ret) == yl);

    return ret;
}



template temp_target(string bitmap)
{
    // set the bitmap as target, and reset the target back to what it was
    // at the end of the caller's current scope
    const char[] temp_target = "
    AlBit last_target_before_" ~ bitmap[0] ~ " = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target_before_" ~ bitmap[0] ~ ");
    al_set_target_bitmap(" ~ bitmap  ~ ");";
}



template temp_lock(string bitmap)
{
    // lock the bitmap; if locking was succesful, unlock at end of scope
    const char[] temp_lock = "
    ALLEGRO_LOCKED_REGION* lock_" ~ bitmap[0] ~ " = al_lock_bitmap("
     ~ bitmap ~ ", ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
     ALLEGRO_LOCK_READWRITE);
    assert (lock_" ~ bitmap[0] ~ ", \"temp_lock has failed\");
    scope (exit) if (lock_" ~ bitmap[0] ~ ") al_unlock_bitmap(" ~bitmap~ ");";
}
