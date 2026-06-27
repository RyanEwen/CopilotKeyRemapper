using System.Collections.Generic;

namespace Repilot.Helpers;

/// <summary>
/// A keyed list used as the item source for a grouped <c>CollectionViewSource</c>.
/// The <see cref="Key"/> is bound by the ListView's group-header template.
/// </summary>
public sealed class Grouping<TKey, TItem> : List<TItem>
{
    public TKey Key { get; }

    public Grouping(TKey key, IEnumerable<TItem> items) : base(items) => Key = key;
}
