=begin
  4chuneThreadChecker
  Author: Gunbard
=end

require 'open-uri'
require 'json'
require 'tk'
require 'htmlentities'
require 'digest/md5'
require_relative 'tkcommon'
require_relative 'threadItem'
require_relative 'downloadManager'

temp_dir = File.dirname($0)
Tk.tk_call('source', "#{temp_dir}/main.tcl")

#####################
# Constants
#####################
SAVED_THREADS_FILENAME = 'threads.dat' 
SAVED_SETTINGS_FILENAME = 'settings.dat'
APPLICATION_TITLE = '4chune Thread Checker'
APPLICATION_AUTHOR = 'Gunbard (gunbard@gmail.com)'
APPLICATION_VERSION = 'v0.4.1'
MIN_REFRESH_RATE = 1
MAX_REFRESH_RATE = 99999
ICON_PATH = "#{temp_dir}/icon.ico" # Needs .ico
ICON_RED_PATH = "#{temp_dir}/iconRed.ico" # Needs .ico
WINDOW_ICON_PATH = "#{temp_dir}/icon.gif" # Needs .gif

#####################
# [Tk/Tcl stuff]
#####################
$root = TkRoot.new
$top_window = $root.winfo_children[0]
$settings_window = $root.winfo_children[1]
$proxy_settings_window = $root.winfo_children[2]

# Set icons
$window_icon = TkPhotoImage.new('file' => WINDOW_ICON_PATH)
$top_window.iconphoto($window_icon)
$settings_window.iconphoto($window_icon)
$proxy_settings_window.iconphoto($window_icon)

# Center application window
center_window($top_window, nil, $root)

# Show application
$top_window.deiconify

# Event handler for window close
$top_window.protocol(:WM_DELETE_WINDOW) { 
  # TODO: Clean up if in process of refreshing
  if defined?(Ocra)
    exit # Don't want to kill when building
  else
    if current_os == 'windows'
      clean_tray_icon
    end
    exit!
  end
}


# Event handler for deiconify top window
$top_window.bind('Map', proc{ |event|
  if event.widget == $top_window && current_os == 'windows'
    # Reset icon to default state
    update_tray_icon($top_window, APPLICATION_TITLE, ICON_PATH)
  end
})

$settings_window.protocol(:WM_DELETE_WINDOW) {
  $settings_window.grab(:release) 
  $settings_window.withdraw
}

$proxy_settings_window.protocol(:WM_DELETE_WINDOW) {
  $proxy_settings_window.grab(:release) 
  $proxy_settings_window.withdraw
}

# Add tray minimize support in Windows
if current_os == 'windows'
  require_relative 'win32TrayMinimize'
  add_tray_minimize($top_window, APPLICATION_TITLE, ICON_PATH)
end

#####################
# [Menu]
#####################
TkOption.add '*tearOff', 0 # Prevents empty menus
$menubar = TkMenu.new($top_window)
$top_window[:menu] = $menubar

# File
menu_opt_file = TkMenu.new($menubar)
$menubar.add :cascade, :menu => menu_opt_file, :label => 'File'

## Settings
menu_opt_file.add :command, :label => 'Settings...', :command => 
proc{
  $save_load_label['textvariable'].value = File.split($settings['save_load_directory'])[1]
  $rate_entry.textvariable.value = $settings['refresh_rate']
  
  $popups_enabled_check.variable.value = 0
  
  if $settings['popups_enabled']
    $popups_enabled_check.variable.value = 1
  end
  
  # Move to top window's origin
  center_window($settings_window, $top_window, $root)
  
  $settings_window.deiconify()
  $settings_window.grab
}

## Proxy Settings
menu_opt_file.add :command, :label => 'Proxy...', :command => 
proc{
  $proxy_url_entry.textvariable.value = $settings['proxy_url']
  $proxy_uname_entry.textvariable.value = $proxyauth_uname
  $proxy_pword_entry.textvariable.value = $proxyauth_pword

  # Move to top window's origin
  center_window($proxy_settings_window, $top_window, $root)
  
  $proxy_settings_window.deiconify()
  $proxy_settings_window.grab
}

