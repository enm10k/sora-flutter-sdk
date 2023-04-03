#!/bin/bash

# environment.dart を生成する
# USAGE: create_env.sh OUTFILE URL_CANDIDATES CHANNEL_ID METADATA
# EX) ./create_env.sh environment.dart url1,url2,url3 sora "{'signaling_key': '12345'}"

FLUTTER_VERSION=$(echo $(flutter --version) | awk '/Flutter[[:space:]]+[[:digit:]]+/ {print $2}')

OUTFILE=$1
URLS=$2
CHANNEL_ID=$3
METADATA=$4

# ファイルを空にする
: > $OUTFILE

echo "Generate $OUTFILE"
cat << EOT >> $OUTFILE
class Environment {
  static const String flutterVersion = '$FLUTTER_VERSION';

  static final List<Uri> urlCandidates = [
EOT

IFS=',' read -ra items <<< "$URLS"
for item in "${items[@]}"; do
    echo "    Uri.parse('$item')," >> $OUTFILE
done

cat << EOT >> $OUTFILE
  ];

  static const String channelId = '$CHANNEL_ID';

  static const dynamic signalingMetadata = "$METADATA";
}
EOT