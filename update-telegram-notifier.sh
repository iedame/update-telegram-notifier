#!/bin/bash

# --- Start Logging ---
# Log the execution timestamp
echo "--- Update / Reboot Telegram Notifier Script started at $(date) ---"

# Load environment variables from .env if it exists
if [ -f ".env" ]; then
    source .env
    echo "Acquired bot token and chat ID from .env file"
else
    echo "No .env file with bot token and chat ID found, you will not receive Telegram notification!"
fi

IFS=';' read updates security_updates < <(/usr/lib/update-notifier/apt-check 2>&1)
# Log the raw output from apt-check
echo "apt-check raw output: $updates;$security_updates"

HOSTNAME=`/usr/bin/hostname`
# Telegram Bot Token acquired from botfather
BOT_TOKEN=$TELEGRAM_BOT_TOKEN
# Telegram Numeric ID of the chat to send notifications
CHAT_ID=$TELEGRAM_CHAT_ID

if [ ! -f "$HOME/.update-check-status" ] ; then
    /bin/echo "0:0" > $HOME/.update-check-status
	# Log if status file was created
    echo ".update-check-status file created."
fi

CONTROL="$updates:$security_updates"
HASCHANGED=false
ACTUALSTATE=`/bin/cat $HOME/.update-check-status`

echo "Current status (from apt-check): $CONTROL"
echo "Previous status (from file): $ACTUALSTATE"

if [ "$ACTUALSTATE" != "$CONTROL" ]; then
    HASCHANGED=true
    /bin/echo $CONTROL > $HOME/.update-check-status
	# Log that the status has changed
    echo "Update status changed. Stored new status: $CONTROL"
else
	# Log that status has not changed
    echo "Update status has not changed."
fi

function send_message {
    /usr/bin/curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$1" -d parse_mode="markdown" > /dev/null
	# Log that a message was attempted to be sent
    echo "Telegram message attempt: '$1'"
}

if [ $updates -gt 0 ] || [ $security_updates -gt 0 ] ; then
	echo "Updates detected: Regular=$updates, Security=$security_updates"
    if $HASCHANGED; then
        send_message "There are *$updates* updates available for *$HOSTNAME* and *$security_updates* of them are security updates"
	else
        echo "Not sending update notification (status not changed)."
    fi
else
    echo "No updates available."
fi

if [ -f /var/run/reboot-required ]; then
    echo "Reboot required file detected."
    send_message "Reboot needed on *$HOSTNAME*"
else
    echo "No reboot required."
fi

# --- End Logging ---
echo "--- Update / Reboot Telegram Notifier Script finished at $(date) ---"
echo "" # Add an empty line for better readability between runs in the log file
