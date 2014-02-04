=begin
    Common, reusable methods for Ruby Tk / vTcl development
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

# Shows a standard info box with ok button
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
        :message => msg,
      })
  end
end


# Centers a window
# @param The window to center
# @param The window to center in, or the screen if nil
def center_window(window, parent)
  window_width = window.winfo_width
  window_height = window.winfo_height
  
  screen_width = $root.winfo_screenwidth
  screen_height = $root.winfo_screenheight
  
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