#################################################################
###
##  File:  STK.rb
##  Desc:  should be funcitonally the same as Stk.pm
##
##  The Stk.rb file is too big to keep everything in mind.  Breaking it up into
##  smaller chucks for easoer gorking.  There are 57 total methods.  That's too many.
##
##  The stuff in the STK sub-directory duplicates the stuff here; except, that stuff has
##  comment blocks on the main headers.  Don't know if its newer or older than the stuff here.
##
##  Some of these methods are junk.  Some only different by a very small amount. Perlers never
##  heard of DRY.
##
##  Everything is camel case with initial cap.  This conflicts with ruby coding conventions. Its
##  driving the IDE bonkers w/r/t color scheme.
##
##  Some of this junk is Ms Windoze specific, for example mucking with the regristery.
##
##  Methods denoted as "old" have been commented out.
##
##
##
##  Other files are:
##    Stk_file_stuff.rb
##    Stk_mswin32.rb
##    Stk_obsolete.rb
##    Stk_Utilities.rb
##
##
##  The file Stk.rb contains all of the socket connection oriented methods.
##
#

require 'rubygems'
require 'socket'
require 'pathname'
require 'pp'

$IS_WINDOWS = RUBY_PLATFORM.include? 'mswin32'
$VERSION = 3.0
$CONNECT_RESULT = "NOT_SET"

$EOL    = "\015\012"
$BLANK  = $EOL * 2

$YELLOW_STK_COLOR    = 4
$BLUE_STK_COLOR      = 5
$RED_STK_COLOR       = 6


##########################################################
## Setting $ISE_ROOT here to the current working directory
## if it is not already defined.  This is required when
## the STK module is used outsdie of a full ISE environment.

$ISE_ROOT = Pathname.pwd unless defined?($ISE_ROOT)






####################################################
## trap control-c events; send to the dokill method

trap("INT") do
  STK.dokill
end



##########################################################
## Global hash contains instances of the TCPSocket class.
## These instances are accessable by the socket_name.
## It is a "functional" programming technique held over
## from the evil Perl implementation.

$tcp_socket_hash      = Hash.new    ## This hash contains the TCPSocket class instances accessed by socket_name

########################################################
## These global hashes contain status information of the
## socket connection with STK

$async_setting_hash  = Hash.new    ## accessed by socket_name, gives status of async setting
$ack_setting_hash    = Hash.new    ## accessed by socket_name, gives status of ack setting

########################################################
## SMELL: may not be global; used in low-level socket IO
## TDV: It is.  It selects the method used to read data from STK
##      via the TCP socket connection in the method
##      read_chars_from_socket

$read_char_flag = 1



################################################################################################
# each connection will add to the following hash table the STK/Connect commands that return data
# the value 1 indicates a single line of returned data; a value of 2 indicates multiple line data

$return_data_table_lookup = Hash.new
$return_data_table_lookup = {
    'GETSTKHOMEDIR' => 1,     # returns single line data
    'SHOWNAMES' => 1,         # returns single line data
    'SHOWUNITS' => 1,         # returns single line data
    'GETTIMEPERIOD' => 1,
    'ALLINSTANCENAMES' => 1,
    'POSITION' => 1,
    'CHECKSCENARIO' => 1,
    'GETANIMATIONDATA' => 1
}



#####################################################
## This hash table has method names to be called to process
## return data from specific STK Connect commands
##
## It is used by read_stk_single_line_output

$returns_data_format_lookup = Hash.new
$returns_data_format_lookup['AER']              = :formatAER
#$returns_data_format_lookup['GETTIMEPERIOD']    = :formatTimePeriod
$returns_data_format_lookup['ALLINSTANCENAMES'] = :formatObjPathNamesSplitOnSpaces
#$returns_data_format_lookup['SHOWNAMES']        = :formatObjPathNamesSplitOnSpaces

=begin
# PerlInterface/STK/blib/lib/stk.pm

sub formatObjPathNamesSplitOnSpaces
{
    my $inputLine = $_[0];
    my $refArray = $_[1];
    
    if(defined($inputLine) && defined($refArray))
    {
        $inputLine =~ s/(\w) \//$1,/g;  #remove _/ from _/Scenario/Scenario1/etc. and insert commas
        $inputLine =~ s/^ \///;
        
        @$refArray = split(/,/, $inputLine);        # gets an entry per object path name
    }
}

sub formatTimePeriod
{
    my $inputLine = $_[0];
    my $refArray = $_[1];
    
    if(defined($inputLine) && defined($refArray))
    {
        # returned data is date_1, date_2 WITH the space after the comma!!!
        # So.. remove it!
        
        $inputLine =~ s/, /,/;      #remove annoying space
        
        @$refArray = split(/,/, $inputLine);        # start, stop are separate entries
    }
}

