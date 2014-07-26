=begin
  Download manager singleton
  Feed me urls and I will download them on separate (CPU) threads.
  I originally thought about having each ThreadItem manage this, but then
  I realized that 100 threads trying to download images all at the same
  time would probably piss off mootykins. Max 4 simultaneous downloads (4 threads).
  Author: Gunbard
=end

require 'open-uri'
require_relative 'downloadWorker'

MAX_WORKERS = 4

class DownloadManager
  attr_accessor :update_image_urls, :images, :in_progress, :download_queue, :process_threads, :status_updated

  def initialize
    # Thread image urls by thread
    # This is continously updated to contain ALL URLs for EVERY ADDED THREAD
    # meaning folders will be pretty much synced to the thread's images
    # {
    #   thread_url: 
    #   {
    #     dir: "/save directory"
    #     images: [list of image urls]
    #     dirty: bool for whether or not thread has new images
    #   }
    # }
    @thread_images = {}
    
    # List of urls that are currently downloading
    # This can be used to clean up failed temp files
    @in_progress = {}
  
    # Work queue with hashes similar to @thread_images
    @download_queue = Queue.new
    
    # List of DownloadWorkers
    @workers = []
    
    create_workers
  end

  # Adds list of urls to download manager's list for the given thread
  # @param {string} thread_url The url of the thread, used as a key
  # @param {array} image_urls An array of image urls
  # @param {string} save_dir Path to save images to
  def update_image_urls(thread_url, image_urls, save_dir)
    thread_info = {
      dir: save_dir,
      images: image_urls,
      dirty: true
    }
    
    @thread_images[thread_url] = thread_info
  end
  
  # Goes through the thread url list and adds non-downloaded image urls
  # to the work queue
  def process_threads
    @thread_images.each do |key, value|
      if value[:dirty]
        value[:images].each do |image|
          if !value[:dir] || value[:dir].length == 0
            # Skip if save directory not set
            next
          end
        
          file_path = value[:dir] + '/' + File.basename(image)
          if @in_progress[image] || File.exists?(file_path)
            # Skip if already downloading/downloaded
            next
          end
          
          value[:dirty] = false
          
          work_data = {
            image_url: image,
            image_path: value[:dir]
          }
          
          # Add to queue
          @download_queue.push(work_data)
        end
      end
      
     status_updated
    end
  end
  
  # Creates workers to do werk
  def create_workers
    MAX_WORKERS.times do
      @workers.push(DownloadWorker.new(self))
    end
  end
  
  # Called whenever downloader status is changed
  def status_updated
    display_text = 'Idle'
    
    if @download_queue.length > 0
      display_text = "#{@download_queue.length} LEFT"
    end
    
    $autoDL_status_label['textvariable'].value = display_text
  end
end