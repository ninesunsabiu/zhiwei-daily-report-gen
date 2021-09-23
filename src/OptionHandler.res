let corsHeaders = [
  ("Access-Control-Allow-Origin", "*"),
  ("Access-Control-Allow-Methods", "POST,OPTIONS"),
  ("Access-Control-Max-Age", "86400"),
  ("Access-Control-Allow-Headers", "Content-Type"),
]

@genType
let handleRequest: RequestHandler.handleRequest = request => {
  let headers = request.headers
  let (originKey, reqHeadersKey, reqMethodKey) = (
    "Origin",
    "Access-Control-Request-Headers",
    "Access-Control-Request-Method",
  )
  let requestCorsHeader = (
    originKey->Request.getHeader(headers, _),
    reqHeadersKey->Request.getHeader(headers, _),
    reqMethodKey->Request.getHeader(headers, _),
  )
  let newHeaders = switch requestCorsHeader {
  | (Some(origin), Some(requestHeader), Some(_)) => {
      let headerDict = Js.Dict.fromArray(corsHeaders)

      [
        ("Access-Control-Allow-Origin", origin),
        ("Access-Control-Allow-Headers", requestHeader),
      ]->Js.Array2.forEach(((key, value)) => {
        Js.Dict.set(headerDict, key, value)
      })

      headerDict
    }
  | _ => Js.Dict.fromArray([("Allow", "POST, OPTIONS")])
  }

  {headers: newHeaders, status: Some(200), statusText: Some("ok")}
  ->Response.make(~init=_, ())
  ->Js.Promise.resolve
}
