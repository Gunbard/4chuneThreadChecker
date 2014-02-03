=begin
  4chuneThreadChecker
  Author: Gunbard
=end

require 'open-uri'
require 'json'
require 'tk'
require 'htmlentities'
require_relative 'tkcommon'
require_relative 'threadItem'

#####################
# [Tk/Tcl stuff]
#####################
temp_dir = File.dirname($0)
Tk.tk_call('source', "#{temp_dir}/main.tcl")
root = TkRoot.new
$top_window = root.winfo_children[0]
$settings_window = root.winfo_children[1]

# Event handler for window close
$top_window.protocol(:WM_DELETE_WINDOW) { 
  if defined?(Ocra)
    exit # Don't want to kill when building
  else
    exit!
  end
}

$settings_window.protocol(:WM_DELETE_WINDOW) { 
  $settings_window.withdraw
  $settings_window.grab(:release)
}

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
menu_opt_file.add :command, :label => 'Settings', :command => 
proc{
  $save_load_label['textvariable'].value = File.split($save_load_directory)[1]

  $settings_window.deiconify()
  $settings_window.grab
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
}


# About
menu_opt_about = TkMenu.new($menubar)
$menubar.add :command, :label => 'About', :command => proc{
  show_msg('About', 'Stuff', $top_window)
}

# Help
menu_opt_help = TkMenu.new($menubar)
$menubar.add :command, :label => '?', :command => proc{
  show_msg('Help', 'Some help here', $top_window)
}

#####################
# [Widget bindings]
#####################

# Main window
$thread_listbox         = wpath($top_window, '.top45.lis51')
$thread_scrollbar       = wpath($top_window, '.top45.scr69')
$add_thread_button      = wpath($top_window, '.top45.but49')
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

# Settings window
$save_load_button       = wpath($settings_window, '.top48.but52')
$save_load_label        = wpath($settings_window, '.top48.lab53.lab54')

#####################
# [Widget events]
#####################

# Listbox selection event
$thread_listbox.bind('<ListboxSelect>', proc{ |event|
  if event.widget.curselection.length == 0 
    next # Note to self: Use 'next' when you want to return from a proc
  end
  
  $openurl_button.state = 'normal'
  
  index = event.widget.curselection[0]
  refresh_info(index)
})

# Open thread in browser
$openurl_button.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index
    next
  end
  
  url = $thread_data[selected_index].url
  system("start #{url}")
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
  else
    show_msg('Error', "Thread seems to have 404'd already.", $top_window)
    $add_thread_button.state = 'normal'
  end
}

# Delete a thread
$delete_thread_button.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index
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
    new_index = selected_index - 1
    $thread_listbox.selection_set new_index 
  else
    clear_info
  end
}

# Open save/load folder dialog
$save_load_button.command = proc{
  dirname = Tk::chooseDirectory(:parent => $settings_window)
  if dirname && dirname.length > 0
    $save_load_directory = dirname
    $save_load_label['textvariable'].value = File.split(dirname)[1]
  end
}

# Refresh now
$refresh_button.command = proc{
  refresh
}

# Set thread update enabled
$enabled_check.command = proc{
  selected_index = $thread_listbox.curselection[0]
  if !selected_index
    next
  end
  
  enabled = true
  
  if $enabled_check['variable'] == 0
    enabled = false
  end
  
  $thread_data[selected_index].enabled = enabled
}

#####################
# [Widget config]
#####################

# Listbox configuration
$thread_listbox[:activestyle] = 'none'
$thread_listbox[:yscrollcommand] = proc{|*args| $thread_scrollbar.set(*args)}
$thread_scrollbar[:command] = proc{|*args| $thread_listbox.yview(*args)}

# Labels (must use textvariable)
$url_label['textvariable']          = TkVariable.new
$status_label['textvariable']       = TkVariable.new
$board_label['textvariable']        = TkVariable.new
$date_label['textvariable']         = TkVariable.new
$replies_label['textvariable']      = TkVariable.new
$images_label['textvariable']       = TkVariable.new
$date_add_label['textvariable']     = TkVariable.new
$title_label['textvariable']        = TkVariable.new
$save_load_label['textvariable']    = TkVariable.new
$new_posts_label['textvariable']    = TkVariable.new

# Entry boxes
$add_thread_entry.textvariable = TkVariable.new

# Check boxes
$enabled_check.variable = TkVariable.new

#####################
# [Helper methods]
#####################

