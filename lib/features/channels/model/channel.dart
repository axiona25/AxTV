import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

@JsonSerializable()
class Channel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logo,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}

