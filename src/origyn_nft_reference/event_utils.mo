import Principal "mo:base/Principal";
import CandyTypes "mo:candy/types";
import Types "types";

module {
	public class TransactionEvents(state : Types.State, caller : Principal) {

		let state : Types.State = state;
		let caller : Principal = caller;
		let events_namespace : Text = "com.origyn.nft.event";

		func get_event(event_type: Text, metadata: CandyTypes.CandyValue): (Text, CandyTypes.CandyValue) {
			let event_name = events_namespace # "." # event_type;
			return (event_name, #Class([
				{name="canister"; value = #Principal(state.canister());immutable=true;},
				{name="type"; value = #Text(event_type); immutable=true;},
				{name="meta"; value = metadata; immutable=true;}
			]));
		};

		public func auction_bid(token_id: Text, sale_id: Text): (Text, CandyTypes.CandyValue) {
			return get_event("auction_bid", #Class([
					{name="token_id"; value = #Text(token_id); immutable=true;},
					{name="sale_id"; value = #Text(sale_id); immutable=true;},
			]));
		};

		public func mint(): (Text, CandyTypes.CandyValue) {
			return get_event("mint", #Class([]));
		};

		public func sale_ended(): (Text, CandyTypes.CandyValue) {
			return get_event("sale_ended", #Class([]));
		};
	};

}
