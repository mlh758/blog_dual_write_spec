/*
We're modeling the replication mechanism as a push service
that gets a stream of messages from a leader database and
replicates them to a follower. Generally you would have
a central log that many followers could pull from.

The distinction matters less than you might think. In P
that log is the mailbox for a state machine and any follower
would have something very much like this replicator in front of
it pulling events from the stream to save in the follower.
*/

type tFollowerMsg = (replyTo: machine, message: tReplicateMsg);

event eAckWrite;
event eUpdateFollower: tFollowerMsg;

machine Replicator {
    var target: Database;
    var timer: Timer;
    start state Init {
        entry (db: Database) {
            target = db;
            timer = CreateTimer(this);
            goto SyncingFollower;
        }
    }

    var writeSucceeded: bool;
    state SyncingFollower {
        ignore eAckWrite, eTimeOut; // events from previous attempt, just drop it
        on eReplicateWrite do (payload: tReplicateMsg) {
            writeSucceeded = false;
            StartTimer(timer);
            while (!writeSucceeded) {
                send target, eUpdateFollower, (replyTo = this, message = payload);
                receive {
                    case eAckWrite: {
                        writeSucceeded = true;
                        CancelTimer(timer);
                    }
                    case eTimeOut: {
                        print format("Timed out with tx: {0}, retrying", payload.txId);
                        StartTimer(timer);
                    }
                }
            }
            
        }
    }
}