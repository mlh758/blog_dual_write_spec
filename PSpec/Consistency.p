event eMonitor_ConsistencyInit: seq[string];

// All databases must eventually have the same sequence of commands
// This assumes at least 1 database is being checked
spec ConsistencyInvariant observes eWriteRecorded, eMonitor_ConsistencyInit
{
    var databaseStates: map[string, seq[int]];
    var iter: string;
    start state Init {
        on eMonitor_ConsistencyInit goto WaitForEvents with (names: seq[string]) {
            foreach (iter in names) {
                databaseStates[iter] = default(seq[int]);
            }
        }
    }
    
    var dbs: seq[seq[int]];
    var dbIter: int;
    cold state WaitForEvents {
        on eWriteRecorded do (write: tWriteRecorded) {
            UpdateDatabase(write);
            dbs = values(databaseStates);
            if (!SameSize()) {
                goto WaitForSequencesToMatch;
            }
            assert AllMatch(), "Sequences are out of order";
        }
    }

    hot state WaitForSequencesToMatch {
        on eWriteRecorded do (write: tWriteRecorded) {
            UpdateDatabase(write);
            dbs = values(databaseStates);
            assert AllMatch(), "Sequences are out of order";
            if (SameSize()) {
                goto WaitForEvents;
            }
        }
    }

    fun UpdateDatabase(write: tWriteRecorded) {
        databaseStates[write.0] += (sizeof(databaseStates[write.0]), write.1);
    }

    // Verify all sequences are the same size
    fun SameSize(): bool {
        var dbSize: int;
        dbSize = sizeof(dbs[0]);
        dbIter = 0;
        while (dbIter < sizeof(dbs)) {
            if (sizeof(dbs[dbIter]) != dbSize) {
                return false;
            }
            dbIter = dbIter + 1;
        }
        return true;
    }
    // Verify that all sequences have the same values in the same order
    fun AllMatch(): bool {
        var referenceValue: int;
        var curSeq: seq[int];
        var smallestDbSize: int;
        smallestDbSize = MinLength();
        dbIter = 0;
        while (dbIter < smallestDbSize) {
            referenceValue = dbs[0][dbIter];
            foreach (curSeq in dbs) {
                if (curSeq[dbIter] != referenceValue) {
                    return false;
                }
            }
            dbIter = dbIter + 1;
        }
        return true;
    }

    // Returns the length of the smallest database
    fun MinLength(): int {
        var min: int;
        var curSeq: seq[int];
        min = 1000; // we should never have a sequence this big
        foreach(curSeq in dbs) {
            if (sizeof(curSeq) < min) {
                min = sizeof(curSeq);
            }
        }
        return min;
    }
}