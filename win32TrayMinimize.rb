=begin
  Minimize to tray support in Windows
  Author: Gunbard
=end

require 'win32/api'

#####################
# [Minimize to tray]
#####################

# WIN32-API CONSTANTS
WM_USER             = 0x400
WM_TRAYICON         = WM_USER + 0x0001
WM_LBUTTONDBLCLK    = 0x0203
WM_LBUTTONUP        = 0x0202
GWL_WNDPROC         = -4

# TRAY ICON CONSTANTS
RT_ICON             = 3
DIFFERENCE          = 11
RT_GROUP_ICON       = RT_ICON + DIFFERENCE
NIF_MESSAGE         = 1
NIF_ICON            = 2
NIF_TIP             = 4
NIM_ADD             = 0
NIM_MODIFY          = 1
NIM_DELETE          = 2

# TRAY ICON SETUP
$SetWindowLong      = Win32::API.new('SetWindowLong', 'LIK', 'L', 'user32')
$CallWindowProc     = Win32::API.new('CallWindowProc', 'LIIIL', 'L', 'user32')
$Shell_NotifyIcon   = Win32::API.new('Shell_NotifyIconA', 'LP', 'I', 'shell32')
$ExtractIcon        = Win32::API.new('ExtractIcon', 'LPI', 'L', 'shell32')
$hicoY              = $ExtractIcon.call(0, 'C:\WINDOWS\SYSTEM32\INETCPL.CPL', 21)  # Green tick
$old_window_proc    = 0
$pnid               = 0

# Allows a window to minimize to the system tray
# @param window The window that can be minimized to the tray
# @param tiptxt The tooltip text for the icon
def add_tray_minimize(window, tiptxt)
  $pnid = [6*4+64, window.winfo_id.to_i(16), 'ruby'.hash, NIF_MESSAGE | NIF_ICON | NIF_TIP, WM_TRAYICON, $hicoY].pack('LLIIIL') << tiptxt << "\0"*(64 - tiptxt.size)
    
  #-------WNDPROC OVERRIDE---------#
  # Custom windowProc override
  $my_window_proc = Win32::API::Callback.new('LIIL', 'I') { |hwnd, umsg, wparam, lparam|

    if umsg == WM_TRAYICON && lparam == WM_LBUTTONUP
      # Restore window
      window.deiconify
      remove_tray_icon
    end

    # I HAVE NO IDEA IF THIS IS THE ACTUAL MINIMIZE MESSAGE but it seems to work okay
    if umsg == 24 && wparam == 0
      window.withdraw
      $Shell_NotifyIcon.call(NIM_ADD, $pnid)
    end

    # Pass messages to original windowProc
    $CallWindowProc.call($old_window_proc, hwnd, umsg, wparam, lparam)
  }

  # Intercept windowProc messages, original windowProc should be returned
  $old_window_proc = $SetWindowLong.call(window.winfo_id.to_i(16), GWL_WNDPROC, $my_window_proc)
  #------END WNDPROC OVERRIDE------#

end

# Deletes the icon from the taskbar
def remove_tray_icon()
  $Shell_NotifyIcon.call(NIM_DELETE, $pnid)
end