/* Local pagination patch for Fredy 29.2.1. No database or notification side effects. */
export async function collectSearchPages(fetchPage, {
  pageSize = 100, maxPages = 5, budgetMs = 180000, delayMs = 1000,
  now = Date.now, wait = ms => new Promise(resolve => setTimeout(resolve, ms)),
} = {}) {
  const deadline = now() + budgetMs;
  const items = new Map();
  const scanned = new Set();
  let pages = 0, total = null;
  const result = (complete, reason) => ({ items: [...items.values()], pages, total, complete, reason });
  for (let page = 1; page <= maxPages; page++) {
    if (page > 1) {
      if (now() + delayMs >= deadline) return result(false, 'time budget');
      await wait(delayMs);
    }
    const timeout = Math.min(20000, deadline - now());
    if (timeout <= 0) return result(false, 'time budget');
    let data;
    try { data = await fetchPage(page, pageSize, timeout, deadline); }
    catch (error) { return result(false, error?.message || 'request failed'); }
    pages++;
    if (!Array.isArray(data?.items) || !Array.isArray(data?.ids)) return result(false, 'invalid page');
    if (Number.isFinite(data.total) && data.total >= 0) total = data.total;
    const before = scanned.size;
    for (const id of data.ids) if (id != null) scanned.add(String(id));
    for (const item of data.items) if (item?.id != null && !items.has(String(item.id))) items.set(String(item.id), item);
    if (data.error) return result(false, data.error);
    if (total != null && scanned.size >= total) return result(true, 'reported total');
    if (data.ids.length === 0) return result(total == null, total == null ? 'empty page' : 'empty page before total');
    if (scanned.size === before) return result(false, 'repeated page');
    if (Number.isInteger(data.pageCount) && page >= data.pageCount) {
      return result(total == null || scanned.size >= total, 'reported last page');
    }
    // A full last page without metadata requires another request to prove completion.
    if (total == null && data.pageCount == null && data.ids.length < pageSize) return result(true, 'short page');
  }
  return result(false, 'page limit');
}
