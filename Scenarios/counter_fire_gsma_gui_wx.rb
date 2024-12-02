#############################################################################
###
##  Name:   counter_fire_gsma_gui.rb
##
##  Desc:   An example scenario to illustrate the use of a event driven scenario.
##          The implacement locations are the Greater Seoul Metro Area (GSMA)
##
##          This senario is designed to run concurrently with the
##          counter_fire_gsma.rb scenario.  These two scenario are
##          run by different instances of the ScenarioDriver.  In this
##          way the event driven scenario can use a GUI that waits
##          on man-in-the-loop decisions before invoking some action.
##

s = IseScenario.new "GUI for Missile Counter-fire GSMA"

require 'systemu'
require 'ostruct'
require 'SimTime'

##########################################################
## global simulation time frame

$sim_time = SimTime.new(  0.1,
                          '27 Jul 1953 11:00:00.000',
                          '27 Jul 1953 11:30:00.000' )

################################################################
## default text for the request for fire / call for fire message

$all_processed  = "All RequestForFire and CallForFire messages have been processed."
$rff_cff_text   = $all_processed

######################################################
## Define the laydown junk as global hashes

$assigned_fire_units = []

$blue_launchers = []

$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_01"
$blue_launchers.last.position  = [37.23796232773378, 126.9975666493282, 0.0]
$blue_launchers.last.selected  = false


$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_02"
$blue_launchers.last.position  = [37.23949057276692, 126.9981968541871, 0.0]
$blue_launchers.last.selected  = false


$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_03"
$blue_launchers.last.position  = [37.81265882971723, 126.8774007941036, 0.0]
$blue_launchers.last.selected  = false





##################################################
## require all the messages to be sent or received

require 'StkLaunchMissile'    ## equivalent to a FireOrder
require 'RequestForFire'

require 'EndEngagement'
require 'EndRun'



############################################################
## instantiate a new scenario with a single line description

s.at(0.0) do
  IseScenario.subscribe(RequestForFire)
end




########################################################
## Event-based tasks

my_engagements      = []  ## array of targets names engaged
my_dne              = []  ## array of targets not engaged
fire_unit_assigned  = 0   ## the fire unit assigned to the current engagement

s.on(:RequestForFire) do

  target_label    = s.message(:RequestForFire)[1].label_
  target_position = s.message(:RequestForFire)[1].target_position_
  
  puts "Received a RequestForFire"
  puts "  Target: #{target_label}   at: #{target_position}"
  
  unless  my_engagements.include?(target_label) or
          my_dne.include?(target_label)

    puts "DEBUG: Displaying xmessage window" if $debug
    
    button_list = ""
    $blue_launchers.each do |bl|
      button_list += bl.name + ","
    end
    button_list += "Shoot w/Best Fit,Do Not Engage"
    fu_value_range = 101 .. 100+$blue_launchers.length
    
    a_msg = "Request For Fire Received: #{target_label} at #{target_position}"
    
    $msg_text_ctrl.set_value( a_msg )
    

puts "showing FCC with a_msg: #{a_msg}"

    $gui_thread.priority *= -1    
#    $app.iconize(false) if running_on_windows

puts "$gui_thread.priority: #{$gui_thread.priority}"


=begin
    status, mil_action, error_msg = systemu("xmessage -nearmouse -buttons '#{button_list}' -timeout 30 -print '#{a_msg}'")
    mil_action.chomp!
  
    if $debug  
      puts "DEBUG: xmessage window closed with following parameters set ..."
      puts "       status:     #{status.inspect}"
      puts "       exitstatus: #{status.exitstatus}"
      puts "       mil_action: #{mil_action}"
      puts "       error_msg:  #{error_msg}"
    end
  
    if 'Do Not Engage' ==  mil_action
      my_dne << target_label
    else
      my_engagements << target_label
      
      case status.exitstatus
        when 0, fu_value_range.max+1    ## 0 means the dialog box timed out
          fire_unit_assigned = rand($blue_launchers.length)    ## assign a random fire unit
        when fu_value_range
          fire_unit_assigned = status.exitstatus - 101        ## remember array index start at zero
      end
      s.set(:FireOrder)
    end

=end
    
  end
  
end

#####################
s.on(:FireOrder) do

    target_label    = s.message(:RequestForFire)[1].label_
    target_position = s.message(:RequestForFire)[1].target_position_
  
    if $debug
      puts "DEBUG: A Fire Order has been simulated"
      puts "  Target: #{target_label}   at: #{target_position}"
      puts "  Fire Unit Assigned: #{fire_unit_assigned} -- #{$blue_launchers[fire_unit_assigned].name}"
    end
    
    $assigned_fire_units << $blue_launchers[fire_unit_assigned] if $assigned_fire_units.empty?


    a_msg = "Sending FireOrder to:\n\n"
    
    $msg_text_ctrl.set_value(a_msg)

