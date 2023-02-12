#!/bin/bash

# Read the Slack incoming webhook URL from a Github Actions secret
SLACK_WEBHOOK_URL=$(echo "${{ secrets.SLACK_WEBHOOK_URL }}")

# Read the list of URLs from the file
while read url || [ -n "$url" ]; do
  # Get the SSL expiration date
  expiration_date=$(echo | openssl s_client -servername "$(echo https://$url | awk -F/ '{print $3}')" -connect "$(echo https://$url | awk -F/ '{print $3}'):443" 2>/dev/null | openssl x509 -noout -enddate | cut -d'=' -f2)

  # Calculate the number of days until expiration
  expiration_in_seconds=$(date --date="$expiration_date" +%s)
  current_time_in_seconds=$(date +%s)
  days_until_expiration=$(( (expiration_in_seconds - current_time_in_seconds) / 60 / 60 / 24 ))

  # Check if the expiration date is less than 60 days away
  if [ $days_until_expiration -lt 60 ]; then
    # Send a notification to the Slack channel using an incoming webhook
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"The SSL certificate for $url will expire in $days_until_expiration days.\"}" $SLACK_WEBHOOK_URL
  fi
done < urls.txt
