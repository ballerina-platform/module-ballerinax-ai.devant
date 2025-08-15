# Ballerina AI Devant Module

## Overview

The `ai.devant` module provides APIs to interact with [Devant by WSO2](https://wso2.com/devant/), enabling document chunking and loading documents from a directory in the format expected by the Devant Chunker. It integrates seamlessly with the [`ballerina/ai`](https://central.ballerina.io/ballerina/ai/latest) module to provide a smooth workflow for processing AI documents using Devant AI services.

## Prerequisites

Before using this module in your Ballerina application, ensure you have the following:

- A valid Devant AI service URL
- An access token to authenticate with the Devant platform

## Quickstart

To use the `ai.devant` module in your Ballerina application, follow these steps:

### Step 1: Import the module

```ballerina
import ballerinax/ai.devant;
```

### Step 2: Load the document

```ballerina
devant:BinaryDataLoader loader = check new ("./sample.pdf");
ai:Document|ai:Document[] docs = check loader.load();
```

### Step 3: Chunk the documents using the Devant service

```ballerina
devant:Chunker chunker = new (serviceUrl, accessToken);
if docs is ai:Document {
    ai:Chunk[] chunks = check chunker.chunk(docs);
}
```