sub formatAER
{
    my $inputLine = $_[0];
    my $refArray = $_[1];
    
    if(defined($inputLine) && defined($refArray))
    {
        # in an ODD choice, the AER cmd returns "objPath1 objPath2 first_time_a_e_r \n next time_a_e_r \n etc.
        # SO... put commas after each path
            
        $inputLine =~ s/^(\S+)\s+(\S+)\s+(\S.*)/$1\n$2\n$3/;
            
        # formatting: replace \n with ,
            
        @$refArray = split(/\n/, $inputLine);       # start, stop are separate entries
    }
}


=end





##########################################
#
# (old) Reading data routines
#


$read_data_function_registration = Hash.new
$read_data_function_registration = {
  'AER'               => 'STK::first_2spaces_then_cr_seperate_data',
#  'GETTIMEPERIOD'     => 'STK::read_time_period_data',
  'ALLINSTANCENAMES'  => 'STK::spaces_seperate_data',
  'CAT_RM'            => 'STK::read_report',
  'CHAINS_RM'         => 'STK::read_report',
  'COV_RM'            => 'STK::read_report',
  'BOUNDARYACCESS'    => 'STK::read_report',
  'CHAINALLACCESS'    => 'STK::read_report',
  'CHAINGETACCESSES'  => 'STK::read_report',
  'CHAINGETINTERVALS' => 'STK::read_report',
  'CHAINGETSTRANDS'   => 'STK::read_report',
  'CLOSEAPPROACH'     => 'STK::read_report',
  'GETATTITUDE'       => 'STK::read_report',
  'GETBOUNDARY'       => 'STK::read_report',
  'GETLICENSES'       => 'STK::read_report',
  'GETMARKERLIST'     => 'STK::read_report',
  'GETPROPNAME'       => 'STK::read_report',
  'GETREPORT'         => 'STK::read_report',
  'GETACCESSES'       => 'STK::read_report',
  'ALLACCESS'         => 'STK::read_report',
  'DECKACCESS'        => 'STK::read_report',
  'GETRPTSUMMARY'     => 'STK::read_report'
}


$data_that_split_on_carriage_returns = {
  'GETREPORT'     => true,
  'GETACCESSES'   => true,
  'ALLACCESS'     => true,
  'CAT_RM'        => true,
#  'GETTIMEPERIOD' => true,
  'GETLICENSES'   => true,
  'VO_R'          => true,
  'GETRPTSUMMARY' => true}









#########################################################
## First cut at an STK API in Ruby
## Its a p.o.s. due to its replication of the evil perl
## functional approach.  Need new OOD