## Quit
menu_opt_file.add :command, :label => 'Quit', :command => proc{exit}

# Tools
menu_opt_tools = TkMenu.new($menubar)
$menubar.add :cascade, :menu => menu_opt_tools, :label => 'Tools'

## Clean
menu_opt_tools.add :command, :label => 'Clean list', :command => proc{
  response = Tk.messageBox ({
    :type    => 'yesno',  
    :icon    => 'question', 
    :title   => 'Clean list?',
    :message => 'This will remove all deleted threads from your list. Are you sure?',
    :parent  => $top_window
  })
  
  if response == 'no'
    next
  end
  
  clean_list
}

## Wipe
menu_opt_tools.add :command, :label => 'Wipe out list', :command => proc{
  response = Tk.messageBox ({
    :type    => 'yesno',  
    :icon    => 'question', 
    :title   => 'Wipe out list?',
    :message => 'This will completely remove ALL threads from your list. Are you sure?',
    :parent  => $top_window
  })
  
  if response == 'no' || $refresh_button.state == 'disabled'
    next
  end
  
  $thread_data = []
  refresh_list
}

# Help
menu_opt_help = TkMenu.new($menubar)
$menubar.add :cascade, :menu => menu_opt_help, :label => 'Help'

## About
menu_opt_help.add :command, :label => 'About', :command => proc{
  show_msg('About', "#{APPLICATION_TITLE} #{APPLICATION_VERSION}\nby #{APPLICATION_AUTHOR}", $top_window)
}

#####################
# [Widget bindings]
#####################

# Main window
$thread_listbox         = wpath($top_window, '.top45.lis51')
$thread_scrollbar       = wpath($top_window, '.top45.scr69')
$add_thread_button      = wpath($top_window, '.top45.but49')
$mark_read_button       = wpath($top_window, '.top45.but45')
$add_thread_entry       = wpath($top_window, '.top45.ent47')
$refresh_button         = wpath($top_window, '.top45.but72')
$delete_thread_button   = wpath($top_window, '.top45.but50')
$openurl_button         = wpath($top_window, '.top45.but64')
$enabled_check          = wpath($top_window, '.top45.che45')
$url_label              = wpath($top_window, '.top45.lab71')
$status_label           = wpath($top_window, '.top45.lab62')
$board_label            = wpath($top_window, '.top45.lab58.lab74')
$new_posts_label        = wpath($top_window, '.top45.lab56.lab57')        
$date_label             = wpath($top_window, '.top45.lab60.lab75')
$replies_label          = wpath($top_window, '.top45.lab59.lab76')
$images_label           = wpath($top_window, '.top45.lab61.lab77')
$date_add_label         = wpath($top_window, '.top45.lab65.lab78')
$title_label            = wpath($top_window, '.top45.lab55.lab56')
$last_post_label        = wpath($top_window, '.top45.lab57.lab58')
$autoDL_dir_label       = wpath($top_window, '.top45.lab46.lab49')
$autoDL_dir_button      = wpath($top_window, '.top45.lab46.but47')
$autoDL_clear_button    = wpath($top_window, '.top45.lab46.but48')
$autoDL_status_label    = wpath($top_window, '.top45.lab46.lab50')

# Settings window
$save_load_button       = wpath($settings_window, '.top48.but52')
$set_rate_button        = wpath($settings_window, '.top48.but55')
$save_load_label        = wpath($settings_window, '.top48.lab53.lab54')
$rate_entry             = wpath($settings_window, '.top48.lab45.ent46')
$popups_enabled_check   = wpath($settings_window, '.top48.che48')

