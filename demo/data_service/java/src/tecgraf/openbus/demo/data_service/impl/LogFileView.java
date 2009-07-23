package tecgraf.openbus.demo.data_service.impl;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;

import tecgraf.openbus.file_system.ILogFileViewHelper;
import tecgraf.openbus.file_system.ILogFileViewPOA;

public class LogFileView extends ILogFileViewPOA {

  private byte[] key;
  private File file;

  public LogFileView() {
    this.file = null;
    this.key = new byte[0];
  }

  public LogFileView(String path, byte[] key) {
    this.file = new File(path);
    this.key = key;
  }

  @Override
  public String getLastLine() {
    try {
      RandomAccessFile ranFile = new RandomAccessFile(file, "rw");
      char c = '?';
      long pos;
      for (pos = file.length() - 2; (c != '\n') && (c != '\r'); pos--) {
        ranFile.seek(pos);
        c = (char) ranFile.read();
      }
      ranFile.seek(pos + 1);
      String line = ranFile.readLine();
      ranFile.close();
      return line;
    }
    catch (FileNotFoundException e) {
      e.printStackTrace();
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return "";
  }

  @Override
  public void deactivate(){
    return;
  }

  @Override
  public String getInterfaceName() {
    return ILogFileViewHelper.id();
  }

  @Override
  public byte[] getKey() {
    return key;
  }

}
