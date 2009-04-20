package demoidl.hello;

import org.omg.PortableServer.POA;

/**
 * Generated from IDL interface "IHello".
 *
 * @author JacORB IDL compiler V 2.3.0, 17-Feb-2007
 * @version generated at Feb 17, 2009 4:47:26 PM
 */

public class IHelloPOATie
	extends IHelloPOA
{
	private IHelloOperations _delegate;

	private POA _poa;
	public IHelloPOATie(IHelloOperations delegate)
	{
		_delegate = delegate;
	}
	public IHelloPOATie(IHelloOperations delegate, POA poa)
	{
		_delegate = delegate;
		_poa = poa;
	}
	public demoidl.hello.IHello _this()
	{
		return demoidl.hello.IHelloHelper.narrow(_this_object());
	}
	public demoidl.hello.IHello _this(org.omg.CORBA.ORB orb)
	{
		return demoidl.hello.IHelloHelper.narrow(_this_object(orb));
	}
	public IHelloOperations _delegate()
	{
		return _delegate;
	}
	public void _delegate(IHelloOperations delegate)
	{
		_delegate = delegate;
	}
	public POA _default_POA()
	{
		if (_poa != null)
		{
			return _poa;
		}
		return super._default_POA();
	}
	public void sayHello()
	{
_delegate.sayHello();
	}

}
