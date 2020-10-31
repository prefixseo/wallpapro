class Wallpaper {
  String smallUrl;
  String regularUrl;
  String highUrl;
  String likes;
  String attribution;
  String description;

  Wallpaper(
      {this.smallUrl,
      this.regularUrl,
      this.highUrl,
      this.likes,
      this.attribution,
      this.description});

  factory Wallpaper.fromJson(Map<String, dynamic> json) => Wallpaper(
    smallUrl: json["urls"]["small"],
    regularUrl: json["urls"]["regular"],
    highUrl: json["urls"]["full"],
    likes: json["likes"].toString(),
    attribution: json["user"]["username"],
    description: json["alt_description"]
  );
}
