=begin
  Model object for a thread
=end

class ThreadItem
  attr_accessor :replies, :images, :date, :board, :date_added, :title, :url, :new_posts, :enabled, :display_title, :display_color, :deleted
  
  TITLE_MAX_LENGTH = 65
  
  def initialize()
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
  end
  
  ### Getter overrides
  def date
    # Format as mm/dd/yy
    formatted_date = Time.at(@date).to_datetime
    formatted_date.strftime('%m/%d/%y%n%l:%M:%S %p')
  end
  
  def date_added
    # Format as mm/dd/yy
    formatted_date = Time.at(@date_added).to_datetime
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
    end
    
    '#000000'
  end
end