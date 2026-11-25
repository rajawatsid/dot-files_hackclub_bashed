#!/bin/bash 
:'
# How will this work?
It should essentially move all the files that are in this repository (https://github.com/rajawatsid/dot-files_hackclub_bashed) to the users ~/.config directory
basic flowchart of how it should work:
    checks the location of where the user cloned the git repo -> checks if the user already has any files in the respective .config folder -> creates a backup of them in a new folder .config/[utc time]_config_backup/ (also ensuring that there is no former backup folder created in there) -> checks and installs any required dependencies -> moves the repos files and folders to their respective places -> gives a cute "tis done" prompt

maybe add colours or whatever later
'