module STK










  ############
  def self.dokill
    #      kill 9,$child if $child
    exit
  end ## end of def self.dokill




  ##########################################
  #
  # Connection routines
  #


  #####################
  # FIXME: look at Portal/app/models/run_peer.rb command method
  def self.connect_to_stk(port, them, socket_name, time_out=1)

    count = 0

    while ( ! create_connection_to_stk(port, them, socket_name)) do
      if ( count == time_out)
        return false
      else
        count += 1
        sleep(1)
      end ## end of if
    end ## end of while

    return  true

  end ## end of def self.connect_to_stk



  ##############################
  # FIXME: Replace Perl junk with Ruby stuff (look at Portal/app/models/run_peer.rb command method)
  def self.create_connection_to_stk(port, host, socket_name)


    $read_char_flag = 1



    begin
      puts "... opening TCP port #{port} to #{host}" if $debug_stk
      $tcp_socket_hash[socket_name] = TCPSocket::new( host, port )
    rescue Exception => e
      puts "ERROR: unable to open TCPSocket"
      puts "TCP Socket Error: #{e}"
      puts "       host:  #{host}"
      puts "       port:  #{port}"
      exit(-1)
    end

    #    $tcp_socket_hash[socket_name]autoflush(1)

    remote = $tcp_socket_hash[socket_name]


    # Set socket to be command buffered.

    ack_on(socket_name)
    async_off(socket_name)
    $CONNECT_RESULT = "CONNECT_OK"

    # add to table of cmds that return data
    # NOTE: since many connections may be opened, to different versions of STK
    # it's important to add then together sicne there's only 1 hash table (not empty each time)

    add_to_returns_data_table(socket_name)

    return true

  end ## end of def self.create_connection_to_stk





  #################################
  ## Process the 'connect.dat' file
  ## FIXME: rework the sequence of over-rides

  def self.add_to_returns_data_table(socket_name=nil)

    filename              = ENV["STK_CONNECT_DAT"] ? ENV["STK_CONNECT_DAT"] : "connect.dat"

    connect_dat_fullpath  = Pathname.new(filename)
    connect_dat_basename  = connect_dat_fullpath.basename
    connect_dat_path      = connect_dat_fullpath.dirname

    if $debug_cmd or $debug_stk
      puts "DEBUG: add_to_returns_data_table >>>>>>>"
      puts "       basename: #{connect_dat_basename}"
      puts "           path: #{connect_dat_path}"
      puts "       fullpath: #{connect_dat_fullpath}"
    end

    result        = false
    output_array  = []
    stk_home_dir  = '.'   # default to the current directory

    if connect_dat_fullpath.absolute?
      # if its absolute and it exists, it came from the system environment variable
      # use it exclusively regardless wither the basename file exists anywhere else
      return add_to_con_cmd_returns_data_table(connect_dat_fullpath) if connect_dat_fullpath.exist?
      puts "..1. #{connect_dat_fullpath} does not exist." if $debug_cmd or $debug_stk
      return false
    end

    # it did not come from an environment variable so lets see where we can find it

    # first assume running on same machine as STK

    result = process_connect_command(socket_name, "GetSTKHomeDir /") if $tcp_socket_hash[socket_name]

    output_array  = result[1]
    result        = result[0]

    if $debug_cmd or $debug_stk
      puts "'GetSTKHomeDir /' result: #{result} output_array -=>"
      pp output_array
    end


    if result == 'ACK'
      stk_home_dir = output_array[0].chomp
    end

    puts "STK Home directory is #{stk_home_dir}" if $debug_cmd or $debug_stk
    stk_home_fullpath = Pathname.new(stk_home_dir) + connect_dat_basename

    return add_to_con_cmd_returns_data_table(stk_home_fullpath) if stk_home_fullpath.exist?
    puts "..2. #{stk_home_fullpath} does not exist." if $debug_cmd or $debug_stk

    ###########################
    # Look in current directory
    connect_dat_fullpath = Pathname.pwd + connect_dat_basename

    return add_to_con_cmd_returns_data_table(connect_dat_fullpath) if connect_dat_fullpath.exist?
    puts "..3. #{connect_dat_fullpath} does not exist." if $debug_cmd or $debug_stk

    #############################
    # Look in previous directory
    connect_dat_fullpath = Pathname.new("../") + connect_dat_basename

    return add_to_con_cmd_returns_data_table(connect_dat_fullpath) if connect_dat_fullpath.exist?
    puts "..4. #{connect_dat_fullpath} does not exist." if $debug_cmd or $debug_stk




    #####################################
    # Look in $ISE_ROOT/etc/STK directory
    connect_dat_fullpath = $ISE_ROOT + "etc" + "STK" + connect_dat_basename

    return add_to_con_cmd_returns_data_table(connect_dat_fullpath) if connect_dat_fullpath.exist?
    puts "..5. #{connect_dat_fullpath} does not exist." if $debug_cmd or $debug_stk




    puts "DEBUG: add_to_returns_data_table was unsuccessful in finding a file to load <<<<<<<<" if $debug_cmd or $debug_stk

    return false

  end ## end of def self.add_to_returns_data_table




  ############################################################
  def self.add_to_con_cmd_returns_data_table(path_to_connect_rc)
  
    puts "path_to_connect_rc; #{path_to_connect_rc}" if $debug_stk

    begin
      fh = File.open(path_to_connect_rc.to_s,'r')
    rescue
      print "ERROR add_to_con_cmd_returns_data_table: Could not open #{path_to_connect_rc} \n";
      return false
    end

    line_array = []  # start with an empty array
    fh.each_line do |a_line|
      line_array << a_line.chomp if a_line.length > 0 and a_line[0,1] != '#'
    end

    fh.close

    # only uncommented lines are in line_array

    line_array.each do |a_line|

      puts "a_line: #{a_line}" if $debug_cmd or $debug_stk

      if a_line =~ /ReturnsData\s+(\S.*)$/

        rest_of_line = $1

        puts "rest_of_line: #{rest_of_line}" if $debug_cmd or $debug_stk

        # return the position that the regex exists or nil if it does not
        multiple = ( rest_of_line.upcase =~ /MULTIPLE/ )

        cmd_name = rest_of_line.strip

        # SMELL: What is this do ???
        cmd_name = cmd_name.split(' ')[0]

        $return_data_table_lookup[cmd_name.upcase] = multiple ? 2 : 1   # 1 if single, 2 if multiple

        puts "(add_to_con_cmd_returns_data_table) cmd: #{cmd_name}, multiple: #{!multiple.nil?}" if $debug_stk

      end ## end of if a_line =~
    end ## end of line_array.each


    if $debug_cmd
      puts "Dump of $return_data_table_lookup ->"
      pp $return_data_table_lookup
    end

    return true      #true

  end ## end of def self.add_to_con_cmd_returns_data_table















  #######################
  def self.get_socket_result
    return $CONNECT_RESULT   ## FIXME: This is tied into low-level socket IO
  end ## end of def self.get_socket_result



  ###########
  def self.ack_on (socket_name)
    $ack_setting_hash[socket_name] = true