# Proxy settings window
$proxy_url_entry        = wpath($proxy_settings_window, '.top46.ent50')
$proxy_uname_entry      = wpath($proxy_settings_window, '.top46.lab47.ent53')
$proxy_pword_entry      = wpath($proxy_settings_window, '.top46.lab47.ent54')
$proxy_ok_button        = wpath($proxy_settings_window, '.top46.but49')
$proxy_clear_button     = wpath($proxy_settings_window, '.top46.but55')
$proxy_test_button      = wpath($proxy_settings_window, '.top46.but47')

#####################
# [Widget config]
#####################

# Listbox configuration
$thread_listbox[:activestyle] = 'none'
$thread_listbox[:yscrollcommand] = proc{|*args| $thread_scrollbar.set(*args)}
$thread_listbox[:exportselection] = 'false'
$thread_scrollbar[:command] = proc{|*args| $thread_listbox.yview(*args)}

# Labels (must use textvariable)
$url_label['textvariable']            = TkVariable.new
$status_label['textvariable']         = TkVariable.new
$board_label['textvariable']          = TkVariable.new
$date_label['textvariable']           = TkVariable.new
$replies_label['textvariable']        = TkVariable.new
$images_label['textvariable']         = TkVariable.new
$date_add_label['textvariable']       = TkVariable.new
$title_label['textvariable']          = TkVariable.new
$save_load_label['textvariable']      = TkVariable.new
$new_posts_label['textvariable']      = TkVariable.new
$last_post_label['textvariable']      = TkVariable.new
$autoDL_dir_label['textvariable']     = TkVariable.new
$autoDL_status_label['textvariable']  = TkVariable.new

# Entry boxes
$add_thread_entry.textvariable        = TkVariable.new
$rate_entry.textvariable              = TkVariable.new
$proxy_url_entry.textvariable         = TkVariable.new
$proxy_uname_entry.textvariable       = TkVariable.new
$proxy_pword_entry.textvariable       = TkVariable.new

# Check boxes
$enabled_check.variable               = TkVariable.new
$popups_enabled_check.variable        = TkVariable.new

# Right-click menu for entry boxes
add_thread_menu = TkMenu.new($add_thread_entry)
add_thread_menu.add :command, :label => 'Paste', :command => proc{
  clipboard_data = TkClipboard.get
  if clipboard_data
    $add_thread_entry.insert('insert', clipboard_data)
  end
}

proxy_url_menu = TkMenu.new($proxy_url_entry)
proxy_url_menu.add :command, :label => 'Paste', :command => proc{
  clipboard_data = TkClipboard.get
  if clipboard_data
    $proxy_url_entry.insert('insert', clipboard_data)
  end
}

# Hide password
$proxy_pword_entry.show = '*'

if Tk.windowingsystem == 'aqua'
    $add_thread_entry.bind '2', proc{|x,y| add_thread_menu.popup(x,y)}, "%X %Y"
    $add_thread_entry.bind 'Control-1', proc{|x,y| add_thread_menu.popup(x,y)}, "%X %Y"
    $proxy_url_entry.bind '2', proc{|x,y| proxy_url_menu.popup(x,y)}, "%X %Y"
    $proxy_url_entry.bind 'Control-1', proc{|x,y| proxy_url_menu.popup(x,y)}, "%X %Y"
else
    $add_thread_entry.bind '3', proc{|x,y| add_thread_menu.popup(x,y)}, "%X %Y"
    $proxy_url_entry.bind '3', proc{|x,y| proxy_url_menu.popup(x,y)}, "%X %Y"
end

#####################
# [Widget events]
#####################

### Main window

# Listbox selection event
$thread_listbox.bind('<ListboxSelect>', proc{ |event|
  if event.widget.curselection.length == 0 
    next # Note to self: Use 'next' when you want to return from a proc
  end

  index = event.widget.curselection[0]
  select_thread(index)
})

