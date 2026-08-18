pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // subsequence match with word-start and streak bonuses; -1 = no match
    function score(query, target) {
        const q = query.toLowerCase()
        const t = target.toLowerCase()
        let qi = 0, s = 0, streak = 0
        for (let ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                qi++
                streak++
                s += streak
                if (ti === 0 || " :-_/".includes(t[ti - 1]))
                    s += 3
            } else {
                streak = 0
            }
        }
        return qi === q.length ? s : -1
    }
}
