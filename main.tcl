#!/bin/sh
# the next line restarts using wish\
exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {

    package require Tk
    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *Scrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }
    
}

#############################################################################
# Visual Tcl v1.60 Project
#


#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## The window may have disappeared
    if {![winfo exists $target]} return
    ## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
                    ## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
            ## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
            ## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
            ## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }

    set command [lindex $args 0]
    set args [lrange $args 1 end]
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}


if {[info exists vTcl(sourcing)]} {

proc vTcl:project:info {} {
    set base .top45
    namespace eval ::widgets::$base {
        set set,origin 1
        set set,size 1
        set runvisible 0
    }
    set site_3_0 $base.lab55
    set site_3_0 $base.lab58
    set site_3_0 $base.lab59
    set site_3_0 $base.lab60
    set site_3_0 $base.lab61
    set site_3_0 $base.lab65
    set site_3_0 $base.lab56
    set site_3_0 $base.lab57
    set base .top46
    namespace eval ::widgets::$base {
        set set,origin 0
        set set,size 1
        set runvisible 0
    }
    set site_3_0 $base.lab47
    set base .top48
    namespace eval ::widgets::$base {
        set set,origin 0
        set set,size 1
        set runvisible 0
    }
    set site_3_0 $base.lab45
    set site_3_0 $base.lab53
    namespace eval ::widgets_bindings {
        set tagslist {_TopLevel _vTclBalloon}
    }
    namespace eval ::vTcl::modules::main {
        set procs {
            init
            main
        }
        set compounds {
        }
        set projectType single
    }
}
}

#################################
# USER DEFINED PROCEDURES
#
#############################################################################
## Procedure:  main

proc ::main {argc argv} {}