# Open thread in browser
$openurl_button.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index
    next
  end
  
  # Reset post counter
  $thread_data[selected_index].new_posts = 0
  
  url = $thread_data[selected_index].url
  refresh_list
  save_threads
  
  open_command = ''
  
  if current_os == 'windows'
    open_command = 'start'
  elsif current_os == 'osx'
    open_command = 'open'
  elsif current_os == 'linux'
    open_command = 'xdg-open'
  end
  
  system("#{open_command} #{url}")
}

# Add a thread
$add_thread_button.command = proc{
  url = $add_thread_entry.textvariable.value
  dupe = false
  
  $thread_data.each do |item|
    if item.url == url
      dupe = true
      break
    end
  end
  
  if dupe
      show_msg('Unable to Add', 'That thread has already been added.', $top_window)
      next
  end
  
  if (url.length == 0 || url == ' ')
    next
  end
  
  $add_thread_button.state = 'disabled'
    
  new_thread_item = get_thread(url)
  if new_thread_item
    add_thread(new_thread_item)
    $add_thread_entry.textvariable.value = ''
    $add_thread_button.state = 'normal'
  else
    show_msg('Error', "Thread seems to have 404'd already.", $top_window)
    $add_thread_entry.textvariable.value = ''
    $add_thread_button.state = 'normal'
  end
}

# Delete a thread
$delete_thread_button.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index || $refresh_button.state == 'disabled'
    next
  end
  
  response = Tk.messageBox ({
    :type    => 'yesno',  
    :icon    => 'question', 
    :title   => 'Delete thread?',
    :message => 'Are you sure you want to delete this thread?',
    :parent  => $top_window
  })
  
  if response == 'no'
    next
  end
  
  selected_thread = $thread_data[selected_index]
  delete_thread(selected_thread)
  
  if $thread_data.length > 0
    new_index = 0
    if selected_index > 0
      new_index = selected_index - 1
    end
    
    select_thread(new_index)
  else
    clear_info
  end
  
  refresh_list
}

# Refresh now
$refresh_button.command = proc{
  Thread.new{refresh}
}

# Mark thread as read
$mark_read_button.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index
    next
  end
  
  if $thread_data[selected_index].new_posts == 0
    next
  end
  
  $thread_data[selected_index].new_posts = 0
  refresh_list
  save_threads
}

# Set image auto download location
$autoDL_dir_button.command = proc{
  dirname = Tk::chooseDirectory(:parent => $settings_window, :initialdir => $settings['save_load_directory'])
  if dirname && dirname.length > 0
    # Save this somewhere
    $autoDL_dir_label['textvariable'].value = File.split(dirname)[1]
  end
}

# Clear image auto download location
$autoDL_clear_button.command = proc{
  # Clear it somewhere
  $autoDL_dir_label['textvariable'].value = ''
}

### Settings

# Open save/load folder dialog
$save_load_button.command = proc{
  dirname = Tk::chooseDirectory(:parent => $settings_window, :initialdir => $settings['save_load_directory'])
  if dirname && dirname.length > 0
    $settings['save_load_directory'] = dirname
    $save_load_label['textvariable'].value = File.split(dirname)[1]
    save_settings
  end
}

# Set refresh rate
$set_rate_button.command = proc{
  rate = $rate_entry.textvariable.value.to_i
  if rate < MIN_REFRESH_RATE || rate > MAX_REFRESH_RATE
      rate = $default_refresh_rate
      $rate_entry.textvariable.value = $default_refresh_rate
      show_msg('Error', "Please enter a value between #{MIN_REFRESH_RATE} and #{MAX_REFRESH_RATE}", $settings_window)
      return
  end

  $settings['refresh_rate'] = rate
  save_settings
  show_msg('OK!', "Refresh rate set to #{rate} minute(s).", $settings_window)
}

