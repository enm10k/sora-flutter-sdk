param (
    [string]$OutputPath,
    [string]$UrlCandidates,
    [string]$ChannelId,
    [string]$Metadata
)

$flutterVersion = (flutter --version).Split(" ")[1]

$urlsArray = $UrlCandidates.Split(',')

$dartCode = @"
class Environment {
  static const String flutterVersion = '$flutterVersion';

  static final List<Uri> urlCandidates = [
$(@($urlsArray.ForEach({"    Uri.parse('$_'),"})) -join "`n")
  ];

  static const String channelId = '$ChannelId';

  static const dynamic signalingMetadata = $Metadata;
}
"@

Set-Content -Path $OutputPath -Value $dartCode
