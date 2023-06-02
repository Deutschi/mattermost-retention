#!/bin/bash

# based on https://github.com/aljazceru/mattermost-retention

# configure vars

DB_USER="mmuser"
DB_NAME="mattermost"
DB_PASS="PASSWORD"
DB_HOST="127.0.0.1"
RETENTION="180"		# retention in days for posts
RETENTION2="7"		# retention in days for user-deleted posts
DATA_PATH="/mattermost/data/"

# calculate epoch in milisec
delete_before=$(date  --date="$RETENTION day ago"  "+%s%3N")
delete_before2=$(date  --date="$RETENTION2 day ago"  "+%s%3N")

echo $(date  --date="$RETENTION day ago")

echo ""
echo ""
echo "cleanup database"
echo ""

# remove old posts that are neither pinned nor saved, based on primary retention
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="DELETE FROM Posts WHERE CreateAt < $delete_before AND IsPinned = 0 AND NOT EXISTS (SELECT * FROM Preferences WHERE Category = 'flagged_post' AND Name = Posts.Id);"

# remove user-deleted posts based on secondary retention2
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="DELETE FROM Posts WHERE CreateAt < $delete_before2 AND DeleteAt > 0;"

# remove old jobs that were successful
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="DELETE FROM Jobs WHERE Status = 'success' AND CreateAt < $delete_before AND StartAt < $delete_before AND LastActivityAt < $delete_before;"

# get list of orphaned files to be removed
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="SELECT Path FROM FileInfo AS fi LEFT JOIN Posts AS p ON fi.PostId = p.Id WHERE p.Id IS NULL OR fi.PostId = '';" > /tmp/mattermost-paths.list
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="SELECT ThumbnailPath FROM FileInfo AS fi LEFT JOIN Posts AS p ON fi.PostId = p.Id WHERE p.Id IS NULL OR fi.PostId = '';" >> /tmp/mattermost-paths.list
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="SELECT PreviewPath FROM FileInfo AS fi LEFT JOIN Posts AS p ON fi.PostId = p.Id WHERE p.Id IS NULL OR fi.PostId = '';" >> /tmp/mattermost-paths.list

# remove orphaned files from db
mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="DELETE fi FROM FileInfo AS fi LEFT JOIN Posts AS p ON fi.PostId = p.Id WHERE p.Id IS NULL OR fi.PostId = '';"

echo ""
echo ""
echo "cleanup filesystem"
echo ""

# delete files from file system
while read -r fp; do
        if [ -n "$fp" ]; then
                echo "$DATA_PATH""$fp"
                shred -u "$DATA_PATH""$fp"
        fi
done < /tmp/mattermost-paths.list

# cleanup after yourself
rm /tmp/mattermost-paths.list

# cleanup empty data dirs
find $DATA_PATH -type d -empty -delete

exit 0
