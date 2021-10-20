# Mattermost data cleanup/retention
Based on https://github.com/aljazceru/mattermost-retention

This script adds retention functionality for the free version of Mattermost. It cleans up posts and attachments based on age. Pinned and saved posts and their attachments are not deleted.

Tested with Mattermost Database Schema Version: 5.38.0 (mysql)
