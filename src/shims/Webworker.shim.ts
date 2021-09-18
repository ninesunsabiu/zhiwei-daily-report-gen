export type RescriptResponse = Response;
export type ReRequest = Request;

export type BodyData = {
    fields: Array<{
        flag: string;
        value: string | Array<{ name: string }>;
    }>;
}