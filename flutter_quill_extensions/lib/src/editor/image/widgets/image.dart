import 'dart:convert' show base64;
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:photo_view/photo_view.dart';

import '../../../common/utils/utils.dart';
import '../config/image_config.dart';
import '../image_embed_types.dart';

String getImageStyleString(QuillController controller) {
  final String? s = controller
      .getAllSelectionStyles()
      .firstWhere((s) => s.attributes.containsKey(Attribute.style.key),
          orElse: Style.new)
      .attributes[Attribute.style.key]
      ?.value;
  return s ?? '';
}

/// [imageProviderBuilder] To override the return value pass value to it
/// [imageSource] The source of the image in the quill delta json document
/// It could be http, file, network, asset, or base 64 image
ImageProvider getImageProviderByImageSource(
  String imageSource, {
  required ImageEmbedBuilderProviderBuilder? imageProviderBuilder,
  required BuildContext context,
}) {
  if (imageProviderBuilder != null) {
    final imageProvider = imageProviderBuilder(context, imageSource);
    if (imageProvider != null) {
      return imageProvider;
    }
  }

  if (isImageBase64(imageSource)) {
    return MemoryImage(base64.decode(imageSource));
  }

  if (isHttpUrl(imageSource)) {
    return NetworkImage(imageSource);
  }

  // File image
  if (kIsWeb) {
    return NetworkImage(imageSource);
  }
  return FileImage(File(imageSource));
}

Image getImageWidgetByImageSource(
  String imageSource, {
  required BuildContext context,
  required ImageEmbedBuilderProviderBuilder? imageProviderBuilder,
  required ImageErrorWidgetBuilder? imageErrorWidgetBuilder,
  required ImageEmbedBuilderLoadingWidgetBuilder? loadingBuilder,
  double? width,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
}) {
  return Image(
    image: getImageProviderByImageSource(
      context: context,
      imageSource,
      imageProviderBuilder: imageProviderBuilder,
    ),
    width: width,
    height: height,
    alignment: alignment,
    errorBuilder: imageErrorWidgetBuilder,
    loadingBuilder: loadingBuilder == null
        ? null
        : (context, child, loadingProgress) {
            return loadingBuilder(context, child, loadingProgress, imageSource);
          },
  );
}

String standardizeImageUrl(String url) {
  if (url.contains('base64')) {
    return url.split(',')[1];
  }
  return url;
}

const List<String> _imageFileExtensions = [
  '.jpeg',
  '.png',
  '.jpg',
  '.gif',
  '.webp',
  '.tif',
  '.heic'
];

/// This is a bug of Gallery Saver Package.
/// It can not save image that's filename does not end with it's file extension
/// like below.
// "https://firebasestorage.googleapis.com/v0/b/eventat-4ba96.appspot.com/o/2019-Metrology-Events.jpg?alt=media&token=bfc47032-5173-4b3f-86bb-9659f46b362a"
/// If imageUrl does not end with it's file extension,
/// file extension is added to image url for saving.
String appendFileExtensionToImageUrl(String url) {
  final endsWithImageFileExtension = _imageFileExtensions
      .firstWhere((s) => url.toLowerCase().endsWith(s), orElse: () => '');
  if (endsWithImageFileExtension.isNotEmpty) {
    return url;
  }

  final imageFileExtension = _imageFileExtensions
      .firstWhere((s) => url.toLowerCase().contains(s), orElse: () => '');

  return url + imageFileExtension;
}

class ImageTapWrapper extends StatelessWidget {
  const ImageTapWrapper({
    required this.imageUrl,
    required this.config,
    super.key,
  });

  final String imageUrl;
  final QuillEditorImageEmbedConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.sizeOf(context).height,
        ),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: getImageProviderByImageSource(
                context: context,
                imageUrl,
                imageProviderBuilder: config.imageProviderBuilder,
              ),
              errorBuilder: config.imageErrorWidgetBuilder,
              loadingBuilder: (context, event) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
            Positioned(
              right: 10,
              top: MediaQuery.paddingOf(context).top + 10.0,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[400],
                        size: 28,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
