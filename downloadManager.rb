=begin
  Feed me urls and I will download them on separate (CPU) threads.
  Each ThreadItem should have one. If a download directory is set,
  this will automatically download images to that directory.
  Author: Gunbard
=end

class DownloadManager

  def initialize(save_dir)
    @queue = Queue.new      # The queue of urls to download
    @save_dir = save_dir    # A directory to save files in
    @progress_percent = 0   # Download progress
    @progress_current = 0
    @progress_total
  end
  
  # Adds urls to a queue for a thread
  # @param urls {array} Urls to download
  def queue_urls(urls)
    urls.each do |url|
      @queue << url
    end
    
    puts "Added #{urls.inspect} to queue for #{self}"
  end
  
  # Download a single resource
  # @param {string} url The url to download
  def download_url(url)
    # TODO: File name conflict
    
    # Create a temp file while downloading
    
    # Rename temp file when complete
  end
  
  
  def execute_queue
    unless @queue.empty?
      Thread.new do
        until @queue.empty? || @save_dir.length == 0
          url = @queue.pop(false)
          puts url.inspect
        end
      end
    end
  end
  
end