# Set thread update enabled
$enabled_check.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index || selected_index < 0 || selected_index > $thread_data.length
    next
  end
  
  enabled = true
  
  if $enabled_check['variable'] == 0
    enabled = false
  end
  
  $thread_data[selected_index].enabled = enabled
  
  # Update listbox title display
  $thread_listbox.itemconfigure selected_index, :foreground, $thread_data[selected_index].display_color
}

# Set popups enabled
$popups_enabled_check.command = proc{
  enabled = true
  
  if $popups_enabled_check['variable'] == 0
    enabled = false
  end
  
  $settings['popups_enabled'] = enabled
  
  save_settings
}

### Proxy settings

# Save settings and dismiss window
$proxy_ok_button.command = proc{
  $settings['proxy_url'] = $proxy_url_entry.textvariable.value
  $proxyauth_uname = $proxy_uname_entry.textvariable.value
  $proxyauth_pword = $proxy_pword_entry.textvariable.value

  save_settings
  
  $proxy_settings_window.grab(:release) 
  $proxy_settings_window.withdraw
}

# Save settings and dismiss window
$proxy_clear_button.command = proc{
  $proxy_url_entry.textvariable.value = ''
  $proxy_uname_entry.textvariable.value = ''
  $proxy_pword_entry.textvariable.value = ''
}

# Test proxy connection
$proxy_test_button.command = proc{
    if $proxy_url_entry.textvariable.value.length == 0
      next
    end

    begin
      test_url = 'http://www.4chan.org/'
      url = $proxy_url_entry.textvariable.value
      user = $proxy_uname_entry.textvariable.value
      pass = $proxy_pword_entry.textvariable.value
      
      puts "Getting data for url #{test_url} with proxy #{url}"
      proxy_uri = URI.parse(url)
      open(test_url, :proxy_http_basic_authentication => [url, user, pass]) do |data|
        json_response = data.read
      end
      
      show_msg('OK!','Successfully connected using proxy', $proxy_settings_window)
      puts 'Proxy connection successful'
    rescue
      show_msg('Error!','Could not connect using proxy', $proxy_settings_window)
      puts 'Failed to connect via proxy'
    end
}

#####################
# [Helper methods]
#####################

# Performs a request for thread data
# $param url The thread url
# $returns A threadItem or nil if didn't get anything back
def get_thread(url)
  # Validate url
  url_pattern = /4chan.org\/(\w+)\/(thread|res)\/(\d+)/
  board = url[url_pattern, 1]
  thread_id = url[url_pattern, 3]
  api_url = "http://a.4cdn.org/#{board}/thread/#{thread_id}.json"
  
  unless board && thread_id
    puts "Malformed url: #{url}"
    show_msg('Error', 'Not a valid thread url', $top_window)
    return nil
  end
  
  json_response = ''

  # Get API response
  if $settings['proxy_url'].to_s.length == 0
    begin
      puts "Getting data for url: #{url}"
      open(api_url) do |data|
        json_response = data.read
      end
    rescue
      puts "Error attempting to open url: #{api_url}"
      return nil
    end
  else
    begin
      puts "Getting data for url #{url} with proxy #{$settings['proxy_url']}"
      proxy_uri = URI.parse($settings['proxy_url'])
      open(api_url, :proxy_http_basic_authentication => [proxy_uri, $proxyauth_uname, $proxyauth_pword]) do |data|
        json_response = data.read
      end
    rescue
      puts "Error attempting to open url: #{api_url}"
      return nil
    end
  end
    
  if json_response && json_response.length > 0
    puts "Got data for url: #{url}"
    response_data = JSON.parse(json_response)
    thread_data = response_data['posts'][0]
    last_item = response_data['posts'].last

    thread_images = []
    
    # Generate list of image urls from thread
    response_data['posts'].each do |post|
      filename = post['filename']
      ext = post['ext']
    
      if filename && ext
        img_url = "http://i.4cdn.org/#{board}/#{filename}#{ext}"
        thread_images.push(img_url)
      end
    end
    
    new_thread_item = ThreadItem.new
    new_thread_item.replies = thread_data['replies']
    new_thread_item.images = thread_data['images']
    new_thread_item.date = thread_data['time']
    new_thread_item.board = board
    new_thread_item.date_added = Time.now.to_i
    new_thread_item.title = 'No title'
    new_thread_item.url = url
    new_thread_item.last_post = last_item['time']
    new_thread_item.image_urls = thread_images

    title = 'No title'
    
    if thread_data['sub']
      title = thread_data['sub']
    elsif thread_data['com']
      title = thread_data['com']
    elsif thread_data['filename'] && thread_data['ext']
      title = "#{thread_data['filename']}#{thread_data['ext']}"
    end
    
    # Strip html
    title.gsub!(/<[^>]*>/m, ' ')
    
    # Decode entites
    coder = HTMLEntities.new
    title = coder.decode(title)
    
    new_thread_item.title = title
    
    return new_thread_item
  end
  
  nil
