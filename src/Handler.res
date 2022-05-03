module Error = {
  @new
  external make: 'a => exn = "Error"

  let toPromise = str => {
    try {
      raise(str->make)
    } catch {
    | _ as error => Promise.reject(error)
    }
  }
}

let mapToDecodeErrorPromise = err => {
  err->Jzon.DecodingError.toString->Error.toPromise
}

module type Codecs = {}

module ErrorPromiseCodecs = (M: Codecs) => {
  let mapToDecodeErrorPromise = err => {
    err->Jzon.DecodingError.toString->Error.toPromise
  }
}

module CommitListResCodecs = {
  type committer = {email: string}
  type commit = {
    shortMessage: string,
    committer: committer,
  }
  type response = {commits: array<commit>}
  type body = {response: response}

  open Jzon

  let committerCodecs = object1(
    ({email}) => email,
    email => {email: email}->Ok,
    field("Email", string),
  )

  let commitCodecs = object2(
    ({shortMessage, committer}) => (shortMessage, committer),
    ((shortMessage, commiter)) => {shortMessage: shortMessage, committer: commiter}->Ok,
    field("ShortMessage", string),
    field("Commiter", committerCodecs),
  )

  let body = object1(
    ({response}) => response,
    response => {response: response}->Ok,
    field(
      "Response",
      object1(
        ({commits}) => commits,
        commits => {commits: commits}->Ok,
        field("Commits", array(commitCodecs)),
      ),
    ),
  )
}

module ValueUnitListResCodecs = {
  type valueUnit = {
    id: string,
    name: string,
    displayCode: string,
    currentStatusName: string,
  }
  type resultValue = array<valueUnit>
  type body = {resultValue: resultValue}

  open Jzon

  let valueUnitCodecs = object4(
    ({id, name, displayCode, currentStatusName}) => (id, name, displayCode, currentStatusName),
    ((id, name, displayCode, currentStatusName)) =>
      {id: id, name: name, displayCode: displayCode, currentStatusName: currentStatusName}->Ok,
    field("id", string),
    field("name", string),
    field("displayCode", string),
    field("currentStatusName", string),
  )

  let body = object1(
    ({resultValue}) => resultValue,
    resultValue => {resultValue: resultValue}->Ok,
    field("resultValue", array(valueUnitCodecs)),
  )
}

