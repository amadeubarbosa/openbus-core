package demoidl.hello;

/**
 * Generated from IDL interface "IHello".
 *
 * @author JacORB IDL compiler V 2.3.0, 17-Feb-2007
 * @version generated at Nov 13, 2008 6:53:42 PM
 */

public final class IHelloHolder	implements org.omg.CORBA.portable.Streamable{
	 public IHello value;
	public IHelloHolder()
	{
	}
	public IHelloHolder (final IHello initial)
	{
		value = initial;
	}
	public org.omg.CORBA.TypeCode _type()
	{
		return IHelloHelper.type();
	}
	public void _read (final org.omg.CORBA.portable.InputStream in)
	{
		value = IHelloHelper.read (in);
	}
	public void _write (final org.omg.CORBA.portable.OutputStream _out)
	{
		IHelloHelper.write (_out,value);
	}
}
