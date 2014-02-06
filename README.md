4chuneThreadChecker
===================
External thread watcher for 4chan. Uses 4chan's API.

![alt text](https://raw.github.com/Gunbard/4chuneThreadChecker/master/readme-img/w7.png "Windows 7 screenshot")

Version history
-------
- 0.1: External thread updater

Features
--------------
* External -- get rid of all those open tabs!
* Can change update rate from 1 to 99999 minutes
* Change save/load folder (Point to a Dropbox folder to sync your watched threads between systems!)
* Quickly view thread stats
* Enable/disable individual threads from being updated
* Popup notification window with a thread report
* Windows version minimizes to tray

Pre-installation
--------------

####Windows
```
N/a
```

####OS X

You will need to install ActiveState Tk/Tcl and upgrade to Ruby 1.9


####Linux
Need to install Ruby 1.9 and Tk/Tcl, but shouldn't need any other dependencies.

Ex:
```
sudo apt-get install ruby libtcltk-ruby
```

Installation
--------------
####Windows
Executable is standalone. Just run normally.
Built with OCRA.

####OS X & Linux*
\* Still looking into standalone builds

Assuming you have git installed:

```
git clone https://github.com/Gunbard/4chuneThreadChecker.git
```

```
cd [dir where you cloned]
```

```
gem install json htmlentities
```

Finally, run with:

```
ruby main.rb
```

License
----

MIT