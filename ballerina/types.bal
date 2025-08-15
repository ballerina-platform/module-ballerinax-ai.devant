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

# Specifies the strategy to split text into chunks.
public enum ChunkStrategy {
    # Recursively split the text into smaller chunks.
    RECURSIVE = "recursive",
    # Split the text into sentence-level chunks.
    SENTENCE = "sentence",
    # Split the text into paragraph-level chunks.
    PARAGRAPH = "paragraph",
    # Split the text into character-level chunks.
    CHARACTER = "character"
}

// Constants related to devant form data and response handling.
const APPLICATION_NDJSON = "application/x-ndjson";
const FORM_DATA = "form-data";
const FILE = "file";
const INDEX = "index";
const CHUNK_TYPE = "chunk_type";
const MAX_CHUNK_SIZE = "max_chunk_size";
const OVERLAP = "overlap";

// Represents the data structures of ndjson responses from the Devant AI service.
type ChunkData record {|
    int chunk_id;
    string content;
    map<json> metadata;
|};

type CompletionData record {|
    "completed" status = "completed";
    int total_chunks;
    string message;
|};

type ErrorData record {|
    "error" status = "error";
    string 'error;
    string message;
    int chunks_processed;
|};
