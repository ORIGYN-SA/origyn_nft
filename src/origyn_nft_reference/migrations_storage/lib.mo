import v_0_1_0 "./v000_001_000";
import MigrationTypes "./types";
import D "mo:base/Debug";

module {
  let upgrades = [
    
    // do not forget to add your new migration upgrade method here
    v_0_1_0.upgrade
  ];

  let downgrades = [
    v_0_1_0.downgrade,
    // do not forget to add your new migration downgrade method here
  ];

  func getMigrationId(state: MigrationTypes.State): Nat {
    return switch (state) {
      case (#v0_0_0(_)) 0;
      case (#v0_1_0(_)) 1;
      // do not forget to add your new migration id here
      // should be increased by 1 as it will be later used as an index to get upgrade/downgrade methods
    };
  };

  public func migrate(
    prevState: MigrationTypes.State, 
    nextState: MigrationTypes.State, 
    args: MigrationTypes.Args
  ): MigrationTypes.State {
    var state = prevState;
    var migrationId = getMigrationId(prevState);

    let nextMigrationId = getMigrationId(nextState);

    while (migrationId != nextMigrationId) {
      D.print("in storage while");
      let migrate = if (nextMigrationId > migrationId) upgrades[migrationId] else downgrades[migrationId - 1];
  D.print("upgrade should have run");
      migrationId := if (nextMigrationId > migrationId) migrationId + 1 else migrationId - 1;

      state := migrate(state, args);
    };

    return state;
  };
};