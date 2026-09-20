<template>
  <main class="workbench tenant-workbench">
    <section class="workbench-hero">
      <div class="hero-orb hero-orb-one"></div>
      <div class="hero-orb hero-orb-two"></div>
      <div class="hero-copy">
        <div class="eyebrow"><Icon icon="ep:magic-stick" /> TEAM PULSE</div>
        <h1>早上好，{{ username }}<span>。</span></h1>
        <p>团队运行平稳。把注意力留给今天真正重要的事情。</p>
        <div class="hero-meta"><span class="live-dot"></span> 工作台数据实时同步</div>
      </div>
      <button class="hero-message" type="button" @click="go('/user/notify-message')">
        <Icon icon="ep:chat-dot-round" />
        <span><b>{{ overview.unreadMessageCount }}</b> 条待处理消息</span>
        <Icon icon="ep:arrow-right" />
      </button>
    </section>

    <section v-if="metrics.length" class="metric-grid" v-loading="loading">
      <article v-for="metric in metrics" :key="metric.label" class="metric-card" :class="metric.tone" @click="go(metric.path)">
        <div class="metric-icon"><Icon :icon="metric.icon" /></div>
        <div><p>{{ metric.label }}</p><strong>{{ metric.value }}</strong><small>{{ metric.note }}</small></div>
        <Icon class="metric-arrow" icon="ep:arrow-up-right" />
      </article>
    </section>

    <section v-if="quickActions.length || hasNoticeAccess" :class="['workbench-grid', { 'workbench-grid--single': !quickActions.length || !hasNoticeAccess }]">
      <article v-if="quickActions.length" class="panel quick-panel">
        <header><div><span class="panel-kicker">FOCUS</span><h2>快捷行动</h2></div><span class="panel-hint">高频工作入口</span></header>
        <div class="quick-list">
          <button v-for="item in quickActions" :key="item.label" type="button" class="quick-action" @click="go(item.path)">
            <span :class="['quick-icon', item.tone]"><Icon :icon="item.icon" /></span><span>{{ item.label }}</span><Icon icon="ep:arrow-right" />
          </button>
        </div>
      </article>

      <article v-if="hasNoticeAccess" class="panel notice-panel" v-loading="loading">
        <header><div><span class="panel-kicker">SIGNAL</span><h2>最新公告</h2></div><button type="button" class="text-action" @click="go('/system/notice')">查看全部 <Icon icon="ep:arrow-right" /></button></header>
        <div v-if="overview.recentNotices.length" class="notice-list">
          <button v-for="notice in overview.recentNotices" :key="notice.id" type="button" class="notice-item" @click="go('/system/notice')">
            <span class="notice-dot"></span><span class="notice-content"><b>{{ notice.title }}</b><small>{{ formatDate(notice.createTime) }}</small></span><Icon icon="ep:arrow-right" />
          </button>
        </div>
        <div v-else class="empty-state"><Icon icon="ep:bell" /><span>暂时没有新公告</span></div>
      </article>
    </section>
  </main>
</template>

<script lang="ts" setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import { getTenantDashboardOverview, type TenantDashboardOverview } from '@/api/dashboard'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)
const username = computed(() => userStore.getUser.nickname || '管理员')
const overview = reactive<TenantDashboardOverview>({ userCount: 0, enabledUserCount: 0, unreadMessageCount: 0, recentNotices: [] })

