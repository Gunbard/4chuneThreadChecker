=begin
  Download manager singleton
  Feed me urls and I will download them on separate (CPU) threads.
  I originally thought about having each ThreadItem manage this, but then
  I realized that 100 threads trying to download images all at the same
  time would probably piss off mootykins. Max 4 simultaneous downloads (4 threads).
  Author: Gunbard
=end

require 'open-uri'

class DownloadManager
  attr_accessor :update_image_urls, :images, :download_url

  def initialize
    # Thread image urls by thread
    # This is continously updated to contain ALL URLs for EVERY ADDED THREAD
    # meaning folders will be pretty much synced to the thread's images
    # {
    #   thread_url: 
    #   {
    #     dir: "/save directory"
    #     images: [list of image urls]
    #   }
    # }
    @thread_images = {}
    
    # List of urls that are currently downloading
    # This can be used to clean up failed temp files
    @in_progress = {}
  
    # Work queue with hashes similar to @thread_images
    @download_queue = Queue.new
    
    # Make pool of reusable threads (4)
    #4.times do
    #  threads << Thread.new do
    #    until @download_queue.empty?
    #      thread_to_download = @download_queue.pop(true) rescue nil
    #      if thread_to_download
    #        # do work
    #      end
    #    end
    #  end
    #end
    
  end

  # Adds list of urls to download manager's list for the given thread
  # @param {string} 
  def update_image_urls(thread_url, image_urls, save_dir)
    thread_info = 
    {
      dir: save_dir,
      images: image_urls
    }
    
    @thread_images[thread_url] = thread_info
  end
  
  def update_save_dir(thread_url, save_dir)
    if @thread_images[thread_url]
      @thread_images[thread_url].dir = save_dir
    end
  end
  
  # Debug
  def images
    puts @thread_images.inspect
  end
  
  # Download a single resource to disk
  # Currently overwrites duped files
  # @param {string} file_url The url to download
  # @param {string} save_location The path to save the file to
  def download_url(file_url, save_location)
    # Check if file is already downloading
    #if @in_progress[file_url]
    #  return
    #end
    
    temp_ext = '.tmp'
    max_size = 1
    max_size_display = ''
    #file_url = 'http://i.4cdn.org/jp/1405874412524.jpg'
    save_filename = File.basename(file_url)
    
    # Proc for determining expected file size
    content_proc = proc{ |total|
      if total && total > 0
        max_size = total
        max_size_display = "#{(total.to_f / 1000).round(0)}K"
      end
    }
    
    # Proc for handling transfer status
    progress_proc = proc{ |size|
      #puts "#{((size.to_f / max_size) * 100).round(0)}%"
    }
    
    # Open url and save to disk
    begin
      # Mark url as downloading
      @in_progress[file_url] = 1
      
      open(file_url, :content_length_proc => content_proc,
      :progress_proc => progress_proc) do |data|
        
        # Download as a temp file in case of error or connection loss so
        # user can know if a file is corrupted/unfinished
        begin
          File.open(save_location + '/' + save_filename + temp_ext, 'wb') do |file| 
            file.write(data.read)
          end
        rescue
          # Handle file open/write/missing save directory error
        end
        
        # Rename temp file
        begin 
          File.rename(save_location + '/' + save_filename + temp_ext, save_filename)
        rescue
          # Handle rename error
        end
      end 
    rescue
      # Handle 404
    end
    
    # Unmark in progress download
    @in_progress.delete(file_url)
    
    # Download complete
    puts "[INFO: DMAN] Saved #{save_filename} (#{max_size_display}) to disk"
  end
  
end