#################################################################
###
##  File: IseRouter.rb
##  Desc: Defines the available IseMessage Routers.  The first one created for ISE
##        is the IseDispatcher.  The next one created makes use of the AMQP protocol
##        with the RabbitMQ Server.
#

require 'debug_me'

module IseRouter

  VALID_ROUTERS   = [:dispatcher, :amqp, :both]
  DEFAULT_ROUTER  = VALID_ROUTERS[0]
  
  
  ####################################################
  ## test for a valid router
  def valid_router?
    return VALID_ROUTERS.include?(@router)
  end
  
  ####################################################
  ## return the instance variable @router
  def router
    @router
  end
  
  ####################################################
  ## validate assignments to @router
  def router=(a_router)
  
    case a_router.class.to_s
      when 'String' then
        my_router = a_router.to_sym
      when 'Symbol' then
        my_router = a_router
      else
        raise(::RuntimeError, "Invalid IseRouter: #{a_router}", caller)
    end
  
    if :default == my_router
      my_router = DEFAULT_ROUTER
    else
      raise(::RuntimeError, "Invalid IseRouter: #{my_router}", caller) unless VALID_ROUTERS.include?(my_router)
      my_router = a_router
    end
    
    @router = my_router
    
  end

end ## end of module IseRouter