const can = (permission: string) => userStore.getPermissions.has('*:*:*') || userStore.getPermissions.has(permission)
const hasUserAccess = computed(() => can('system:user:query'))
const hasNoticeAccess = computed(() => can('system:notice:query'))
const metrics = computed(() => [
  { label: '团队成员', value: overview.userCount, note: '当前租户全部成员', icon: 'ep:user', tone: 'indigo', path: '/system/user', visible: hasUserAccess.value },
  { label: '正常账号', value: overview.enabledUserCount, note: '可正常访问后台', icon: 'ep:circle-check-filled', tone: 'mint', path: '/system/user', visible: hasUserAccess.value },
  { label: '待处理消息', value: overview.unreadMessageCount, note: '需要你的关注', icon: 'ep:message', tone: 'amber', path: '/user/notify-message' }
].filter((metric) => metric.visible !== false))
const quickActions = computed(() => [
  { label: '成员管理', icon: 'ep:user-filled', tone: 'indigo', path: '/system/user', visible: hasUserAccess.value },
  { label: '角色与权限', icon: 'ep:key', tone: 'violet', path: '/system/role', visible: can('system:role:query') },
  { label: '部门结构', icon: 'ep:connection', tone: 'cyan', path: '/system/dept', visible: can('system:dept:query') },
  { label: '公告管理', icon: 'ep:bell', tone: 'amber', path: '/system/notice', visible: hasNoticeAccess.value }
].filter((item) => item.visible))
const go = (path: string) => router.push(path)
const formatDate = (value?: string | number) => {
  if (!value) return '刚刚'
  if (typeof value === 'string') return value.slice(0, 10).replaceAll('-', '.')
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return '刚刚'
  return `${parsed.getFullYear()}.${String(parsed.getMonth() + 1).padStart(2, '0')}.${String(parsed.getDate()).padStart(2, '0')}`
}

onMounted(async () => {
  loading.value = true
  try { Object.assign(overview, await getTenantDashboardOverview()) } finally { loading.value = false }
})
</script>

