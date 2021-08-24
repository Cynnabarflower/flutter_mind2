import 'package:flutter/services.dart';

class MyParser {
  int b = 1;
  int c = 0;
  int d = 0;
  int e = 0;
  int f = 0;
  late ByteData gBuffer;
  int h = 0;

  Function callback;

  MyParser(Function this.callback) {
    this.gBuffer = new ByteData(256);
    this.b = 1;
  }

  int parse(ByteData var1, int var2) {
    int   var3 = 0;
    if (var2 > var1.lengthInBytes) {
      return -3;
    } else {
      for (int var4 = 0; var4 < var2; ++var4) {
        this.h = var1.getInt8(var4);
        switch (this.b) {
          case 1:
            if ((this.h & 255) == 170) {
              this.b = 2;
            }
            break;
          case 2:
            if ((this.h & 255) == 170) {
              this.b = 3;
            } else {
              this.b = 1;
            }
            break;
          case 3:
            this.c = this.h & 255;
            this.d = 0;
            this.e = 0;
            this.b = 4;
            break;
          case 4:
            this.gBuffer.setInt8(this.d++, this.h);
            this.e += this.h & 255;
            if (this.d >= this.c) {
              this.b = 5;
            }
            break;
          case 5:
            this.f = this.h & 255;
            this.b = 1;
            if (this.f == (~this.e & 255)) {
              var3 = 1;
              MyParser var5 = this;
              int var6 = 0;

              while (var6 < var5.c) {
                while (var5.gBuffer.getInt8(var6) == 85) {
                  ++var6;
                }

                int var7;
                int var8;
                if ((var7 = var5.gBuffer.getInt8(var6++) & 255) > 127) {
                  var8 = var5.gBuffer.getInt8(var6++) & 255;
                } else {
                  var8 = 1;
                }

                if (var7 == 128) {
                  if (var8 == 2) {
                    int var10 = var5.gBuffer.getInt8(var6);
                    int var9 = var5.gBuffer.getInt8(var6 + 1);
                    var7 = var10 & 255;
                    int var12 = var9 & 255;
                    if ((var7 = var7 << 8 | var12) > 32768) {
                      var7 -= 65536;
                    }

                    this.callback(128, var7);

                  }
                  var6 += var8;
                } else {
                  switch (var7) {
                    case 2:
                      var7 = var5.gBuffer.getInt8(var6) & 255;
                      var6 += var8;
                      callback(2, var7);
                      break;
                    case 3:
                      var7 = var5.gBuffer.getInt8(var6) & 255;
                      var6 += var8;
                      callback(3, var7);
                      break;
                    case 4:
                      var7 = var5.gBuffer.getInt8(var6) & 255;
                      var6 += var8;
                      callback(4, var7);
                      break;
                    case 5:
                      var7 = var5.gBuffer.getInt8(var6) & 255;
                      var6 += var8;
                     callback(5, var7);
                      break;
                    case 131:
                      print('power');
                      // EEGPower var11;
                      // if ((var11 = new EEGPower(var5.gBuffer, var6, var8)).isValidate()) {
                      // if (var5.streamHandler != null) {
                      // var5.streamHandler.onDataReceived(131, 0, var11);
                      // }
                      // } else {
                      // Log.e("Parser", "EEGPower object is invalidate, start is: " + var6 + " length is: " + var8);
                      // }

                      var6 += var8;
                      break;
                    case 132:
                      if (var8 == 5) {
                        var6 += var8;
                      }
                      break;
                    case 133:
                      if (var8 == 3) {
                        var6 += var8;
                      }
                  }
                }
              }

              var5.b = 1;
            } else {
              // if (this.streamHandler != null) {
              //
              //   this.streamHandler.onChecksumFail(this.gBuffer, this.c, this.f);
              // }

              var3 = -2;
              // print('Checksum error!');
              // TgStreamReader.streamHandler(this.streamReader, "Parser", "CheckSum ERROR!!!!!");
            }
        }
      }

      return var3;
    }
  }
}