puts "="*45
    
    x = 0
    $assigned_fire_units.each do |afu|
      x += 1
      a_message = StkLaunchMissile.new
      a_message.label_            = "cf_#{my_engagements.length}_#{x}"
      a_message.launch_position_  = afu.position
      a_message.target_position_  = target_position
      a_message.publish
      
      a_msg += "\t#{afu.name}\n"
      $msg_text_ctrl.set_value(a_msg)


puts "published StkLaunchMissile command for: #{a_message.label_}"

      if $debug
        puts "DEBUG: StkLaunchMissile has been published"
        puts "       Label: #{a_message.label_}"
      end

      
    end

puts "="*45

    a_msg += "\nAll Fire Orders have been sent."
    $msg_text_ctrl.set_value(a_msg)
    
    
    $assigned_fire_units = []

puts "hiding FCC"
    
#    $app.iconize(true) if running_on_windows
    $gui_thread.priority *= -1

puts "$gui_thread.priority: #{$gui_thread.priority}"

end ## end of s.on(:FireOrder) do

s.list  if $debug_sim


########################################################################
## Define a GUI to replace the xmessage dialog

require 'wx'


####################################################
## The overall frame for the GUI

class IseFrame < Wx::Frame
  def initialize(title, pos, size, style = Wx::DEFAULT_FRAME_STYLE)

    super(nil, -1, title, pos, size, style)

    @s = IseScenario.new "An instance inside the GUI frame"
    
    file_menu = Wx::Menu.new()
    file_menu.append(Wx::ID_EXIT, "E&xit\tAlt-X", "Quit this program")
    evt_menu(Wx::ID_EXIT) { on_quit }
    
    help_menu = Wx::Menu.new()
    help_menu.append(Wx::ID_ABOUT, "&About FCC ...\tF1", "Show about dialog")
    evt_menu(Wx::ID_ABOUT) { on_about }
    
    menubar = Wx::MenuBar.new()
    menubar.append(file_menu, "&File")
    menubar.append(help_menu, "&Help")
    set_menu_bar(menubar)

    create_status_bar(2)
    set_status_text("ISE Simulation Support Component")


    # Start creating the sashes - these are created from outermost
    # inwards. 
    sash = Wx::SashLayoutWindow.new(self, -1, Wx::DEFAULT_POSITION,
      Wx::Size.new(150, self.get_size.y) )
    # The default width of the sash is 150 pixels, and it extends the
    # full height of the frame
    sash.set_default_size( Wx::Size.new(150, self.get_size.y) )
    
    # This sash splits the frame top to bottom
    sash.set_orientation(Wx::LAYOUT_VERTICAL)
    
    # Place the sash on the left of the frame
    sash.set_alignment(Wx::LAYOUT_LEFT)
    
    # Show a drag bar on the right of the sash
    sash.set_sash_visible(Wx::SASH_RIGHT, true)
    sash.set_background_colour(Wx::Colour.new(225, 200, 200) )

    panel = Wx::Panel.new(sash)
    v_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    
    $blue_launchers.each_with_index do |bl, x|
      cb_item = Wx::CheckBox.new(panel, x, bl.name)
      v_siz.add(cb_item, 0, Wx::ADJUST_MINSIZE)
    end
    
    evt_checkbox(-1) {|event| on_checkbox(event) }
    
    panel.set_sizer_and_fit(v_siz)

    # handle the sash being dragged
    evt_sash_dragged( sash.get_id ) { | e | on_v_sash_dragged(sash, e) }

    # Create another small sash on the bottom of the frame
    sash_2 = Wx::SashLayoutWindow.new(self, -1, Wx::DEFAULT_POSITION,
      Wx::Size.new(self.get_size.x,
        100),
      Wx::SW_3DSASH)
    sash_2.set_default_size( Wx::Size.new(self.get_size.x, 100) )
    sash_2.set_orientation(Wx::LAYOUT_HORIZONTAL)
    sash_2.set_alignment(Wx::LAYOUT_BOTTOM)
    sash_2.set_sash_visible(Wx::SASH_TOP, true)
    #    text = Wx::StaticText.new(sash_2, -1, "Put some buttons in this area")

    sizer_top = Wx::BoxSizer.new(Wx::VERTICAL)

    @btn_1 = Wx::Button.new(sash_2, 1, "Engage with Designated Fire Units")
    @btn_2 = Wx::Button.new(sash_2, 2, "Engage with Most Capable Fire Unit")
    @btn_3 = Wx::Button.new(sash_2, 3, "Do Not Engage This Target")

    sizer_top.add(@btn_1, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)
    sizer_top.add(@btn_2, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)
    sizer_top.add(@btn_3, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)

    set_auto_layout(true)
    set_sizer(sizer_top)

    sizer_top.set_size_hints(sash_2)
    sizer_top.fit(sash_2)

    @btn_2.set_focus()
    @btn_2.set_default()
    
    evt_button(-1) {|event| on_button(event) }

    evt_sash_dragged( sash_2.get_id ) { | e | on_h_sash_dragged(sash_2, e) }


    # The main panel - the residual part of the frame that takes up all
    # remaining space not used by the sash windows.
    @m_panel = Wx::Panel.new(self, -1)
    sizer = Wx::BoxSizer.new(Wx::VERTICAL)

    $msg_text_ctrl  = Wx::TextCtrl.new(@m_panel, -1, $rff_cff_text,
      Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE,
      Wx::SUNKEN_BORDER|Wx::TE_MULTILINE)


    pp $msg_text_ctrl
    pp $msg_text_ctrl.methods.sort

    puts $msg_text_ctrl.get_value


    sizer.add($msg_text_ctrl, 1, Wx::EXPAND|Wx::ADJUST_MINSIZE|Wx::ALL, 10)
    @m_panel.set_sizer_and_fit(sizer)

    # Adjust the size of the sashes when the frame is resized
    evt_size { | e | on_size(e) }

    # Call LayoutAlgorithm#layout_frame to layout the sashes.
    # The second argument is the residual window that takes up remaining
    # space
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_checkbox(event)
    id        = event.get_id
    selected  = event.is_checked
    $blue_launchers[id].selected = selected
  end

  def on_button(event)
    id = event.get_id

