=begin
  Constantly checks for work in the work queue. A worker
  manages its own thread for work.
=end

class DownloadWorker
  attr_accessor :start, :stop, :working

  # Start the worker
  # @param {DownloadManager} manager The worker's manager
  def initialize(manager)
    @manager = manager
    @running = true
    @working = false
    
    start
    
    @work_thread = Thread.new{do_work}
  end
  
  def start
    @running = true
    puts "[INFO: DMAN] #{self} started!"
  end
  
  def stop
    @running = false
    puts "[INFO: DMAN] #{self} stopped!"
  end
  
  def do_work
    # Check for work, otherwise sleep
    if @running && !@working && @manager.download_queue.length > 0
      work = @manager.download_queue.pop
      download_url(work[:image_url], work[:image_path])
    else
      sleep 1
    end
    
    do_work
  end
  
  # Download a single resource to disk
  # Currently overwrites duped files
  # @param {string} file_url The url to download
  # @param {string} save_location The path to save the file to
  def download_url(file_url, save_location)
    @working = true
    temp_ext = '.tmp'
    max_size = 1
    max_size_display = ''
    save_filename = File.basename(file_url)
    save_path = save_location + '/' + save_filename + temp_ext
    
    # Proc for determining expected file size
    content_proc = proc{ |total|
      if total && total > 0
        max_size = total
        max_size_display = "#{(total.to_f / 1000).round(0)}K"
      end
    }
    
    # Proc for handling transfer status
    progress_proc = proc{ |size|
      #puts "[INFO: DMAN] #{save_filename}: #{((size.to_f / max_size) * 100).round(0)}%"
    }
    
    # Open url and save to disk
    begin
      puts "[INFO: DMAN] #{self} starting download of #{file_url} to #{save_location}"
    
      errors = []
    
      # Mark url as downloading
      @manager.in_progress[file_url] = 1
      @manager.status_updated
      
      open(file_url, :content_length_proc => content_proc,
      :progress_proc => progress_proc) do |data|
        
        # Download as a temp file in case of error or connection loss so
        # user can know if a file is corrupted/unfinished
        begin
         
          File.open(save_path, 'wb') do |file| 
            file.write(data.read)
          end
        rescue Exception => msg
          # Handle file open/write/missing save directory error
          errors.push("[ERROR] File open exception: #{msg}")
        end
        
        # Rename temp file
        begin 
          File.rename(save_path, save_path.chomp(temp_ext))
        rescue Exception => msg
          # Handle rename error
          errors.push("[ERROR] File rename exception: #{msg}")
        end
      end 
    rescue Exception => msg
      # Handle 404
      errors.push("[ERROR] URL open exception: #{msg}")
    end
    
    # Unmark in progress download
    @manager.in_progress.delete(file_url)
    @manager.status_updated
    
    if errors.length > 0
      # Dump errors
      errors.each do |error|
        puts error
      end
    else
      # Download complete
      puts "[INFO: DMAN] Saved #{save_filename} (#{max_size_display}) to disk"
    end
    
    @working = false
  end
end