$stderr.puts "stk ack_on socket_name: #{socket_name}" if $debug_stk_ack
    rtn_ack = send_command_to_stk(socket_name, "ConControl / AckOn")
$stderr.puts "#{rtn_ack.pretty_inspect}" if $debug_stk_ack
  end ## end of def self.ack_on



  #############
  def self.is_ack_on(socket_name)

    return $ack_setting_hash[socket_name]

  end ## end of def self.is_ack_on



  ###########
  def self.ack_off(socket_name)
    $ack_setting_hash[socket_name] = false
$stderr.puts "stk ack_off socket_name: #{socket_name}" if $debug_stk_ack
    send_command_to_stk(socket_name, "ConControl / AckOff")
  end ## end of def self.ack_off



  ###########
  def self.async_on(socket_name)
    $async_setting_hash[socket_name] = true
    send_command_to_stk(socket_name, "ConControl / AsyncOn")
  end ## end of def self.async_on



  #############
  def self.is_async_on(socket_name)
    return $async_setting_hash[socket_name]
  end ## end of def self.is_async_on



  ############
  def self.async_off(socket_name)
    $async_setting_hash[socket_name] = false
    send_command_to_stk(socket_name, "ConControl / AsyncOff")
  end ## end of def self.async_off



  ############################
  def self.close_connection_to_stk(socket_name)
    ack_off(socket_name)
    send_command_to_stk(socket_name, "ConControl / Disconnect")
    $tcp_socket_hash[socket_name].close
    $tcp_socket_hash.delete socket_name
  end ## end of def self.close_connection_to_stk



  ###########
  def self.quit_stk(socket_name, parameter="")
    parameter = " #{parameter}" unless parameter == ""  ## Note space before #(...
    ack_off(socket_name)
    send_command_to_stk(socket_name, "ConControl / QuitStk#{parameter}") ## Note: no space before #{...
  end ## end of def self.quit_stk






  #######################
  def self.send_command_to_stk (socket_name, local_command)

    remote = $tcp_socket_hash[socket_name]
    
    pp $tcp_socket_hash if $debug_stk

    remote.send("#{local_command}#{$EOL}",0)

    puts "(send_command_to_stk) cmd: -=>[#{local_command}]<=-" if $debug_stk

    output_header = nil

    if is_ack_on(socket_name)

      puts "Ack is On"  if $debug_stk

      if (is_async_on(socket_name))

        puts "Async is On -- calling read_async_header_stk_output"  if $debug_stk

        async_header = read_async_header_stk_output(socket_name)

        if $debug_stk
          puts "DEBUG: send_command_to_stk >>>>>>>>>> #{local_command}"
          pp async_header
          puts "DEBUG: send_command_to_stk <<<<<<<<<<"
        end

        puts "calling read_chars_from_socket with async_header[9]: -=>[#{async_header[9]}]<=-"

        data = read_chars_from_socket(socket_name, async_header[9])

        puts "(send_command_to_stk) (AsyncOn) data: #{data}" if $debug_stk

        fist_char = async_header[5][0,1]

        if (fist_char == 'N')
          output_header = async_header[5][0,4]
        else
          output_header = async_header[5][0,3]
        end ## end of if

      else

        puts "Async is OFF -- doing remote.recv(1)"  if $debug_stk

        output_header = remote.recv(1)

        puts "output_header: #{output_header}" if $debug_stk

        if (output_header == 'N')
          char_count = 3
        else
          char_count = 2
        end ## end of if

        puts "calling read_chars_from_socket with char_count: #{char_count}" if $debug_stk

        rest_header = read_chars_from_socket(socket_name, char_count)

        puts "(send_command_to_stk) (AsyncOff) rest_header: #{rest_header}" if $debug_stk

        output_header << rest_header

        puts "ack hdr> #{output_header}"  if $debug_stk

      end ## end of if

    else

      puts "Ack is Off" if $debug_stk

    end ## end of if

    return output_header

  end ## end of def self.send_command_to_stk










  ###############################
  def self.read_async_stk_output(socket_name)

    output_data      = ""
    async_header     = read_async_header_stk_output(socket_name)
    num_of_packets   = async_header[7]

    (1..num_of_packets).each do |i|
      output_data = read_chars_from_socket(socket_name, async_header[9])
      if (i < async_header[8])
        async_header = read_async_header_stk_output(socket_name)
      end ## end of if
    end ## end of for

    return output_data.split("\n")

  end ## end of def self.read_async_stk_output





  ###############################
  def self.read_async_header_stk_output(socket_name)

    output_header_array = []
    output_header_array << read_chars_from_socket(socket_name, 3)   ## SyncPattern
    output_header_array << read_chars_from_socket(socket_name, 2)   ## HeaderLength
    output_header_array << read_chars_from_socket(socket_name, 1)   ## HeaderVer
    output_header_array << read_chars_from_socket(socket_name, 1)   ## HeaderRev
    output_header_array << read_chars_from_socket(socket_name, 2)   ## TypeLength
    output_header_array << read_chars_from_socket(socket_name, 15)  ## AsyncType
    output_header_array << read_chars_from_socket(socket_name, 6)   ## Ident
    output_header_array << read_chars_from_socket(socket_name, 4)   ## TotalPack
    output_header_array << read_chars_from_socket(socket_name, 4)   ## PackNum
    output_header_array << read_chars_from_socket(socket_name, 4)   ## DataLength

    return output_header_array

  end ## end of def self.read_async_header_stk_output



  ################################
  def self.read_stk_return_header_split(socket_name)

    header_length = 40

    output_header = read_chars_from_socket(socket_name, header_length)

    puts "(read_stk_return_header_split): <#{output_header}>" if $debug_stk

    cmd_name  = ""
    num       = 0

    if output_header =~ /^(\S+)\s+(\d+)/
      cmd_name = $1
      num      = $2
    end ## end of if

    return cmd_name, num   ## returns a two element array

  end ## end of def


  #################
  def self.remark(a_str, b_str=nil)
    puts "STK::remark -=> #{b_str.nil? ? a_str : b_str}"
  end


  #############################################################################
  def self.process_connect_command(socket_name, local_command)

    puts "DEBUG: entering pcc local_command: #{local_command}" if $debug_cmd or $debug_stk

    ret_array_ref = []  # first empty the array

    ########################
    # check for bad commands

    if local_command =~ /ConControl/

      puts "local_command is like ConControl" if $debug_cmd

      if local_command =~ /^\s*ConControl\s+\/\s+(\w+)(.*)/

        action = $1
        optionalParameter = $2


        puts "action: #{action} optionalParameter: #{optionalParameter}" if $debug_cmd



        if action =~ /AsyncOn|AckOff/

          puts "action is like AsyncOn|AckOff" if $debug_cmd

          #############
          # bad command

          puts "ERROR: process_connect_command cannot do \'#{local_command}\'"

          puts "DEBUG: leaving-1 pcc local_command: #{local_command}" if $debug_cmd or $debug_stk
          return [false]

        elsif action =~ /Disconnect/

          puts "action is like Disconnect" if $debug_cmd

          close_connection_to_stk(socket_name)

          puts "DEBUG: leaving-2 pcc local_command: #{local_command}" if $debug_cmd or $debug_stk

          return [true]

        elsif action =~ /QuitStk/

          puts "action is like QuitStk" if $debug_cmd

          quit_stk(socket_name, optionalParameter)
          puts "DEBUG: leaving-3 pcc local_command: #{local_command}" if $debug_cmd or $debug_stk
          return [true]

        end
      end
    end

    puts "sending local_command: #{local_command}" if $debug_cmd

    result = send_command_to_stk(socket_name, local_command)

    puts "Result> #{result}"   if $debug_cmd or $debug_stk

    if result == 'ACK'

      # determine if cmd returns data

      lc = local_command.strip  ## remove all white space from left and right
      cmd = lc.split(' ')[0]    ## ignore all but the command name keyword

      if $debug_cmd
        puts "lc:  #{lc}"
        puts "cmd: #{cmd}"
      end

      kind_of_response = $return_data_table_lookup[cmd.upcase]

      puts "cmd <#{cmd}>  kind_of_response: <#{kind_of_response}>"    if $debug_cmd or $debug_stk


      unless kind_of_response.nil?

        if kind_of_response == 1

          # single line read method
          puts "Single Line Read!"   if  $debug_cmd or $debug_stk
          ret_array_ref = read_stk_single_line_output(socket_name)

        elsif kind_of_response == 2

          # multiple line read method
          puts "Multiple Line Read!" if $debug_cmd or $debug_stk
          ret_array_ref = read_stk_multiple_line_output(socket_name)


        end ## end of if retReadMethod == 1
      end ## end of unless retReadMethod.nil?
    else
      puts "result was not 'ACK'" if $debug_cmd
    end ## end of if result == 'ACK'


    if $debug_cmd or $debug_stk
      puts "DEBUG: leaving pcc w/result: #{result}"
      pp ret_array_ref
    end

    puts "DEBUG: leaving-last pcc local_command: #{local_command}" if $debug_cmd or $debug_stk

    return [result, ret_array_ref]

  end ## end of def self.process_connect_command





  ##############################
  def self.read_stk_single_line_output(socket_name)

    array_ref = []

    cmd_name, num = read_stk_return_header_split(socket_name)
      
    reply_msg = read_chars_from_socket(socket_name, num)  # this line is the returned data

    if array_ref

      formatSubRef = $returns_data_format_lookup[cmd_name.upcase]

      if formatSubRef

        #eval("#{formatSubRef}(reply_msg, array_ref)") ## SMELL: Is this suppose to return anything?
        array_ref << reply_msg

      else
      
        array_ref << reply_msg

      end ## end of if
    end ## end of if

    return array_ref

  end ## end of def self.read_stk_single_line_output





  ################################
  def self.read_stk_multiple_line_output(socket_name)

    array_ref = []

    cmd_name, num = read_stk_return_header_split(socket_name)


    numRows = read_chars_from_socket(socket_name, num).to_i   # number of packages to read

    print "NumRows in MultiLineRead> #{numRows}\n"  if $debug_stk


    numRows.times do |i|

      cmd_name, num = read_stk_return_header_split(socket_name)

      print "Row(#{i})> #{cmd_name}, #{num}\n" if $debug_stk

      a_line = read_chars_from_socket(socket_name, num)

      print "Row> #{a_line} \n" if $debug_stk

      unless array_ref.nil?

        # formatting: if inside a quoted string, a \n appears, then change it into a !

        a_line.chomp!

        if(a_line =~ /\n/)

          # found a newline

          strs = a_line.split('"')

          j = strs.length

          print "J> #{j}\n"   if $debug_stk

          (1..j).step(2) do |k|
            # SMELL: whats this? replace \n with a space and a banger?? for every other line
            strs[k].gsub!(/\n/, ' !')   ## replace end of line with space-banger
          end ## end of for

          a_line = strs.join('"')
        end ## end of if

        array_ref << a_line
      end ## end of if
    end ## end of for


    return array_ref


  end ## end of def self.read_stk_multiple_line_output











  ##########################################
  #
  # STK related utilities - may be old or only work on UNIX
  #



  ##############
  # FIXME: DRY
  def self.stk_home(socket_name)

    # SMELL: should STKSocket1 be socket_name
    result = send_command_to_stk(socket_name, "GetReport * \"InstallInfoCon\" ")

    unless 'ACK' == result
      puts "Did not get expected 'ACK' to GetReport command" if $debug_cmd or $debug_stk
      return ""
    end


    install_result_array = read_stk_output(socket_name)

    length_of_install_result_array = install_result_array.length

    return  install_result_array[4]   ## Perl had it at 3

  end ## end of def self.stk_home(socket_name)



  #####################
  # FIXME: DRY
  def self.user_config_dir(socket_name)
    # SMELL: should STKSocket1 be socket_name
    result = send_command_to_stk(socket_name, "GetReport * \"InstallInfoCon\" ")

    unless 'ACK' == result
      puts "Did not get expected 'ACK' to GetReport command" if $debug_cmd or $debug_stk
      return ""
    end

    install_result_array = read_stk_output(socket_name)
    length_of_install_result_array = install_result_array.length

    return install_result_array[7]  ## Perl had it as 5

  end ## end of def self.user_config_dir



  ##################
  # FIXME: DRY
  def self.stk_version(socket_name)

    # SMELL: should STKSocket1 be socket_name
    result = send_command_to_stk(socket_name, "GetReport * \"InstallInfoCon\" ")

    unless 'ACK' == result
      puts "Did not get expected 'ACK' to GetReport command" if $debug_cmd or $debug_stk
      return ""
    end

    install_result_array = read_stk_output(socket_name)
    length_of_install_result_array = install_result_array.length

    return install_result_array[1]

  end ## end of def self.stk_version



  #############
  # FIXME: DRY
  def self.stk_db(socket_name)

    puts "Entered stk_db" if $debug_cmd or $debug_stk

    result = send_command_to_stk(socket_name, "GetReport * \"InstallInfoCon\" ")

    unless 'ACK' == result
      puts "Did not get expected 'ACK' to GetReport command" if $debug_cmd or $debug_stk
      return ""
    end

    install_result_array = read_stk_output(socket_name)
    length_of_install_result_array = install_result_array.length

    if $debug_cmd or $debug_stk
      puts "install_result_array -=>"
      pp install_result_array
    end

    puts "leaving stk_db returning: #{install_result_array[10]}" if $debug_cmd or $debug_stk

    return install_result_array[10]   # Perl: had it as 7

  end ## end of def self.stk_db






  ##########################################################
  ## SMELL: Not sure anything past this line is really used



  ########################
  def self.read_stk_output_raw(socket_name)

    # reads the STK return Header in order to parse the message correctly
    # then reads in the message and returns the message

    cmdName         = ""
    outputreplymsg  = ""

    headerLength = 40

    output_header = read_chars_from_socket(socket_name, headerLength)

    if output_header =~ /^(\S+)\s+(\d+)/

      cmdName = $1
      num     = $2

      # TODO this below may be a Multiple line decision being made baseed on hard-coded data!

      if $read_data_function_registration[cmdName].nil?

        # just read this many chars

        outputreplymsg = read_chars_from_socket(socket_name, num)

      else

        # use registered read function

        subRef = $read_data_function_registration[cmdName]

        puts "DEBUG: read_stk_output_raw doing eval on: #{subRef}" if $debug_cmd or $debug_stk

        # FIXME: invoke method stored in $read_data_function_registration with two parameters
        outputreplymsg = eval("#{subRef}(socket_name, num)")

      end ## end of if

    else

      print "Error reading header: #{output_header}\n"

    end ## end of if

    return cmdName, outputreplymsg

  end ## end of def self.read_stk_output_raw



  ###################
  def self.read_stk_output(socket_name)

    # reads the STK return Header inorder to parse the message correctly
    # then reads in the message and returns the message

    cmd, output_reply_msg = read_stk_output_raw(socket_name)

    my_array = []

    # This is an extra formatting step

    if $data_that_split_on_carriage_returns.include? cmd
      my_array  = output_reply_msg.split("\n")
    else
      my_array  = output_reply_msg.split(',')
    end ## end of if

    return my_array

  end ## end of def self.read_stk_output



  ############################
  def self.read_stk_return_header(socket_name)

    header_length = 40

    output_header = read_chars_from_socket(socket_name, header_length)

    output_header.gsub!(' ', ',')    ## SMELL: replace all spaces with commas.... why?
    output_header_array = output_header.split(',')

    return output_header_array

  end ## end of def self.read_stk_return_header



  #############
  def self.con_log(con_log_state, con_file_path)

    #CON_LOG (ON/OFF, [file_path if ON])


    if (con_log_state == "ON")
      conlog_file = File.open(con_file_path, 'a')
      conlog_file.print "\n#{Time.now}\t OPEN \t CON_LOG $con_file_path"
    end ## end of if

    if (con_log_state == "OFF")
      conlog_file.print "\n#{Time.now}\t CLOSE \t CON_LOG\n"
      close conlog_file
    end ## end of if

  end ## end of def self.con_log






  ##########################################
  #
  # (old) Reading mutliple line msgs and post-receive formatting
  #
  ##############
  def self.read_report(socket_name, length_of_data)

    msgs = []

    length_of_data = length_of_data.to_i if length_of_data.class.to_s == 'String'

    number_of_rows = read_chars_from_socket(socket_name, length_of_data).to_i

    print "number_of_rows> #{number_of_rows}\n" if $debug_stk

    number_of_rows.times do |i|

      cmdName, num = read_stk_return_header_split(socket_name)

      print "Row(#{i})> #{cmdName}, #{num}\n" if $debug_stk

      msgs << read_chars_from_socket(socket_name, num).chomp

      print "Row> #{msgs[i]} \n" if $debug_stk

      # formatting: if inside a quoted string, a \n appears, then change it into a !

      if(msgs[i] =~ /\n/)

        # found a newline

        strs = msgs[i].split('"')

        j = strs.length
        print "J> #{j}\n"   if $debug_stk

        (1..j).step(2) do |k|
          strs[k].gsub!(/\n/, ' !')   ## SMELL: replace end of line with a space-banger
        end ## end of for

        msgs[i] = strs.join('"')
      end ## end of if
    end ## end of for

    output_reply_msg = msgs.join("\n")

    return output_reply_msg

  end ## end of def self.read_report



  ###################################################
  def self.first_2spaces_then_cr_seperate_data(socket_name, length_of_data)

    # reads the STK return Header inorder to parse the message correctly
    # then reads in the message and returns the message


    output_reply_msg = read_chars_from_socket(socket_name, length_of_data)

    # in an ODD choice, the AER cmd returns "objPath1 objPath2 first_time_a_e_r \n next time_a_e_r \n etc.
    # SO... put commas after each path

    output_reply_msg.gsub!(/(\S+)\s+/) {|s| s+','}  ## replace sequences of white-space following a word with a comma



    # formatting: replace \n with ,

    output_reply_msg.gosub!(/\n/, ',')  ## replace end of line with a comma

    return output_reply_msg

  end ## end of def self.first_2spaces_then_cr_seperate_data




  #########################
  def self.spaces_seperate_data(socket_name, length_of_data)

    # reads the STK return Header inorder to parse the message correctly
    # then reads in the message and returns the message


    output_reply_msg = read_chars_from_socket(socket_name, length_of_data)

    # this is space separated: use commas instead, and remove leading /

    print "output_reply_msg: #{output_reply_msg}\n" if $debug_stk

    output_reply_msg.gsub!(/(\w) \//) {|s| s+','} ## change 'SSS /' into 'SSS,/' where SSS is any word
    output_reply_msg.gsub!(/^ \//, '')            ## remove leading ' /'

    print "VTC> #{output_reply_msg}\n"  if $debug_stk

    return output_reply_msg

  end ## end of def self.spaces_seperate_data




  #########################
  def self.read_time_period_data(socket_name, length_of_data)

    output_reply_msg = read_chars_from_socket(socket_name, length_of_data)

    # returned data is date_1, date_2 WITH the space after the comma!!!
    # So.. remove it!

    output_reply_msg.gsub!(', ', ',')

    return  output_reply_msg

  end ## end of def self.read_time_period_data







  #######################
  def self.load_obj_in_array(socket_name, type_of_obj, obj_array)
    #send Objectarray Type (Facility, Missile,...) and Pointer to array


    length_of_array = obj_array.length
    print "length_of_array  = #{length_of_array} \n" if $debug_stk

    obj_array.each do |obj_to_load|
      send_command_to_stk(socket_name, "Load / */#{type_of_obj} #{obj_to_load}")
    end ## end of for

  end ## end of def self.load_obj_in_array








  ###############################
  def self.return_list_of_object_type(socket_name, object_type_sub)
    # This subroutine retuns a comma delimited list of all scenario objects of type $ObjectTypesub.
    # $ObjectTypesub (Facility, Sensor, Target, Sattellite, ..)

    object_type_list_sub = ""

    send_command_to_stk(socket_name, "AllInstanceNames /")

    all_instance_array_sub = read_stk_output(socket_name)

    length_all_instance_array_sub = all_instance_array_sub.length
    scenario_name_sub = all_instance_array_sub[0]

    (0..length_all_instance_array_sub).each do |j|
      scenario_object_array_sub = all_instance_array_sub[j].split('/')
      length_scenario_object_array_sub = scenario_object_array_sub.length
      scenario_object_type_sub = scenario_object_array_sub[length_scenario_object_array_sub - 1]

      print "scenario_object_type_sub = #{scenario_object_type_sub}\n" if $debug_stk

      if (scenario_object_type_sub == object_type_sub)

        print "all_instance_array_sub[#{j}] = #{all_instance_array_sub[j]}\n" if $debug_stk

        all_instance_array_sub[j].chomp!
        object_type_list_sub << "#{all_instance_array_sub[j]},"
      end ## end of if
    end ## end of for

    object_type_list_sub.chop!
    return  object_type_list_sub

  end ## end of def self.return_list_of_object_type




  #######################
  # FIXME: low-level reading characters from socket
  def self.read_chars_from_socket(socket_name, len)


    if len.class.to_s == 'String'
      puts "DEBUG: read_chars_from_socket len is type String; using to_i function" if $debug_stk
      len = len.to_i
    end

    puts "DEBUG: read_chars_from_socket len: #{len}" if $debug_stk


    line = ""

    unless len > 0
      puts "DEBUG: read_chars_from_socket len is not > 0: #{len}" if $debug_stk
      return line
    end


    puts "DEBUG: read_chars_from_socket $read_char_flag: #{$read_char_flag}" if $debug_stk


    if($read_char_flag == 1)

      remote = $tcp_socket_hash[socket_name]
      chars = remote.recv(len)

      puts "DEBUG: read_chars_from_socket chars: -=>[#{chars}]<=-" if $debug_stk

      line = chars


=begin
    elsif($read_char_flag == 2)

      win = ''

      vec($win, fileno(socket_name), 1) = 1

      timeout = 10
      done = false
      retLine = ""
      count = 0

      while ( !done  ) do

        nfound = select($wout = $win, undef, undef, $timeout);  #wait until ready for reading

        ret = recv socket_name, retLine, len, 0  # 0 is a flag

        retLen = retLine.length

        line << retLine

        if (len == retLen)
          done = true
        else
          len -= retLen
          retLine = ""
        end ## end of if
        count += 1
      end ## end of while
=end

    end ## end of if


=begin
      if false # FIXME: WTF

        chars = []

        len.times do |i|
          chars[i-1] = getc(socket_name)
        end

        line = chars.join('')
      end ## end of if
=end


=begin
      if false ## FIXME: WTF

        line=""

        len.times do
          char = getc(socket_name)
          line << char
        end
      end ## end of if
=end




    return line

  end ## end of def self.read_chars_from_socket




  ###########################################
  ## Perlish helper functions
  ## These helper functions implement some of the Perl junk
  ## so that the functional code is not rewritten.
  ## Intend to re-architect into an OO design later

  def self.getc(socket_name)

    return $tcp_socket_hash[socket_name].recv(1)

  end ## end of def self.getc
  

  class << self
    alias :send_msg :process_connect_command
  end



end ## end of module STK

