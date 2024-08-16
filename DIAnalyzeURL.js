"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DIAnalyzeUrl = void 0;
const functions_1 = require("@azure/functions");
const dotenv = require("dotenv");
const ai_document_intelligence_1 = require("@azure-rest/ai-document-intelligence");
const di = require("../di");
dotenv.config();
async function DIAnalyzeUrl(request, context) {
    var _a, _b;
    context.log(`${context.functionName}: function processed request for url "${request.url}"`);
    const client = await di.DIClient;
    var documentJsonUrl, documentJsonPages, documentJsonModelId, documentJsonMode, documentJsonResultId, documentJsonAdfWebActivity;
    try {
        const documentJson = await request.json();
        documentJsonUrl = documentJson["documentUrl"];
        documentJsonPages = documentJson["documentPages"];
        documentJsonModelId = documentJson["modelId"];
        documentJsonMode = documentJson["mode"];
        documentJsonResultId = documentJson["resultId"];
        documentJsonAdfWebActivity = documentJson["adfWebActivity"];
    }
    catch (error) {
        context.log(`${context.functionName}: ${request.url}: Empty or bad json payload.  Using query parameters for documentUrl or processing async retry request`);
    }
    try {
        const documentUrl = documentJsonUrl || request.query.get("documentUrl");
        const documentPages = documentJsonPages || request.query.get("documentPages");
        const modelId = documentJsonModelId || request.query.get("modelId") || "prebuilt-layout";
        const mode = documentJsonMode || request.query.get("mode") || "sync";
        const resultId = documentJsonResultId || request.query.get("resultId");
        const adfWebActivity = documentJsonAdfWebActivity || request.query.get("adfWebActivity") || "false";
        context.log(`${context.functionName}: Calling model with: (documentUrl: ${documentUrl}, 
      documentPages: ${documentPages}, modelId: ${modelId}, mode: ${mode}, 
      resultId: ${resultId}, adfWebActivity: ${adfWebActivity}`);
        var initialResponse;
        if (resultId) {
            initialResponse = await client.path("/documentModels/{modelId}/analyzeResults/{resultId}", "customModel", resultId).get();
            if ((0, ai_document_intelligence_1.isUnexpected)(initialResponse)) {
                throw initialResponse.body.error;
            }
        }
        else {
            initialResponse = await client
                .path("/documentModels/{modelId}:analyze", modelId)
                .post({
                contentType: "application/json",
                body: {
                    //urlSource: "https://raw.githubusercontent.com/Azure/azure-sdk-for-js/main/sdk/formrecognizer/ai-form-recognizer/assets/forms/Invoice_1.pdf",
                    urlSource: documentUrl
                },
                queryParameters: {
                    pages: documentPages
                }
            });
            if ((0, ai_document_intelligence_1.isUnexpected)(initialResponse)) {
                throw initialResponse.body.error;
            }
        }
        var result;
        //var responseHeaders = initialResponse.headers;
        var responseHeaders = {};
        if (mode === "async" || resultId) {
            context.info(`${context.functionName}: Asyc response status: ${documentUrl || resultId}: Request ${request.url} Status ${initialResponse.status}`);
            //the adf webacitivity appears to follow the async protocol differently than document intelligence implementation.  It seems to expext to receive a 202 for each async request until completion.  Need to investigate further.
            //It also appears to ignore the operation-location header
            //if result id is passed in use it.  otherwise extract from DI response
            responseHeaders["Retry-After"] = initialResponse.headers["Retry-After"] || initialResponse.headers["retry-after"];
            var responseResultId = resultId;
            if (initialResponse.headers["Operation-Location"] || initialResponse.headers["operation-location"]) {
                const diOperationLocation = new URL(initialResponse.headers["Operation-Location"] || initialResponse.headers["operation-location"]);
                const resultIdExtracted = ((_b = (_a = diOperationLocation === null || diOperationLocation === void 0 ? void 0 : diOperationLocation.pathname) === null || _a === void 0 ? void 0 : _a.split("/")) === null || _b === void 0 ? void 0 : _b.at(-1)) || resultId;
                responseResultId = resultIdExtracted || responseResultId;
            }
            const diProxyOperationLocationUrl = new URL(request.url);
            diProxyOperationLocationUrl.searchParams.set("resultId", responseResultId);
            //const diProxyOperationHeaders = initialResponse.headers;
            //const diProxyOperationHeaders = {}
            var responseStatus = parseInt(initialResponse.status);
            // if (adfWebActivity === "true") {
            //   //some articles online indicate that the adf web activity requires a 202 status and a Location header rather than 200 status with retry-after and operation-location header
            //   responseHeaders["Location"] = diProxyOperationLocationUrl.href;
            //   //responseHeaders["Retry-After"] = responseHeaders["Retry-After"] || "5";
            //   status = 202;  
            // }
            //diProxyOperationHeaders["operation-location"] = diProxyOperationLocationUrl.href;
            //const diProxyAsyncBody = initialResponse.body;
            context.info(`${context.functionName}: Asyc response: ${documentUrl || resultId}: Request ${request.url} Operation-Location ${diProxyOperationLocationUrl.href}`);
            //Cannot pass a non-empty body with a 202
            // diProxyAsyncBody["operation-location"] = "diProxyOperationLocationUrl.href";
            // diProxyAsyncBody["status"] = parseInt(initialResponse.status);
            // diProxyAsyncBody["resultId"] = resultId;
            // diProxyAsyncBody["requestUrl"] = request.url;
            //some articles online indicate that the adf web activity requires a 202 status and a Location header rather than 200 status with retry-after and operation-location header
            if (initialResponse.status === "202" || (adfWebActivity === "true" && (initialResponse.headers["retry-after"] || initialResponse.headers["Retry-After"]))) {
                responseStatus = 202;
            }
            else {
                //if we are no longer in the 202 polling cycle make sure to remove the adfWebActivity query param from the location url
                diProxyOperationLocationUrl.searchParams.delete("adfWebActivity");
            }
            //Going to always include the location headers even though these are not needed when there is a 200 with retry-after for most use cases.  these are needed for ADF
            // responseHeaders["Operation-Location"] = diProxyOperationLocationUrl.href;  //this appears to be proper case for the header but function converts to lower case somewhere in the pipeline
            // responseHeaders["Location"] = diProxyOperationLocationUrl.href;
            //context.info(`${context.functionName}: Asyc response: ${documentUrl || resultId}: Request ${request.url}  Async Response headers ${JSON.stringify(responseHeaders)} Async Response status: ${responseStatus}`);
            if (responseStatus == 202 || adfWebActivity === "true") {
                //delete responseHeaders["Content-Length"];
                //delete responseHeaders["content-type"];
                responseHeaders["Operation-Location"] = diProxyOperationLocationUrl.href; //this appears to be proper case for the header but function converts to lower case somewhere in the pipeline
                responseHeaders["Location"] = diProxyOperationLocationUrl.href;
                if (adfWebActivity === "true") {
                    responseHeaders["Retry-After"] = responseHeaders["Retry-After"] || 1;
                }
                context.info(`${context.functionName}: Asyc response: ${documentUrl || resultId}: Request ${request.url}  Async Response headers ${JSON.stringify(responseHeaders)} Async Response status: ${responseStatus}`);
                return {
                    //status: parseInt(initialResponse.status),
                    status: responseStatus,
                    headers: responseHeaders
                };
            }
            else {
                result = initialResponse.body;
            }
        }
        else {
            const poller = (0, ai_document_intelligence_1.getLongRunningPoller)(client, initialResponse);
            (await poller).onProgress((state) => { context.info(`${context.functionName}: Analyze status: ${documentUrl}: ${state.status}`); });
            result = (await (await poller).pollUntilDone()).body;
            //responseHeaders = (await (await poller).pollUntilDone()).headers;
        }
        const analyzeResult = result === null || result === void 0 ? void 0 : result.analyzeResult;
        const pages = analyzeResult === null || analyzeResult === void 0 ? void 0 : analyzeResult.pages;
        if (!pages || pages.length <= 0) {
            context.log(`DILayoutUrl: ${documentUrl}: No pages were extracted from the document.`);
        }
        else {
            context.log(`DILayoutUrl: ${documentUrl}: Extracted page count: ${pages.length}`);
        }
        context.info(`${context.functionName}: Response: ${documentUrl || resultId}: Request ${request.url}  Response headers ${JSON.stringify(responseHeaders)} Async Response status: ${responseStatus}`);
        return {
            headers: responseHeaders,
            jsonBody: {
                status: result === null || result === void 0 ? void 0 : result.status,
                lastUpdatedDateTime: (result === null || result === void 0 ? void 0 : result.lastUpdatedDateTime) || new Date().toISOString(),
                createdDateTime: (result === null || result === void 0 ? void 0 : result.createdDateTime) || new Date().toISOString(),
                error: result === null || result === void 0 ? void 0 : result.error,
                analyzeResult
            }
        };
    }
    catch (error) {
        context.log(`${context.functionName}:  Error while requesting for analyze result: ${JSON.stringify(error)}`);
        return {
            status: 500,
            jsonBody: error
        };
    }
}
exports.DIAnalyzeUrl = DIAnalyzeUrl;
functions_1.app.http('DIAnalyzeUrl', {
    methods: ['GET', 'POST'],
    authLevel: 'function',
    handler: DIAnalyzeUrl
});
//# sourceMappingURL=DIAnalyzeUrl.js.map