#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm focusmodel $top passive
    wm geometry $top 200x200+208+208; update
    wm maxsize $top 1916 1053
    wm minsize $top 124 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl"
    bindtags $top "$top Vtcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top45 {base} {
    if {$base == ""} {
        set base .top45
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 410x321+742+291; update
    wm maxsize $top 1916 1053
    wm minsize $top 134 10
    wm overrideredirect $top 0
    wm resizable $top 0 0
    wm title $top "4chune Thread Checker"
    vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    listbox $top.lis51 \
        -background white -foreground {#000000} -listvariable "$top\::lis51" 
    vTcl:DefineAlias "$top.lis51" "Listbox1" vTcl:WidgetProc "Toplevel1" 1
    entry $top.ent47 \
        -background white -textvariable "$top\::ent47" 
    vTcl:DefineAlias "$top.ent47" "Entry1" vTcl:WidgetProc "Toplevel1" 1
    button $top.but49 \
        -pady 0 -text {Add Thread} 
    vTcl:DefineAlias "$top.but49" "Button1" vTcl:WidgetProc "Toplevel1" 1
    button $top.but50 \
        -pady 0 -state disabled -text Delete 
    vTcl:DefineAlias "$top.but50" "Button2" vTcl:WidgetProc "Toplevel1" 1
    labelframe $top.lab55 \
        -text Title -height 70 -width 220 
    vTcl:DefineAlias "$top.lab55" "Labelframe1" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab55
    label $site_3_0.lab56 \
        -justify left -text { } -width 207 -wraplength 207 
    vTcl:DefineAlias "$site_3_0.lab56" "Label1" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab56 \
        -in $site_3_0 -x 5 -y 15 -width 207 -height 49 -anchor nw \
        -bordermode ignore 
    labelframe $top.lab58 \
        -text Board -height 50 -width 55 
    vTcl:DefineAlias "$top.lab58" "Labelframe2" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab58
    label $site_3_0.lab74 \
        -text { } 
    vTcl:DefineAlias "$site_3_0.lab74" "Label3" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab74 \
        -in $site_3_0 -x 5 -y 15 -width 47 -height 29 -anchor nw \
        -bordermode ignore 
    labelframe $top.lab59 \
        -text Replies -height 50 -width 55 
    vTcl:DefineAlias "$top.lab59" "Labelframe3" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab59
    label $site_3_0.lab76 \
        -text { } 
    vTcl:DefineAlias "$site_3_0.lab76" "Label5" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab76 \
        -in $site_3_0 -x 5 -y 20 -width 47 -height 24 -anchor nw \
        -bordermode ignore 
    labelframe $top.lab60 \
        -text Date -height 50 -width 100 
    vTcl:DefineAlias "$top.lab60" "Labelframe4" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab60
    label $site_3_0.lab75 \
        -text { } -wraplength 92 
    vTcl:DefineAlias "$site_3_0.lab75" "Label4" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab75 \
        -in $site_3_0 -x 5 -y 15 -width 92 -height 29 -anchor nw \
        -bordermode ignore 
    labelframe $top.lab61 \
        -text Images -height 50 -width 55 
    vTcl:DefineAlias "$top.lab61" "Labelframe5" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab61
    label $site_3_0.lab77 \
        -text { } 
    vTcl:DefineAlias "$site_3_0.lab77" "Label6" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab77 \
        -in $site_3_0 -x 5 -y 20 -width 47 -height 24 -anchor nw \
        -bordermode ignore 
    button $top.but64 \
        -pady 0 -state disabled -text {Open URL} 
    vTcl:DefineAlias "$top.but64" "Button3" vTcl:WidgetProc "Toplevel1" 1
    bindtags $top.but64 "$top.but64 Button $top all _vTclBalloon"
    bind $top.but64 <<SetBalloon>> {
        set ::vTcl::balloon::%W {Opens thread in the default browser}
    }
    labelframe $top.lab65 \
        -text {Date Added} -height 50 -width 100 
    vTcl:DefineAlias "$top.lab65" "Labelframe7" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab65
    label $site_3_0.lab78 \
        -text { } -wraplength 92 
    vTcl:DefineAlias "$site_3_0.lab78" "Label7" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab78 \
        -in $site_3_0 -x 5 -y 15 -width 92 -height 29 -anchor nw \
        -bordermode ignore 
    scrollbar $top.scr69
    vTcl:DefineAlias "$top.scr69" "Scrollbar1" vTcl:WidgetProc "Toplevel1" 1
    label $top.lab71 \
        -text { } 
    vTcl:DefineAlias "$top.lab71" "Label2" vTcl:WidgetProc "Toplevel1" 1
    button $top.but72 \
        -pady 0 -text {Refresh Now} 
    vTcl:DefineAlias "$top.but72" "Button4" vTcl:WidgetProc "Toplevel1" 1
    checkbutton $top.che45 \
        -state disabled -text Enabled -variable "$top\::che45" 
    vTcl:DefineAlias "$top.che45" "Checkbutton1" vTcl:WidgetProc "Toplevel1" 1
    labelframe $top.lab56 \
        -text New -height 50 -width 55 
    vTcl:DefineAlias "$top.lab56" "Labelframe6" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab56
    label $site_3_0.lab57 \
        -text { } 
    vTcl:DefineAlias "$site_3_0.lab57" "Label8" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab57 \
        -in $site_3_0 -x 6 -y 18 -width 47 -height 24 -anchor nw \
        -bordermode ignore 
    label $top.lab62 \
        -text { } 
    vTcl:DefineAlias "$top.lab62" "Label9" vTcl:WidgetProc "Toplevel1" 1
    labelframe $top.lab57 \
        -text {Last Post} -height 50 -width 100 
    vTcl:DefineAlias "$top.lab57" "Labelframe8" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab57
    label $site_3_0.lab58
    vTcl:DefineAlias "$site_3_0.lab58" "Label10" vTcl:WidgetProc "Toplevel1" 1
    place $site_3_0.lab58 \
        -in $site_3_0 -x 5 -y 15 -width 91 -height 31 -anchor nw \
        -bordermode ignore 
    button $top.but45 \
        -pady 0 -state disabled -text {Mark Read} 
    vTcl:DefineAlias "$top.but45" "Button5" vTcl:WidgetProc "Toplevel1" 1
    ###################
    # SETTING GEOMETRY
    ###################
    place $top.lis51 \
        -in $top -x 5 -y 45 -width 154 -height 179 -anchor nw \
        -bordermode ignore 
    place $top.ent47 \
        -in $top -x 170 -y 10 -width 149 -height 22 -anchor nw \
        -bordermode ignore 
    place $top.but49 \
        -in $top -x 320 -y 5 -width 78 -height 29 -anchor nw \
        -bordermode ignore 
    place $top.but50 \
        -in $top -x 10 -y 235 -width 87 -height 34 -anchor nw \
        -bordermode ignore 
    place $top.lab55 \
        -in $top -x 185 -y 55 -width 220 -height 70 -anchor nw \
        -bordermode ignore 
    place $top.lab58 \
        -in $top -x 185 -y 125 -width 55 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.lab59 \
        -in $top -x 185 -y 175 -width 55 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.lab60 \
        -in $top -x 305 -y 125 -width 100 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.lab61 \
        -in $top -x 245 -y 175 -width 55 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.but64 \
        -in $top -x 200 -y 235 -width 87 -height 34 -anchor nw \
        -bordermode ignore 
    place $top.lab65 \
        -in $top -x 305 -y 175 -width 100 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.scr69 \
        -in $top -x 161 -y 43 -width 17 -height 176 -anchor nw \
        -bordermode ignore 
    place $top.lab71 \
        -in $top -x 10 -y 270 -width 392 -height 24 -anchor nw \
        -bordermode ignore 
    place $top.but72 \
        -in $top -x 35 -y 5 -width 87 -height 34 -anchor nw \
        -bordermode ignore 
    place $top.che45 \
        -in $top -x 180 -y 35 -width 71 -height 24 -anchor nw \
        -bordermode ignore 
    place $top.lab56 \
        -in $top -x 245 -y 125 -width 55 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.lab62 \
        -in $top -x 285 -y 35 -width 107 -height 24 -anchor nw \
        -bordermode ignore 
    place $top.lab57 \
        -in $top -x 305 -y 225 -width 100 -height 50 -anchor nw \
        -bordermode ignore 
    place $top.but45 \
        -in $top -x 105 -y 235 -width 87 -height 34 -anchor nw \
        -bordermode ignore 

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top46 {base} {
    if {$base == ""} {
        set base .top46
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 312x162; update
    wm maxsize $top 1926 1063
    wm minsize $top 134 10
    wm overrideredirect $top 0
    wm resizable $top 0 0
    wm title $top "Proxy Settings"
    vTcl:DefineAlias "$top" "Toplevel3" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    labelframe $top.lab47 \
        -text Authentication -height 75 -width 280 
    vTcl:DefineAlias "$top.lab47" "Labelframe1" vTcl:WidgetProc "Toplevel3" 1
    set site_3_0 $top.lab47
    label $site_3_0.lab51 \
        -justify right -text Username: 
    vTcl:DefineAlias "$site_3_0.lab51" "Label2" vTcl:WidgetProc "Toplevel3" 1
    label $site_3_0.lab52 \
        -justify right -text Password: 
    vTcl:DefineAlias "$site_3_0.lab52" "Label3" vTcl:WidgetProc "Toplevel3" 1
    entry $site_3_0.ent53 \
        -background white -textvariable "$top\::ent53" 
    vTcl:DefineAlias "$site_3_0.ent53" "Entry2" vTcl:WidgetProc "Toplevel3" 1
    entry $site_3_0.ent54 \
        -background white -textvariable "$top\::ent54" 
    vTcl:DefineAlias "$site_3_0.ent54" "Entry3" vTcl:WidgetProc "Toplevel3" 1
    place $site_3_0.lab51 \
        -in $site_3_0 -x 37 -y 20 -anchor nw -bordermode ignore 
    place $site_3_0.lab52 \
        -in $site_3_0 -x 40 -y 40 -anchor nw -bordermode ignore 
    place $site_3_0.ent53 \
        -in $site_3_0 -x 105 -y 20 -anchor nw -bordermode ignore 
    place $site_3_0.ent54 \
        -in $site_3_0 -x 105 -y 45 -anchor nw -bordermode ignore 
    label $top.lab48 \
        -text {Proxy URL:} 
    vTcl:DefineAlias "$top.lab48" "Label1" vTcl:WidgetProc "Toplevel3" 1
    button $top.but49 \
        -pady 0 -text OK 
    vTcl:DefineAlias "$top.but49" "Button1" vTcl:WidgetProc "Toplevel3" 1
    entry $top.ent50 \
        -background white -textvariable "$top\::ent50" 
    vTcl:DefineAlias "$top.ent50" "Entry1" vTcl:WidgetProc "Toplevel3" 1
    button $top.but55 \
        -pady 0 -text Clear 
    vTcl:DefineAlias "$top.but55" "Button2" vTcl:WidgetProc "Toplevel3" 1
    ###################
    # SETTING GEOMETRY
    ###################
    place $top.lab47 \
        -in $top -x 15 -y 40 -width 280 -height 75 -anchor nw \
        -bordermode ignore 
    place $top.lab48 \
        -in $top -x 20 -y 15 -anchor nw -bordermode ignore 
    place $top.but49 \
        -in $top -x 125 -y 120 -width 69 -height 30 -anchor nw \
        -bordermode ignore 
    place $top.ent50 \
        -in $top -x 90 -y 15 -width 204 -height 19 -anchor nw \
        -bordermode ignore 
    place $top.but55 \
        -in $top -x 250 -y 120 -width 38 -height 29 -anchor nw \
        -bordermode ignore 

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top48 {base} {
    if {$base == ""} {
        set base .top48
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 312x162; update
    wm maxsize $top 1916 1053
    wm minsize $top 134 10
    wm overrideredirect $top 0
    wm resizable $top 0 0
    wm title $top "Settings"
    vTcl:DefineAlias "$top" "Toplevel2" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    labelframe $top.lab45 \
        -text {Update rate} -height 55 -width 115 
    vTcl:DefineAlias "$top.lab45" "Labelframe1" vTcl:WidgetProc "Toplevel2" 1
    set site_3_0 $top.lab45
    entry $site_3_0.ent46 \
        -background white -textvariable "$top\::ent46" 
    vTcl:DefineAlias "$site_3_0.ent46" "Entry1" vTcl:WidgetProc "Toplevel2" 1
    label $site_3_0.lab47 \
        -text minute(s) 
    vTcl:DefineAlias "$site_3_0.lab47" "Label1" vTcl:WidgetProc "Toplevel2" 1
    place $site_3_0.ent46 \
        -in $site_3_0 -x 10 -y 20 -width 39 -height 27 -anchor nw \
        -bordermode ignore 
    place $site_3_0.lab47 \
        -in $site_3_0 -x 50 -y 20 -anchor nw -bordermode ignore 
    checkbutton $top.che48 \
        -text {Show popup notifications} -variable "$top\::che48" 
    vTcl:DefineAlias "$top.che48" "Checkbutton1" vTcl:WidgetProc "Toplevel2" 1
    button $top.but52 \
        -pady 0 -text Set 
    vTcl:DefineAlias "$top.but52" "Button4" vTcl:WidgetProc "Toplevel2" 1
    bindtags $top.but52 "$top.but52 Button $top all _vTclBalloon"
    bind $top.but52 <<SetBalloon>> {
        set ::vTcl::balloon::%W {Folder to save thread data to}
    }
    labelframe $top.lab53 \
        -text {Save/load location} -height 55 -width 190 
    vTcl:DefineAlias "$top.lab53" "Labelframe2" vTcl:WidgetProc "Toplevel2" 1
    set site_3_0 $top.lab53
    label $site_3_0.lab54 \
        -text { } -width 177 -wraplength 177 
    vTcl:DefineAlias "$site_3_0.lab54" "Label2" vTcl:WidgetProc "Toplevel2" 1
    place $site_3_0.lab54 \
        -in $site_3_0 -x 5 -y 20 -width 177 -height 29 -anchor nw \
        -bordermode ignore 
    button $top.but55 \
        -pady 0 -text Set 
    vTcl:DefineAlias "$top.but55" "Button1" vTcl:WidgetProc "Toplevel2" 1
    ###################
    # SETTING GEOMETRY
    ###################
    place $top.lab45 \
        -in $top -x 20 -y 65 -width 115 -height 55 -anchor nw \
        -bordermode ignore 
    place $top.che48 \
        -in $top -x 15 -y 120 -width 169 -height 39 -anchor nw \
        -bordermode ignore 
    place $top.but52 \
        -in $top -x 225 -y 25 -width 69 -height 30 -anchor nw \
        -bordermode ignore 
    place $top.lab53 \
        -in $top -x 20 -y 10 -width 190 -height 55 -anchor nw \
        -bordermode ignore 
    place $top.but55 \
        -in $top -x 150 -y 80 -width 69 -height 30 -anchor nw \
        -bordermode ignore 

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top46 {base} {
    if {$base == ""} {
        set base .top46
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 312x162; update
    wm maxsize $top 1926 1063
    wm minsize $top 134 10
    wm overrideredirect $top 0
    wm resizable $top 0 0
    wm title $top "Proxy Settings"
    vTcl:DefineAlias "$top" "Toplevel3" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    labelframe $top.lab47 \
        -text Authentication -height 75 -width 280 
    vTcl:DefineAlias "$top.lab47" "Labelframe1" vTcl:WidgetProc "Toplevel3" 1
    set site_3_0 $top.lab47
    label $site_3_0.lab51 \
        -justify right -text Username: 
    vTcl:DefineAlias "$site_3_0.lab51" "Label2" vTcl:WidgetProc "Toplevel3" 1
    label $site_3_0.lab52 \
        -justify right -text Password: 
    vTcl:DefineAlias "$site_3_0.lab52" "Label3" vTcl:WidgetProc "Toplevel3" 1
    entry $site_3_0.ent53 \
        -background white -textvariable "$top\::ent53" 
    vTcl:DefineAlias "$site_3_0.ent53" "Entry2" vTcl:WidgetProc "Toplevel3" 1
    entry $site_3_0.ent54 \
        -background white -textvariable "$top\::ent54" 
    vTcl:DefineAlias "$site_3_0.ent54" "Entry3" vTcl:WidgetProc "Toplevel3" 1
    place $site_3_0.lab51 \
        -in $site_3_0 -x 37 -y 20 -anchor nw -bordermode ignore 
    place $site_3_0.lab52 \
        -in $site_3_0 -x 40 -y 40 -anchor nw -bordermode ignore 
    place $site_3_0.ent53 \
        -in $site_3_0 -x 105 -y 20 -anchor nw -bordermode ignore 
    place $site_3_0.ent54 \
        -in $site_3_0 -x 105 -y 45 -anchor nw -bordermode ignore 
    label $top.lab48 \
        -text {Proxy URL:} 
    vTcl:DefineAlias "$top.lab48" "Label1" vTcl:WidgetProc "Toplevel3" 1
    button $top.but49 \
        -pady 0 -text OK 
    vTcl:DefineAlias "$top.but49" "Button1" vTcl:WidgetProc "Toplevel3" 1
    entry $top.ent50 \
        -background white -textvariable "$top\::ent50" 
    vTcl:DefineAlias "$top.ent50" "Entry1" vTcl:WidgetProc "Toplevel3" 1
    button $top.but55 \
        -pady 0 -text Clear 
    vTcl:DefineAlias "$top.but55" "Button2" vTcl:WidgetProc "Toplevel3" 1
    ###################
    # SETTING GEOMETRY
    ###################
    place $top.lab47 \
        -in $top -x 15 -y 40 -width 280 -height 75 -anchor nw \
        -bordermode ignore 
    place $top.lab48 \
        -in $top -x 20 -y 15 -anchor nw -bordermode ignore 
    place $top.but49 \
        -in $top -x 125 -y 120 -width 69 -height 30 -anchor nw \
        -bordermode ignore 
    place $top.ent50 \
        -in $top -x 90 -y 15 -width 204 -height 19 -anchor nw \
        -bordermode ignore 
    place $top.but55 \
        -in $top -x 250 -y 120 -width 38 -height 29 -anchor nw \
        -bordermode ignore 

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

bind "_TopLevel" <<Create>> {
    if {![info exists _topcount]} {set _topcount 0}; incr _topcount
}
bind "_TopLevel" <<DeleteWindow>> {
    if {[set ::%W::_modal]} {
                vTcl:Toplevel:WidgetProc %W endmodal
            } else {
                destroy %W; if {$_topcount == 0} {exit}
            }
}
bind "_TopLevel" <Destroy> {
    if {[winfo toplevel %W] == "%W"} {incr _topcount -1}
}
#############################################################################
## Binding tag:  _vTclBalloon


if {![info exists vTcl(sourcing)]} {
}

Window show .
Window show .top45
Window show .top48
Window show .top46

main $argc $argv
