
Creates a dm-writecache device on top of a artiically slow device.

dm-writecache is easier to use than dm-cache.

dm-writecache is enough, because reads should be cached in page cache.

This is done with DM, but LVM supports the same, just liek stratis does.

Overall dm-cache confirmed that performance is higer when using fio on slow vs cached device.
