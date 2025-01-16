import MigrationTypes "./types";
import v0_1_0 "./v000_001_000";
import v0_1_3 "./v000_001_003";
import v0_1_4 "./v000_001_004";
import v0_1_5 "./v000_001_005";
import v0_1_6 "./v000_001_006";
import v0_1_7 "./v000_001_007";
import D "mo:base/Debug";

module {
  let upgrades = [
    v0_1_0.upgrade,
    v0_1_3.upgrade,
    v0_1_4.upgrade,
    v0_1_5.upgrade,
    v0_1_6.upgrade,
    v0_1_7.upgrade,
    // do not forget to add your new migration upgrade method here
  ];

  let downgrades = [
    v0_1_0.downgrade,
    v0_1_3.downgrade,
    v0_1_4.downgrade,
    v0_1_5.downgrade,
    v0_1_6.downgrade,
    v0_1_7.downgrade,
    // do not forget to add your new migration downgrade method here
  ];

  func getMigrationId(state : MigrationTypes.State) : Nat {
    return switch (state) {
      case (#v0_0_0(_)) 0;
      case (#v0_1_0(_)) 1;
      case (#v0_1_3(_)) 2;
      case (#v0_1_4(_)) 3;
      case (#v0_1_5(_)) 4;
      case (#v0_1_6(_)) 5;
      case (#v0_1_7(_)) 6;
      // do not forget to add your new migration id here
      // should be increased by 1 as it will be later used as an index to get upgrade/downgrade methods
    };
  };

  public func migrate(
    prevState : MigrationTypes.State,
    nextState : MigrationTypes.State,
    args : MigrationTypes.Args,
    caller : Principal,
  ) : MigrationTypes.State {

    // D.print("in migrate" # debug_show(prevState));
    var state = prevState;
    var migrationId = getMigrationId(prevState);
    D.print("getting migration id");
    let nextMigrationId = getMigrationId(nextState);
    D.print(debug_show (nextMigrationId));

    while (migrationId != nextMigrationId) {
      D.print("in nft while" # debug_show ((nextMigrationId, migrationId)));
      let migrate = if (nextMigrationId > migrationId) upgrades[migrationId] else downgrades[migrationId - 1];
      D.print("upgrade should have run");
      migrationId := if (nextMigrationId > migrationId) migrationId + 1 else migrationId - 1;

      state := migrate(state, args, caller);
    };

    return state;
  };
};
