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

# Loads documents as `ai:BinaryDocument` instances from a specified file or directory path.
# This loader can handle either a single file or a directory containing multiple files.
# Typically used in conjunction with `devant:Chunker` to split documents into chunks for processing.
public isolated class BinaryDataLoader {
    *ai:DataLoader;
    private final string path;

    # Creates a new `BinaryDataLoader` instance.
    # + path - The file or directory path to load documents from
    # + return - `nil` on success, or an `ai:Error` if the initialization fails
    public isolated function init(string path) returns ai:Error? {
        do {
            boolean pathExist = check file:test(path, file:EXISTS);
            if !pathExist {
                return error(string `the specified path '${path}' does not exist.`);
            }
            self.path = check file:getAbsolutePath(path);
        } on fail error e {
            return error(string `failed to initialize data loader: ${e.message()}`, e);
        }
    }

    # Loads documents from the specified path.
    #
    # + return - An array of `ai:Document` instances if the path is a directory,
    # or a single `ai:Document` if the path is a file.
    # Returns an `ai:Error` if the path is invalid or loading fails.
    public isolated function load() returns ai:Document[]|ai:Document|ai:Error {
        do {
            if !check file:test(self.path, file:IS_DIR) {
                return check createDocument(self.path);
            }
            file:MetaData[] entries = check file:readDir(self.path);
            // filter first-level regular files and map to documents
            return from file:MetaData entry in entries
                where !entry.dir
                select check createDocument(entry.absPath);
        } on fail error e {
            return error(string `failed to load files: ${e.message()}`, e);
        }
    }
}
