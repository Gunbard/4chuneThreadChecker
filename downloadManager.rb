=begin
  Download manager singleton
  Feed me urls and I will download them on separate (CPU) threads.
  I originally thought about having each ThreadItem manage this, but then
  I realized that 100 threads trying to download images all at the same
  time would probably piss off mootykins. Max 4 simultaneous downloads (4 threads).
  Author: Gunbard
=end

class DownloadManager

  def initialize
  
  end
  
  
  # Download a single resource
  # TODO: Handle file name conflict
  # @param {string} url The url to download
  def download_url(url)
    
    # Create a temp file while downloading
    
    # Rename temp file when complete
  end
  
  
  #def execute_queue
  #  unless @queue.empty?
  #    Thread.new do
  #      until @queue.empty? || @save_dir.length == 0
  #        url = @queue.pop(false)
  #        puts url.inspect
  #      end
  #    end
  #  end
  #end
  
end