end

# Adds a thread item to the thread data array
def add_thread(thread_item)
  $thread_data.push(thread_item)
  refresh_list
  save_threads
end

# Deletes a thread item in the thread data array
def delete_thread(thread_item)
  $thread_data.delete(thread_item)
  save_threads
end

# Updates latest data for all threads in list
# This method iterates through thread_data and requests
# for the latest data.
def refresh  
  $refresh_button.state = 'disabled'
  $refresh_button.text = 'Refreshing...'
  $add_thread_button.state = 'disabled'
  $delete_thread_button.state = 'disabled'
  
  # Don't refresh if no threads or currently refreshing
  if $thread_data.length == 0 || $checking_connection || !network_is_connected
    unless network_is_connected
      puts "Network connection unavailable. Not refreshing."
    end
    
    $refresh_button.state = 'normal'
    $refresh_button.text = 'Refresh Now'
    $add_thread_button.state = 'normal'
    $delete_thread_button.state = 'normal'
    return
  end
  
  new_stuff = false
  
  $thread_data.each_with_index do |thread_item, index|
    unless thread_item.enabled
      next
    end
    
    updated_thread_item = get_thread(thread_item.url)
    if updated_thread_item
      new_posts = updated_thread_item.replies - thread_item.replies
      if new_posts > 0
        new_stuff = true
        
        updated_thread_item.new_posts = thread_item.new_posts + new_posts
        
        if $new_thread_data[index] && $new_thread_data[index] > 0
          $new_thread_data[index] += new_posts
        else
          $new_thread_data[index] = new_posts
        end

        if $new_thread_data['total'] && $new_thread_data['total'] > 0
          $new_thread_data['total'] += new_posts
        else
          $new_thread_data['total'] = new_posts
        end
        
        puts "#{new_posts} new post(s) for thread: #{thread_item.url}"
      else
        updated_thread_item.new_posts = thread_item.new_posts
        puts "No new posts for thread: #{thread_item.url}"
      end
      
      # Don't update certain properties
      updated_thread_item.enabled = thread_item.enabled
      updated_thread_item.date_added = thread_item.date_added
      
      $thread_data[index] = updated_thread_item
      $download_manager.update_image_urls(updated_thread_item)
    else
      $thread_data[index].deleted = true
    end
  end
  
  refresh_list
  save_threads if new_stuff
  
  # Enable buttons
  $refresh_button.state = 'normal'
  $refresh_button.text = 'Refresh Now'
  $add_thread_button.state = 'normal'
  $delete_thread_button.state = 'normal'
    
  if $new_thread_data['total'] && $new_thread_data['total'] > 0
    new_posts_msg = "#{$new_thread_data['total']} new post(s)! - #{APPLICATION_TITLE}"

    if $settings['popups_enabled']
      begin
        $popup_notification.destroy
      rescue
      end
    
      report_msg = generate_report($new_thread_data)
      close_popup_action = proc{
        $popup_notification.destroy
        $new_thread_data = {}
      }
      
      $popup_notification = show_dialog("#{new_posts_msg}", report_msg, nil, $root, close_popup_action)
      
      $popup_notification.iconphoto($window_icon)

      $popup_notification.protocol(:WM_DELETE_WINDOW) {
        close_popup_action.call
      }
    end
    
    $download_manager.images
    
    if current_os == 'windows' && $top_window.state != 'normal'
      # Change tooltip and icon
      update_tray_icon($top_window, "#{new_posts_msg}", ICON_RED_PATH)
    end
  end
