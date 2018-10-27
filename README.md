# ieee_oui_downloader

## Status

- Old but serviceable!
- 2018-10-27: The script passes [ShellCheck](https://www.shellcheck.net/)

## What

Download the Ethernet MAC address database (which is a file) from the IEEE server that publishes it, compare it with an existing `nmap` MAC address database (which is a file) and generate a new `nmap` MAC address database containing any entries missing in the existing one.

This is a modified version of a script by [Alain Kelder's](http://giantdorks.org/alain/), which can be found [here](http://giantdorks.org/alain/script-to-update-nmap-mac-prefixes-with-latest-entries-from-the-ieee-oui-database/).

## How

1. Start script with no arguments
2. Script will create a working directory underneath `/tmp`, `cd` to it, download the IEEE file using `curl`, copy the local nmap file to the working directory, compare the IEEE file to the original nmap file, generate a new complete file for nmap with any missing entries found in the IEEE file added, then exit.
3. You have to copy the generated completed file to the correct nmap location manually.
4. If anything goes wrong after the download, you can restart the script while passing it the path to the working directory created in the previous run. It will then use the already downloaded IEEE file and not attempt to download it again.
5. Cleanup of the working directory is left to you and your command line skills.

## License

The original script is licensed under [Creative Commons Attribution 3.0 United States License](http://creativecommons.org/licenses/by/3.0/us/), and thus so is the present modified script.
