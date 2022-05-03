module RequestInit = {
  type t = {
    body: string,
    headers: Js.Dict.t<string>,
    method: [#POST | #GET],
  }

  @obj
  external make: (
    ~body: string=?,
    ~headers: Js.Dict.t<string>=?,
    ~method: [#POST | #GET]=?,
    unit,
  ) => t = ""
}

type response

@send
external toJson: response => Js.Promise.t<Js.Json.t> = "json"

@val
external fetchOfURL: (~input: string, ~init: RequestInit.t=?, unit) => Js.Promise.t<response> =
  "fetch"
