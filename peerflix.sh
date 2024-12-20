#!/bin/bash

# Function to enter the magnet link
function enter_magnet_link() {
    read -p "Enter the magnet link: " magnet_link
    if [[ -z "$magnet_link" ]]; then
        echo "Magnet link cannot be empty!"
        enter_magnet_link
    fi
}

# Function to configure Peerflix options
function configure_options() {
    # Set the default values
    connections=100
    port=8888
    player=""

    # Ask for the number of connections
    read -p "Enter max connected peers (default: 100): " input_connections
    connections=${input_connections:-$connections}

    # Ask for the HTTP port
    read -p "Enter HTTP port (default: 8888): " input_port
    port=${input_port:-$port}

    # Ask for player choice
    echo "Select a player:"
    echo "1) VLC"
    echo "2) MPlayer"
    echo "3) SMPlayer"
    echo "4) MPV"
    echo "5) OMX"
    echo "6) Webplay"
    echo "7) Airplay"
    read -p "Enter your choice (1-7): " player_choice

    case $player_choice in
        1) player="--vlc" ;;
        2) player="--mplayer" ;;
        3) player="--smplayer" ;;
        4) player="--mpv" ;;
        5) player="--omx" ;;
        6) player="--webplay" ;;
        7) player="--airplay" ;;
        *) player="" ;;
    esac

    # Execute peerflix with the selected options
    run_peerflix
}

# Function to run the Peerflix command
function run_peerflix() {
    # Run the peerflix command with the configured options
    echo "Running Peerflix with the following options:"
    echo "Magnet Link: $magnet_link"
    echo "Max Peers: $connections"
    echo "Port: $port"
    echo "Player: $player"

    # Example command to run peerflix (assuming peerflix is installed and in PATH)
    peerflix "$magnet_link" --connections "$connections" --port "$port" $player
}

# Main entry point
enter_magnet_link
configure_options
