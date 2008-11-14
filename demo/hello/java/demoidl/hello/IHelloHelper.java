package demoidl.hello;


/**
 * Generated from IDL interface "IHello".
 *
 * @author JacORB IDL compiler V 2.3.0, 17-Feb-2007
 * @version generated at Nov 13, 2008 6:53:42 PM
 */

public final class IHelloHelper
{
	public static void insert (final org.omg.CORBA.Any any, final demoidl.hello.IHello s)
	{
			any.insert_Object(s);
	}
	public static demoidl.hello.IHello extract(final org.omg.CORBA.Any any)
	{
		return narrow(any.extract_Object()) ;
	}
	public static org.omg.CORBA.TypeCode type()
	{
		return org.omg.CORBA.ORB.init().create_interface_tc("IDL:demoidl/hello/IHello:1.0", "IHello");
	}
	public static String id()
	{
		return "IDL:demoidl/hello/IHello:1.0";
	}
	public static IHello read(final org.omg.CORBA.portable.InputStream in)
	{
		return narrow(in.read_Object(demoidl.hello._IHelloStub.class));
	}
	public static void write(final org.omg.CORBA.portable.OutputStream _out, final demoidl.hello.IHello s)
	{
		_out.write_Object(s);
	}
	public static demoidl.hello.IHello narrow(final org.omg.CORBA.Object obj)
	{
		if (obj == null)
		{
			return null;
		}
		else if (obj instanceof demoidl.hello.IHello)
		{
			return (demoidl.hello.IHello)obj;
		}
		else if (obj._is_a("IDL:demoidl/hello/IHello:1.0"))
		{
			demoidl.hello._IHelloStub stub;
			stub = new demoidl.hello._IHelloStub();
			stub._set_delegate(((org.omg.CORBA.portable.ObjectImpl)obj)._get_delegate());
			return stub;
		}
		else
		{
			throw new org.omg.CORBA.BAD_PARAM("Narrow failed");
		}
	}
	public static demoidl.hello.IHello unchecked_narrow(final org.omg.CORBA.Object obj)
	{
		if (obj == null)
		{
			return null;
		}
		else if (obj instanceof demoidl.hello.IHello)
		{
			return (demoidl.hello.IHello)obj;
		}
		else
		{
			demoidl.hello._IHelloStub stub;
			stub = new demoidl.hello._IHelloStub();
			stub._set_delegate(((org.omg.CORBA.portable.ObjectImpl)obj)._get_delegate());
			return stub;
		}
	}
}
