#!/bin/bash

if [ "$UID" != 0 ]; then
    echo -e "\e[91mThis script must be run as root.\e[0m" >&2
    exit 1
fi

if [ ! -f "theme.txt" ]; then
    echo -e "\e[91mThis script must be run from its own directory.\e[0m" >&2
    exit 1
fi

if [ -d "/boot/grub" ]; then
    GRUB="grub"
elif [ -d "/boot/grub2" ]; then
    GRUB="grub2"
else
    echo -e "\e[91mGRUB directory not found. Check GRUB is installed.\e[0m" >&2
    exit 1
fi

THEMES_DIR="/boot/${GRUB}/themes"
DEST_DIR="${THEMES_DIR}/grubby-terminal"
DEFAULTS_FILE="/etc/default/grub"

echo -e "\e[0m\nThis script will install the \e[92mGrubby Terminal\e[0m theme to ${DEST_DIR},"
echo -e "\e[91moverwriting\e[0m any conflicting files there without prompt.  It will edit the GRUB default"
echo -e "file (${DEFAULTS_FILE}) by \e[91mdeleting\e[0m any lines for GRUB_GFXMODE, GRUB_BACKGROUND, and"
echo -e "GRUB_THEME, and add its own.  You will need to manually run \e[92m${GRUB}-mkconfig\e[0m (or the"
echo -e "equivalent) as is appropriate for your distribution.\n"
echo -e "\e[96mYou may wish to make a backup copy of ${DEFAULTS_FILE} before running this script.\n\e[0m"
echo -e "You will need to enter a resolution that your firmware is capable of, for GRUB to use.  These"
echo -e "values must be whole numbers, larger than 700.\n"
echo -en "Would you like to continue ('\e[92my\e[0m' to continue, any other key to exit)? "

read RESPONSE

if [ "$RESPONSE" != 'y' ]; then
    echo
    exit 0
fi

while [ true ]; do
    echo -ne "\n\e[92mWidth: \e[0m"
    read RESOLUTION_WIDTH

    if [[ $RESOLUTION_WIDTH =~ ^[0-9]+$ ]] && [ $RESOLUTION_WIDTH -gt 700 ]; then
        break
    else
        echo -ne "\n\e[91mValue must be a whole number, larger than 700. \e[0m\n"
    fi
done

while [ true ]; do
    echo -ne "\n\e[92mHeight: \e[0m"
    read RESOLUTION_HEIGHT

    if [[ $RESOLUTION_HEIGHT =~ ^[0-9]+$ ]] && [ $RESOLUTION_HEIGHT -gt 700 ]; then
        break
    else
        echo -ne "\n\e[91mValue must be a whole number, larger than 700. \e[0m\n"
    fi
done

if [ ! -d $THEMES_DIR ]; then
    echo "Creating directory ${THEMES_DIR}"
    mkdir $THEMES_DIR
fi

if [ ! -d $DEST_DIR ]; then
    echo "Creating directory ${DEST_DIR}"
    mkdir $DEST_DIR
fi

echo -e "\n\e[92mCopying files to ${DEST_DIR}\e[0m"
cp -fv *\.png *\.pf2 $DEST_DIR

TERMINAL_X=$((( RESOLUTION_WIDTH - 700 ) / 2 ))
TERMINAL_Y=$((( RESOLUTION_HEIGHT - 700 ) / 2 ))

BOOT_MENU_X=$(( TERMINAL_X + 60 ))
BOOT_MENU_Y=$(( TERMINAL_Y + 316 ))

PROGRESS_BAR_X=$(( TERMINAL_X + 45 ))
PROGRESS_BAR_Y=$(( TERMINAL_Y + 611 ))

PROGRESS_LBL_X=$(( PROGRESS_BAR_X + 10 ))
PROGRESS_LBL_Y=$(( PROGRESS_BAR_Y + 2 ))

echo -e "\n\e[92mPreparing theme.txt\e[0m"

sed \
    -e "s/TERMINAL_X/$TERMINAL_X/" \
    -e "s/TERMINAL_Y/$TERMINAL_Y/" \
    -e "s/BOOT_MENU_X/$BOOT_MENU_X/" \
    -e "s/BOOT_MENU_Y/$BOOT_MENU_Y/" \
    -e "s/PROGRESS_BAR_X/$PROGRESS_BAR_X/" \
    -e "s/PROGRESS_BAR_Y/$PROGRESS_BAR_Y/" \
    -e "s/PROGRESS_LBL_X/$PROGRESS_LBL_X/" \
    -e "s/PROGRESS_LBL_Y/$PROGRESS_LBL_Y/" \
    theme.txt > "$DEST_DIR/theme.txt"

echo -e "\n\e[92mMaking changes to ${DEFAULTS_FILE}\e[0m"

sed \
    -e '/^GRUB_GFXMODE/d' \
    -e '/^GRUB_BACKGROUND/d' \
    -e '/^GRUB_THEME/d' \
    -i $DEFAULTS_FILE

RND=$(( RANDOM % 1000 ))
tac $DEFAULTS_FILE | sed -e '/[^[:blank:]]/,$!d' | tac > $DEFAULTS_FILE.tmp.$RND
mv $DEFAULTS_FILE.tmp.$RND $DEFAULTS_FILE

echo >> $DEFAULTS_FILE
echo -e "GRUB_GFXMODE=${RESOLUTION_WIDTH}x${RESOLUTION_HEIGHT}" >> $DEFAULTS_FILE
echo -e "GRUB_THEME=\"${DEST_DIR}/theme.txt\"" >> $DEFAULTS_FILE
echo >> $DEFAULTS_FILE

echo
echo -e "You now need to manually run \e[92m${GRUB}-mkconfig\e[0m (or the equivalent) as is"
echo -e "appropriate for your distribution.\n"
echo -e "Thanks for installing the \e[92mGrubby Terminal\e[0m theme."
echo -e "I hope it makes you smile each time you reboot! :D"
echo -e "    -- \e[96mPerthshireTim\e[0m\n"
