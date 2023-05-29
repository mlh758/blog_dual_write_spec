// simple check to make sure we're recording writes
test tcSingleDatabase [ main = SingleDatabase]:
    assert ConsistencyInvariant in (union DualWrites, {SingleDatabase});

// Single server, no data loss
test tcPerfectDualWrites [ main = SingleServerPerfectDualWrites]:
    assert ConsistencyInvariant in (union DualWrites, {SingleServerPerfectDualWrites});

// Two servers, no data loss
test tcTwoServerDualWrites [ main = TwoServerPerfectDualWrites]:
    assert ConsistencyInvariant in (union DualWrites, {TwoServerPerfectDualWrites});

// Two servers, leader/follower
test tcLeaderFollower [ main = LeaderFollower]:
    assert ConsistencyInvariant in (union DualWrites, {LeaderFollower});