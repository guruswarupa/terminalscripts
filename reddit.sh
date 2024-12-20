#!/bin/sh

# Check if necessary programs are installed
for prog in jq sxiv; do
	[ ! "$(which "$prog")" ] && echo "Please install $prog!" && exit 1
done
# If notify-send is not installed, use echo as notifier
[ ! "$(which notify-send)" ] && notifier="echo" || notifier="notify-send"

# args
while [ $# -gt 0 ]; do
	case $1 in
		-l|--limit)
			shift
			LIMIT=$1
			case $LIMIT in
				''|*[!0-9]*)
					echo 'limit is NaN'
					exit 1
			esac
			shift
			;;
		-f|--filter)
			FILTER=1
			shift
			;;
		-k|--keep)
			KEEP=1
			shift
			;;
		-v|--verbose)
			VERBOSE=1
			shift
			;;
		*)
			subreddit=$1
			shift
			;;
	esac
done

# Set default values if variables are unset
VERBOSE=${VERBOSE:-0}
FILTER=${FILTER:-0}
KEEP=${KEEP:-0}

# Default config directory
configdir="${XDG_CONFIG_HOME:-$HOME/.config}/reddit"

# Create .config/reddit if it does not exist to prevent
# the program from not functioning properly
[ ! -d "$configdir" ] && echo "Directory $configdir does not exist, creating..." && mkdir -p "$configdir"

# Default subreddit that will be inserted in "subreddit.txt"
# if it does not exist
defaultsub="linuxmemes"

# If subreddit.txt does not exist, create it to prevent
# the program from not functioning properly
[ ! -f "$configdir/subreddit.txt" ] && echo "$defaultsub" >> "$configdir/subreddit.txt"

# Read and number subreddits from subreddit.txt
subreddits=()
counter=1
while IFS= read -r line; do
	subreddits+=("$counter $line")
	counter=$((counter + 1))
done < "$configdir/subreddit.txt"

# Add an option for custom subreddit
subreddits+=("0 Custom Subreddit")

# Ask the user to select a subreddit
echo "Select a subreddit from the list (or 0 for custom):"
for subreddit in "${subreddits[@]}"; do
	echo "$subreddit"
done

# Read the user's choice
read -p "Enter number (0 for custom subreddit): " choice

# If the user chooses 0, prompt for a custom subreddit
if [ "$choice" -eq 0 ]; then
	read -p "Enter custom subreddit: " subreddit

	# Ask if the user wants to add the custom subreddit to the list
	read -p "Do you want to add this subreddit to the list? (y/n): " add_to_list
	if [ "$add_to_list" = "y" ]; then
		# Add the custom subreddit to the subreddit.txt
		echo "$subreddit" >> "$configdir/subreddit.txt"
		echo "Subreddit added to the list."
	fi

else
	# Select the subreddit based on the user's choice
	subreddit=$(echo "${subreddits[$choice-1]}" | awk '{print $2}')
fi

# If no subreddit was chosen, exit
[ -z "$subreddit" ] && echo "No subreddit chosen" && exit 1

# Default directory used to store the feed file and fetched images
cachedir="/tmp/reddit"

# If cachedir does not exist, create it
if [ ! -d "$cachedir" ]; then
	echo "$cachedir does not exist, creating..."
	mkdir -p "$cachedir"
fi

# Send a notification if VERBOSE is set to 1
if [ "$VERBOSE" -eq 1 ]; then
	$notifier "Reddit" "📩 Downloading your 🖼️ Memes"
fi

# Download the subreddit feed, containing only the
# first 100 entries (limit), and store it inside
# cachedir/tmp.json
curl -H "User-agent: 'your bot 0.1'" "https://www.reddit.com/r/$subreddit/hot.json?limit=${LIMIT:-100}" > "$cachedir/tmp.json"

# Create a list of images
imgs=$(jq '.' < "$cachedir/tmp.json" | grep url_overridden_by_dest | grep -Eo "http(s|)://.*(jpg|png)\b" | sort -u)

# If there are no images, exit
[ -z "$imgs" ] && $notifier "Reddit" "Sadly, there are no images for subreddit $subreddit, please try again later!" && exit 1

# Download images to $cachedir
for img in $imgs; do
	if [ ! -e "$cachedir/${img##*/}" ]; then
		wget -P "$cachedir" $img
	fi
done

# Send a notification if VERBOSE is set to 1
if [ "$VERBOSE" -eq 1 ]; then
	$notifier "Reddit" "👍 Download Finished, Enjoy! 😊"
fi
rm "$cachedir/tmp.json"

# Display the images
if [ "$FILTER" -eq 1 ]; then
	sxiv -a -o "$cachedir"
else
	sxiv -a "$cachedir"
fi

# Once finished, remove all of the cached images unless KEEP is set to 1
if [ "$KEEP" -ne 1 ]; then
	rm "${cachedir:?}"/*
fi
