import MigrationTypes "../types";

module {
  public func upgrade(prevmigration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    return #v0_0_0(#data);
  };

  public func downgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    return #v0_0_0(#data);
  };

};