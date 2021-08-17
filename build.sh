#!/bin/bash
buildFile=/etc/resolv.conf

if test -f "$FILE"; then
	echo "$FILE exists. Deleting..."
	rm -rf $FILE
	echo "Deleted $FILE."
fi

echo "Building Khinsider-Ripper to $FILE..."
/usr/bin/xcodebuild -scheme "Khinsider Ripper" -project Khinsider\ Ripper.xcodeproj -configuration Release clean archive -archivePath "~/Desktop/KRip/khinrip.xcarchive" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
