import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

@JsonSerializable()
class Channel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String? license; // Per canali Rai: "rai-akamai", per LA7: "clearkey"
  final String? region; // Regione geografica del canale (paese/area)
  final String? category; // Categoria del canale (News, Sports, Entertainment, ecc.)

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logo,
    this.license,
    this.region,
    this.category,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}

