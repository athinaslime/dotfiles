TARGET_FILE="/usr/share/X11/xkb/symbols/capslock"
TIMESTAMP=$(date +%F_%H-%M-%S)
BACKUP_FILE="${TARGET_FILE}.bak.${TIMESTAMP}"

if [ "$EUID" -ne 0 ]; then
  echo "this script must be ran as root."
  exit 1
fi

echo "starting to fix caps lock delay"

echo "creating backup at: $BACKUP_FILE"
cp "$TARGET_FILE" "$BACKUP_FILE"

export NEW_BLOCK='// This changes the <CAPS> key to become a Control modifier,// but it will still produce the Caps_Lock keysym.
hidden partial modifier_keys
xkb_symbols "ctrl_modifier" {
    key <CAPS> {
        type="ALPHABETIC",
        repeat=No,
        symbols[Group1]= [ Caps_Lock, Caps_Lock ],
        actions[Group1]= [ LockMods(modifiers=Lock),
                           LockMods(modifiers=Shift+Lock,affect=unlock) ]
    };
};'

perl -i -0777 -pe 's/hidden partial modifier_keys\s+xkb_symbols "ctrl_modifier" \{.*?\};/$ENV{NEW_BLOCK}/s' "$TARGET_FILE"

if [ $? -eq 0 ]; then
  echo "file patched."
else
  echo "failed to patch file."
  exit 1
fi

echo "clearing xkb cache."
rm -rf /var/lib/xkb/*.xkm