# Performs a request for thread data
# $param url The thread url
# $returns A threadItem or nil if didn't get anything back
def get_thread(url)
  # Validate url
  url_pattern = /4chan.org\/(\w+)\/res\/(\d+)/
  board = url[url_pattern, 1]
  thread_id = url[url_pattern, 2]
  api_url = "http://a.4cdn.org/#{board}/res/#{thread_id}.json"
  
  unless board && thread_id
    puts "Malformed url: #{url}"
    show_msg('Error', 'Not a valid thread url', $top_window)
    return nil
  end
  
  json_response = ''

  # Get API response
  begin
    puts "Getting data for url: #{url}"
    open(api_url) do |data|
      json_response = data.read
    end
  rescue
    puts "Error attempting to open url: #{api_url}"
    return nil
  end

  if json_response && json_response.length > 0
    puts "Got data for url: #{url}"
    response_data = JSON.parse(json_response)
    thread_data = response_data['posts'][0]

    new_thread_item = ThreadItem.new
    new_thread_item.replies = thread_data['replies']
    new_thread_item.images = thread_data['images']
    new_thread_item.date = thread_data['time']
    new_thread_item.board = board
    new_thread_item.date_added = Time.now.to_i
    new_thread_item.title = 'No title'
    new_thread_item.url = url

    title = 'No title'
    
    if thread_data['subject']
      title = thread_data['subject']
    elsif thread_data['com']
      title = thread_data['com']
    elsif thread_data['filename']
      title = thread_data['filename']
    end
    
    # Strip html
    title.gsub!(/<[^>]*>/, ' ')
    
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
  refresh_list
  save_threads
end

# Updates latest data for all threads in list
# This method iterates through thread_data and requests
# for the latest data.
def refresh()
  # TODO: Perform on new thread
  # TODO: Prevent adding new stuff while this is running
  $thread_data.each_with_index do |thread_item, index|
    unless thread_item.enabled && !thread_item.deleted
      next
    end
    
    updated_thread_item = get_thread(thread_item.url)
    if updated_thread_item
      new_posts = updated_thread_item.replies - thread_item.replies
      if new_posts > 0
        updated_thread_item.new_posts = new_posts
        puts "#{new_posts} new post(s) for thread: #{thread_item.url}"
      else
        puts "No new posts for thread: #{thread_item.url}"
      end
      
      updated_thread_item.enabled = thread_item.enabled
      $thread_data[index] = updated_thread_item
    else
      $thread_data[index].deleted = true
    end
  end
  
  refresh_list
  save_threads
end

# Refreshes the listbox of threads
def refresh_list()
  $thread_listbox.delete 0, $thread_listbox.size
  
  $thread_data.each_with_index do |item, index|
    $thread_listbox.insert index, item.display_title
    $thread_listbox.itemconfigure index, :foreground, item.display_color
  end
  
  clear_info
  $add_thread_button.state = 'normal'
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
  $date_add_label['textvariable'].value     = thread_item.date_added
  $title_label['textvariable'].value        = thread_item.title
  $new_posts_label['textvariable'].value    = thread_item.new_posts
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
  $title_label['textvariable'].value        = ''
  $new_posts_label['textvariable'].value    = ''
  $status_label['textvariable'].value       = ''
  
  $enabled_check.state                      = 'disabled'
end

# Save $thread_data to file
def save_threads()
  thread_savefile = File.open("#{$save_load_directory}/#{SAVED_THREADS_FILENAME}", 'w')
  thread_savefile << Marshal.dump($thread_data)
  thread_savefile.close
  puts 'Saved thread data to file'
end

# Load thread data from file
def load_threads()
  begin
    thread_savedata = File.read("#{$save_load_directory}/#{SAVED_THREADS_FILENAME}")
  rescue
    puts "Didn't find thread list savedata"
    return
  end
  
  saved_thread_data = Marshal.load(thread_savedata)
  $thread_data = saved_thread_data
  refresh_list
  
  puts 'Loaded saved thread data'
end

#####################################################

#####################
# Constants
#####################
SAVED_THREADS_FILENAME = 'threads.dat' 
SAVED_SETTINGS_FILENAME = 'settings.dat' 

#####################
# Global vars
#####################

# Data source containing threadItems
$thread_data = []

# Default save directory is working directory
$save_load_directory = Dir.pwd

#########################################
# [MAIN]
#########################################

load_threads

Tk.mainloop
