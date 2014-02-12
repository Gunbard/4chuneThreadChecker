=begin
  Common, reusable methods for Ruby Tk / vTcl development
  Author: Gunbard
=end

# Finds and returns a widget
# @param window The window to look in
# @param str The path string for the widget
# @returns A widget
def wpath(window, str)
  depth = str.count('.')
  
  if depth == 2
    window.winfo_children.each do |some_widget|
      if some_widget.path == str
        return some_widget
      end
    end
  elsif depth == 3
    window.winfo_children.each do |some_widget|
      some_widget.winfo_children.each do |some_inner_widget|
        if some_inner_widget.path == str
          return some_inner_widget
        end
      end
    end
  end
end

# Shows a standard, blocking, modal info box with ok button
# @param title The title of the dialog
# @param msg The display message
# @param window The window this is attached to
def show_msg(title, msg, window)
  if window  
      Tk.messageBox ({
        :type    => 'ok',  
        :icon    => 'info', 
        :title   => title,
        :message => msg,
        :parent  => window
      })
  else
      # Make box free-floating!
      Tk.messageBox ({
        :type    => 'ok',  
        :icon    => 'info', 
        :title   => title,
        :message => msg
      })
  end
end

# Creates and shows a non-modal, non-blocking message window with OK button
# @param title The window title
# @param msg The message to show
# @param window The window to center in or nil to ceter on screen
# @param root Tk root, used for screen centering
# @param command Command block for the OK button
# @returns The dialog window
def show_dialog(title, msg, window, root, command)
  window_width = 360
  window_height = 180

  dialog = TkToplevel.new ({
    :width => window_width,
    :height => window_height,
    :title => title
  })
  
  dialog['minsize'] = window_width, window_height
  dialog['resizable'] = false, false

  msg_label = TkLabel.new(dialog, { 
    :text => msg
  })
  
  unless command
    dialog.destroy
  end
  
  ok_button = TkButton.new(dialog, {
    :text => 'OK',
    :width => 10,
    :height => 2,
    :command => command
  })
  
  msg_label.pack(:padx => 20, :pady => 20, :side => 'top')
  ok_button.pack(:padx => 20, :pady => 20, :side => 'bottom')
  
  dialog.update
  dialog.focus
  center_window(dialog, window, root)
  
  dialog
end

# Centers a window
# @param window The window to center
# @param parent The window to center in, or the screen if nil
# @param root Tk root, used for screen centering
def center_window(window, parent, root)
  window_width = window.winfo_width
  window_height = window.winfo_height
  
  screen_width = root.winfo_screenwidth
  screen_height = root.winfo_screenheight
  
  screen_Xorigin = 0
  screen_Yorigin = 0
  
  if parent
    screen_width = parent.winfo_width
    screen_height = parent.winfo_height
    
    screen_Xorigin = parent.winfo_x
    screen_Yorigin = parent.winfo_y
  end
  
  center_x = (screen_width / 2) - (window_width / 2)
  center_y = (screen_height / 2) - (window_height / 2)
  
  window.geometry("+#{screen_Xorigin + center_x}+#{screen_Yorigin + center_y}")
end

# Determines current operating system
# @returns OS string or 'unknown'
def current_os
   if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
     return 'windows'
   elsif (/darwin/ =~ RUBY_PLATFORM) != nil
     return 'osx'
   elsif (/linux|bsd/ =~ RUBY_PLATFORM) != nil
     return 'linux'
   end
   
   'unknown'
end