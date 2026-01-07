import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

@JsonSerializable()
class Channel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String? license; // Per canali Rai: "rai-akamai", per LA7: "clearkey"

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logo,
    this.license,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}

