/* Embedded by build_arsenal_catalog.py so the catalogue also works on file://. */
class ResourceGallery {
  constructor(root, payload, escape) {
    this.root = root;
    this.data = payload || {records: [], categories: [], summary: {}};
    this.esc = escape;
    this.state = {category: 'all', folder: 'all', status: 'all', query: '', page: 1};
    this.pageSize = 48;
    this.byId = new Map(this.data.records.map(item => [item.id, item]));
    this.currentItems = [];
    this.backgrounds = ['checker', 'dark', 'light'];
    this.background = 0;
    this.notice = document.createElement('div');
    this.notice.className = 'resource-notice';
    this.notice.setAttribute('role', 'status');
    this.notice.hidden = true;
    document.body.append(this.notice);
    this.modal = document.createElement('div');
    this.modal.className = 'resource-lightbox';
    this.modal.hidden = true;
    this.modal.setAttribute('role', 'dialog');
    this.modal.setAttribute('aria-modal', 'true');
    this.modal.setAttribute('aria-labelledby', 'resourceModalTitle');
    this.modal.innerHTML = '<div class="resource-lightbox-panel">' +
      '<header class="resource-lightbox-head"><div><h2 id="resourceModalTitle"></h2><p id="resourceModalMeta"></p></div>' +
      '<button class="resource-button resource-lightbox-close" data-modal="close" aria-label="关闭预览">关闭 ×</button></header>' +
      '<div class="resource-lightbox-tools"><button class="resource-button" data-modal="prev" aria-label="上一张图片">← 上一张</button>' +
      '<button class="resource-button" data-modal="next" aria-label="下一张图片">下一张 →</button>' +
      '<button class="resource-button" data-modal="fit">适应窗口</button><button class="resource-button" data-modal="actual">原始尺寸</button>' +
      '<button class="resource-button" data-modal="minus" aria-label="缩小图片">−</button><span id="resourceZoom"></span>' +
      '<button class="resource-button" data-modal="plus" aria-label="放大图片">＋</button>' +
      '<button class="resource-button" data-modal="background">底色：网格</button></div>' +
      '<div class="resource-stage" data-background="checker"><div class="resource-stage-inner">' +
      '<img class="resource-full-image" alt=""><p class="resource-image-error" hidden>原图未能加载，请检查资源路径。</p></div></div>' +
      '<footer class="resource-lightbox-foot"><code id="resourceModalPath"></code><div class="resource-actions">' +
      '<button class="resource-button" data-modal="copy">复制路径</button><a class="resource-button" id="resourceOpenOriginal" target="_blank" rel="noopener">打开原图 ↗</a></div></footer></div>';
    document.body.append(this.modal);
    this.image = this.modal.querySelector('img');
    this.stage = this.modal.querySelector('.resource-stage');
    this.image.addEventListener('load', () => {
      this.image.hidden = false;
      this.modal.querySelector('.resource-image-error').hidden = true;
      this.resizeImage();
    });
    this.image.addEventListener('error', () => {
      this.image.hidden = true;
      this.modal.querySelector('.resource-image-error').hidden = false;
    });
    this.root.addEventListener('click', event => this.click(event));
    this.root.addEventListener('change', event => {
      if (event.target.dataset.filter) {
        this.state[event.target.dataset.filter] = event.target.value;
        this.state.page = 1; this.render();
      }
    });
    this.root.addEventListener('play', event => {
      if (event.target.tagName === 'AUDIO') this.pauseAudio(event.target);
    }, true);
    this.root.addEventListener('error', event => {
      if (event.target.tagName === 'IMG') {
        event.target.hidden = true;
        const button = event.target.closest('.resource-preview');
        if (button) {
          button.querySelector('.resource-zoom-label').style.opacity = '1';
          button.querySelector('.resource-zoom-label').textContent = '缩略图不可用 · 查看原图';
        }
      }
    }, true);
    this.modal.addEventListener('click', event => {
      if (event.target === this.modal) return this.close();
      const action = event.target.closest('[data-modal]')?.dataset.modal;
      if (action === 'close') this.close();
      if (action === 'prev') this.move(-1);
      if (action === 'next') this.move(1);
      if (action === 'copy') this.copy(this.current.path);
      if (action === 'fit') { this.zoom = null; this.resizeImage(); }
      if (action === 'actual') { this.zoom = 1; this.resizeImage(); }
      if (action === 'plus' || action === 'minus') {
        this.zoom = Math.max(.02, Math.min(8, this.effectiveZoom * (action === 'plus' ? 1.4 : 1 / 1.4)));
        this.resizeImage();
      }
      if (action === 'background') {
        this.background = (this.background + 1) % this.backgrounds.length;
        this.stage.dataset.background = this.backgrounds[this.background];
        event.target.textContent = '底色：' + ['网格', '深色', '浅色'][this.background];
      }
    });
    document.addEventListener('keydown', event => this.keydown(event));
    window.addEventListener('resize', () => { if (!this.modal.hidden) this.resizeImage(); });
  }
  pauseAudio(except) {
    this.root.querySelectorAll('audio').forEach(audio => { if (audio !== except) audio.pause(); });
  }
  setQuery(query) { this.state.query = query; this.state.page = 1; }
  filtered() {
    const query = this.state.query.trim().toLowerCase();
    return this.data.records.filter(item =>
      (this.state.category === 'all' || this.state.category === item.category) &&
      (this.state.folder === 'all' || this.state.folder === item.group) &&
      (this.state.status === 'all' || this.state.status === item.status) &&
      (!query || [item.name, item.path, item.categoryLabel, item.group, item.statusLabel, item.sceneIds.join(' '),
        item.usage.map(x => x.label).join(' ')].join(' ').toLowerCase().includes(query))
    ).sort((a, b) => {
      const order = this.data.categories.map(x => x.id);
      const status = {adopted:0, referenced:1, unconfirmed:2, candidate:3, rejected:4};
      return order.indexOf(a.category) - order.indexOf(b.category) || status[a.status] - status[b.status] ||
        a.group.localeCompare(b.group, 'zh-CN') || a.name.localeCompare(b.name, 'zh-CN');
    });
  }
  card(item) {
    const e = this.esc;
    const media = item.media === 'image' ?
      '<button class="resource-preview" data-preview="' + item.id + '" aria-label="放大查看 ' + e(item.name) + '">' +
      '<img src="' + e(item.animationPreview || item.thumbnail) + '" alt="' + e(item.name) + '" loading="lazy" decoding="async">' +
      '<span class="resource-zoom-label">点击放大 ↗</span></button>' :
      '<div class="resource-audio-cover"><b aria-hidden="true">♫</b><span>' + e(item.categoryLabel) + '<br>' +
      e(item.duration == null ? item.format : item.duration + ' 秒 · ' + item.format) + '</span></div>';
    const usage = item.usage.slice(0, 2).map(x => '<a href="' + e(x.url) + '">' + e(x.label) + '</a>').join('<br>');
    return '<article class="resource-card" data-resource-id="' + item.id + '">' + media +
      '<div class="resource-card-body"><div class="resource-tagline">' + e(item.categoryLabel) + ' / ' + e(item.group) + '</div>' +
      '<h3>' + e(item.name) + '</h3><div class="resource-meta"><span class="resource-status ' + e(item.status) + '">' +
      e(item.statusLabel) + '</span><span>' + e(item.size.length ? item.size.join(' × ') + ' px · ' : '') +
      e((item.bytes / 1024).toFixed(1)) + ' KiB</span></div>' +
      (item.media === 'audio' ? '<audio controls preload="none" aria-label="试听 ' + e(item.name) + '" src="' + e(item.url) + '"></audio>' : '') +
      '<code class="resource-path">' + e(item.path) + '</code><div class="resource-usage">' +
      (usage ? '引用入口：<br>' + usage + (item.usageCount > 2 ? '<br>共 ' + item.usageCount + ' 个静态来源' : '') : '按目录或文件名动态引用，或尚待选用核对') +
      '</div><p class="resource-note">' + e(item.note) + '</p>' +
      '<div class="resource-actions"><button class="resource-button" data-copy="' + item.id + '">复制路径</button>' +
      (item.animationPreview ? '<a class="resource-button" href="' + e(item.animationPreview) + '" target="_blank" rel="noopener">行走动画预览 ↗</a>' : '') +
      '<a class="resource-button" href="' + e(item.url) + '" target="_blank" rel="noopener">' + (item.media === 'image' ? '打开原图' : '打开音频') + ' ↗</a></div></div></article>';
  }
  render() {
    this.pauseAudio();
    this.currentItems = this.filtered();
    this.totalPages = Math.max(1, Math.ceil(this.currentItems.length / this.pageSize));
    this.state.page = Math.max(1, Math.min(this.state.page, this.totalPages));
    const offset = (this.state.page - 1) * this.pageSize;
    const items = this.currentItems.slice(offset, offset + this.pageSize);
    const e = this.esc;
    const folders = [...new Set(this.data.records.filter(x => this.state.category === 'all' || x.category === this.state.category).map(x => x.group))].sort((a,b) => a.localeCompare(b, 'zh-CN'));
    this.root.innerHTML = '<header class="resource-intro"><div><h2>资源库</h2><p>地图、人物与声音按类别收录。点击缩略图查看原图，音频可直接试听；路径可复制到新模块。' +
      '“配置引用”与“正式接入”分别标注，其他城镇、AP 与新增音频候选单列。<a href="resource-reuse-index.md">完整资源索引 ↗</a></p></div>' +
      '<div class="resource-tally"><strong>' + this.data.summary.total + '</strong> 项<br>' + this.data.summary.images + ' 张图像 · ' + this.data.summary.audio +
      ' 个音频<br>资源同步：' + e(this.data.generatedAt) + '</div></header>' +
      '<nav class="resource-categories" aria-label="资源分类">' +
      [{id: 'all', name: '全部资源', count: this.data.records.length}, ...this.data.categories].map(c => '<button data-category="' + c.id +
      '" aria-pressed="' + (this.state.category === c.id) + '">' + e(c.name) + '<span>' + c.count + '</span></button>').join('') + '</nav>' +
      '<div class="resource-tools"><label><span>使用状态</span><select data-filter="status" aria-label="资源使用状态">' +
      [['all','全部使用状态'],['adopted','正式接入 / 认可库'],['referenced','配置中有引用'],['candidate','候选 · 未正式'],['unconfirmed','使用状态待核对'],['rejected','弃用 / 退役稿']].map(([value,label]) =>
        '<option value="' + value + '"' + (this.state.status === value ? ' selected' : '') + '>' + label + '</option>').join('') +
      '</select></label><label><span>子分类 / 模块</span><select data-filter="folder" aria-label="资源子分类"><option value="all">全部子分类</option>' +
      folders.map(folder => '<option' + (this.state.folder === folder ? ' selected' : '') + ' value="' + e(folder) + '">' + e(folder) + '</option>').join('') +
      '</select></label><button class="resource-button resource-clear" data-clear>清除筛选</button></div>' +
      '<div class="resource-results" role="status"><span>找到 <strong>' + this.currentItems.length + '</strong> 项' +
      (items.length ? ' · 当前 ' + (offset + 1) + '–' + (offset + items.length) : '') + '</span><span>缩略图保留透明背景 · 原图按需打开</span></div>' +
      '<div class="resource-grid">' + (items.length ? items.map(item => this.card(item)).join('') :
      '<div class="empty">没有匹配的资源<br><small>试试名称、路径或其他类别</small></div>') + '</div>' +
      '<nav class="resource-pager" aria-label="资源分页"><button class="resource-button" data-page="-1"' + (this.state.page === 1 ? ' disabled' : '') +
      '>← 上一页</button><span>第 ' + this.state.page + ' / ' + this.totalPages + ' 页 · 每页 ' + this.pageSize + ' 项</span>' +
      '<button class="resource-button" data-page="1"' + (this.state.page === this.totalPages ? ' disabled' : '') + '>下一页 →</button></nav>';
  }
  click(event) {
    const category = event.target.closest('[data-category]');
    const preview = event.target.closest('[data-preview]');
    const copy = event.target.closest('[data-copy]');
    const page = event.target.closest('[data-page]');
    if (category) { this.state.category = category.dataset.category; this.state.folder = 'all'; this.state.page = 1; this.render(); }
    if (preview) this.open(this.byId.get(preview.dataset.preview), preview);
    if (copy) this.copy(this.byId.get(copy.dataset.copy).path);
    if (page && !page.disabled) { this.state.page += Number(page.dataset.page); this.render(); this.root.scrollIntoView({block:'start'}); }
    if (event.target.closest('[data-clear]')) {
      this.state = {category:'all', folder:'all', status:'all', query:'', page:1};
      document.querySelector('#search').value = '';
      document.querySelector('#search').dispatchEvent(new Event('input', {bubbles:true}));
    }
  }
  open(item, trigger) {
    if (!item || item.media !== 'image') return;
    this.pauseAudio();
    if (this.modal.hidden) this.returnFocus = trigger;
    this.current = item; this.zoom = null;
    this.images = this.currentItems.filter(x => x.media === 'image');
    const index = this.images.findIndex(x => x.id === item.id);
    this.modal.querySelector('[data-modal="prev"]').disabled = index <= 0;
    this.modal.querySelector('[data-modal="next"]').disabled = index < 0 || index >= this.images.length - 1;
    this.modal.querySelector('#resourceModalTitle').textContent = item.name;
    this.modal.querySelector('#resourceModalMeta').textContent = (item.animationPreview ? '行走循环预览 · 原图规格 ' : item.categoryLabel + ' · ') + item.size.join(' × ') + ' px · ' + item.statusLabel;
    this.modal.querySelector('#resourceModalPath').textContent = item.path;
    this.modal.querySelector('#resourceOpenOriginal').href = item.url;
    this.image.hidden = true;
    this.modal.querySelector('.resource-image-error').hidden = true;
    this.image.alt = item.name; this.image.src = item.animationPreview || item.url;
    this.modal.hidden = false; document.body.classList.add('gallery-open');
    this.modal.querySelector('[data-modal="close"]').focus();
    if (this.image.complete && this.image.naturalWidth) { this.image.hidden = false; this.resizeImage(); }
  }
  resizeImage() {
    if (!this.image.naturalWidth || this.modal.hidden) return;
    const fit = Math.min(1, Math.max(1, this.stage.clientWidth - 40) / this.image.naturalWidth,
      Math.max(1, this.stage.clientHeight - 40) / this.image.naturalHeight);
    this.effectiveZoom = this.zoom == null ? fit : this.zoom;
    this.image.style.width = Math.max(1, Math.round(this.image.naturalWidth * this.effectiveZoom)) + 'px';
    this.image.style.height = Math.max(1, Math.round(this.image.naturalHeight * this.effectiveZoom)) + 'px';
    this.modal.querySelector('#resourceZoom').textContent = Math.round(this.effectiveZoom * 100) + '%';
  }
  move(direction) {
    const index = this.images.findIndex(x => x.id === this.current.id) + direction;
    if (this.images[index]) this.open(this.images[index]);
  }
  close() {
    this.modal.hidden = true; document.body.classList.remove('gallery-open');
    if (this.returnFocus?.isConnected) this.returnFocus.focus();
  }
  keydown(event) {
    if (this.modal.hidden) return;
    if (event.key === 'Escape') { event.preventDefault(); this.close(); }
    if (event.key === 'ArrowLeft') { event.preventDefault(); this.move(-1); }
    if (event.key === 'ArrowRight') { event.preventDefault(); this.move(1); }
    if (event.key === 'Tab') {
      const nodes = [...this.modal.querySelectorAll('button:not(:disabled), a[href]')];
      const first = nodes[0], last = nodes[nodes.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    }
  }
  async copy(path) {
    let ok = false;
    try { await navigator.clipboard.writeText(path); ok = true; } catch (_) {
      const input = document.createElement('textarea');
      input.value = path; input.style.cssText = 'position:fixed;left:-9999px';
      const focus = document.activeElement;
      document.body.append(input); input.select();
      try { ok = document.execCommand('copy'); } catch (_) { /* visible manual fallback below */ }
      input.remove(); focus?.focus();
    }
    this.notice.textContent = ok ? '路径已复制' : '复制未完成，请选中卡片上的路径手动复制';
    this.notice.hidden = false;
    clearTimeout(this.noticeTimer);
    this.noticeTimer = setTimeout(() => { this.notice.hidden = true; }, 2500);
  }
}
