#!/bin/bash
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "your-project-id")
BUCKET="true-ledger-archive-$PROJECT_ID"

echo "Creating immutable bucket: gs://$BUCKET"
gsutil mb -l US gs://$BUCKET 2>/dev/null || echo "Bucket exists"
gsutil versioning set on gs://$BUCKET
gsutil retention set 365 gs://$BUCKET  # Optional: 1-year retention

echo "✅ GCS archive ready"