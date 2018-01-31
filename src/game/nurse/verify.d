module game.nurse.verify;

import basics.user : Trophy;
import game.nurse.base;

class VerifyingNurse : Nurse {
private:
    bool _maySaveTrophy;
    int _required;

public:
    struct EvalResult {
        Trophy trophy; //
        bool mercyKilled; // replay took too long after last assign before win
    }

    this(in Level lev, Replay rp, in bool mst)
    {
        super(lev, rp, null);
        _maySaveTrophy = mst;
        _required = lev.required;
    }

    EvalResult evaluateReplay()
    in {
        assert (model);
        assert (replay);
    }
    body {
        EvalResult ret;
        while (! cs.singleplayerHasSavedAtLeast(_required)
            && ! everybodyOutOfLix
        ) {
            updateOnce();
            // allow 5 minutes after the last replay data before cancelling
            if (upd >= replay.latestPhyu + 5 * (60 * 15)) {
                ret.mercyKilled = true;
                break;
            }
        }
        ret.trophy = trophyForTribe(replay.playerLocalOrSmallest.style);
        return ret;
    }
}