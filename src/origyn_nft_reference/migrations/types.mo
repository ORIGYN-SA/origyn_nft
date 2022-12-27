import v0_1_0 "./v000_001_000/types";
import v0_1_2 "./v000_001_200/types";

module {
  public let Current = v0_1_2;

  public type Args = {
    owner: Principal;
    storage_space: Nat;
    // you can add any fields here to pass external data to your migrations
  };

  public type State = {
    #v0_0_0: {#id; #data: ()};
    #v0_1_0: { #id; #data: v0_1_0.State };
    #v0_1_2: { #id; #data: v0_1_2.State };
    // do not forget to add your new migration state types here
  };
};