=begin    
    Wx::message_box("Button #{id} pressed", "Info",
                Wx::OK | Wx::ICON_INFORMATION, self)
=end

        
    case id
    when @btn_1.get_id
      puts "1"
      $blue_launchers.each do |bl|
        $assigned_fire_units << bl if bl.selected
      end
    when @btn_2.get_id
      puts "2"
      $blue_launchers.length.times do |x|
        $blue_launchers[x].selected = false
      end
      x = rand($blue_launchers.length)
      $blue_launchers[x].selected = true
      $assigned_fire_units << $blue_launchers[x]
    when @btn_3.get_id
      puts "3"
    else
      event.skip()
    end

    if $assigned_fire_units.empty?
      a_msg = "Please confirm DO NOT ENGAGE."
    else

      a_msg = "The following fire units have been selected to engage this target:\n\n"
    
      $assigned_fire_units.each do |afu|
        a_msg += "\t" + afu.name + "\n"
      end

      a_msg += "\n"
    end
    
    a_dialog = Wx::MessageDialog.new(nil,
      "Button #{id} pressed\n\n" + a_msg,
      "Confirm Engagement", 
      Wx::NO_DEFAULT | Wx::YES_NO | Wx::CANCEL | Wx::ICON_INFORMATION)

    case a_dialog.show_modal()
    when Wx::ID_YES
      puts "yes"
      
      $rff_cff_text = $all_processed
      $msg_text_ctrl.set_value($rff_cff_text)
      
      @s.set(:FireOrder)
      
    when Wx::ID_NO
      puts "no"
    when Wx::ID_CANCEL
      puts "cancel"
    else
      puts "something else"
    end

  end
  
  
  def on_v_sash_dragged(sash, e)
    # Call get_drag_rect to get the new size
    size = Wx::Size.new(  e.get_drag_rect.width(), self.get_size.y )
    sash.set_default_size( size )
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_h_sash_dragged(sash, e)
    size = Wx::Size.new( self.get_size.x, e.get_drag_rect.height() )
    sash.set_default_size( size )
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_size(e)
    e.skip()
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_quit
    close(true)
  end

  def on_about
    msg =  sprintf("FCC is an ISE component  It is " \
        "a rudimentary implementation to simulation only a small part of a FIRES " \
        "control node.  This implementation responds to MissileDetected " \
        "messages from Search Radars.  It presents a list of available " \
        "fire units which are capable of engaging the launch coordinates " \
        "of the detected missile.\n\n" \
        "The Integrated System Environment (ISE) is a distributed network " \
        "communications middleware technology " \
        "which ties together existing legacy systems and simulations " \
        "using a protocol conversion concept that allows systems " \
        "not specifically designed for interoperability to communicate.\n\n" \
        "The FCC is prototyped in Ruby using the %s cross-platform GUI library.\n\n" \
        "Copyright (c) 2009 Lockheed Martin Corp.", Wx::VERSION_STRING)
    Wx::message_box(msg, "FIRES Control Console (FCC)", Wx::OK|Wx::ICON_INFORMATION, self)
  end
end




###################################
## The Wx::App Class

class SashApp < Wx::App
  def on_init

    $frame = IseFrame.new(  "FIRES Control Console (rudimentary)",
                        Wx::Point.new(50, 50),
                        Wx::Size.new(450, 340) )

puts "Just created the gui $frame"

    $frame.show(true)

puts "$gui_thread.priority: #{$gui_thread.priority}"

  end
end

###############################
## Start new thread for the GUI

$app = SashApp.new


$stderr.puts "#{$app.methods.sort}"


  
$gui_thread = Thread.new do
  $app.main_loop()
end


# $app.iconize(true) if running_on_windows


$gui_thread.priority = -2

puts "$gui_thread.priority: #{$gui_thread.priority}"

Thread.main.priority = -1   ## The main thread has a higher priority than the GUI


$msg_text_ctrl.set_value( "No FIRES requests are pending." )

## The End
##################################################################


