import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:grw_laser/services/directories.dart';

class ImageUtils {
  static const String TEMP_FOLDER_NAME = "temp_folder_img_conversion";

  static Future<File?> optimizeImageForUpload(
      {required File file,
      required int maxSize,
      required String suffix}) async {
    try {
      // Leggi i bytes
      final bytes = await file.readAsBytes();

      // Prova a decodificare l'immagine
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        print('Il file non è un\'immagine valida.');
        return null;
      }

      // Ridimensionamento se necessario
      int width = image.width;
      int height = image.height;
      int longestSide = width > height ? width : height;

      if (longestSide > maxSize) {
        int newWidth = width;
        int newHeight = height;

        if (width > height) {
          if (width > maxSize) {
            newWidth = maxSize;
            newHeight = (height * (maxSize / width)).round();
          }
        } else {
          if (height > maxSize) {
            newHeight = maxSize;
            newWidth = (width * (maxSize / height)).round();
          }
        }
        image = img.copyResize(image, width: newWidth, height: newHeight);
      }

      // Sempre salviamo come JPEG
      final jpegBytes = img.encodeJpg(image, quality: 90);

      // Recupera la directory temporanea

      // Crea la sotto-cartella "temp_folder_img_conversion"
      final customDir =
          Directory(p.join(Directories.tempPath, TEMP_FOLDER_NAME));
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }

      // Scrive il file JPEG nella sotto-cartella
      final fileName = '${suffix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newFilePath = p.join(customDir.path, fileName);
      final newFile = File(newFilePath);
      await newFile.writeAsBytes(jpegBytes);

      return newFile;
    } catch (e) {
      print('Errore nel processare il file immagine: $e');
      return null;
    }
  }

  static Future<void> clearConvertedImagesFolder() async {
    try {
      final customDirPath = p.join(Directories.tempPath, TEMP_FOLDER_NAME);
      final customDir = Directory(customDirPath);

      if (await customDir.exists()) {
        final files = customDir.listSync();

        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Errore durante la pulizia della cartella: $e');
    }
  }
}
