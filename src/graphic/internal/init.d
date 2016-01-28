module graphic.internal.init;

import std.string; // format
import std.algorithm;

import basics.alleg5;
import basics.globals;
import basics.help;
import basics.matrix;
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters; // for asserting stuff got there
import graphic.internal.vars;
import graphic.internal.recol;
import hardware.display; // show progress during startup, maybe make this lazy
import lix.enums;
import lix.fields;

package:

// DTODOLAZY: Right now, we do everything at program start. Maybe we
// can be lazy and load other sprite colors only when they become necessary
// for displaying replays, or when connecting to a game server. (They must
// be ready without delay when a multiplayer game starts!)
void implInitializeInteractive()
{
    nullCutbit = new Cutbit(cast (Cutbit) null);

    displayStartupMessage("Loading internal bitmaps...");
    loadInternalsFromFiles();

    displayStartupMessage("Examining Lix spritesheet for eye positions...");
    auto lock = LockReadWrite(getLixRawSprites.albit);
    createEyeCoordinateMatrix();
    displayStartupMessage("Recoloring Lix sprites for multiplayer...");
    recolor_into_vector(getLixRawSprites(), spritesheets, magicnrSpritesheets);

    displayStartupMessage("Recoloring panel info icons for multiplayer...");
    recolorGuiAccordingToPlayerColors(
        fileImageGameIcon, panelInfoIcons, magicnrPanelInfoIcons);

    displayStartupMessage("Recoloring skill buttons for multiplayer...");
    recolorGuiAccordingToPlayerColors(
        fileImageSkillIcons, skillButtonIcons, magicnrSkillButtonIcons);

    displayStartupMessage("Recoloring GUI elements...");
    makeGuiElementsHaveCorrectColor();

    // DTODO: move load_all_file_replacements(); into obj_lib
    auto toAssert = implGetSkillButton(Style.garden);
    assert (toAssert);
    assert (toAssert.valid);
}

void implInitializeVerify()
{
    nullCutbit = new Cutbit(cast (Cutbit) null);
    // Load only the Lix spritesheet, because physics depend on it.
    // Is this a design bug? Discuss with the IRCies eventually.
    loadInternalsOnlySprites();
    auto lock = LockReadWrite(getLixRawSprites.albit);
    createEyeCoordinateMatrix();
}

void implDeinitialize()
{
    destroyArray(skillButtonIcons);
    destroyArray(panelInfoIcons);
    destroyArray(spritesheets);
    destroyArray(internal);

    destroy(nullCutbit);
    nullCutbit = null;
}

private:

void loadInternalsFromFiles()
{
    // Since this is unrelated to the terrain name replacements, the internal
    // graphics are array-keyed WITH dir, WITH pre-ext, WITHOUT image file ext.
    auto files = file.search.findRegularFilesRecursively(dirDataBitmap);
    files.filter!(fn => fn.hasImageExtension)
        .each!   (fn => loadInternalFile(fn));
}

// copy-pasted from loadInternalsFromSprites
void loadInternalsOnlySprites()
{
    auto files = file.search.findRegularFilesRecursively(dirDataBitmap);
    files.filter!(fn => fn.hasImageExtension)
        .filter! (fn => fn.rootlessNoExt == fileImageSpritesheet.rootlessNoExt)
        .each!   (fn => loadInternalFile(fn));
}

void loadInternalFile(Filename fn)
{
    Cutbit cb = new Cutbit(fn);
    assert (cb, "error loading internal cutbit: " ~ fn.rootful);
    al_convert_mask_to_alpha(cb.albit, color.pink);
    internal[fn.rootlessNoExt] = cb;
    assert (getInternalMutable(fn).valid,
        "can't retrieve from array: " ~ fn.rootful);
}

void createEyeCoordinateMatrix()
{
    // Each frame of the Lix spritesheet has the eyes in some position.
    // The exploder fuse shall start at that position, let's calculate it.
    // It's also important for physics, eyes touching fire will kill.
    Cutbit cb = getLixRawSprites();
    Albit b = cb.albit;
    assert (b, "apparently your gfx card can't store the Lix spritesheet");

    lix.fields.countdown = new Matrix!XY(cb.xfs, cb.yfs);
    // fx, fy = which x- respective y-frame
    // x,  y  = which pixel inside this frame, offset from frame's top left
    for  (int fy = 0; fy < cb.yfs; ++fy)
     for (int fx = 0; fx < cb.xfs; ++fx) {
        for  (int y = 0; y < cb.yl; ++y )
         for (int x = 0; x < cb.xl; ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.xl + 1) + x;
            const int real_y = 1 + fy * (cb.yl + 1) + y;
            if (al_get_pixel(b, real_x, real_y) == color.lixFileEye) {
                countdown.set(fx, fy, XY(x, y-1));
                goto GOTO_NEXTFRAME;
            }
            // If not yet gone to GOTO_NEXTFRAME:
            // Use the XY of the frame left to the current one if there was
            // nothing found, and a default value for the leftmost frames.
            // Frames (0, y) and (1, y) are the skill button images.
            if (y == cb.yl - 1 && x == cb.xl - 1) {
                if (fx < 3) countdown.set(fx, fy, XY(cb.xl / 2 - 1, 12));
                else        countdown.set(fx, fy, countdown.get(fx - 1, fy));
            }
        }
        GOTO_NEXTFRAME:
        if (fy == Ac.blocker) {
            XY blockerEyes = countdown.get(fx, fy);
            blockerEyes.x = lix.enums.exOffset;
            countdown.set(fx, fy, blockerEyes);
        }
    }
    // All pixels of the entire spritesheet have been examined.
}

void recolorGuiAccordingToPlayerColors(
    in Filename fn,
    ref Cutbit[Style] vec,
    in int magicnr
) {
    Cutbit cb_icons = getInternalMutable(fn);
    assert (cb_icons && cb_icons.valid,
        format("can't get bitmap for magicnr %d", magicnr));
    if (! cb_icons || ! cb_icons.valid)
        return;
    Albit  cb_bmp   = cb_icons.albit;
    auto lock_icons = LockReadWrite(cb_bmp);
    recolor_into_vector(cb_icons, vec, magicnr);
}

void makeGuiElementsHaveCorrectColor()
{
    // We assume the user file to have been loaded already,
    // and therefore the correct GUI colors have been computed.
    enum files = [  fileImageGuiNumber,
                    fileImageEditFlip,
                    fileImageEditHatch,
                    fileImageEditPanel,
                    fileImageGameArrow,
                    fileImageGameNuke,
                    fileImageGamePanel,
                    fileImageGamePanel2,
                    fileImageGamePanelHints,
                    fileImageGameSpawnint,
                    fileImageGamePause,
                    fileImageLobbySpec,
                    fileImageMenuCheckmark,
                    fileImagePreviewIcon ];
    files.each!(fn => fn.getInternalMutable.eidrecol(0));
}
