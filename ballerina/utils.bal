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
import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/mime;

isolated function createFileEntity(ai:BinaryDocument document, string fileName) returns mime:Entity {
    mime:Entity entity = new;
    entity.setByteArray(document.content);
    mime:ContentDisposition disposition = getContentDispositionForFormData(FILE);
    disposition.fileName = fileName;
    entity.setContentDisposition(disposition);

    return entity;
}

isolated function createFormEntity(string name, string value) returns mime:Entity {
    mime:Entity entity = new;
    entity.setBody(value);
    entity.setContentDisposition(getContentDispositionForFormData(name));
    return entity;
}

isolated function getContentDispositionForFormData(string partName) returns mime:ContentDisposition {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.disposition = FORM_DATA;
    contentDisposition.name = partName;
    return contentDisposition;
}

isolated function readResponseAsString(http:Response response) returns string|Error {
    if response.getContentType() != APPLICATION_NDJSON {
        return error(string `unexpected content type '${response.getContentType()}', expected 'application/x-ndjson'.`);
    }

    do {
        byte[] allBytes = [];
        stream<byte[], io:Error?> byteStream = check response.getByteStream();
        check from byte[] bytes in byteStream
            do {
                allBytes.push(...bytes);
            };
        return check string:fromBytes(allBytes); // Returns a newline-delimited JSON (NDJSON) string
    } on fail error e {
        return error("unable to read response", e);
    }
}

isolated function parseChunks(string ndjsonString) returns ai:Chunk[]|ai:Error {
    string[] chunkStrings = re `\n`.split(ndjsonString);
    ai:TextChunk[] textChunks = [];
    foreach string chunkStr in chunkStrings {
        ChunkData|CompletionData|ErrorData|error data = chunkStr.fromJsonStringWithType();
        if data is error {
            return error(string `failed to process chunk: ${data.message()}`);
        }
        if data is ErrorData {
            return error(string `failed to process chunk: ${data.'error}`, detail = data);
        }
        if data is CompletionData {
            break;
        }

        ai:Metadata metadata = {...data.metadata};
        metadata[INDEX] = data.chunk_id;
        textChunks.push({content: data.content, metadata});
    }
    return textChunks;
}

isolated function inheritMetadataFromDocument(ai:Chunk chunk, ai:Document document) returns ai:Chunk {
    ai:Metadata? chunkMetadata = chunk.metadata;
    ai:Metadata? documentMetadata = document.metadata;
    if documentMetadata is () || chunkMetadata is () {
        return chunk;
    }
    ai:Metadata merged = {...chunkMetadata};
    string[] keys = documentMetadata.keys();
    foreach string key in keys {
        if !merged.hasKey(key) {
            merged[key] = documentMetadata[key];
        }
    }
    chunk.metadata = merged;
    return chunk;
}

isolated function createDocument(string filePath) returns ai:BinaryDocument|Error {
    do {
        string fileName = check file:basename(filePath);
        file:MetaData meta = check file:getMetaData(filePath);
        byte[] content = check io:fileReadBytes(filePath);

        ai:Metadata metadata = {fileName, modifiedAt: meta.modifiedTime, fileSize: <decimal>meta.size};
        return {content, metadata};
    } on fail error e {
        return error(string `failed to create binary document from file '${filePath}': ${e.message()}`, e);
    }
}
