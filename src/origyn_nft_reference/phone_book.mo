import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Map "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
//this simple phone book canister is a stand in for a more robust
//service required for the exOS

shared (deployer) actor class PhoneBook(admin : Principal) = this {

  type Name = Text;
  type Canister = Principal;
  type Canisters = [Canister];


  type Entry = {
    collection: Text;
    canisters: Canisters;
  };

  stable var phonebook_stable : [(Name, Canisters)] = [];
  let phonebook = Map.fromEntries<Name, Canisters>(phonebook_stable.vals(), Text.equal, Text.hash);

  stable var admins_stable : Canisters = [admin];


  private func isAdmin(caller: Principal) : Bool {
      for(this_item in admins_stable.vals()){
          if (this_item == caller){
              return true;
          }
      };
      return false;
  };

  public shared (msg) func insert(name : Name, entry : Canisters): async ?Canisters {
    if(isAdmin(msg.caller) == false){throw(Error.reject("Not an admin"));};
    phonebook.put(name, entry);
    return phonebook.get(name);
  };

  public shared (msg) func list(skip : ?Nat, take : ?Nat): async [(Name,Canisters)] {
    if(isAdmin(msg.caller) == false){throw(Error.reject("Not an admin"));};
    let results = Buffer.Buffer<(Name, Canisters)>(phonebook.size());
    for(this_item in phonebook.entries()){
      results.add((this_item.0, this_item.1));
    };
    return results.toArray();
  };

  public shared (msg) func delete(name : Name): async ?Canisters {
    if(isAdmin(msg.caller) == false){throw(Error.reject("Not an admin"));};
    phonebook.delete(name);
    return phonebook.get(name);
  };

  public shared (msg) func update_admin(admins : Canisters): async Canisters {
    if(isAdmin(msg.caller) == false){throw(Error.reject("Not an admin"));};
    admins_stable := admins;
    return admins_stable;
  };

  public query func lookup(name : Name) : async ?[Canister] {
     phonebook.get(name)
  };

  public query func reverse_lookup(value : Canister) : async (Name) {
    var name : Name = "";
    label search for(element in phonebook.entries()){
        var array_canisters = element.1;
        label searchVal for(val in array_canisters.vals()){
          if(val == value){
            name := element.0;
            break searchVal;
          };
        };  
      }; 
    return name;
  };

  system func preupgrade() {
    phonebook_stable := Iter.toArray(phonebook.entries());
           
  };

  system func postupgrade() {
    phonebook_stable := [];
           
  };
};
