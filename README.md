# ieee_oui_downloader

## What

Download the Ethernet MAC address database (which is a file) from the IEEE server that publishes it, compare it with an existing nmap(1) MAC address database (which is a file) and generate a new MAC address database for nmap containing any missing entries.

This is a modified version of a script by [Alain Kelder's](http://giantdorks.org/alain/), which can be found [here](http://giantdorks.org/alain/script-to-update-nmap-mac-prefixes-with-latest-entries-from-the-ieee-oui-database/).

## How

1. Start script with no arguments
2. Script will create a working directory in /tmp, cd to it, download the IEEE file, copy the local nmap file, compare these, generate a more complete file, then exit.
3. You have to copy the generated complete file to the correct nmap location.
4. If anything goes wrong after the download, you can restart the script while passing it the path to the working directory created earlier. It will then use the already downloaded file and not attempt to download again.
5. Cleanup of the working directory is left to you.

## License

The original script is licensed under [Creative Commons Attribution 3.0 United States License](http://creativecommons.org/licenses/by/3.0/us/), and thus so is the present modified script.
