package demoidl.hello;


/**
 * Generated from IDL interface "IHello".
 *
 * @author JacORB IDL compiler V 2.3.0, 17-Feb-2007
 * @version generated at Nov 13, 2008 6:53:42 PM
 */

public abstract class IHelloPOA
	extends org.omg.PortableServer.Servant
	implements org.omg.CORBA.portable.InvokeHandler, demoidl.hello.IHelloOperations
{
	static private final java.util.Hashtable m_opsHash = new java.util.Hashtable();
	static
	{
		m_opsHash.put ( "sayHello", new java.lang.Integer(0));
	}
	private String[] ids = {"IDL:demoidl/hello/IHello:1.0"};
	public demoidl.hello.IHello _this()
	{
		return demoidl.hello.IHelloHelper.narrow(_this_object());
	}
	public demoidl.hello.IHello _this(org.omg.CORBA.ORB orb)
	{
		return demoidl.hello.IHelloHelper.narrow(_this_object(orb));
	}
	public org.omg.CORBA.portable.OutputStream _invoke(String method, org.omg.CORBA.portable.InputStream _input, org.omg.CORBA.portable.ResponseHandler handler)
		throws org.omg.CORBA.SystemException
	{
		org.omg.CORBA.portable.OutputStream _out = null;
		// do something
		// quick lookup of operation
		java.lang.Integer opsIndex = (java.lang.Integer)m_opsHash.get ( method );
		if ( null == opsIndex )
			throw new org.omg.CORBA.BAD_OPERATION(method + " not found");
		switch ( opsIndex.intValue() )
		{
			case 0: // sayHello
			{
				_out = handler.createReply();
				sayHello();
				break;
			}
		}
		return _out;
	}

	public String[] _all_interfaces(org.omg.PortableServer.POA poa, byte[] obj_id)
	{
		return ids;
	}
}
