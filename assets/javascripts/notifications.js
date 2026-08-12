document.addEventListener('DOMContentLoaded', () => {
  const menuIcon = document.getElementById('notifications-menu-icon');
  if (!menuIcon) return;

  // 1. Create Badge & Dropdown elements
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
        <strong>Notifications</strong>
        <div>
          <a href="#" id="notif-mark-all-read" style="font-size: 11px;">Tout marquer lu</a>
        </div>
      </div>
      <div class="notif-body">
        <ul id="notif-items-list">
          <li class="notif-empty">Chargement...</li>
        </ul>
      </div>
      <div class="notif-footer">
        <a href="/user_notifications">Voir toutes les notifications</a>
      </div>
    `;
    document.body.appendChild(dropdown);
  }

  let lastNotifiedId = parseInt(sessionStorage.getItem('last_notified_id') || '0', 10);

  // 2. Fetch Unread Count & Items with Push Toast Trigger
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

          // Trigger native Desktop Browser Notification Toast for new unread notifications
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
          list.innerHTML = '<li class="notif-empty">Aucune notification non lue.</li>';
        }
      });
  }

  function triggerPushNotification(title, body, issueId) {
    if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
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
      list.innerHTML = '<li class="notif-empty">Aucune notification pour le moment.</li>';
      return;
    }

    list.innerHTML = data.slice(0, 10).map(n => `
      <li class="notif-item ${n.read_at ? 'read' : 'unread'}" data-id="${n.id}">
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

  // 3. Toggle Dropdown Popup under Bell Icon
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

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (dropdown && !dropdown.contains(e.target) && e.target !== menuIcon) {
      dropdown.classList.remove('visible');
    }
  });

  // Mark all as read click handler
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

  // 4. Initial Load + Periodic Polling (every 5s)
  loadNotifications();
  setInterval(loadNotifications, 5000);

  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }
});
