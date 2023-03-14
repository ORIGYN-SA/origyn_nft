import Principal "mo:base/Principal";
import CandyTypes "mo:candy/types";
import Types "types";

module {

	public class EventUtils(state : Types.State, caller : Principal) {

		public let state = state;
		public let caller = caller;
		public let events_namespace = "com.origyn.nft.event";

		public func auction_bid_event(token_id: Text, sale_id: Text) {
			let event_name = events_namespace # ".auction_bid";
			return (event_name, #Class([
				{name="canister"; value = #Principal(state.canister());immutable=true;},
				{name="type"; value = #Text("auction_bid"); immutable=true;},
				{name="meta"; value = #Class([
					{name="token_id"; value = #Text(token_id); immutable=true;},
					{name="sale_id"; value = #Text(sale_id); immutable=true;},
				]); immutable=true;}
			]));
		};

		public func mint_event() {
			let event_name = events_namespace # ".mint";
			return (event_name, #Class([
				{name="canister"; value = #Principal(state.canister());immutable=true;},
				{name="type"; value = #Text("mint"); immutable=true;},
				{name="meta"; value = #Class([]); immutable=true;}
			]));
		};

		public func sale_ended() {
			let event_name = events_namespace # ".sale_ended";
			return (event_name, #Class([
				{name="canister"; value = #Principal(state.canister());immutable=true;},
				{name="type"; value = #Text("sale_ended"); immutable=true;},
				{name="meta"; value = #Class([]); immutable=true;}
			]));
		};
	};

}
