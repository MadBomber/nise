#########################################################################
###
##  File:   pathname_mods.rb
##  Desc:   Modifications to the Pathname class to fix problems under Windoze
##
##  Problem Statement:
##
##      MS Windows sucks!  The standard path seperator under windows is
##      the backslash.  Forward slashes are used to indicate switches on
##      the command line within the cmd.exe shell.  A pathname in the
##      form of C:/a/b/c is treated the same as C: /a /b /c where the
##      /a /b and /c elements are either together or space seperated.
##      All paths created to be used by windows cmd.exe shells must have
##      the correct path seperator.
##

require 'pathname'      ## StdLib: Cross-platform File and Directory

class Pathname  ## modifications to existing class

  def to_s

    if RUBY_PLATFORM.include? "mswin32"
      mswin32_normalize_path
    end

    @path.dup   ## This is all the original stdlib method does

  end   ## end of def to_s


  def mswin32_normalize_path

    # File::SEPARATOR       contains '/'
    # File::ALT_SEPARATOR   contains '\\'

    # replace every File::SEPARATOR with File:ALT_SEPARATOR

    @path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR) if @path.include? File::SEPARATOR

  end   ## end of mswin32_normalize_path


  # Used by the STK libraries
  def stkfmt
    mswin32_normalize_path    
    return sprintf('"%s"', @path)
  end ## end of def stkfmt


end ## end of class Pathname
