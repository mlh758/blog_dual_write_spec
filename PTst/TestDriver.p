type BuiltDatabases = (Database, set[Database]);

machine SingleDatabase {
    var database: Database;
    var iter: int;
    var instances: seq[string];
    start state Init {
        entry {
            instances += (0, "Primary");
            announce eMonitor_ConsistencyInit, instances;
            database = BuildDatabaseNoFollower(instances[0]);
            while (iter < 10) {
                iter = iter + 1;
                send database, eWriteReq, iter;
            }
        }
    }
}

machine SingleServerPerfectDualWrites {
    var server: Server;
    var iter: int;
    var instances: seq[string];
    var dbs: BuiltDatabases;
    start state Init {
        entry {
            instances += (0, "Primary");
            instances += (1, "Secondary");
            announce eMonitor_ConsistencyInit, instances;
            dbs = BuildDatabases(instances);
            server = new Server((primary = dbs.0, followers = dbs.1, startAt = 0, messageCount = 10));
        }
    }
}

machine TwoServerPerfectDualWrites {
    var servers: set[Server];
    var iter: int;
    var instances: seq[string];
    var dbs: BuiltDatabases;
    start state Init {
        entry {
            instances += (0, "Primary");
            instances += (1, "Secondary");
            announce eMonitor_ConsistencyInit, instances;
            dbs = BuildDatabases(instances);
            servers += (new Server((primary = dbs.0, followers = dbs.1, startAt = 0, messageCount = 10)));
            servers += (new Server((primary = dbs.0, followers = dbs.1, startAt = 20, messageCount = 10)));
        }
    }
}

machine LeaderFollower {
    var instances: seq[string];
    var servers: set[Server];
    var leader: Database;
    var follower: Database;
    var replicators: set[Replicator];
    start state Init {
        entry {
            instances += (0, "Leader");
            instances += (1, "Follower");
            announce eMonitor_ConsistencyInit, instances;
            follower = new Database((name = "Follower", replicas = default(set[Replicator]), isLeader = false));
            replicators += (new Replicator(follower));
            leader = new Database((name = "Leader", replicas = replicators, isLeader = true));
            servers += (new Server((primary = leader, followers = default(set[Database]), startAt = 0, messageCount = 10)));
            servers += (new Server((primary = leader, followers = default(set[Database]), startAt = 20, messageCount = 10)));
        }
    }
}

fun BuildDatabases(names: seq[string]): BuiltDatabases {
    var primary: Database;
    var followers: set[Database];
    var idx: int;
    primary = BuildDatabaseNoFollower(names[0]);
    if (sizeof(names) > 1) {
        idx = 1;
        while (idx < sizeof(names)) {
            followers += (BuildDatabaseNoFollower(names[idx]));
            idx = idx + 1;
        }
    }
    return (primary, followers);
}

fun BuildDatabaseNoFollower(name: string): Database {
    return new Database((name = name, replicas = default(set[Replicator]), isLeader = true));
}