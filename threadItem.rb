=begin
  Model object for a thread
  Author: Gunbard
=end

class ThreadItem
  attr_accessor :replies, :images, :date, :board, :date_added, :title, :url, :new_posts, :enabled, :display_title, :display_color, :deleted, :last_post, :image_urls, :save_dir, :save_dir_display
  
  TITLE_MAX_LENGTH = 65
  
  def initialize
   @replies = ''     # Number of replies in a thread
   @images = ''      # Number of images in a thread
   @date = ''        # Date of post (UNIX timestamp)
   @board = ''       # The board the post is on
   @date_added = ''  # The date this thread was added
   @title = ''       # May be thread subject or content snippit
   @url = ''         # Url of thread
   @new_posts = 0    # The number of new posts
   @enabled = true   # Enabled for update checking
   @deleted = false  # If thread was deleted
   @last_post = ''   # Date of last post
   @image_urls = []  # List of image urls
   @save_dir = ''    # Location to save images
  end
  
  ### Getter overrides
  def date
    # Format as mm/dd/yy
    formatted_date = Time.at(@date).to_datetime
    formatted_date.strftime('%m/%d/%y%n%l:%M:%S %p')
  end
  
  def date_added_display
    # Format as mm/dd/yy
    formatted_date = Time.at(@date_added).to_datetime
    formatted_date.strftime('%m/%d/%y%n%l:%M:%S %p')
  end
  
  def last_post_display
    # Format as mm/dd/yy
    formatted_date = Time.at(@last_post).to_datetime
    formatted_date.strftime('%m/%d/%y%n%l:%M:%S %p')
  end
  
  def title
    # Truncate long string
    short_title = @title
    
    if @title.length > TITLE_MAX_LENGTH
      short_title = "#{@title[0, TITLE_MAX_LENGTH - 3]}..."
    end
    
    short_title
  end
  
  def board
    "/#{@board}/"
  end
  
  ### Public methods
  
  # Returns a title for the listbox
  def display_title
    if @new_posts > 0
      return "(#{@new_posts}) #{title}"
    end
    
    title
  end
  
  # Returns a (hex) color for the listbox title
  def display_color
    if @deleted
      return '#FF0000' # Red
    elsif !@enabled
      return '#AAAAAA' # Gray
    end
    
    '#000000'
  end
  
  # Just shows the folder rather than the full path
  def save_dir_display
    File.split(@save_dir)[1]
  end
end