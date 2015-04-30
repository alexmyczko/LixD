module basics.mainloop;

/* This class supervises all the major menus and browsers, game, and editor,
 * which are members of this class.
 *
 * To kill the game at any time, hit Shift + ESC.
 * This breaks straight out of the main loop. Unsaved data is lost.
 *
 * How to use this class: Instantiate, run main_loop() once, and then
 * exit the program when that function is done.
 */

import basics.alleg5;
import basics.demo;
import gui;
import hardware.display;
import hardware.keyboard;
import hardware.mouse;
import hardware.mousecur;
import hardware.sound;
import menu.mainmenu;

class MainLoop {

public:

    ~this() { kill(); }

    void main_loop()
    {
        while (true) {
            immutable last_tick = al_get_timer_count(basics.alleg5.timer);
            calc();
            if (exit) break;
            draw();

            while (last_tick == al_get_timer_count(basics.alleg5.timer))
                al_rest(0.001);
        }
    }

private:

    bool exit;

    MainMenu main_menu;
    Demo demo;



void
kill()
{
    if (main_menu) {
        gui.rm_elder(main_menu);
        destroy(main_menu);
        main_menu = null;
    }
    if (demo) {
        destroy(demo);
        demo = null;
    }
}

void
calc()
{
    hardware.display .calc();
    hardware.keyboard.calc();
    hardware.mouse   .calc();
    gui              .calc();

    exit = exit
     || hardware.display.get_display_close_was_clicked()
     || get_shift() && key_once(ALLEGRO_KEY_ESCAPE);

    if (main_menu) {
        // no need to calc the menu, it's a GUI elder
        if (main_menu.exit_program) {
            kill();
            demo = new Demo;
        }
    }
    else if (demo) {
        demo.calc();
    }
    else {
        // program has just started, nothing exists yet
        main_menu = new MainMenu;
        gui.add_elder(main_menu);
    }

}



void
draw()
{
    // main_menu etc. are GUI Windows. Those have been added as elders and
    // are therefore supervised by module gui.root.
    if (demo) demo   .draw();

    gui              .draw();
    hardware.mousecur.draw();
    hardware.sound   .draw();

    al_flip_display();
}

}
// end class
