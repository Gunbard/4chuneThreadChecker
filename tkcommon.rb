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