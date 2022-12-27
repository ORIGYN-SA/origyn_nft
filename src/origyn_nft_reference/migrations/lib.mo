import D "mo:base/Debug";

import MigrationTypes "./types";
import v0_1_0 "./v000_001_000";
import v0_1_2 "./v000_001_200";

module {
  let upgrades = [
    v0_1_0.upgrade,
    v0_1_2.upgrade,
    // do not forget to add your new migration upgrade method here
  ];

  let downgrades = [
    v0_1_0.downgrade,
    v0_1_2.downgrade,
    // do not forget to add your new migration downgrade method here
  ];

  func getMigrationId(state: MigrationTypes.State): Nat {
    return switch (state) {
      case (#v0_0_0(_)) 0;
      case (#v0_1_0(_)) 1;
      case (#v0_1_2(_)) 2;
      // do not forget to add your new migration id here
      // should be increased by 1 as it will be later used as an index to get upgrade/downgrade methods
    };
  };

  public func migrate(
    prevState: MigrationTypes.State, 
    nextState: MigrationTypes.State, 
    args: MigrationTypes.Args
  ): MigrationTypes.State {

    D.print("in migrate" # debug_show(prevState));
    var state = prevState;
    var migrationId = getMigrationId(prevState);
    D.print("getting migration id");
    let nextMigrationId = getMigrationId(nextState);
    D.print(debug_show(nextMigrationId));

    while (migrationId != nextMigrationId) {
      D.print("in nft while");
      let migrate = if (nextMigrationId > migrationId) upgrades[migrationId] else downgrades[migrationId - 1];
      D.print("upgrade should have run");
      migrationId := if (nextMigrationId > migrationId) migrationId + 1 else migrationId - 1;

      state := migrate(state, args);
    };

    return state;
  };
};