end

# Refreshes the listbox of threads
def refresh_list()
  saved_selected_index = $thread_listbox.curselection[0]
  
  # Clear list
  $thread_listbox.delete 0, $thread_listbox.size
  
  $thread_data.each_with_index do |item, index|
    $thread_listbox.insert index, item.display_title
    $thread_listbox.itemconfigure index, :foreground, item.display_color
  end
  
  if saved_selected_index && saved_selected_index != '' && $thread_data.length > 0
    select_thread(saved_selected_index)
  else
    clear_info
  end
end

# Refreshes the display info for the selected thread
# @param index Index of thread item
def refresh_info(index)
  thread_item = $thread_data[index]
  $url_label['textvariable'].value          = thread_item.url
  $board_label['textvariable'].value        = thread_item.board
  $date_label['textvariable'].value         = thread_item.date
  $replies_label['textvariable'].value      = thread_item.replies
  $images_label['textvariable'].value       = thread_item.images
  $date_add_label['textvariable'].value     = thread_item.date_added_display
  $title_label['textvariable'].value        = thread_item.title
  $new_posts_label['textvariable'].value    = thread_item.new_posts
  $last_post_label['textvariable'].value    = thread_item.last_post_display
  $enabled_check['variable'].value          = thread_item.enabled
  
  if thread_item.new_posts > 0
    $new_posts_label['foreground'] = '#009900'
  else
    $new_posts_label['foreground'] = '#000000'
  end
  
  if thread_item.deleted
    $status_label['textvariable'].value = 'Deleted'
    $status_label['foreground']         = '#FF0000'
    $enabled_check.state                = 'disabled'
  else
    $status_label['textvariable'].value = ''
    $enabled_check.state                = 'normal'
  end
  
end

# Clears the display info
def clear_info()
  $url_label['textvariable'].value          = ''
  $board_label['textvariable'].value        = ''
  $date_label['textvariable'].value         = ''
  $replies_label['textvariable'].value      = ''
  $images_label['textvariable'].value       = ''
  $date_add_label['textvariable'].value     = ''
  $last_post_label['textvariable'].value    = ''
  $title_label['textvariable'].value        = ''
  $new_posts_label['textvariable'].value    = ''
  $status_label['textvariable'].value       = ''
  
  $enabled_check.state                      = 'disabled'
end

# Goes through $thread_data and deletes deleted threads
def clean_list()
  if $refresh_button.state == 'disabled'
    return
  end
  
  $thread_data.delete_if {|thread_item| thread_item.deleted}
  refresh_list
  save_threads
end

# Save $thread_data to file
def save_threads()
  # Before saving, ensure save file was not modified during refresh
  previous_checksum = $settings['save_file_checksum']
  current_checksum = save_file_checksum
  
  if previous_checksum && previous_checksum.length > 0 && previous_checksum != current_checksum
    puts 'There is a save file conflict'
    
    # TODO: Do something about conflict
  end

  File.open("#{$settings['save_load_directory']}/#{SAVED_THREADS_FILENAME}", 'wb') do |file|
    Marshal.dump($thread_data, file)
  end
  
  save_checksum
  puts 'Saved thread data to file'
end

