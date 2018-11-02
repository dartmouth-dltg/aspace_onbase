require 'tempfile'

class FileBuffer

  def initialize
    @tempfile = Tempfile.new("filebuffer")
  end

  def <<(chunk)
    @tempfile << chunk
    @tempfile.flush
  end

  def each
    @tempfile.rewind

    while true
      chunk = ""
      len = @tempfile.read(4096, chunk)
      break if len.nil?

      yield(chunk)
    end

    @tempfile.close
  ensure
    File.unlink(@tempfile.path)
  end

end


