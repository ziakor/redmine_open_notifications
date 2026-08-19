document.addEventListener('DOMContentLoaded', () => {

  const I18N = Object.assign({
    title: 'Notifications',
    markAllRead: 'Mark all read',
    viewAll: 'View all notifications',
    loading: 'Loading...',
    empty: 'No notifications yet.',
    emptyUnread: 'No unread notifications.'
  }, (window.RedmineOpenNotifications || {}).i18n || {});

  const menuIcon = document.getElementById('notifications-menu-icon');
  if (!menuIcon) return;

  const webpushEnabled = !!(window.RedmineOpenNotifications || {}).webpushEnabled;

  if (webpushEnabled && typeof Notification !== 'undefined' && Notification.permission === 'default') {
    Notification.requestPermission();
  }

  let badge = document.getElementById('notifications-badge-count');
  if (!badge) {
    badge = document.createElement('span');
    badge.id = 'notifications-badge-count';
    badge.style.display = 'none';
    menuIcon.appendChild(badge);
  }

  let dropdown = document.getElementById('notifications-dropdown-popup');
  if (!dropdown) {
    dropdown = document.createElement('div');
    dropdown.id = 'notifications-dropdown-popup';
    dropdown.innerHTML = `
      <div class="notif-header">
        <strong>${escapeHtml(I18N.title)}</strong>
        <div>
          <a href="#" id="notif-mark-all-read" style="font-size: 11px;">${escapeHtml(I18N.markAllRead)}</a>
        </div>
      </div>
      <div class="notif-body">
        <ul id="notif-items-list">
          <li class="notif-empty">${escapeHtml(I18N.loading)}</li>
        </ul>
      </div>
      <div class="notif-footer">
        <a href="/user_notifications">${escapeHtml(I18N.viewAll)}</a>
      </div>
    `;
    document.body.appendChild(dropdown);
  }

  let lastNotifiedId = parseInt(sessionStorage.getItem('last_notified_id') || '0', 10);

  function loadNotifications() {
    fetch('/user_notifications', {
      headers: { 'Accept': 'application/json' },
      credentials: 'same-origin'
    })
      .then(res => {
        if (!res.ok) throw new Error('Network or auth error');
        return res.json();
      })
      .then(data => {
        if (Array.isArray(data)) {
          const unreadCount = data.filter(n => !n.read_at).length;
          badge.textContent = unreadCount;
          badge.style.display = unreadCount > 0 ? 'inline-block' : 'none';
          renderDropdownItems(data);

          const latestUnread = data.find(n => !n.read_at);
          if (latestUnread) {
            if (lastNotifiedId === 0) {
              lastNotifiedId = latestUnread.id;
              sessionStorage.setItem('last_notified_id', lastNotifiedId.toString());
            } else if (latestUnread.id > lastNotifiedId) {
              lastNotifiedId = latestUnread.id;
              sessionStorage.setItem('last_notified_id', lastNotifiedId.toString());
              triggerPushNotification(latestUnread.title, stripHtml(latestUnread.body), latestUnread.issue_id);
            }
          }
        }
      })
      .catch(() => {
        const list = document.getElementById('notif-items-list');
        if (list) {
          list.innerHTML = `<li class="notif-empty">${escapeHtml(I18N.emptyUnread)}</li>`;
        }
      });
  }

  function triggerPushNotification(title, body, issueId) {
    if (webpushEnabled && typeof Notification !== 'undefined' && Notification.permission === 'granted') {
      const toast = new Notification(title, {
        body: body,
        icon: '/favicon.ico'
      });
      toast.onclick = () => {
        window.focus();
        if (issueId) {
          window.location.href = '/issues/' + issueId;
        }
      };
    }
  }

  function renderDropdownItems(data) {
    const list = document.getElementById('notif-items-list');
    if (!list) return;

    if (!Array.isArray(data) || data.length === 0) {
      list.innerHTML = `<li class="notif-empty">${escapeHtml(I18N.empty)}</li>`;
      return;
    }

    list.innerHTML = data.slice(0, 10).map(n => `
      <li class="notif-item ${n.read_at ? 'read' : 'unread'}" data-id="${n.id}" data-url="${escapeHtml(n.target_url || '')}">
        <div class="notif-title">${escapeHtml(n.title)}</div>
        <div class="notif-text">${n.event_type === 'digest_summary' ? (n.body || '') : escapeHtml(n.body || '')}</div>
      </li>
    `).join('');
  }

  function escapeHtml(str) {
    return (str || '').replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[m]));
  }

  function stripHtml(html) {
    const tmp = document.createElement("div");
    tmp.innerHTML = html || "";
    return tmp.textContent || tmp.innerText || "";
  }

  menuIcon.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();

    const isVisible = dropdown.classList.contains('visible');
    if (isVisible) {
      dropdown.classList.remove('visible');
    } else {
      const rect = menuIcon.getBoundingClientRect();
      dropdown.style.top = (rect.bottom + window.scrollY + 6) + 'px';
      dropdown.style.left = (rect.right + window.scrollX - 320) + 'px';
      dropdown.classList.add('visible');
      loadNotifications();
    }
  });

  document.addEventListener('click', (e) => {
    if (dropdown && !dropdown.contains(e.target) && !menuIcon.contains(e.target)) {
      dropdown.classList.remove('visible');
    }
  });

  document.addEventListener('click', (e) => {
    if (e.target && e.target.id === 'notif-mark-all-read') {
      e.preventDefault();
      fetch('/user_notifications/read_all', {
        method: 'POST',
        headers: { 'X-CSRF-Token': getCsrfToken(), 'Accept': 'application/json' },
        credentials: 'same-origin'
      })
        .then(() => {
          badge.style.display = 'none';
          badge.textContent = '0';
          loadNotifications();
        });
    }
  });

  document.addEventListener('click', (e) => {
    const item = e.target.closest ? e.target.closest('.notif-item') : null;
    if (!item) return;

    e.preventDefault();

    const id = item.dataset.id;
    const url = item.dataset.url;
    const wasUnread = item.classList.contains('unread');
    const go = () => { if (url) { window.location.href = url; } else { loadNotifications(); } };

    if (!id || !wasUnread) { go(); return; }

    fetch('/user_notifications/' + id, {
      method: 'PATCH',
      headers: { 'X-CSRF-Token': getCsrfToken(), 'Accept': 'application/json' },
      credentials: 'same-origin'
    }).then(go, go);
  });

  loadNotifications();
  setInterval(loadNotifications, 5000);

  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }
});
