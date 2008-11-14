package demoidl.hello;


/**
 * Generated from IDL interface "IHello".
 *
 * @author JacORB IDL compiler V 2.3.0, 17-Feb-2007
 * @version generated at Nov 13, 2008 6:53:42 PM
 */

public class _IHelloStub
	extends org.omg.CORBA.portable.ObjectImpl
	implements demoidl.hello.IHello
{
	private String[] ids = {"IDL:demoidl/hello/IHello:1.0"};
	public String[] _ids()
	{
		return ids;
	}

	public final static java.lang.Class _opsClass = demoidl.hello.IHelloOperations.class;
	public void sayHello()
	{
		while(true)
		{
		if(! this._is_local())
		{
			org.omg.CORBA.portable.InputStream _is = null;
			try
			{
				org.omg.CORBA.portable.OutputStream _os = _request( "sayHello", true);
				_is = _invoke(_os);
				return;
			}
			catch( org.omg.CORBA.portable.RemarshalException _rx ){}
			catch( org.omg.CORBA.portable.ApplicationException _ax )
			{
				String _id = _ax.getId();
				throw new RuntimeException("Unexpected exception " + _id );
			}
			finally
			{
				this._releaseReply(_is);
			}
		}
		else
		{
			org.omg.CORBA.portable.ServantObject _so = _servant_preinvoke( "sayHello", _opsClass );
			if( _so == null )
				throw new org.omg.CORBA.UNKNOWN("local invocations not supported!");
			IHelloOperations _localServant = (IHelloOperations)_so.servant;
			try
			{
				_localServant.sayHello();
			}
			finally
			{
				_servant_postinvoke(_so);
			}
			return;
		}

		}

	}

}
