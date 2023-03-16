import Principal "mo:base/Principal";
import CandyTypes "mo:candy/types";
import Types "types";
import Timer "mo:base/Timer";
import Droute "mo:droute_client/Droute";

module {
	public type FeatureStatus = {
		#feature_enabled;
		#feature_disabled;
	};

	public class TransactionEvents(_state : Types.State, _caller : Principal) {

		let state : Types.State = _state;
		let caller : Principal = _caller;
		let events_namespace : Text = "com.origyn.nft.event";

		public let feature_status : FeatureStatus = #feature_enabled;

		public func announceTransaction(rec : Types.TransactionRecord, newTrx : Types.TransactionRecord) : () {
			switch(feature_status) {
				case(#feature_enabled) {
					let (eventName, payload) = switch (rec.txn_type) {
						case (#auction_bid(data)) { auction_bid(rec.token_id, data.sale_id) };
						case (#mint _) { mint() };
						case (#sale_ended _) { sale_ended() };
					};

					ignore Timer.setTimer(#seconds(0), func () : async () {
						let event = await* Droute.publish(state.state.droute,eventName, payload);
					});
				};
				case(#feature_disabled) {};
			};
		};

		func get_event(event_type: Text, metadata: CandyTypes.CandyValue): (Text, CandyTypes.CandyValue) {
			let event_name = events_namespace # "." # event_type;
			return (event_name, #Class([
				{name="canister"; value = #Principal(state.canister());immutable=true;},
				{name="type"; value = #Text(event_type); immutable=true;},
				{name="meta"; value = metadata; immutable=true;}
			]));
		};

		func auction_bid(token_id: Text, sale_id: Text): (Text, CandyTypes.CandyValue) {
			return get_event("auction_bid", #Class([
					{name="token_id"; value = #Text(token_id); immutable=true;},
					{name="sale_id"; value = #Text(sale_id); immutable=true;},
			]));
		};

		func mint(): (Text, CandyTypes.CandyValue) {
			return get_event("mint", #Class([]));
		};

		func sale_ended(): (Text, CandyTypes.CandyValue) {
			return get_event("sale_ended", #Class([]));
		};
	};

}
