import v0_1_0 "./v000_001_000/types";
import v0_1_3 "./v000_001_003/types";

module {
  // do not forget to change current migration when you add a new one
  // you should use this field to import types from you current migration anywhere in your project
  // instead of importing it from migration folder itself
  public let Current = v0_1_3;

  public type Args = {
    owner: Principal;
    storage_space: Nat;
    // you can add any fields here to pass external data to your migrations
  };

  public type State = {
    #v0_0_0: {#id; #data: ()};
    #v0_1_0: { #id; #data: v0_1_0.State };
    #v0_1_3: { #id; #data: v0_1_3.State };
    // do not forget to add your new migration state types here
  };
};