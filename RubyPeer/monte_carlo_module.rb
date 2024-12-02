##########################################################
###
##  File: monte_carlo_module.rb
##  Desc: Defines the default behavior for IseRubyModels
##        Establishes hooks init_case, step, end_case, end_run
#

module MonteCarlo

  ##################################################
  ## Allow IseRubyModel to over-ride require methods
  
  def self.register(model_name)
  
    [:init_case, :step, :end_case, :end_run].each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__
        def self.#{sym}(header=nil,message=nil)
          #{model_name}.#{sym}(header,message)
        end
      EOS
    end
  
  end ## end of def self.register(model_name)


  #############
	def self.init_case(header=nil,message=nil)
    puts "Default Peerrb::MonteCarlo.init_case; expect IseRubyModel to over-ride" if $debug or $verbose
	end
	
	########
	def self.step(header=nil,message=nil)
    puts "Default Peerrb::MonteCarlo.step; expect IseRubyModel to over-ride" if $debug or $verbose
  end
	
	############
	def self.end_case(header=nil,message=nil)
    puts "Default Peerrb::MonteCarlo.end_case; expect IseRubyModel to over-ride" if $debug or $verbose
	end
	
	###########
	def self.end_run(header=nil,message=nil)
    puts "Default Peerrb::MonteCarlo.end_run; expect IseRubyModel to over-ride" if $debug or $verbose
	end

end  ## end of modeule Peerrb::MonteCarlo

