package <%= package_path %>;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ise.EventMgr;
import ise.utils.log4j.Log4jConfigUtils;

public class <%= model_name.camelize %>Main {
    private static Logger mLogger = LoggerFactory.getLogger(<%= model_name.camelize %>Main.class);

	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		
	    String logFileName = "<%= model_name.camelize %>Log";
	    
	    Log4jConfigUtils.loadLog4jConfigProperites(logFileName);
	    
		mLogger.info("Entering<%= model_name.camelize %>Main.");
		
		// initialize
		if ( EventMgr.instance().init(args, <%= model_name.camelize %>Main.class.getSimpleName()) < 0 )
		{
			mLogger.info("System did not initialize.");
			System.exit(-1);
		}

		try
		{
			<%= model_name.camelize %>.instance().init();
		}
		catch(Exception e)
		{
			mLogger.error("Could not Initialize <%= model_name.camelize %>", e);
			System.exit(-1);			
		}

		try {
			EventMgr.instance().run();
		}
		catch (IOException e)
        {
            mLogger.debug("<%= model_name.camelize %>Main::run", e);
        }
		finally
		{
			Observer.instance().fini();
			EventMgr.instance().fini();
		}

		mLogger.info("Exiting <%= model_name.camelize %>Main.");

		return;
	}

}
