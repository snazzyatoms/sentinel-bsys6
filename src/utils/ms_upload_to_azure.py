#!/usr/bin/env python3

from azure.storage.blob import BlobClient
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("upload_url", type=str)
parser.add_argument("file", type=str)
args = parser.parse_args()

blob_client = BlobClient.from_blob_url(args.upload_url)
with open(args.file, "rb") as data:
    blob_client.upload_blob(data, blob_type="BlockBlob", overwrite=True)
