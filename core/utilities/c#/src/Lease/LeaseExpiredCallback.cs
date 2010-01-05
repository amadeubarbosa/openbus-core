

namespace OpenbusAPI.Lease
{
  /// <summary>
  /// Define como informar que a renovação do <i>lease</i> expirou.
  /// </summary>
  public interface LeaseExpiredCallback
  {
    /// <summary>
    /// Informa que o <i>lease</i> expirou e não será mais renovado pelo
    /// <seealso cref="LeaseRenewer"/>
    /// </summary>
    void Expired();
  }
}
