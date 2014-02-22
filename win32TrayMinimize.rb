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
WM_RBUTTONUP        = 0x0205
GWL_WNDPROC         = -4

# TRAY ICON CONSTANTS
RT_ICON             = 3
DIFFERENCE          = 11
RT_GROUP_ICON       = RT_ICON + DIFFERENCE
NIF_MESSAGE         = 1
NIF_ICON            = 2
NIF_TIP             = 4
NIF_SHOWTIP         = 128
NIF_INFO            = 16
NIF_GUID            = 32
NIM_ADD             = 0
NIM_MODIFY          = 1
NIM_DELETE          = 2
NIM_SETVERSION      = 4

class NOTIFYICONDATA
  attr_accessor :cbSize, :hWnd, :uID, :uFlags, :uCallbackMessage, :hIcon, :szTip, :dwState, :dwStateMask, :szInfo, :uTimeoutOrVersion, :szInfoTitle, :dwInfoFlags, :guidItem, :hBalloonIcon

  def initialize
    @cbSize = Marshal.dump(NOTIFYICONDATA).size
    @hWnd = 0
    @uID = 0
    @uFlags = 0
    @uCallbackMessage = 0
    @hIcon = 0
    @szTip = ''
    @dwState = 0
    @dwStateMask = 0 
    @szInfo = ''
    @uTimeoutOrVersion = 0
    @szInfoTitle = ''
    @dwInfoFlags = 0
    @guidItem = 0
    @hBalloonIcon = 0
  end
  
  def pack
    data = [@cbSize, @hWnd, @uID, @uFlags, @uCallbackMessage, @hIcon].pack('LLIIIL') << @szTip << "\0"*(64 - @szTip.size) << [@dwState, @dwStateMask].pack('LL') << @szInfo << "\0"*(256 - @szInfo.size) << [@uTimeoutOrVersion].pack('I') << @szInfoTitle << "\0"*(64 - @szInfoTitle.size) << [@dwInfoFlags].pack('L') << @guidItem << [@hBalloonIcon].pack('L')
    data
  end
end

# TRAY ICON SETUP
$SetWindowLong      = Win32::API.new('SetWindowLong', 'LIK', 'L', 'user32')
$CallWindowProc     = Win32::API.new('CallWindowProc', 'LIIIL', 'L', 'user32')
$Shell_NotifyIcon   = Win32::API.new('Shell_NotifyIconA', 'LP', 'I', 'shell32')
$ExtractIcon        = Win32::API.new('ExtractIcon', 'LPI', 'L', 'shell32')
$GetCursorPos       = Win32::API.new('GetCursorPos', 'P', 'I', 'user32')
$old_window_proc    = 0
$pnid               = 0

# Set this to prevent an icon from being added on window close
# Since Win API seems to send the same message again
$tray_listen        = true 

# Allows a window to minimize to the system tray
# @param window The window that can be minimized to the tray
# @param tiptxt The tooltip text for the icon
# @param icon_path Path for the icon file
# @param context_menu A TkMenu used as the right-click menu for the tray icon
def add_tray_minimize(window, tiptxt, icon_path, context_menu) 
  icon = $ExtractIcon.call(0, icon_path, 0)
  
  $pnid = NOTIFYICONDATA.new
  $pnid.hWnd = window.winfo_id.to_i(16)
  $pnid.uID = 'ruby'.hash 
  $pnid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP
  $pnid.uCallbackMessage = WM_TRAYICON
  $pnid.hIcon = icon
  $pnid.szTip = tiptxt

  #-------WNDPROC OVERRIDE---------#
  # Custom windowProc override
  $my_window_proc = Win32::API::Callback.new('LIIL', 'I') { |hwnd, umsg, wparam, lparam|

    if umsg == WM_TRAYICON
      if lparam == WM_LBUTTONUP
        # Restore window
        window.deiconify
        $Shell_NotifyIcon.call(NIM_DELETE, $pnid.pack)
      elsif lparam == WM_RBUTTONUP
        cursorPoint = [0, 0].pack('LL')
        $GetCursorPos.call(cursorPoint)
        x, y = cursorPoint.unpack('LL')
        context_menu.popup(x, y)
      end
    end

    # I HAVE NO IDEA IF THIS IS THE ACTUAL MINIMIZE MESSAGE but it seems to work okay
    # These messages seem to be different from what is documented in the Windows API
    if umsg == 24 && wparam == 0 && $tray_listen
      window.withdraw
      $Shell_NotifyIcon.call(NIM_ADD, $pnid.pack)
    end

    # Pass messages to original windowProc
    $CallWindowProc.call($old_window_proc, hwnd, umsg, wparam, lparam)
  }

  # Intercept windowProc messages, original windowProc should be returned
  $old_window_proc = $SetWindowLong.call(window.winfo_id.to_i(16), GWL_WNDPROC, $my_window_proc)
  #------END WNDPROC OVERRIDE------#

end

# Deletes the icon from the taskbar and tells to stop listening for minimize event
def clean_tray_icon()
  $Shell_NotifyIcon.call(NIM_DELETE, $pnid.pack)
  $tray_listen = false
end