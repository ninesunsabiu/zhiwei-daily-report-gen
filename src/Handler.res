type response 
@new external ofResponse: Js.Nullable.t<string> => response = "Response";

type request
@send external toJson: (request) => Js.Promise.t<Js.Json.t> = "json";

let handleRequest = req => {
    open Promise
    let promiseJsonBody = req->toJson

    promiseJsonBody
    ->thenResolve(
        body => {
            switch body->Js.Json.classify {
                | Js.Json.JSONArray(value) => value 
                | _ => [] 
            }
        }
    )
    ->thenResolve(
        (val) => {
            val
                ->Js.Array2.joinWith(",")
                ->Js.Nullable.return
                ->ofResponse
        }
    )
}