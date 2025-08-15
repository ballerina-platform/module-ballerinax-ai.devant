// Copyright (c) 2025 WSO2 LLC (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/ai;
import ballerina/http;
import ballerina/mime;

# Splits documents loaded by the `devant:BinaryDataLoader` into smaller chunks 
# using the Devant AI service.
public isolated class Chunker {
    *ai:Chunker;
    private final http:Client devantEp;
    private final int maxChunkSize;
    private final int maxOverlapSize;
    private final ChunkStrategy strategy;

    # Initializes a new `Chunker` instance.
    #
    # + serviceUrl - The base URL of the Devant AI service endpoint
    # + accessToken - The access token used to authenticate API requests
    # + maxChunkSize - The maximum number of characters allowed per chunk
    # + maxOverlapSize - The maximum number of characters to reuse from the end of the previous
    # chunk when creating the next one
    # + strategy - The strategy to use for chunking the document
    # + connectionConfig - Additional HTTP connection configurations
    # + return - `nil` on success, or a `devant:Error` if the initialization fails
    public isolated function init(@display {label: "Service URL"} string serviceUrl,
            @display {label: "Access Token"} string accessToken,
            @display {label: "Maximum Chunk Size in Characters"} int maxChunkSize = 500,
            @display {label: "Maximum Overlap Size in Characters"} int maxOverlapSize = 50,
            @display {label: "Chunking Strategy"} ChunkStrategy strategy = RECURSIVE,
            @display {label: "Connection Configuration"} *ai:ConnectionConfig connectionConfig) returns ai:Error? {
        http:ClientConfiguration httpConfig = {
            ...connectionConfig,
            auth: {
                token: accessToken
            }
        };

        http:Client|error devantEp = new (serviceUrl, httpConfig);
        if devantEp is error {
            return error(string `failed to initialize the client: ${devantEp.message()}`, devantEp);
        }
        self.devantEp = devantEp;
        self.maxChunkSize = maxChunkSize;
        self.maxOverlapSize = maxOverlapSize;
        self.strategy = strategy;
    }

    # Chunks the provided document.
    # + document - The input document to be chunked
    # + return - An array of chunks, or an `ai:Error` if the chunking fails
    public isolated function chunk(ai:Document document) returns ai:Chunk[]|ai:Error {
        check self.validateDocument(document);
        do {
            // Safe cast: already validated document is ai:BinaryDocument above
            http:Request request = self.prepareRequest(<ai:BinaryDocument>document);
            http:Response response = check self.devantEp->/retrieve/chunks.post(request);
            string ndJson = check readResponseAsString(response);
            ai:Chunk[] chunks = check parseChunks(ndJson);
            return from ai:Chunk chunk in chunks
                select inheritMetadataFromDocument(chunk, document);
        } on fail error e {
            return error(string `failed to retrieve chunks: ${e.message()}`, e);
        }
    }

    private isolated function validateDocument(ai:Document document) returns ai:Error? {
        if document !is ai:BinaryDocument {
            return error("only binary documents are supported for chunking with devant services. " +
            "Use `devant:BinaryDataloader` to load the document in expected format");
        }
        if document.metadata?.fileName is () {
            return error("the document must have a file name in its metadata to perform chunking");
        }
    }

    private isolated function prepareRequest(ai:BinaryDocument document) returns http:Request {
        mime:Entity fileEntity = createFileEntity(document, document.metadata?.fileName ?: "unknown_file_name");
        mime:Entity chunkTypeEntity = createFormEntity(CHUNK_TYPE, self.strategy);
        mime:Entity chunkSizeEntity = createFormEntity(MAX_CHUNK_SIZE, self.maxChunkSize.toString());
        mime:Entity overlapEntity = createFormEntity(OVERLAP, self.maxOverlapSize.toString());

        http:Request request = new;
        request.setBodyParts([fileEntity, chunkTypeEntity, chunkSizeEntity, overlapEntity], mime:MULTIPART_FORM_DATA);
        return request;
    }
}
