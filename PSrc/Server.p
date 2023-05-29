type tStartServer = (primary: Database, followers: set[Database], startAt: int, messageCount: int);

// The server is a client to the database.
machine Server {
    var primary: Database;
    var followers: set[Database];
    var counter: int;
    var startAt: int;
    var messageCount: int;

    start state Init {
        entry (payload: tStartServer) {
            counter = 0;
            primary = payload.primary;
            followers = payload.followers;
            startAt = payload.startAt;
            messageCount = payload.messageCount;
            goto SendMessages;
        }
    }

    // for each message in our range, send it to the primary
    // and then any followers we're aware of to simulate dual writes
    var follower: Database;
    state SendMessages {
        entry {
            while (counter < messageCount) {
                send primary, eWriteReq, startAt + counter;
                foreach (follower in followers) {
                    send follower, eWriteReq, startAt + counter;
                }
                counter = counter + 1;
            }
        }
    }
}