# Mattermost data cleanup/retention
Based on https://github.com/aljazceru/mattermost-retention

This script adds retention functionality for the free version of Mattermost. In contrast to the original script, which simply deleted posts and attachments by their respective age, pinned and saved posts and their attachments are not deleted here. I also introduced a second retention setting for user-deleted posts, so they can be removed from the database earlier.

Tested with Mattermost Server Version: 7.8.0 (mysql)
