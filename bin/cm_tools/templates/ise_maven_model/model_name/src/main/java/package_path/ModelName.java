package <%= package_path %>;

import ise.IseInitializationException;
import ise.ModelBase;

public class <%= model_name.camelize %> extends MccModelBase
{
	// =======================================================================================================================================
	private <%= model_name.camelize %>()
	{
		super();
	}

	// =======================================================================================================================================
	public static <%= model_name.camelize %> instance() 
	{
		if (mInstance == null)
		{
			mInstance = new Observer();			
		}	

		return (<%= model_name.camelize %>) mInstance;
	}

	// =======================================================================================================================================
	public void init()  throws IseInitializationException
	{
		super.init();
	}
	
	// =======================================================================================================================================
	public void fini() 
	{
		super.fini();
	}

	// =======================================================================================================================================
	@Override
	public StringBuilder info()
	{
		StringBuilder log_msg = new StringBuilder().append(super.info());
		log_msg.append("<%= model_name.camelize %>\n");
		return log_msg;
	}
}