# Load thread data from file
def load_threads()
  saved_thread_data = nil
  if File.exists?("#{$settings['save_load_directory']}/#{SAVED_THREADS_FILENAME}")
    File.open("#{$settings['save_load_directory']}/#{SAVED_THREADS_FILENAME}") do |file|
      saved_thread_data = Marshal.load(file)
    end  
  else
    puts "Didn't find thread list savedata"
  end
  
  if saved_thread_data
    $thread_data = saved_thread_data
  else
    puts 'Unable to load thread save file'
    return
  end
  
  refresh_list
  
  puts 'Loaded saved thread data'
end

# @returns The checksum for the save file
def save_file_checksum()
  if File.exists?("#{$settings['save_load_directory']}/#{SAVED_THREADS_FILENAME}")
    Digest::MD5.file("#{$settings['save_load_directory']}/#{SAVED_THREADS_FILENAME}").hexdigest
  end
  
  nil
end

# Sets the checksum of the save file in the settings
def save_checksum()
  $settings['save_file_checksum'] = save_file_checksum
  save_settings
end

# Save $settings to file
def save_settings()
  File.open("#{SAVED_SETTINGS_FILENAME}", 'wb') do |file|
    Marshal.dump($settings, file)
  end
  
  puts 'Saved settings to file'
end

# Load settings from file
def load_settings()
  saved_settings_data = nil
  if File.exists?("#{SAVED_SETTINGS_FILENAME}")
    File.open("#{SAVED_SETTINGS_FILENAME}") do |file|
      saved_settings_data = Marshal.load(file)
    end  
  else
    puts "Didn't find settings savedata"
  end
  
  if saved_settings_data
    $settings = saved_settings_data
  else
    puts 'Unable to load settings save file'
    return
  end
  
  puts 'Loaded saved settings data'
end

# Selects a thread in the listbox
def select_thread(index)
  if index < 0 || index > $thread_data.length
    puts "Attempted to select out of bounds index: #{index}"
    return
  end

  $openurl_button.state = 'normal'
  $mark_read_button.state = 'normal'
  $delete_thread_button.state = 'normal'
  $thread_listbox.selection_set index
  refresh_info(index)
end

# Returns a basic report of new posts
def generate_report(thread_data)
  report = ''
  
  $thread_data.each_with_index do |thread_item, index|
    if thread_item.new_posts > 0
      new_posts = thread_data[index]
      if new_posts
        report << "#{new_posts} new post(s) for thread: #{thread_item.board} #{thread_item.title}\n"
      end
    end
  end
  
  report
end

# Determines if there's a network connection avaialable
# NOTE: Assumes Google is always up. ALWAYS.
def network_is_connected
  begin
    $checking_connection = true
    if open("http://www.4chan.org")
      $checking_connection = false
      return true
    end
  rescue
    $checking_connection = false
    return false
  end
end
#####################################################

#####################
# Global vars
#####################

# Data source containing threadItems
$thread_data = []

# Used to keep track of new posts in the popup {thread_index => new_posts}
$new_thread_data = {}

# Used to prevent user from adding threads or refreshing while checking connection
$checking_connection = false

# Proxy auth info
$proxyauth_uname = ''
$proxyauth_pword = ''

# Default settings
$default_save_load_dir = Dir.pwd
$default_refresh_rate = 3
$default_popups_enabled = false;

# Hash containing default settings
$settings = {
  'save_load_directory' => $default_save_load_dir,
  'refresh_rate' => $default_refresh_rate,
  'popups_enabled' => $default_popups_enabled,
  'save_file_checksum' => '',
  'proxy_url' => ''
}

#########################################
# [MAIN]
#########################################

# Reload data
load_settings
load_threads

# Start refresh timer
refresh_timer = TkTimer.new($settings['refresh_rate'] * 60000, -1, proc{refresh})
refresh_timer.start

# Start download manager
$download_manager = DownloadManager.new
#$download_manager.download_url()

Tk.mainloop