<style lang="scss" scoped>
.workbench{--ink:#17213a;--muted:#75809a;max-width:1440px;margin:0 auto;padding:4px 4px 28px;color:var(--ink)}
.workbench-hero{position:relative;overflow:hidden;display:flex;align-items:center;justify-content:space-between;min-height:205px;padding:34px 42px;border-radius:22px;background:linear-gradient(120deg,#252d83,#4f46e5 58%,#7774f6);box-shadow:0 18px 42px rgba(66,56,190,.22);color:#fff}.hero-orb{position:absolute;border-radius:50%;background:rgba(255,255,255,.11);filter:blur(1px)}.hero-orb-one{width:280px;height:280px;right:18%;top:-160px}.hero-orb-two{width:180px;height:180px;right:-35px;bottom:-90px}.hero-copy,.hero-message{position:relative;z-index:1}.eyebrow,.panel-kicker{display:flex;align-items:center;gap:6px;font-size:11px;font-weight:800;letter-spacing:1.2px}.eyebrow{opacity:.78}.hero-copy h1{margin:10px 0 6px;font-size:29px;letter-spacing:-.5px}.hero-copy h1 span{color:#b9c4ff}.hero-copy p{margin:0;color:rgba(255,255,255,.78)}.hero-meta{display:flex;align-items:center;gap:7px;margin-top:18px;font-size:12px;color:#dfe3ff}.live-dot{width:7px;height:7px;border-radius:50%;background:#83f2c0;box-shadow:0 0 0 5px rgba(131,242,192,.16)}.hero-message{display:flex;align-items:center;gap:11px;min-width:176px;padding:15px 18px;border:1px solid rgba(255,255,255,.2);border-radius:15px;background:rgba(19,24,95,.24);color:#fff;backdrop-filter:blur(10px);cursor:pointer}.hero-message b{display:block;font-size:17px}.hero-message span{flex:1;text-align:left;font-size:12px}.metric-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin:18px 0}.metric-card{position:relative;display:flex;align-items:center;gap:15px;min-height:118px;padding:19px;border:1px solid #e8ebf5;border-radius:17px;background:#fff;box-shadow:0 7px 18px rgba(30,41,80,.045);cursor:pointer;transition:.25s ease}.metric-card:hover{transform:translateY(-3px);box-shadow:0 14px 26px rgba(50,57,126,.12)}.metric-icon{display:grid;place-items:center;width:45px;height:45px;border-radius:14px;font-size:21px}.indigo .metric-icon,.quick-icon.indigo{background:#ecebff;color:#5148e8}.mint .metric-icon{background:#e6f8f0;color:#16a471}.amber .metric-icon,.quick-icon.amber{background:#fff3df;color:#e99119}.metric-card p,.metric-card small{display:block;margin:0;color:var(--muted);font-size:12px}.metric-card strong{display:block;margin:3px 0;font-size:26px;letter-spacing:-.5px}.metric-arrow{position:absolute;right:17px;top:16px;color:#abb4c8}.workbench-grid{display:grid;grid-template-columns:1.08fr 1fr;gap:18px}.panel{min-height:274px;padding:24px;border:1px solid #e9edf6;border-radius:19px;background:#fff;box-shadow:0 7px 18px rgba(30,41,80,.04)}.panel header{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:18px}.panel-kicker{color:#7e78ee}.panel h2{margin:4px 0 0;font-size:17px}.panel-hint{color:#9ba5b8;font-size:12px}.quick-list{display:grid;grid-template-columns:1fr 1fr;gap:10px}.quick-action,.notice-item{display:flex;align-items:center;border:0;background:transparent;cursor:pointer}.quick-action{gap:10px;padding:11px;border-radius:12px;color:#34405b;text-align:left}.quick-action:hover{background:#f6f7ff}.quick-action>span:nth-child(2){flex:1;font-size:13px}.quick-action>svg,.notice-item>svg{color:#a5aec1}.quick-icon{display:grid;place-items:center;width:34px;height:34px;border-radius:10px}.quick-icon.violet{background:#f2eaff;color:#8b54d9}.quick-icon.cyan{background:#e6f7fb;color:#1ca7bc}.text-action{display:flex;align-items:center;gap:3px;border:0;background:transparent;color:#5b52e9;font-size:12px;cursor:pointer}.notice-list{display:grid}.notice-item{gap:12px;width:100%;padding:12px 0;border-bottom:1px solid #f0f2f7;text-align:left}.notice-item:last-child{border-bottom:0}.notice-dot{width:7px;height:7px;border-radius:50%;background:#7067ed;box-shadow:0 0 0 4px #f0efff}.notice-content{flex:1;min-width:0}.notice-content b{display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:13px;font-weight:600;color:#39435b}.notice-content small{display:block;margin-top:4px;color:#9da7ba;font-size:11px}.empty-state{display:grid;place-items:center;gap:8px;height:160px;color:#a3adbf;font-size:13px}.empty-state svg{font-size:25px}@media(max-width:900px){.workbench-hero{padding:28px;min-height:unset}.metric-grid,.workbench-grid{grid-template-columns:1fr}.hero-message{display:none}}@media(max-width:560px){.workbench{padding:0}.hero-copy h1{font-size:23px}.quick-list{grid-template-columns:1fr}.metric-grid{gap:10px}.metric-card{min-height:100px}}
.workbench-grid--single{grid-template-columns:1fr}

:global(html.dark) .tenant-workbench{--ink:var(--el-text-color-primary);--muted:var(--el-text-color-secondary)}
:global(html.dark) .tenant-workbench .metric-card,:global(html.dark) .tenant-workbench .panel{background:var(--el-bg-color);border-color:rgba(255,255,255,.08);box-shadow:0 10px 24px rgba(0,0,0,.16)}
:global(html.dark) .tenant-workbench .metric-card:hover,:global(html.dark) .tenant-workbench .quick-action:hover{background:var(--el-fill-color-light);box-shadow:0 15px 30px rgba(0,0,0,.25)}
:global(html.dark) .tenant-workbench .quick-action{color:var(--el-text-color-primary)}
:global(html.dark) .tenant-workbench .notice-item{border-bottom-color:rgba(255,255,255,.07)}
:global(html.dark) .tenant-workbench .notice-content b{color:var(--el-text-color-primary)}
:global(html.dark) .tenant-workbench .notice-content small,:global(html.dark) .tenant-workbench .panel-hint,:global(html.dark) .tenant-workbench .empty-state{color:var(--el-text-color-secondary)}
:global(html.dark) .tenant-workbench .indigo .metric-icon,:global(html.dark) .tenant-workbench .quick-icon.indigo{background:#282550;color:#a9a2ff}:global(html.dark) .tenant-workbench .mint .metric-icon{background:#153b35;color:#5fddad}:global(html.dark) .tenant-workbench .amber .metric-icon,:global(html.dark) .tenant-workbench .quick-icon.amber{background:#472f16;color:#ffbf63}:global(html.dark) .tenant-workbench .quick-icon.violet{background:#38234d;color:#d1a8ff}:global(html.dark) .tenant-workbench .quick-icon.cyan{background:#153b46;color:#70d7ed}:global(html.dark) .tenant-workbench .notice-dot{box-shadow:0 0 0 4px #29254c}
</style>
