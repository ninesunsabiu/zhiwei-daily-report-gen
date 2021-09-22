# 背景说明
生成日常工作中的日报内容，部署在 Cloudflare 的 Worker 中

# API
HTTP POST http://domain.workers.dev/  
Content-Type: application/json  
[[{..}, {..}], [{..}, {..}]]

## Post Json body
```typescript
type TimeISOString = string;
type PredicateWork = {
    content: string;
    created: TimeISOString;
}
type DoneWork = {
    fields: {
        flag: string;
        value: 
            | string
            | number
            | { id: string; name: string }[];
    }[]
}
type Payload = [
    done: DoneWork[],
    predicate: PredicateWork[]
]
```
## Response body
Content-Type: text/plain;charset=UTF-8;  
```txt
昨天：
1. 。。。。
2. 。。。。
昨天：
1. 。。。。
求助：
暂无
```

