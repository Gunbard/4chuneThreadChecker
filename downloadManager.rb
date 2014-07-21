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
    # {
    #   thread_url: [list of image urls]
    # }
    @thread_images = {}
  
    # Make pool of reusable threads (4)
  end

  # Adds list of urls to download manager's list for the given thread
  # @param {ThreadItem} The thread to update urls from
  def update_image_urls(thread)
    @thread_images[thread.url] = thread.image_urls
  end
  
  def images
    puts @thread_images.inspect
  end
  
  # Download a single resource to disk
  # @param {string} file_url The url to download
  def download_url(file_url)
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
      open(file_url, :content_length_proc => content_proc,
      :progress_proc => progress_proc) do |data|
        # Download as a temp file in case of error or connection loss
        begin
          File.open(save_filename + temp_ext, 'wb') do |file| 
            file.write(data.read)
          end
        rescue
          # Handle file open/write error
        end
        
        # Rename temp file
        begin 
          File.rename(save_filename + temp_ext, save_filename)
        rescue
          # Handle rename error
        end
      end 
    rescue
      # Handle 404
    end
    
    # Download complete
    puts "Saved #{save_filename} (#{max_size_display}) to disk"
  end
  
end