class PopupConfig {
  final String title;
  final String url;
  final String buttonText;
  final String buttonLink;
  final String description;
  final bool status;

  const PopupConfig({
    this.title = 'WallRio Update',
    this.url = '',
    this.buttonText = '',
    this.buttonLink = '',
    this.description = '',
    this.status = false,
  });

  factory PopupConfig.fromJson(Map<dynamic, dynamic> json) => PopupConfig(
        title: (json['title'] ?? 'WallRio Update').toString(),
        url: json['url']?.toString() ?? '',
        buttonText: (json['button text'] ?? json['button_text'] ?? '').toString(),
        buttonLink: (json['button link'] ?? json['button_link'] ?? '').toString(),
        description: json['description']?.toString() ?? '',
        status: json['status'] == true || json['status']?.toString().toLowerCase() == 'true',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'button text': buttonText,
        'button link': buttonLink,
        'description': description,
        'status': status,
      };
}
