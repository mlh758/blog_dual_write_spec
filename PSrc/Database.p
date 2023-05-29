type tWriteRecorded = (string, int);
type tDatabaseInit = (name: string, replicas: set[Replicator], isLeader: bool);
type tReplicateMsg = (txId: int, value: int);

event eWriteReq: int;
event eReplicateWrite: tReplicateMsg;
event eWriteRecorded: (string, int);

machine Database
{
    var name: string;
    var replicas: set[Replicator];
    var txId: int;
    start state Init {
        entry (payload: tDatabaseInit) {
            name = payload.name;
            replicas = payload.replicas;
            txId = 0;
            if (payload.isLeader) {
                goto WaitForRequests;
            } else {
                goto Following;
            }
        }
        defer eWriteReq;
    }

    var replica: Replicator;
    state WaitForRequests {
        on eWriteReq do (val: int) {
            txId = txId + 1;
            announce eWriteRecorded, (name, val);
            foreach (replica in replicas) {
                send replica, eReplicateWrite, (txId = txId, value = val);
            }
        }
    }

    state Following {
        on eUpdateFollower do (payload: tFollowerMsg) {
            if (payload.message.txId > txId) {
                announce eWriteRecorded, (name, payload.message.value);
                txId = payload.message.txId;
            }
            
            if ($) {
                send payload.replyTo, eAckWrite;
            }
        }
    }
}
