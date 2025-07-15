# Linux Server Update Telegram Notifier 

This is a simple and lightweight shell script designed to notify a specified Telegram chat about pending system updates (including security updates) and pending reboots on a Linux server. It's ideal for maintaining awareness of your server's health and update status without needing to log in constantly.

## Features

* Checks for available package updates (total and security-specific).
* Checks if a system reboot is required.
* Sends notifications to a Telegram chat via a bot.
* Prevents repetitive notifications by tracking update status changes.
* Securely handles sensitive information (bot token, chat ID) via environment variables.

**Important Note:** For simplicity and to keep the script lightweight, it does not explicitly check the success status of Telegram messages. Therefore, it is crucial to **test the script manually and thoroughly troubleshoot any issues** before setting up automation (e.g., via cron).

## Getting Started

Follow these steps to set up the Telegram Update Notifier on your Linux server.

### Prerequisites

* A Linux server (e.g., Ubuntu, Debian).
* `curl` installed (for sending Telegram messages).
* `apt-check` (usually part of `update-notifier-common` on Debian/Ubuntu-based systems).

### 1. Clone the Repository

First, clone this repository to your server:

```bash
git clone https://github.com/iedame/update-telegram-notifier.git
cd update-telegram-notifier
```
### 2. Set Up Your Telegram Bot

  #### 1. Create a new Telegram Bot:
  * Open Telegram and search for `@BotFather`.
  * Send the `/newbot` command to BotFather and follow the instructions to create your bot.
  * BotFather will give you a Bot Token (e.g., `123456789:ABCDEfGHIjKLMNOpQRStUvWXYz`). Keep this token secure!

  #### 2. Get your Chat ID:
  * Start a chat with your new bot.
  * To find your chat ID, you can send a message to your bot, then open your browser and go to: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
  * Replace `<YOUR_BOT_TOKEN>` with the token you just got from BotFather.
  * Look for the "`id`" field under "`chat`" in the JSON response. This is your `CHAT_ID`. It will be a string of numbers, possibly negative if it's a group chat.
  ### Another way to get your chat ID:
  Open the private channel, then:
  * on **web client**:
    * look at the URL in your browser:
    * if it's for example `https://web.telegram.org/#/im?p=c1192292378_2674311763110923980`
    * then `1192292378` is the channel ID
  * on **mobile and desktop**:
    * copy the link of any message of the channel:
    * if it's for example `https://t.me/c/1192292378/31`
    * then `1192292378` is the channel ID (bonus: `31` is the message ID)
  * on **Plus Messenger** for Android:
    * open the infos of the channel:
    * the channel ID appears above, right under its name
    * **WARNING** be sure to add `-100` prefix when using Telegram Bot API:
    * if the channel ID is for example `1192292378`, then you should use `-1001192292378`

### 3. Configure Environment Variables

For security, the bot token and chat ID are loaded from a `.env` file, which is not tracked by Git.
#### 1. Create a new file named `.env` in the root of your `update-telegram-notifier` directory:
```
cp .env.example .env
```
#### 2. Edit the newly created `.env` file and replace the placeholder values with your actual bot token and chat ID:
```
TELEGRAM_BOT_TOKEN="YOUR_NEW_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
```
It should look something like this:
```
TELEGRAM_BOT_TOKEN="123456789:AAHGFDSkjhgfdsfghjkLkjhgfds"
TELEGRAM_CHAT_ID="-1234567890"
```
### 4. Make the Script Executable
```
chmod +x update-telegram-notifier.sh
```
### 5. Test the Script (Optional but Recommended)

You can run the script manually to ensure it's working and sending notifications correctly:
```
./update-telegram-notifier.sh
```
Check your Telegram chat for messages from your bot.
### 6. Set up a Cron Job (Recommended for Automation)
To automate the notifications, you can set up a cron job to run the script regularly.
#### 1. Open your crontab for editing:
```
crontab -e
```
#### 2. Add a line to run the script at your desired interval. For example, to run it every 6 hours:
```
0 */6 * * * /path/to/your/update-telegram-notifier/update-telegram-notifier.sh >> /var/log/update_notifier.log 2>&1
```
Important: Replace `/path/to/your/update-telegram-notifier/` with the actual full path to your script (e.g., `/home/youruser/update-telegram-notifier/`).
This cron job will run the script, and its output (including the echo statements in the script) will be appended to `/var/log/update_notifier.log`. This log file can be helpful for debugging.

## Script Logic Explained
The script performs the following actions:
1. Loads Secrets: Reads `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` from the `.env` file. If `.env` is missing, it logs a warning and exits.
2. Checks Updates: Uses `/usr/lib/update-notifier/apt-check` to determine the number of pending regular and security updates.
3. Tracks State: Stores the current update count in a file (`$HOME/.update-check-status`). If the current state differs from the last recorded state, it flags that updates have changed. This prevents repeated "no updates" messages.
4. Checks Reboot Requirement: Detects the presence of `/var/run/reboot-required` to determine if a reboot is needed.
5. Sends Notifications:
  * If updates are available and the status has changed, it sends a message detailing the number of updates.
  * If a reboot is required, it sends a separate message.
  * All messages are sent using `curl` to the Telegram Bot API.

## Troubleshooting
* No Telegram messages received:
  * Double-check your `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in the `.env` file.
  * Ensure your bot is not blocked or stopped in Telegram.
  * Check the `/var/log/update_notifier.log` (if using cron) or run the script manually and observe its output for errors.
  * Verify `curl` is installed and functioning correctly.
* Script not running via `cron`:
  * Ensure the path in your `crontab` entry is correct and uses the `full absolute path` to the script.
  * Check `syslog` or `journalctl` for cron-related errors.
  * Make sure the script has `execute` permissions (`chmod +x update-telegram-notifier.sh`).
* Updates detected but no notification:
  * Check your `.update-check-status` file in your home directory. The script only sends a notification if the update count has changed since the last run.
 
## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
