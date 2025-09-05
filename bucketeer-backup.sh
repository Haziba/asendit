# ----- settings -----
APP=secret-dusk-43871
BACKUP_DIR=./bucketeer-backup
mkdir -p "$BACKUP_DIR"

# Function to sync a single Bucketeer set by prefix (e.g., BUCKETEER or BUCKETEER_GRAY)
sync_bucketeer () {
  PREFIX="$1"            # BUCKETEER or BUCKETEER_GRAY
  echo "==> Backing up $PREFIX for app $APP"

  # Pull creds & bucket from Heroku config
  export AWS_ACCESS_KEY_ID=$(heroku config:get ${PREFIX}_AWS_ACCESS_KEY_ID -a "$APP")
  export AWS_SECRET_ACCESS_KEY=$(heroku config:get ${PREFIX}_AWS_SECRET_ACCESS_KEY -a "$APP")
  export AWS_DEFAULT_REGION=$(heroku config:get ${PREFIX}_AWS_REGION -a "$APP")
  BUCKET=$(heroku config:get ${PREFIX}_BUCKET_NAME -a "$APP")

  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ] || [ -z "$BUCKET" ]; then
    echo "!! Missing one or more config vars for $PREFIX. Skipping."
    return
  fi

  DEST="$BACKUP_DIR/$PREFIX"
  mkdir -p "$DEST"

  echo "-- Bucket: $BUCKET (region: $AWS_DEFAULT_REGION)"
  echo "-- Listing (summary):"
  aws s3 ls "s3://$BUCKET" --recursive --human-readable --summarize || {
    echo "!! List failed for $PREFIX ($BUCKET). Check creds/region."; return 1;
  }

  echo "-- Syncing to $DEST ..."
  aws s3 sync "s3://$BUCKET" "$DEST" || {
    echo "!! Sync failed for $PREFIX ($BUCKET)."; return 1;
  }

  echo "-- Verifying local copy:"
  find "$DEST" -type f | wc -l
  du -sh "$DEST"
  echo ""
}

# Avoid any existing AWS profile interfering
unset AWS_PROFILE

# Back up both buckets (the second will be skipped if not present)
sync_bucketeer BUCKETEER
sync_bucketeer BUCKETEER_GRAY

echo "All done. Backups are in: $BACKUP_DIR"