let handleRequest: RequestHandler.handleRequest = req => {
  open Promise

  let searchParams = req.url->URL.make->URL.getSearchParams

  let resultOfFetchCommitsReqInit = {
    open Belt

    {
      open URL.SearchParams
      let p = (getParam(searchParams, ~key="startDate"), getParam(searchParams, ~key="endDate"))
      switch p {
      | (Some(start), Some(end)) => Ok(start, end)
      | _ => Error(`请求参数不完整`)
      }
    }
    ->Result.map(((start, end)) => {
      let makeCommitQueryPayload = (~startDate: string, ~endDate: string) => {
        {
          "Action": "DescribeGitCommits",
          "DepotId": 8968222,
          "PageNumber": 1,
          "PageSize": 200,
          "Ref": "scrum",
          "StartDate": startDate,
          "EndDate": endDate,
        }
      }
      makeCommitQueryPayload(~startDate=start, ~endDate=end)
    })
    ->Result.flatMap(payload => {
      open Js.Json
      stringifyAny(payload)->Belt.Option.mapWithDefault(Error(`转换为请求体失败`), it => Ok(
        it,
      ))
    })
    ->Result.map(payload => {
      open Js.Dict
      open Fetch
      RequestInit.make(
        ~method=#POST,
        ~body=payload,
        ~headers=fromArray([
          ("Authorization", `token ${GVar.token}`),
          ("Accept", "application/json"),
        ]),
        (),
      )
    })
  }

  let promiseOfFetchCommits = {
    switch resultOfFetchCommitsReqInit {
    | Ok(init) => {
        open Fetch
        init->fetchOfURL(~input="https://e.coding.net/open-api", ~init=_, ())
      }
    | Error(message) => message->Error.toPromise
    }
  }

  promiseOfFetchCommits
  ->then(Fetch.toJson)
  ->thenResolve(Jzon.decodeWith(_, CommitListResCodecs.body))
  ->then(it => {
    switch it {
    | Ok(ret) => ret.response.commits->resolve
    | Error(err) => {
        // 尝试一下 Module Function
        module T = ErrorPromiseCodecs(CommitListResCodecs)
        let {mapToDecodeErrorPromise} = module(T)
        err->mapToDecodeErrorPromise
      }
    }
  })
  ->thenResolve({
    let user = searchParams->URL.SearchParams.getParam(~key="user")
    switch user {
    | Some(i) => Js.Array2.filter(_, it => Js.String2.startsWith(it.committer.email, i))
    | None => _ => []
    }
  })
  ->thenResolve(Js.Array2.map(_, it => it.shortMessage))
  ->thenResolve(commits =>
    commits
    ->Js.Array2.map(it => {
      let codeRe = %re("/^#(?<code>\d+)\s/")
      switch Js.Re.exec_(codeRe, it) {
      | Some(r) => {
          let result = Js.Re.captures(r)->Js.Array.unsafe_get(1)
          Js.Nullable.toOption(result)
        }
      | None => None
      }
    })
    ->Js.Array2.reduceRight((acc, it) => {
      switch it {
      | Some(code) =>
        if Belt.List.has(acc, code, (a, b) => a == b) {
          acc
        } else {
          list{code, ...acc}
        }
      | _ => acc
      }
    }, list{})
  )
  ->then(codeList => {
    open Js
    open Fetch
    let codeArray = codeList->Belt.List.toArray
    let payload = {"codes": codeArray, "orgId": "771ac1a5-fca5-4af2-b744-27b16e989b18"}
    fetchOfURL(
      ~input="https://tkb.agilean.cn/openapi/api/v1/value-units/filter?by=code",
      ~init=RequestInit.make(
        ~method=#POST,
        ~headers=Dict.fromArray([("Content-Type", "application/json")]),
        ~body=Json.stringifyAny(payload)->Belt.Option.getWithDefault(""),
        (),
      ),
      (),
    )
  })
  ->then(Fetch.toJson)
  ->thenResolve(Jzon.decodeWith(_, ValueUnitListResCodecs.body))
  ->then(it => {
    switch it {
    | Ok(ret) => ret.resultValue->resolve
    | Error(err) => err->mapToDecodeErrorPromise
    }
  })
  ->thenResolve(
    Js.Array2.mapi(_, ({name, displayCode, currentStatusName}, idx) => {
      `${(idx + 1)
          ->Js.Int.toString}. #${displayCode} ${name} 卡片状态: 「${currentStatusName}」`
    }),
  )
  ->thenResolve(workArray => {
    open Js
    let origin = req.headers->Request.getHeader("Origin")->Belt.Option.getWithDefault("*")
    let headers = Dict.fromArray([
      ("Access-Control-Allow-Origin", origin),
      ("Content-Type", "application/json"),
    ])
    Response.make(
      ~body=Json.stringify(
        Json.object_(
          Dict.fromArray([
            ("result", 0.->Json.number),
            ("resultValue", workArray->Json.stringArray),
          ]),
        ),
      ),
      ~init={headers: headers, status: Some(200), statusText: Some("ok")},
      (),
    )
  })
  ->catch(error => {
    let fallbackMsg = `未知错误`
    let message = switch error->Js.Exn.asJsExn {
    | Some(exn) => Belt.Option.getWithDefault(exn->Js.Exn.message, fallbackMsg)
    | _ => fallbackMsg
    }
    Response.make(
      ~body=message,
      ~init={headers: Js.Dict.empty(), status: Some(500), statusText: None},
      (),
    )->resolve
  })
}
