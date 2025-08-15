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
import ballerina/test;

service on new http:Listener(9090) {
    resource function post retrieve/chunks(http:Request req) returns http:Response|error {
        // Mock the cunk service
        mime:Entity[] parts = check req.getBodyParts();
        string[] contents = from mime:Entity part in parts
            where part.getContentDisposition().fileName != ""
            select check part.getText();
        if contents.length() == 0 {
            return error("");
        }
        ai:Chunk[] chunks = check ai:chunkDocumentRecursively(contents.pop());
        int chunk_id = 0;
        string[] jsonParts = [];
        from ai:Chunk chunk in chunks
        do {
            chunk_id += 1;
            ChunkData chunkData = {chunk_id, content: chunk.content.toString(), metadata: chunk.metadata ?: {}};
            jsonParts.push(chunkData.toJsonString());
        };
        CompletionData completed = {total_chunks: chunk_id, message: "Chunking successful."};
        jsonParts.push(completed.toJsonString());

        http:Response response = new;
        check response.setContentType(APPLICATION_NDJSON);
        response.setTextPayload(string:'join("\n", ...jsonParts));
        return response;
    }
}

@test:Config
isolated function testChunker() returns error? {
    BinaryDataLoader loader = check new BinaryDataLoader("./tests/resources/sample.md");
    ai:Document|ai:Document[] doc = check loader.load();
    if doc is ai:Document[] {
        return error("An ai:Document is expected");
    }

    Chunker chunker = check new ("http://localhost:9090", "token");
    ai:Chunk[] chunks = check chunker.chunk(doc);
    test:assertEquals(chunks.length(), 25);
    test:assertEquals(chunks[0].metadata?.fileName, "sample.md");
}
